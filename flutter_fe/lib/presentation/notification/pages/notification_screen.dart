import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/responses/announcement_model.dart';
import '../../announcement/bloc/announcement_list/announcement_list_bloc.dart';
import '../../announcement/bloc/announcement_list/announcement_list_event.dart';
import '../../announcement/bloc/announcement_list/announcement_list_state.dart';
import '../../announcement/pages/announcement_detail_screen.dart';

/// Notification Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24 px
/// Font sizes: 10, 12, 14, 16, 20 px
/// Icon sizes: 16, 20, 24 px
/// Container sizes: 40, 48 px
/// Border radius: 4, 8, 12, 16 px
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
    context.read<AnnouncementListBloc>().add(const LoadAnnouncements());
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AnnouncementListBloc>().add(const LoadMoreAnnouncements());
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
              context.read<AnnouncementListBloc>().add(const RefreshAnnouncements());
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      body: BlocBuilder<AnnouncementListBloc, AnnouncementListState>(
        builder: (context, state) {
          if (state is AnnouncementListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnnouncementListError) {
            return JagoEmptyState(
              title: 'Gagal Memuat Notifikasi',
              message: state.message,
              icon: Icons.error_outline_rounded,
              actionText: 'Coba Lagi',
              onAction: _loadData,
            );
          }

          if (state is AnnouncementListLoaded) {
            final announcements = state.announcements;

            if (announcements.isEmpty) {
              return const JagoEmptyState(
                title: 'Tidak Ada Notifikasi',
                message: 'Semua notifikasi Anda akan muncul di sini',
                icon: Icons.notifications_off_outlined,
              );
            }

            // Group by date
            final grouped = _groupByDate(announcements);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AnnouncementListBloc>().add(const RefreshAnnouncements());
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
                  final items = group['items'] as List<AnnouncementModel>;

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

  List<Map<String, dynamic>> _groupByDate(List<AnnouncementModel> announcements) {
    final Map<String, List<AnnouncementModel>> grouped = {};

    for (final announcement in announcements) {
      String dateLabel;
      try {
        final date = DateTime.parse(announcement.publishedAt);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final announcementDate = DateTime(date.year, date.month, date.day);

        if (announcementDate == today) {
          dateLabel = 'Hari Ini';
        } else if (announcementDate == yesterday) {
          dateLabel = 'Kemarin';
        } else {
          dateLabel = DateFormat('d MMM yyyy', 'id_ID').format(date);
        }
      } catch (e) {
        dateLabel = announcement.publishedAt;
      }

      grouped.putIfAbsent(dateLabel, () => []);
      grouped[dateLabel]!.add(announcement);
    }

    return grouped.entries
        .map((e) => {'dateLabel': e.key, 'items': e.value})
        .toList();
  }

  Widget _buildNotificationItem(AnnouncementModel announcement) {
    final isUnread = !announcement.isRead;

    IconData icon;
    Color color;
    switch (announcement.priority) {
      case 'high':
        icon = Icons.priority_high_rounded;
        color = AppColors.danger;
        break;
      case 'medium':
        icon = Icons.campaign_outlined;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.info;
    }

    String timeText;
    try {
      final date = DateTime.parse(announcement.publishedAt);
      timeText = DateFormat('HH:mm').format(date);
    } catch (e) {
      timeText = '';
    }

    return InkWell(
      onTap: () => _handleNotificationTap(announcement),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isUnread
            ? AppColors.primary50.withValues(alpha: 0.5)
            : AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
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
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
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
                    announcement.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (announcement.isPinned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.push_pin_rounded,
                                size: 10,
                                color: AppColors.accent500,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Disematkan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (announcement.priorityLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            announcement.priorityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(AnnouncementModel announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(
          announcementId: announcement.id,
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<AnnouncementListBloc>().add(const RefreshAnnouncements());
      }
    });
  }
}
