import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_inspection_api.dart';
import '../../models/store_inspection.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 巡店/自检 - 详情页
/// 对应 PWA /pages/path-d/store-inspection/info.tsx
/// 显示巡店记录详情，检查项结果，操作按钮
class StoreInspectionInfoPage extends ConsumerStatefulWidget {
  final int logID;
  const StoreInspectionInfoPage({super.key, required this.logID});

  @override
  ConsumerState<StoreInspectionInfoPage> createState() => _StoreInspectionInfoPageState();
}

class _StoreInspectionInfoPageState extends ConsumerState<StoreInspectionInfoPage> {
  final StoreInspectionApi _api = StoreInspectionApi();

  bool _isLoading = true;
  String? _errorMsg;
  StoreInspectionLogDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final detail = await _api.logDetail(widget.logID);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorMsg = '加载失败：$e'; });
      }
    }
  }

  Future<void> _submitInspection() async {
    if (_detail == null) return;
    setState(() => _isSubmitting = true);
    try {
      bool ok = false;
      if (_detail!.logStatus == StoreInspectionLogStatus.toAccepted) {
        // 验收
        ok = await _api.acceptLog(id: widget.logID);
      } else {
        // 提交结果
        ok = await _api.editLog(
          logID: widget.logID,
          status: 'finished',
        );
      }
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isSubmitting = false; _errorMsg = '操作失败：$e'; });
    }
  }

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_detail?.storeInspectionType == 'selfInspection' ? '自检详情' : '巡店详情'),
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
                : _detail == null
                    ? Center(child: Text('未找到记录', style: AppText.body))
                    : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final detail = _detail!;
    final status = detail.logStatus;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态卡片
                _buildStatusCard(detail, status),
                const SizedBox(height: AppSpacing.md),

                // 基本信息
                _buildInfoCard(detail),
                const SizedBox(height: AppSpacing.md),

                // 检查项结果
                if (detail.checkInfo.isNotEmpty) ...[
                  _buildCheckItemsCard(detail),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 整改信息
                if (detail.correctBy != null) ...[
                  _buildRectifyCard(detail),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 验收/复核信息
                if (detail.acceptedBy != null || detail.reviewedBy != null) ...[
                  _buildApprovalCard(detail),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 总结
                if (detail.assess != null || detail.thinkAbout != null) ...[
                  _buildSummaryCard(detail),
                  const SizedBox(height: AppSpacing.md),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // 底部操作按钮
        _buildBottomActions(detail, status),
      ],
    );
  }

  Widget _buildStatusCard(StoreInspectionLogDetail detail, StoreInspectionLogStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [status.color, status.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(detail.storeInspectionType == 'selfInspection' ? '自检' : '巡店',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.white, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status.label,
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail.inspectionName ?? '巡店项目',
            style: const TextStyle(fontSize: 18, color: CupertinoColors.white, fontWeight: FontWeight.bold),
          ),
          if (detail.score != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.star_fill, size: 18, color: Color(0xFFFFD60A)),
                const SizedBox(width: 6),
                Text('得分：${detail.score}',
                    style: const TextStyle(fontSize: 15, color: CupertinoColors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if (detail.spend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: 16, color: Color(0xFFB6D1F9)),
                const SizedBox(width: 6),
                Text('耗时：${_formatDuration(detail.spend!)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB6D1F9))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  Widget _buildInfoCard(StoreInspectionLogDetail detail) {
    return _buildCard([
      _InfoRow('门店', detail.departmentName ?? '部门${detail.departmentID}'),
      _InfoRow('创建人', detail.createdByName ?? '用户${detail.createdBy}'),
      _InfoRow('创建时间', detail.formattedCreatedAt),
      if (detail.correctByName != null) _InfoRow('整改人', detail.correctByName!),
      if (detail.acceptedByName != null) _InfoRow('验收人', detail.acceptedByName!),
      if (detail.reviewedByName != null) _InfoRow('复核人', detail.reviewedByName!),
    ], '基本信息');
  }

  Widget _buildCheckItemsCard(StoreInspectionLogDetail detail) {
    return _buildCard([
      ...detail.checkInfo.map((item) => _CheckItemRow(item: item)),
    ], '检查项 (${detail.checkInfo.length})');
  }

  Widget _buildRectifyCard(StoreInspectionLogDetail detail) {
    return _buildCard([
      _InfoRow('整改人', detail.correctByName ?? '用户${detail.correctBy}'),
      if (detail.acceptanceComments != null && detail.acceptanceComments!.isNotEmpty)
        _InfoRow('整改说明', detail.acceptanceComments!),
    ], '整改信息');
  }

  Widget _buildApprovalCard(StoreInspectionLogDetail detail) {
    return _buildCard([
      if (detail.acceptedByName != null) ...[
        _InfoRow('验收人', detail.acceptedByName!),
        if (detail.acceptanceComments != null && detail.acceptanceComments!.isNotEmpty)
          _InfoRow('验收评语', detail.acceptanceComments!),
        if (detail.formattedAcceptedAt != null)
          _InfoRow('验收时间', detail.formattedAcceptedAt!),
      ],
      if (detail.reviewedByName != null) ...[
        _InfoRow('复核人', detail.reviewedByName!),
        if (detail.reviewedComments != null && detail.reviewedComments!.isNotEmpty)
          _InfoRow('复核评语', detail.reviewedComments!),
        if (detail.formattedReviewedAt != null)
          _InfoRow('复核时间', detail.formattedReviewedAt!),
      ],
    ], '验收/复核信息');
  }

  Widget _buildSummaryCard(StoreInspectionLogDetail detail) {
    return _buildCard([
      if (detail.assess != null && detail.assess!.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('评价', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ),
        Text(detail.assess!, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
        const SizedBox(height: 12),
      ],
      if (detail.thinkAbout != null && detail.thinkAbout!.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('思考点', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ),
        Text(detail.thinkAbout!, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
      ],
    ], '总结');
  }

  Widget _buildCard(List<Widget> children, String title) {
    return Container(
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBottomActions(StoreInspectionLogDetail detail, StoreInspectionLogStatus status) {
    // 只有特定状态显示操作按钮
    if (status != StoreInspectionLogStatus.toAccepted) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0xFFFF3B30),
                onPressed: _isSubmitting ? null : () => _reject(),
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('驳回', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _isSubmitting ? null : _submitInspection,
                child: _isSubmitting
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('验收通过', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject() async {
    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.rejectLog(widget.logID);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) context.pop();
      }
    } catch (e) {
      if (mounted) setState(() { _isSubmitting = false; _errorMsg = '驳回失败：$e'; });
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }
}

class _CheckItemRow extends StatelessWidget {
  final StoreInspectionCheckItem item;
  const _CheckItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('检查项', style: const TextStyle(fontSize: 10, color: Color(0xFF5856D6))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (item.scoreRange != null) ...[
            const SizedBox(height: 6),
            Text('分值范围：${item.scoreRange![0]} - ${item.scoreRange![1]}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ],
          if (item.attachment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('附件：${item.attachment.length}个', style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF))),
          ],
        ],
      ),
    );
  }
}
