import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://booking-backend-0b9z.onrender.com';
  static final http.Client _client = http.Client();

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
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveTokens(
          data['tokens']['accessToken'],
          data['tokens']['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
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

  // POST request with auto token refresh
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      var response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );

      // If token expired, try to refresh
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final newToken = await _getAccessToken();
          headers['Authorization'] = 'Bearer $newToken';
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else {
          throw ApiException(message: 'Session expired. Please login again.');
        }
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
    var uri = Uri.parse('$baseUrl$endpoint');

    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = <String, String>{};

    if (requiresAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      var response = await _client.get(uri, headers: headers);

      // If token expired, try to refresh
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          final newToken = await _getAccessToken();
          headers['Authorization'] = 'Bearer $newToken';
          response = await _client.get(uri, headers: headers);
        } else {
          throw ApiException(message: 'Session expired. Please login again.');
        }
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
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      var response = await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode(data),
      );

      // If token expired, try to refresh
      if (response.statusCode == 401 && requiresAuth) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          final newToken = await _getAccessToken();
          headers['Authorization'] = 'Bearer $newToken';
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else {
          throw ApiException(message: 'Session expired. Please login again.');
        }
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e');
    }
  }

  // ==================== AUTH ====================

  static Future<String> sendOtp(String phone) async {
    final response = await post('/auth/send-otp', {'phone': phone});
    return response['message'];
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    final response = await post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
    });

    await _saveTokens(
      response['tokens']['accessToken'],
      response['tokens']['refreshToken'],
    );
    await _saveUserId(response['user']['id']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', phone);
    if (response['user']['name'] != null) {
      await prefs.setString('userName', response['user']['name']);
    }
    if (response['user']['city'] != null) {
      await prefs.setString('userCity', response['user']['city']);
    }
    if (response['user']['email'] != null) {
      await prefs.setString('userEmail', response['user']['email']);
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
      if (email != null) 'email': email,
      if (city != null) 'city': city,
    }, requiresAuth: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    if (city != null) {
      await prefs.setString('userCity', city);
    }
    if (email != null) {
      await prefs.setString('userEmail', email);
    }

    return response['user'];
  }

  // ==================== USER PROFILE ====================

  static Future<Map<String, dynamic>> getMyProfile() async {
    final response = await get('/me', requiresAuth: true);

    final user = response['user'];
    final prefs = await SharedPreferences.getInstance();
    if (user['name'] != null) {
      await prefs.setString('userName', user['name']);
    }
    if (user['city'] != null) {
      await prefs.setString('userCity', user['city']);
    }
    if (user['email'] != null) {
      await prefs.setString('userEmail', user['email']);
    }
    if (user['phone'] != null) {
      await prefs.setString('userPhone', user['phone']);
    }

    return user;
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? city,
    String? profilePicture,
  }) async {
    final response = await patch('/me', {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (city != null) 'city': city,
      if (profilePicture != null) 'profilePicture': profilePicture,
    }, requiresAuth: true);

    final user = response['user'];
    final prefs = await SharedPreferences.getInstance();
    if (user['name'] != null) {
      await prefs.setString('userName', user['name']);
    }
    if (user['city'] != null) {
      await prefs.setString('userCity', user['city']);
    }
    if (user['email'] != null) {
      await prefs.setString('userEmail', user['email']);
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

    if (city != null) params['city'] = city;
    if (professionType != null) params['professionType'] = professionType;
    if (q != null) params['q'] = q;

    final response = await get('/professional', queryParams: params);
    return response['data'];
  }

  static Future<Map<String, dynamic>> getProfessionalById(String id) async {
    final response = await get('/professional/$id');
    return response;
  }

  static Future<Map<String, dynamic>> applyProfessional({
    required String title,
    required String professionType,
    required String categorySlug,
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
      'about': about,
      'city': city,
      'consultationMode': consultationMode,
      'baseFee': baseFee,
      'yearsExperience': yearsExperience,
      'bookingType': bookingType,
      if (address != null) 'address': address,
      if (proof != null) 'proof': proof,
      if (tags != null) 'tags': tags,
    }, requiresAuth: true);
    return response;
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await get('/professional/categories');
    return response['categories'];
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
    return response['booking'];
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
    return response['booking'];
  }

  static Future<List<dynamic>> getMyBookings() async {
    final response = await get('/bookings/my', requiresAuth: true);
    return response['bookings'];
  }

  static Future<Map<String, dynamic>> getBookingStatus(String bookingId) async {
    final response = await get(
      '/bookings/$bookingId/status',
      requiresAuth: true,
    );
    return response;
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await patch(
      '/bookings/$bookingId/cancel',
      {},
      requiresAuth: true,
    );
    return response['booking'];
  }

  // ==================== PROFESSIONAL QUEUE ====================

  static Future<Map<String, dynamic>> getTodayQueue() async {
    final response = await get('/bookings/queue/today', requiresAuth: true);
    return response;
  }

  static Future<Map<String, dynamic>?> callNextPatient({DateTime? date}) async {
    final response = await post('/bookings/call-next', {
      if (date != null) 'date': date.toIso8601String(),
    }, requiresAuth: true);
    return response['nextToken'];
  }

  static Future<Map<String, dynamic>> markNoShow(String bookingId) async {
    final response = await patch(
      '/bookings/$bookingId/no-show',
      {},
      requiresAuth: true,
    );
    return response['booking'];
  }

  // ==================== ADMIN ====================

  static Future<List<dynamic>> getPendingProfessionals() async {
    final response = await get(
      '/admin/professionals/pending',
      requiresAuth: true,
    );
    return response['professionals'];
  }

  static Future<Map<String, dynamic>> approveProfessional(
    String id, {
    String? adminNote,
  }) async {
    final response = await patch('/admin/professionals/$id/approve', {
      if (adminNote != null) 'adminNote': adminNote,
    }, requiresAuth: true);
    return response['professional'];
  }

  static Future<Map<String, dynamic>> rejectProfessional(
    String id, {
    String? adminNote,
  }) async {
    final response = await patch('/admin/professionals/$id/reject', {
      if (adminNote != null) 'adminNote': adminNote,
    }, requiresAuth: true);
    return response['professional'];
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await get('/admin/users', requiresAuth: true);
    return response['users'];
  }

  static Future<List<dynamic>> getAllBookings() async {
    final response = await get('/admin/bookings', requiresAuth: true);
    return response['bookings'];
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
