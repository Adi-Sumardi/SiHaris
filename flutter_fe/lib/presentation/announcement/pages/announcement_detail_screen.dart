import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/components/widgets.dart';
import '../../../data/models/responses/announcement_model.dart';
import '../bloc/announcement_detail/announcement_detail_bloc.dart';
import '../bloc/announcement_detail/announcement_detail_event.dart';
import '../bloc/announcement_detail/announcement_detail_state.dart';
import '../bloc/announcement_mark_read/announcement_mark_read_bloc.dart';
import '../bloc/announcement_mark_read/announcement_mark_read_event.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final int announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnnouncementDetailBloc>().add(
      LoadAnnouncementDetail(widget.announcementId),
    );
    context.read<AnnouncementMarkReadBloc>().add(
      MarkAnnouncementAsRead(widget.announcementId),
    );
  }

  Future<void> _openOrDownloadAttachment(AnnouncementModel announcement) async {
    final urlStr =
        announcement.attachmentDownloadUrl ?? announcement.attachmentPreviewUrl;
    if (urlStr == null || urlStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL lampiran tidak tersedia')),
      );
      return;
    }

    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka lampiran: $e')));
      }
    }
  }

  Widget _buildAttachment(AnnouncementModel announcement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Lampiran', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        if (announcement.isAttachmentImage &&
            announcement.attachmentPreviewUrl != null)
          GestureDetector(
            onTap: () => _openOrDownloadAttachment(announcement),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: announcement.attachmentPreviewUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
              ),
            ),
          )
        else
          InkWell(
            onTap: () => _openOrDownloadAttachment(announcement),
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          (announcement.isAttachmentPdf
                                  ? AppColors.danger
                                  : AppColors.primary600)
                              .withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      announcement.isAttachmentPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_rounded,
                      color: announcement.isAttachmentPdf
                          ? AppColors.danger
                          : AppColors.primary600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.attachmentName ?? 'Lampiran',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (announcement.humanAttachmentSize != null)
                          Text(
                            announcement.humanAttachmentSize!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(title: 'Detail Pengumuman'),
      body: BlocBuilder<AnnouncementDetailBloc, AnnouncementDetailState>(
        builder: (context, state) {
          if (state is AnnouncementDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnnouncementDetailError) {
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
                    'Gagal memuat detail',
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
                      context.read<AnnouncementDetailBloc>().add(
                        LoadAnnouncementDetail(widget.announcementId),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is AnnouncementDetailLoaded) {
            final announcement = state.announcement;

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
              formattedDate = DateFormat(
                'd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(date);
            } catch (e) {
              formattedDate = announcement.publishedAt;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (announcement.isPinned)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: 14,
                                      color: AppColors.warning,
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
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(announcement.title, style: AppTextStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),

                  // Creator (if available)
                  if (announcement.creatorName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Oleh: ${announcement.creatorName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Content
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.borderRadiusMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      announcement.content,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  if (announcement.hasAttachment)
                    _buildAttachment(announcement),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
