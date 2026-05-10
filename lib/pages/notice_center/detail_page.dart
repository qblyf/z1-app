import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/notice_center_api.dart';
import '../../models/notice_center.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 通知详情页
/// 对应 PWA /components/mobile/NoticeInfo.tsx
class NoticeDetailPage extends ConsumerStatefulWidget {
  final int noticeLogId;

  const NoticeDetailPage({super.key, required this.noticeLogId});

  @override
  ConsumerState<NoticeDetailPage> createState() => _NoticeDetailPageState();
}

class _NoticeDetailPageState extends ConsumerState<NoticeDetailPage> {
  final NoticeCenterApi _api = NoticeCenterApi();
  NoticeLog? _notice;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final detail = await _api.detail(widget.noticeLogId);
      if (mounted) {
        setState(() {
          _notice = detail;
          _isLoading = false;
        });
        // 标记已读
        if (detail != null && detail.readStatus == ReadStatus.unread) {
          _api.markRead(widget.noticeLogId);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onAssociatedTap() {
    if (_notice == null) return;
    final associatedType = _notice!.associatedType;
    final associatedId = _notice!.associatedID;
    if (associatedId == null || associatedType == AssociatedType.none) return;

    switch (associatedType) {
      case AssociatedType.preSaleOrder:
        context.push('/pre-sale-order/detail/$associatedId');
        break;
      case AssociatedType.order:
        context.push('/mall-order/$associatedId');
        break;
      case AssociatedType.invoice:
        context.push('/invoice/$associatedId');
        break;
      case AssociatedType.approval:
        context.push('/approval/$associatedId');
        break;
      case AssociatedType.transferOrder:
        context.push('/transfer-order/detail/$associatedId');
        break;
      default:
        break;
    }
  }

  String _formatDate(int ts) {
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
                leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        middle: const Text('通知详情'),
        trailing: _isLoading
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey),
                onPressed: () => context.pop(),
              ),
      ),
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载中...');
    }
    if (_hasError || _notice == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text('加载失败', style: AppText.body),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final notice = _notice!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 标题
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: notice.receiverType == ReceiverType.carbonCopy
                          ? const Color(0xFFFF9500).withValues(alpha: 0.1)
                          : const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notice.receiverType.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: notice.receiverType == ReceiverType.carbonCopy
                            ? const Color(0xFFFF9500)
                            : const Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(notice.createdAt),
                    style: AppText.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice.title,
                style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold),
              ),
              if (notice.senderName != null && notice.senderName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(CupertinoIcons.person_circle,
                        size: 14, color: CupertinoColors.secondaryLabel),
                    const SizedBox(width: 4),
                    Text('发送人: ${notice.senderName}',
                        style: AppText.caption),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 关联业务
        if (notice.associatedType != AssociatedType.none &&
            notice.associatedID != null) ...[
          GestureDetector(
            onTap: _onAssociatedTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.link,
                      size: 18, color: Color(0xFF0A84FF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '关联业务: ${notice.associatedType.label}',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF0A84FF)),
                        ),
                        Text(
                          '点击查看详情 >',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF0A84FF).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 16, color: Color(0xFF0A84FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 内容
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('通知内容', style: AppText.label),
              const SizedBox(height: AppSpacing.sm),
              if (notice.content.isEmpty)
                Text('暂无内容', style: AppText.caption)
              else
                _buildContentBody(notice.content),
            ],
          ),
        ),

        // 附件
        if (notice.attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('附件', style: AppText.label),
                const SizedBox(height: AppSpacing.sm),
                ...notice.attachments.map((att) => _buildAttachmentItem(att)),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  /// 渲染通知内容（支持 Markdown 子集）
  Widget _buildContentBody(String content) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }
        // 标题行 (# ## ###)
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(4),
              style: AppText.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        }
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: AppText.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              trimmed.substring(2),
              style: AppText.body.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          );
        }
        // 列表项
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(child: _renderInlineText(trimmed.substring(2))),
              ],
            ),
          );
        }
        if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
          final match = RegExp(r'^(\d+)\. (.*)').firstMatch(trimmed);
          if (match != null) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${match.group(1)}. ', style: const TextStyle(fontSize: 14)),
                  Expanded(child: _renderInlineText(match.group(2)!)),
                ],
              ),
            );
          }
        }
        // 普通段落
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _renderInlineText(trimmed),
        );
      }).toList(),
    );
  }

  /// 渲染行内文本（粗体、斜体、链接、图片）
  Widget _renderInlineText(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[(.+?)\]\((.+?)\)|!\[(.+?)\]\((.+?)\)');

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)),
        ));
      }
      if (match.group(1) != null) {
        // **粗体**
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ));
      } else if (match.group(2) != null) {
        // *斜体*
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontSize: 14, height: 1.6, fontStyle: FontStyle.italic, color: Color(0xFF333333)),
        ));
      } else if (match.group(3) != null) {
        // `行内代码`
        spans.add(TextSpan(
          text: match.group(3),
          style: const TextStyle(fontSize: 13, height: 1.6, fontFamily: 'Menlo', backgroundColor: Color(0xFFF0F0F0), color: Color(0xFFE53935)),
        ));
      } else if (match.group(4) != null && match.group(5) != null) {
        // [文字](链接)
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontSize: 14, height: 1.6, decoration: TextDecoration.underline, color: Color(0xFF0A84FF)),
        ));
      } else if (match.group(6) != null && match.group(7) != null) {
        // ![alt](图片URL)
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                match.group(7)!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                  ),
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CupertinoActivityIndicator()),
                  );
                },
              ),
            ),
          ),
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)),
      ));
    }
    if (spans.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)));
    }
    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildAttachmentItem(NoticeAttachment att) {
    return GestureDetector(
      onTap: () {
        // TODO: 打开附件预览/下载
        _showTip('附件: ${att.name}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              att.isImage
                  ? CupertinoIcons.photo
                  : CupertinoIcons.doc,
              size: 24,
              color: const Color(0xFF0A84FF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    att.name,
                    style: AppText.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (att.mimeType != null)
                    Text(
                      att.mimeType!,
                      style: AppText.caption,
                    ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.arrow_down_to_line,
                size: 18, color: CupertinoColors.secondaryLabel),
          ],
        ),
      ),
    );
  }

  void _showTip(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
