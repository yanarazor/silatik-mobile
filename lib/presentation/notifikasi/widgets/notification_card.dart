import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/notifikasi_model.dart';
import '../../../providers/notifikasi_provider.dart';
import 'notification_colors.dart';

class NotificationCard extends ConsumerWidget {
  const NotificationCard({super.key, required this.item});

  final NotifikasiModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.isRead;
    final hasAction = (item.actionUrl ?? '').trim().isNotEmpty;

    return Material(
      // Read cards sit slightly translucent over the page background so they
      // recede without introducing a second surface color.
      color: unread ? Colors.white : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(notifCardRadius),
      elevation: unread ? 1.5 : 0,
      shadowColor: const Color(0x140B2D5C),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(notifCardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(notifCardRadius),
            border: Border.all(
              color: unread
                  ? notifBorderColor
                  : notifBorderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: notifIconSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 21,
                      color: unread
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timestamp and unread dot ride the title's first line
                        // and end flush with the card edge. The title is the
                        // flexible half, so a long absolute date truncates the
                        // title instead of overlapping it.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.judul,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread
                                      ? notifTitleColor
                                      : notifBodyColor,
                                  fontSize: 14,
                                  height: 1.3,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              // Nudges the 11px label onto the title's cap line.
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Text(
                                    _timeAgo(item.waktu),
                                    style: const TextStyle(
                                      color: notifTimeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 6),
                                    Semantics(
                                      label: 'Belum dibaca',
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFEFF6FF),
                                        ),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: notifUnreadDot,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (item.isi.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.isi,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  unread ? notifBodyColor : notifMutedColor,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (hasAction) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: notifDividerColor),
                const SizedBox(height: 11),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Buka',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.open_in_new_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime waktu) {
    final d = DateTime.now().difference(waktu);
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin';
    return DateFormat('MMM d, yyyy h:mm a').format(waktu);
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (!item.isRead) {
      ref.read(notifikasiListProvider.notifier).markAsRead(item.id);
    }

    final uri = Uri.tryParse((item.actionUrl ?? '').trim());
    if (uri == null || uri.toString().isEmpty) return;

    final invoiceRef = _invoiceRefFromUrl(uri);
    if (invoiceRef != null) {
      context.push(
          '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(invoiceRef)}');
      return;
    }

    // Relative or schemeless action URLs cannot be launched externally.
    if (!uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  String? _invoiceRefFromUrl(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    for (var i = 0; i < segments.length; i++) {
      if ((segments[i] == 'invoice' || segments[i] == 'transaction') &&
          i + 1 < segments.length) {
        return segments[i + 1];
      }
    }
    return null;
  }
}