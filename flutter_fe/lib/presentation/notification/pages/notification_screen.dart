import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/responses/notification_model.dart';
import '../bloc/notification_list/notification_list_bloc.dart';
import '../bloc/notification_list/notification_list_event.dart';
import '../bloc/notification_list/notification_list_state.dart';

/// Notification Screen — shows the employee's real notifications (approval
/// results, reminders, etc.) from `GET /notifications`, not announcements.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<NotificationListBloc>().add(const LoadNotifications());
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<NotificationListBloc>().add(const LoadMoreNotifications());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context
                  .read<NotificationListBloc>()
                  .add(const MarkAllNotificationsAsRead());
            },
            icon: const Icon(Icons.done_all_rounded, size: 20),
            tooltip: 'Tandai semua dibaca',
          ),
          IconButton(
            onPressed: () {
              context
                  .read<NotificationListBloc>()
                  .add(const RefreshNotifications());
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: BlocBuilder<NotificationListBloc, NotificationListState>(
        builder: (context, state) {
          if (state is NotificationListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationListError) {
            return JagoEmptyState(
              title: 'Gagal Memuat Notifikasi',
              message: state.message,
              icon: Icons.error_outline_rounded,
              actionText: 'Coba Lagi',
              onAction: _loadData,
            );
          }

          if (state is NotificationListLoaded) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return const JagoEmptyState(
                title: 'Tidak Ada Notifikasi',
                message: 'Semua notifikasi Anda akan muncul di sini',
                icon: Icons.notifications_off_outlined,
              );
            }

            final grouped = _groupByDate(notifications);

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<NotificationListBloc>()
                    .add(const RefreshNotifications());
              },
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: grouped.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index >= grouped.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final group = grouped[index];
                  final dateLabel = group['dateLabel'] as String;
                  final items = group['items'] as List<NotificationModel>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...items.map((item) => _buildNotificationItem(item)),
                    ],
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};

    for (final notification in notifications) {
      String dateLabel;
      try {
        final date = DateTime.parse(notification.createdAt);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final notificationDate = DateTime(date.year, date.month, date.day);

        if (notificationDate == today) {
          dateLabel = 'Hari Ini';
        } else if (notificationDate == yesterday) {
          dateLabel = 'Kemarin';
        } else {
          dateLabel = DateFormat('d MMM yyyy', 'id_ID').format(date);
        }
      } catch (e) {
        dateLabel = notification.createdAt;
      }

      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(notification);
    }

    return grouped.entries
        .map((e) => {'dateLabel': e.key, 'items': e.value})
        .toList();
  }

  static const Map<String, IconData> _typeIcons = {
    'leave_request': Icons.event_available_outlined,
    'leave_requested': Icons.event_available_outlined,
    'payroll': Icons.account_balance_wallet_outlined,
    'attendance': Icons.access_time_rounded,
    'attendance_clock_in': Icons.login_rounded,
    'attendance_clock_out': Icons.logout_rounded,
    'attendance_recap': Icons.summarize_outlined,
    'employee': Icons.person_outline_rounded,
    'approval': Icons.check_circle_outline_rounded,
    'warning': Icons.warning_amber_rounded,
    'success': Icons.check_circle_outline_rounded,
    'error': Icons.error_outline_rounded,
  };

  static const Map<String, Color> _typeColors = {
    'warning': AppColors.warning,
    'error': AppColors.danger,
    'success': AppColors.success,
    'approval': AppColors.success,
    'attendance_clock_in': AppColors.success,
    'attendance_clock_out': AppColors.info,
    'attendance_recap': AppColors.info,
  };

  Widget _buildNotificationItem(NotificationModel notification) {
    final isUnread = !notification.isRead;
    final icon = _typeIcons[notification.type] ?? Icons.notifications_outlined;
    final color = _typeColors[notification.type] ?? AppColors.info;

    String timeText;
    try {
      final date = DateTime.parse(notification.createdAt);
      timeText = DateFormat('HH:mm').format(date);
    } catch (e) {
      timeText = '';
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isUnread
            ? AppColors.primary50.withValues(alpha: 0.5)
            : AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary600,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      context
          .read<NotificationListBloc>()
          .add(MarkNotificationAsRead(notification.id));
    }
  }
}
