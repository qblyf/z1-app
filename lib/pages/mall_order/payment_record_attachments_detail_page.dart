import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/payment_detail_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 支付记录附件详情页
/// 对应 PWA /pages/path-d/mall-order/payment-record-attachments-detail.tsx
class PaymentRecordAttachmentDetailPage extends ConsumerStatefulWidget {
  final String paymentDetailNumber;
  const PaymentRecordAttachmentDetailPage({super.key, required this.paymentDetailNumber});

  @override
  ConsumerState<PaymentRecordAttachmentDetailPage> createState() => _PaymentRecordAttachmentDetailPageState();
}

class _PaymentRecordAttachmentDetailPageState extends ConsumerState<PaymentRecordAttachmentDetailPage> {
  final PaymentDetailApi _api = PaymentDetailApi();

  bool _isLoading = true;
  String? _errorMsg;
  PaymentDetailInfo? _detail;
  bool _isProcessing = false;

  // 支付方式名称缓存
  final Map<int, String> _paymentTypeNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final detail = await _api.getDetailByNumber(widget.paymentDetailNumber);

      // 加载支付方式名称
      if (_paymentTypeNames.isEmpty) {
        try {
          final types = await _api.getPaymentTypeList();
          for (final t in types) {
            _paymentTypeNames[t.id] = t.name;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() { _detail = detail; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  Future<void> _handleApprove() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final ok = await _api.updateAttachState(
        paymentDetailNumbers: [widget.paymentDetailNumber],
        attachState: 'approved',
      );
      if (ok && mounted) {
        _showToast('审核通过成功');
        _loadData();
      } else {
        _showToast('审核通过失败');
      }
    } catch (e) {
      _showToast('操作失败：$e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(String reason) async {
    if (reason.trim().isEmpty) { _showToast('请输入驳回原因'); return; }
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final ok = await _api.updateAttachState(
        paymentDetailNumbers: [widget.paymentDetailNumber],
        attachState: 'rejected',
        remarks: reason,
      );
      if (ok && mounted) {
        Navigator.pop(context);
        _showToast('驳回成功');
        _loadData();
      } else {
        _showToast('驳回失败');
      }
    } catch (e) {
      _showToast('操作失败：$e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectSheet() {
    final textCtrl = TextEditingController();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('驳回原因', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('确定', style: TextStyle(color: Color(0xFF0A84FF))),
                  onPressed: () => _handleReject(textCtrl.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: CupertinoTextField(
                controller: textCtrl,
                placeholder: '请输入驳回原因（必填，限200字）',
                maxLines: 6,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  String _attachStateLabel(String? s) {
    switch (s) {
      case 'wait': return '待上传';
      case 'not_required': return '不需要审核';
      case 'pending': return '待审核';
      case 'approved': return '已通过';
      case 'rejected': return '已驳回';
      default: return '未知';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('订单支付记录附件详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMsg != null
                ? Center(child: Text(_errorMsg!, style: AppText.body))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final detail = _detail;
    if (detail == null) return Center(child: Text('未找到支付记录', style: AppText.body));

    final payTypeName = _paymentTypeNames[detail.paymentTypeID] ?? 'ID: ${detail.paymentTypeID}';
    final stateColor = detail.attachStateColor;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基础信息卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('基础信息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _InfoRow('订单编号', detail.associated?.gmall ?? detail.orderNumber),
                    _InfoRow('支付流水号', detail.paymentDetailNumber),
                    _InfoRow(payTypeName, '¥${(detail.amount / 100).toStringAsFixed(2)}'),
                    _InfoRow('附件状态', _attachStateLabel(detail.attachState), valueColor: stateColor),
                    if (detail.remarks != null && detail.remarks!.isNotEmpty)
                      _InfoRow('备注', detail.remarks!),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 附件信息
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('附件信息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if ((detail.attachments == null || detail.attachments!.isEmpty) &&
                        (detail.images == null || detail.images!.isEmpty))
                      const Text('暂无附件', style: TextStyle(fontSize: 14, color: Color(0xFF999999)))
                    else ...[
                      if (detail.attachments != null)
                        ...detail.attachments!.map((a) => _AttachmentItem(
                          id: a.id,
                          images: a.value,
                        )),
                      if (detail.images != null && detail.images!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE0B2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('其他', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF995000))),
                              const SizedBox(height: 4),
                              const Text('此分类包含未关联有效规则的附件，提交时将被忽略',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF995000))),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: detail.images!.map((url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(imageUrl: url, width: 80, height: 80, fit: BoxFit.cover),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // 底部操作栏
        if (detail.attachState == 'pending' || detail.attachState == 'approved')
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: const Color(0xFFFF3B30),
                        onPressed: _isProcessing ? null : _showRejectSheet,
                        child: _isProcessing
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text('驳回', style: TextStyle(color: CupertinoColors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: _isProcessing ? null : _handleApprove,
                        child: _isProcessing
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text('通过'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? const Color(0xFF333333)))),
        ],
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final String id;
  final List<String> images;
  const _AttachmentItem({required this.id, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('附件 $id', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              if (images.isEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('未上传', style: TextStyle(fontSize: 11, color: Color(0xFFFF3B30))),
                ),
              ],
            ],
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: images.map((url) => GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: url, width: 80, height: 80, fit: BoxFit.cover),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
