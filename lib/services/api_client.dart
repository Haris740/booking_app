import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://booking-backend-0b9z.onrender.com';
  // static const String baseUrl = 'http://10.0.2.2:4000';
  static final http.Client _client = http.Client();
  
  // Prevent multiple simultaneous refresh attempts
  static bool _isRefreshing = false;

  // Get stored tokens
  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  // Save tokens
  static Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  // Save user ID
  static Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await _getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Refresh access token
  static Future<bool> refreshAccessToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      debugPrint('🔄 Refresh already in progress, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      return await isLoggedIn();
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      debugPrint('🔄 Attempting token refresh...');

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh timeout');
        },
      );

      debugPrint('🔄 Refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          debugPrint('❌ Empty response body from refresh endpoint');
          await clearTokens();
          return false;
        }

        final data = jsonDecode(response.body);

        if (data == null || data['tokens'] == null) {
          debugPrint('❌ Invalid response structure: $data');
          await clearTokens();
          return false;
        }

        final tokens = data['tokens'];
        if (tokens['accessToken'] == null || tokens['refreshToken'] == null) {
          debugPrint('❌ Missing tokens in response');
          await clearTokens();
          return false;
        }

        await _saveTokens(
          tokens['accessToken'].toString(),
          tokens['refreshToken'].toString(),
        );

        debugPrint('✅ Token refresh successful');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('❌ Refresh token expired or invalid');
        await clearTokens();
        return false;
      } else {
        debugPrint('❌ Refresh failed with status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      await clearTokens();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Handle session expiry
  static Future<void> handleSessionExpired() async {
    debugPrint('🚪 Session expired - clearing tokens');
    await clearTokens();
  }

  // Clear tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userCity');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
  }

  // Common request handler to avoid code duplication
  static Future<http.Response> _makeRequest({
    required Future<http.Response> Function(Map<String, String> headers) request,
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw ApiException(
          message: 'No access token available',
          statusCode: 401,
        );
      }
    }

    var response = await request(headers);

    // Handle token expiration
    if (response.statusCode == 401 && requiresAuth) {
      debugPrint('🔄 Token expired, attempting refresh...');
      final refreshed = await refreshAccessToken();

      if (refreshed) {
        final newToken = await _getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $newToken';
          response = await request(headers);
        }
      } else {
        await handleSessionExpired();
        throw ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
    }

    return response;
  }

  // Process response
  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw ApiException(message: 'Empty response from server');
    }

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(
        message: responseData['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  // POST request with auto token refresh
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _makeRequest(
        request: (headers) => _client.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        ),
        requiresAuth: requiresAuth,
      );

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  // GET request with auto token refresh
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _makeRequest(
        request: (headers) {
          // Remove Content-Type for GET requests
          headers.remove('Content-Type');
          return _client.get(uri, headers: headers);
        },
        requiresAuth: requiresAuth,
      );

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  // PATCH request with auto token refresh
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _makeRequest(
        request: (headers) => _client.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(data),
        ),
        requiresAuth: requiresAuth,
      );

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  // DELETE request with auto token refresh
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final response = await _makeRequest(
        request: (headers) {
          // Remove Content-Type for DELETE requests
          headers.remove('Content-Type');
          return _client.delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          );
        },
        requiresAuth: requiresAuth,
      );

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  // ==================== AUTH ====================

  static Future<String> sendOtp(String phone) async {
    final response = await post('/auth/send-otp', {'phone': phone});
    return response['message'] ?? 'OTP sent successfully';
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    final response = await post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });

    if (response['tokens'] == null || response['user'] == null) {
      throw ApiException(message: 'Invalid response from server');
    }

    await _saveTokens(
      response['tokens']['accessToken'].toString(),
      response['tokens']['refreshToken'].toString(),
    );
    await _saveUserId(response['user']['id'].toString());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', phone);
    if (response['user']['name'] != null) {
      await prefs.setString('userName', response['user']['name'].toString());
    }
    if (response['user']['city'] != null) {
      await prefs.setString('userCity', response['user']['city'].toString());
    }
    if (response['user']['email'] != null) {
      await prefs.setString('userEmail', response['user']['email'].toString());
    }

    return response['user'];
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    String? city,
  }) async {
    final response = await post('/auth/register', {
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (city != null && city.isNotEmpty) 'city': city,
    }, requiresAuth: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    if (city != null && city.isNotEmpty) {
      await prefs.setString('userCity', city);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString('userEmail', email);
    }

    return response['user'];
  }

  // ==================== USER PROFILE ====================

  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await get('/me/me', requiresAuth: true);

    if (response['user'] == null) {
      throw ApiException(message: 'Invalid response from server');
    }

    final user = response['user'];
    final prefs = await SharedPreferences.getInstance();
    
    if (user['name'] != null) {
      await prefs.setString('userName', user['name'].toString());
    }
    if (user['city'] != null) {
      await prefs.setString('userCity', user['city'].toString());
    }
    if (user['email'] != null) {
      await prefs.setString('userEmail', user['email'].toString());
    }
    if (user['phone'] != null) {
      await prefs.setString('userPhone', user['phone'].toString());
    }

    return user;
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? city,
    String? profilePicture,
  }) async {
    final response = await patch('/me/me', {
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (city != null && city.isNotEmpty) 'city': city,
      if (profilePicture != null && profilePicture.isNotEmpty) 
        'profilePicture': profilePicture,
    }, requiresAuth: true);

    final user = response['user'];
    final prefs = await SharedPreferences.getInstance();
    
    if (user['name'] != null) {
      await prefs.setString('userName', user['name'].toString());
    }
    if (user['city'] != null) {
      await prefs.setString('userCity', user['city'].toString());
    }
    if (user['email'] != null) {
      await prefs.setString('userEmail', user['email'].toString());
    }

    return user;
  }

  // ==================== PROFESSIONALS ====================

  static Future<List<dynamic>> searchProfessionals({
    String? city,
    String? professionType,
    String? q,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (city != null && city.isNotEmpty) params['city'] = city;
    if (professionType != null && professionType.isNotEmpty) {
      params['professionType'] = professionType;
    }
    if (q != null && q.isNotEmpty) params['q'] = q;

    try {
      final response = await get(
        '/professional',
        queryParams: params,
        requiresAuth: true,
      );

      // Handle different possible response structures
      if (response['data'] is List) {
        return response['data'] as List<dynamic>;
      } else if (response['professionals'] is List) {
        return response['professionals'] as List<dynamic>;
      } else if (response['results'] is List) {
        return response['results'] as List<dynamic>;
      }

      debugPrint('⚠️ Unexpected response structure: $response');
      return [];
    } catch (e) {
      debugPrint('❌ Search professionals error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getProfessionalById(String id) async {
    final response = await get('/professional/$id', requiresAuth: true);

    // Handle different response structures
    if (response['professional'] != null) {
      return response['professional'] as Map<String, dynamic>;
    } else if (response['data'] != null) {
      return response['data'] as Map<String, dynamic>;
    }

    return response;
  }

  static Future<Map<String, dynamic>> applyProfessional({
    required String title,
    required String professionType,
    required String categorySlug,
    required int categoryId,
    required String about,
    required String city,
    required String consultationMode,
    required int baseFee,
    required int yearsExperience,
    required String bookingType,
    String? address,
    String? proof,
    List<String>? tags,
  }) async {
    final response = await post('/professional/apply', {
      'title': title,
      'professionType': professionType,
      'categorySlug': categorySlug,
      'categoryId': categoryId,
      'about': about,
      'city': city,
      'consultationMode': consultationMode,
      'baseFee': baseFee,
      'yearsExperience': yearsExperience,
      'bookingType': bookingType,
      if (address != null && address.isNotEmpty) 'address': address,
      if (proof != null && proof.isNotEmpty) 'proof': proof,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    }, requiresAuth: true);
    
    return response;
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await get('/professional/categories');
    return response['categories'] ?? [];
  }

  // ==================== PROFESSIONAL STAFF MANAGEMENT ====================

  static Future<Map<String, dynamic>> inviteStaff({
    required String phone,
    String? message,
  }) async {
    return await post('/professional/staff/invite', {
      'phone': phone,
      if (message != null && message.isNotEmpty) 'message': message,
    }, requiresAuth: true);
  }

  static Future<List<dynamic>> getProfessionalStaff() async {
    final response = await get('/professional/staff', requiresAuth: true);
    return response['staff'] ?? [];
  }

  static Future<void> removeStaff(String staffId) async {
    await delete('/professional/staff/$staffId', requiresAuth: true);
  }

  // ==================== USER STAFF INVITATIONS ====================

  static Future<List<dynamic>> getStaffInvitations() async {
    final response = await get(
      '/professional/staff/invitations',
      requiresAuth: true,
    );
    return response['invitations'] ?? [];
  }

  static Future<void> acceptStaffInvitation(String invitationId) async {
    await post(
      '/professional/staff/invitations/$invitationId/accept',
      {},
      requiresAuth: true,
    );
  }

  static Future<void> rejectStaffInvitation(String invitationId) async {
    await post(
      '/professional/staff/invitations/$invitationId/reject',
      {},
      requiresAuth: true,
    );
  }

  // ==================== PROFESSIONAL STATUS ====================

  static Future<Map<String, dynamic>> canApplyProfessional() async {
    return await get('/professional/can-apply', requiresAuth: true);
  }

  // ==================== QUEUE MANAGEMENT ====================

  static Future<Map<String, dynamic>> getTodayQueue({
    String? professionalId,
  }) async {
    final queryParams = professionalId != null && professionalId.isNotEmpty
        ? {'professionalId': professionalId}
        : null;
    return await get(
      '/bookings/queue/today',
      requiresAuth: true,
      queryParams: queryParams,
    );
  }

  static Future<Map<String, dynamic>> callNextToken({
    required String professionalId,
    required DateTime date,
  }) async {
    return await post('/bookings/call-next', {
      'professionalId': professionalId,
      'date': date.toUtc().toIso8601String(),
    }, requiresAuth: true);
  }

  static Future<Map<String, dynamic>> markNoShow(String bookingId) async {
    return await patch(
      '/bookings/$bookingId/no-show',
      {},
      requiresAuth: true,
    );
  }

  // ==================== BOOKINGS ====================

  static Future<Map<String, dynamic>> createTokenBooking({
    required String professionalId,
    required String name,
    required int age,
    required String gender,
    required String phone,
    required DateTime appointmentDate,
  }) async {
    final response = await post('/bookings/token', {
      'professionalId': professionalId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'appointmentDate': appointmentDate.toIso8601String(),
    }, requiresAuth: true);
    
    return response['booking'] ?? response;
  }

  static Future<Map<String, dynamic>> createTimeslotBooking({
    required String professionalId,
    required String name,
    required int age,
    required String gender,
    required String phone,
    required DateTime appointmentDate,
    required String timeSlot,
  }) async {
    final response = await post('/bookings/timeslot', {
      'professionalId': professionalId,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
    }, requiresAuth: true);
    
    return response['booking'] ?? response;
  }

  static Future<List<dynamic>> getMyBookings() async {
    final response = await get('/bookings/my', requiresAuth: true);
    return response['bookings'] ?? [];
  }

  static Future<Map<String, dynamic>> getBookingStatus(String bookingId) async {
    return await get('/bookings/$bookingId/status', requiresAuth: true);
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await patch(
      '/bookings/$bookingId/cancel',
      {},
      requiresAuth: true,
    );
    return response['booking'] ?? response;
  }

  // ==================== ADMIN ====================

  static Future<List<dynamic>> getPendingProfessionals() async {
    final response = await get(
      '/admin/professionals/pending',
      requiresAuth: true,
    );
    return response['professionals'] ?? [];
  }

  static Future<Map<String, dynamic>> approveProfessional(
    String id, {
    String? adminNote,
  }) async {
    final response = await patch('/admin/professionals/$id/approve', {
      if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
    }, requiresAuth: true);
    
    return response['professional'] ?? response;
  }

  static Future<Map<String, dynamic>> rejectProfessional(
    String id, {
    String? adminNote,
  }) async {
    final response = await patch('/admin/professionals/$id/reject', {
      if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
    }, requiresAuth: true);
    
    return response['professional'] ?? response;
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await get('/admin/users', requiresAuth: true);
    return response['users'] ?? [];
  }

  static Future<List<dynamic>> getAllBookings() async {
    final response = await get('/admin/bookings', requiresAuth: true);
    return response['bookings'] ?? [];
  }

  // ==================== DEBUG ====================

  /// Decode and debugPrint JWT token info
  static Future<void> debugToken() async {
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('❌ No token found');
      return;
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('❌ Invalid token format');
        return;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);

      debugPrint('🔑 TOKEN DEBUG:');
      debugPrint('User ID: ${data['sub'] ?? data['userId'] ?? data['id'] ?? 'N/A'}');
      debugPrint('Role: ${data['role'] ?? 'N/A'}');
      debugPrint('Is Professional: ${data['isProfessional'] ?? 'N/A'}');

      if (data['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
        final now = DateTime.now();
        final remaining = expiry.difference(now);

        debugPrint(
          'Issued at: ${data['iat'] != null ? DateTime.fromMillisecondsSinceEpoch(data['iat'] * 1000) : 'N/A'}',
        );
        debugPrint('Expires at: $expiry');
        debugPrint('Current time: $now');
        debugPrint(
          'Time remaining: ${remaining.isNegative ? 'EXPIRED' : '${remaining.inHours}h ${remaining.inMinutes % 60}m'}',
        );
        debugPrint('Is expired: ${expiry.isBefore(now)}');
      }

      debugPrint('Full payload: $data');
    } catch (e) {
      debugPrint('❌ Error decoding token: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
