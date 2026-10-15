
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  String? _error;

  int get _unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.getNotifications();
      final rawNotifications = response['notifications'];

      if (rawNotifications is! List) {
        throw Exception('The server returned invalid notification data.');
      }

      final items = rawNotifications
          .whereType<Map>()
          .map(
            (item) => _NotificationItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(_NotificationItem notification) async {
    if (notification.isRead) return;

    final index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index == -1) return;

    try {
      await ApiService.markNotificationAsRead(notification.id);

      if (!mounted) return;

      setState(() {
        _notifications[index].isRead = true;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isMarkingAllRead) return;

    setState(() => _isMarkingAllRead = true);

    try {
      await ApiService.markAllNotificationsAsRead();

      if (!mounted) return;

      setState(() {
        for (final notification in _notifications) {
          notification.isRead = true;
        }
        _isMarkingAllRead = false;
      });

      _showMessage('All notifications marked as read.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isMarkingAllRead = false);
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              child: _isMarkingAllRead
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorNotifications(
                  message: _error!,
                  onRetry: _loadNotifications,
                )
              : _notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 150),
                          _EmptyNotifications(),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        children: [
                          Text(
                            _unreadCount == 0
                                ? 'You’re all caught up'
                                : '$_unreadCount new notification'
                                    '${_unreadCount == 1 ? '' : 's'}',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          ..._notifications.map(
                            (notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationCard(
                                notification: notification,
                                onTap: () => _markAsRead(notification),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
    required this.icon,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final Color color;
  final IconData icon;
  bool isRead;

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    final type = (json['type'] ?? '').toString();
    final title = (data['title'] ?? data['subject'] ?? 'Notification')
        .toString();
    final message =
        (data['message'] ?? data['body'] ?? data['description'] ?? '')
            .toString();

    final createdAt = DateTime.tryParse(
      (json['created_at'] ?? '').toString(),
    );

    return _NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: title,
      message: message.isEmpty ? _friendlyType(type) : message,
      time: _formatTime(createdAt),
      color: _notificationColor(type),
      icon: _notificationIcon(type),
      isRead: json['read_at'] != null,
    );
  }

  static String _friendlyType(String type) {
    final name = type.split(r'\').last.split('.').last;
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll('_', ' ');
  }

  static String _formatTime(DateTime? date) {
    if (date == null) return '';

    final localDate = date.toLocal();
    final difference = DateTime.now().difference(localDate);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  static IconData _notificationIcon(String type) {
    final value = type.toLowerCase();

    if (value.contains('blood') || value.contains('request')) {
      return Icons.bloodtype_rounded;
    }
    if (value.contains('donat')) return Icons.water_drop_rounded;
    if (value.contains('appointment')) return Icons.calendar_month_rounded;
    if (value.contains('success') || value.contains('approved')) {
      return Icons.check_circle_rounded;
    }

    return Icons.notifications_active_rounded;
  }

  static Color _notificationColor(String type) {
    final value = type.toLowerCase();

    if (value.contains('urgent') || value.contains('critical')) {
      return AppColors.critical;
    }
    if (value.contains('success') || value.contains('approved')) {
      return AppColors.success;
    }

    return AppColors.primary;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final _NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = notification.isRead
        ? theme.colorScheme.surface
        : theme.colorScheme.primary.withValues(alpha: 0.07);

    return Card(
      color: background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: notification.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6, left: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      notification.time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll let you know when something needs your attention.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorNotifications extends StatelessWidget {
  const _ErrorNotifications({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load notifications',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
