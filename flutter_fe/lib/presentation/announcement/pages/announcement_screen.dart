import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/components/widgets.dart';
import '../bloc/announcement_list/announcement_list_bloc.dart';
import '../bloc/announcement_list/announcement_list_event.dart';
import '../bloc/announcement_list/announcement_list_state.dart';
import '../bloc/announcement_unread_count/announcement_unread_count_bloc.dart';
import '../bloc/announcement_unread_count/announcement_unread_count_event.dart';
import '../bloc/announcement_unread_count/announcement_unread_count_state.dart';
import '../../notification/pages/notification_screen.dart';
import 'announcement_detail_screen.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AnnouncementListBloc>().add(const LoadAnnouncements());
    context.read<AnnouncementUnreadCountBloc>().add(const LoadUnreadCount());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      appBar: JagoAppBar(
        title: 'Pengumuman',
        actions: [
          BlocBuilder<
            AnnouncementUnreadCountBloc,
            AnnouncementUnreadCountState
          >(
            builder: (context, state) {
              final count = state is AnnouncementUnreadCountLoaded
                  ? state.count
                  : 0;
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<AnnouncementUnreadCountBloc>().add(
                        const RefreshUnreadCount(),
                      );
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AnnouncementListBloc, AnnouncementListState>(
        builder: (context, state) {
          if (state is AnnouncementListLoading &&
              state is! AnnouncementListLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnnouncementListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Gagal memuat pengumuman',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AnnouncementListBloc>().add(
                        const LoadAnnouncements(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is AnnouncementListLoaded) {
            if (state.announcements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Belum ada pengumuman',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AnnouncementListBloc>().add(
                  const RefreshAnnouncements(),
                );
                context.read<AnnouncementUnreadCountBloc>().add(
                  const RefreshUnreadCount(),
                );
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.hasReachedMax
                    ? state.announcements.length
                    : state.announcements.length + 1,
                itemBuilder: (context, index) {
                  if (index >= state.announcements.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final announcement = state.announcements[index];
                  return _buildAnnouncementCard(context, announcement);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, announcement) {
    final isUnread = !announcement.isRead;
    Color priorityColor;

    switch (announcement.priority) {
      case 'high':
        priorityColor = AppColors.danger;
        break;
      case 'normal':
        priorityColor = AppColors.primary600;
        break;
      case 'low':
      default:
        priorityColor = AppColors.textTertiary;
    }

    IconData icon;
    Color iconColor;

    // Determine icon based on priority
    switch (announcement.priority) {
      case 'high':
        icon = Icons.priority_high_rounded;
        iconColor = AppColors.danger;
        break;
      case 'normal':
        icon = Icons.info_outline;
        iconColor = AppColors.primary600;
        break;
      case 'low':
      default:
        icon = Icons.campaign_outlined;
        iconColor = AppColors.textTertiary;
    }

    // Format date
    String formattedDate;
    try {
      final date = DateTime.parse(announcement.publishedAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          formattedDate = '${difference.inMinutes} menit lalu';
        } else {
          formattedDate = '${difference.inHours} jam lalu';
        }
      } else if (difference.inDays == 1) {
        formattedDate = 'Kemarin';
      } else if (difference.inDays < 7) {
        formattedDate = '${difference.inDays} hari lalu';
      } else {
        formattedDate = DateFormat('d MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      formattedDate = announcement.publishedAt;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AnnouncementDetailScreen(announcementId: announcement.id),
          ),
        ).then((_) {
          // Refresh list and count after viewing detail
          context.read<AnnouncementListBloc>().add(
            const RefreshAnnouncements(),
          );
          context.read<AnnouncementUnreadCountBloc>().add(
            const RefreshUnreadCount(),
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primary50 : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusCard,
          border: isUnread
              ? Border.all(color: AppColors.primary200, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary600,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (announcement.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (announcement.hasAttachment == true) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.attach_file_rounded,
                              size: 12,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    announcement.priorityLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              announcement.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
