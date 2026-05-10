import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/my_invoice_api.dart';
import '../../theme/app_theme.dart';

/// 我的发票详情页
/// 对应 PWA /pages/path-d/my-invoice/detail.tsx
class MyInvoiceDetailPage extends ConsumerStatefulWidget {
  final int invoiceId;

  const MyInvoiceDetailPage({super.key, required this.invoiceId});

  @override
  ConsumerState<MyInvoiceDetailPage> createState() => _MyInvoiceDetailPageState();
}

class _MyInvoiceDetailPageState extends ConsumerState<MyInvoiceDetailPage> {
  final MyInvoiceApi _api = MyInvoiceApi();

  MyInvoiceDetail? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _api.detail(widget.invoiceId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showImageViewer(String imageUrl) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImageViewerPage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('发票详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _detail == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('未获取到发票详情', style: AppText.caption),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 申请详情标题
          _SectionTitle('申请详情'),
          const SizedBox(height: 8),
          _InfoCard([
            _InfoRow('申请人', detail.applicantName ?? '工号${detail.applicant}'),
            _InfoRow('部门', detail.departmentName ?? '部门${detail.department}'),
            _InfoRow('申请日期', detail.formattedApplyTime),
            _InfoRow('状态', detail.statusLabel, valueColor: _getStatusColor(detail.status)),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 发票信息标题
          _SectionTitle('发票信息'),
          const SizedBox(height: 8),
          _InfoCard([
            if (detail.orderNumbers != null && detail.orderNumbers!.isNotEmpty)
              _InfoRow('订单编号', detail.orderNumbers!.join('、')),
            _InfoRow('发票金额', detail.formattedInvoiceAmount, valueColor: const Color(0xFFFF9500)),
            _InfoRow('发票类型', detail.invoiceTypeLabel),
            _InfoRow('单位性质', detail.unitPropertiesLabel),
            _InfoRow('开票方式', detail.invoiceMethodLabel),
            _InfoRow('开票主体', detail.invoiceUsciName ?? '主体${detail.invoiceUsci}'),
            _InfoRow('发票抬头', detail.invoiceHeader),
            _InfoRow('联系电话', detail.phone),
            if (detail.email != null) _InfoRow('电子邮箱', detail.email!),
            if (detail.taxID != null) _InfoRow('税号', detail.taxID!),
            if (detail.bankAccountNumber != null) _InfoRow('银行账号', detail.bankAccountNumber!),
            if (detail.companyPhone != null) _InfoRow('公司电话', detail.companyPhone!),
            if (detail.openingBank != null) _InfoRow('开户银行', detail.openingBank!),
            if (detail.companyAddress != null) _InfoRow('公司地址', detail.companyAddress!, isLast: true),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 开票信息
          if (detail.invoiceNumber != null) ...[
            _SectionTitle('开票信息'),
            const SizedBox(height: 8),
            _InfoCard([
              _InfoRow('发票号码', detail.invoiceNumber!),
              _InfoRow('开票日期', detail.invoiceTime != null
                  ? _formatDate(detail.invoiceTime!)
                  : '-'),
              if (detail.lessAmount != null)
                _InfoRow('少开金额', '¥${(detail.lessAmount! / 100).toStringAsFixed(2)}'),
              if (detail.attachment != null && detail.attachment!.isNotEmpty) ...[
                _AttachmentRow(
                  label: '附件',
                  attachments: detail.attachment!,
                  onImageTap: _showImageViewer,
                ),
              ],
              if (detail.remarks != null && detail.remarks!.isNotEmpty)
                _RemarksRow(remarks: detail.remarks!, isLast: true),
            ]),
          ],

          // 无订单商品信息
          if (detail.orderNumbers == null && detail.orderInfo != null) ...[
            _SectionTitle('商品信息'),
            const SizedBox(height: 8),
            ...detail.orderInfo!.where((o) => o.noOrder != null && o.noOrder!.isNotEmpty).expand((order) {
              return order.noOrder!.map((no) => _NoOrderCard(noOrder: no, onImageTap: _showImageViewer));
            }),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'to-be-invoiced':
        return const Color(0xFF007AFF);
      case 'invoiced':
        return const Color(0xFF34C759);
      case 'deprecated':
      case 'reverse':
      case 'reversed':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF007AFF);
    }
  }

  String _formatDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C1E),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow(this.label, this.value, {this.valueColor, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(
                color: valueColor ?? const Color(0xFF1C1C1E),
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final String label;
  final List<String> attachments;
  final void Function(String) onImageTap;

  const _AttachmentRow({
    required this.label,
    required this.attachments,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments.map((url) {
              final ext = url.split('.').last.toLowerCase();
              final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
              if (isImage) {
                return GestureDetector(
                  onTap: () => onImageTap(url),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: CupertinoColors.systemGrey6,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const CupertinoActivityIndicator(),
                      errorWidget: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 24),
                    ),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    url.split('/').last,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RemarksRow extends StatelessWidget {
  final List<MyInvoiceRemark> remarks;
  final bool isLast;

  const _RemarksRow({required this.remarks, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备注', style: AppText.caption),
          const SizedBox(height: 8),
          ...remarks.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: AppText.caption,
                    children: [
                      TextSpan(
                        text: '${r.formattedTime} ',
                        style: AppText.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      TextSpan(
                        text: '【${r.createdByName ?? '工号${r.createdBy}'}】',
                        style: const TextStyle(color: Color(0xFF007AFF)),
                      ),
                      TextSpan(text: r.content, style: AppText.body),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _NoOrderCard extends StatelessWidget {
  final MyInvoiceNoOrder noOrder;
  final void Function(String) onImageTap;

  const _NoOrderCard({required this.noOrder, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(noOrder.name, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('数量: ${noOrder.quantity}', style: AppText.caption),
              const SizedBox(width: 16),
              Text('单价: ${noOrder.formattedAmount}', style: AppText.caption),
              const SizedBox(width: 16),
              Text('合计: ¥${(noOrder.quantity * noOrder.amount / 100).toStringAsFixed(2)}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFFF9500))),
            ],
          ),
          if (noOrder.attachment != null && noOrder.attachment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: noOrder.attachment!.map((url) {
                return GestureDetector(
                  onTap: () => onImageTap(url),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: CupertinoColors.systemGrey6,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const CupertinoActivityIndicator(),
                      errorWidget: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 图片查看器
class _ImageViewerPage extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerPage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.8),
        middle: const Text('查看大图', style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
            errorWidget: (_, __, ___) => const Icon(
              CupertinoIcons.photo,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
    );
  }
}
