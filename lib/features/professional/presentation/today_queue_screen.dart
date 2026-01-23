import 'package:booking_app/services/api_client.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TodayQueueScreen extends StatefulWidget {
  final String professionalId;

  const TodayQueueScreen({super.key, required this.professionalId});

  @override
  State<TodayQueueScreen> createState() => _TodayQueueScreenState();
}

class _TodayQueueScreenState extends State<TodayQueueScreen> {
  bool _loading = true;
  Map<String, dynamic>? _queue;
  String? _error;
  bool _isCallingNext = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      debugPrint('📋 Loading queue for professional: ${widget.professionalId}');
      final res = await ApiClient.getTodayQueue(
        professionalId: widget.professionalId,
      );
      debugPrint('📋 Queue response: $res');

      if (!mounted) return;
      setState(() => _queue = res);
    } catch (e) {
      debugPrint('❌ Error loading queue: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _callNext() async {
    if (_isCallingNext) {
      debugPrint('⚠️ Already calling next token, please wait');
      return;
    }

    setState(() => _isCallingNext = true);

    try {
      debugPrint('📢 Calling next token...');
      debugPrint('Professional ID: ${widget.professionalId}');
      debugPrint('Date: ${DateTime.now()}');

      final res = await ApiClient.callNextToken(
        professionalId: widget.professionalId,
        date: DateTime.now(),
      );

      debugPrint('📢 Call next response: $res');

      // Reload queue to get updated data
      await _loadQueue();

      if (!mounted) return;

      // Show success message
      if (res['nextToken'] != null) {
        final nextToken = res['nextToken'];
        final tokenNumber = nextToken['tokenNumber'] ?? nextToken['token'];
        final patientName = nextToken['patientName'] ?? 'Patient';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📢 Called Token #$tokenNumber - $patientName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (res['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'].toString()),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Next token called successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error calling next token: $e');

      if (!mounted) return;

      String errorMessage = 'Error calling next token';
      if (e.toString().contains('No bookings available')) {
        errorMessage = 'No pending bookings in queue';
      } else if (e.toString().contains('already called')) {
        errorMessage = 'Current token is already being served';
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCallingNext = false);
    }
  }

  Future<void> _markNoShow(String bookingId, String tokenNumber) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as No-Show?'),
        content: Text('Mark Token #$tokenNumber as no-show?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Mark No-Show'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🚫 Marking booking $bookingId as no-show');
      await ApiClient.markNoShow(bookingId);
      await _loadQueue();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Marked as no-show'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error marking no-show: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = (_queue?['bookings'] as List?) ?? [];
    final currentToken = _queue?['currentToken'];
    final totalBookings = _queue?['total'] ?? bookings.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Queue'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueue,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadQueue,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Current Token Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Token',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentToken != null ? '#$currentToken' : 'None',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: $totalBookings booking${totalBookings != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Call Next Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isCallingNext || bookings.isEmpty
                          ? null
                          : _callNext,
                      icon: _isCallingNext
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.campaign_outlined),
                      label: Text(
                        _isCallingNext
                            ? 'Calling...'
                            : bookings.isEmpty
                            ? 'No bookings'
                            : 'Call Next Token',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                // Queue List
                Expanded(
                  child: bookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No bookings for today',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: bookings.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final b = bookings[index] as Map<String, dynamic>;
                            final status = b['status'] as String? ?? 'PENDING';
                            final token = b['tokenNumber'] ?? b['token'] ?? '-';
                            final patientName = b['name'] ?? 'Patient';
                            final age = b['age'];
                            final phone = b['phone'];

                            Color statusColor;
                            IconData statusIcon;
                            switch (status) {
                              case 'CALLED':
                                statusColor = AppTheme.primaryGreen;
                                statusIcon = Icons.phone_forwarded;
                                break;
                              case 'NO_SHOW':
                                statusColor = Colors.red;
                                statusIcon = Icons.person_off;
                                break;
                              case 'COMPLETED':
                                statusColor = Colors.blue;
                                statusIcon = Icons.check_circle;
                                break;
                              default:
                                statusColor = Colors.orange;
                                statusIcon = Icons.hourglass_empty;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    '#$token',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (age != null || phone != null)
                                      Text(
                                        '${age != null ? "Age: $age" : ""}${age != null && phone != null ? " • " : ""}${phone ?? ""}',
                                      ),
                                    Row(
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(color: statusColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing:
                                    status == 'NO_SHOW' || status == 'COMPLETED'
                                    ? null
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _markNoShow(
                                          b['id'] as String,
                                          token.toString(),
                                        ),
                                        tooltip: 'Mark as no-show',
                                      ),
                                isThreeLine: age != null || phone != null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
