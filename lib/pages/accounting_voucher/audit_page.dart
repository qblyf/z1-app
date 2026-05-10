import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/accounting_voucher_api.dart';
import '../../models/accounting_voucher.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 会计凭证审核详情页 Provider
final voucherDetailProvider =
    FutureProvider.family<AccountingVoucher?, int>((ref, id) async {
  return AccountingVoucherApi().details([id]);
});

/// 会计凭证分录 Provider
final journalEntriesProvider =
    FutureProvider.family<List<JournalEntry>, int>((ref, voucherId) async {
  return AccountingVoucherApi().journalEntryList([voucherId]);
});

/// 凭证审核详情页
class AccountingVoucherAuditPage extends ConsumerStatefulWidget {
  final int voucherId;

  const AccountingVoucherAuditPage({super.key, required this.voucherId});

  @override
  ConsumerState<AccountingVoucherAuditPage> createState() =>
      _AccountingVoucherAuditPageState();
}

class _AccountingVoucherAuditPageState
    extends ConsumerState<AccountingVoucherAuditPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  AccountingVoucher? _voucher;
  List<JournalEntry> _journals = [];
  List<JournalDraft> _drafts = [];
  int _currentUserIdent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取当前用户标识
      final user = ref.read(currentUserProvider).valueOrNull;
      _currentUserIdent = user?.userIdent ?? 0;

      // 获取凭证详情
      final api = AccountingVoucherApi();
      final voucher = await api.details([widget.voucherId]);
      if (voucher == null) {
        setState(() {
          _isLoading = false;
          _error = '凭证不存在或已被删除';
        });
        return;
      }

      _voucher = voucher;

      // 获取分录数据（草稿用 journalDraft，已审核用 journalEntryList）
      if (voucher.state == VoucherState.s3) {
        // 草稿
        _drafts = voucher.journalDraft ?? [];
        _journals = [];
      } else {
        _drafts = [];
        _journals = await api.journalEntryList([widget.voucherId]);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// 计算借贷合计
  ({int debitTotal, int creditTotal, String totalText}) _calcTotal() {
    int debit = 0;
    int credit = 0;

    for (final j in _journals) {
      if (j.loan == 1) {
        debit += j.amountCent;
      } else {
        credit += j.amountCent;
      }
    }
    for (final d in _drafts) {
      if (d.loan == 1) {
        debit += d.amount;
      } else {
        credit += d.amount;
      }
    }

    final debitText = _formatMoney(debit);
    final creditText = _formatMoney(credit);
    String totalText = '';
    if (debit > 0) totalText = _cnMoney(debit);
    if (debit != credit) {
      totalText += '（借贷不平衡，请检查数据）';
    }

    return (debitTotal: debit, creditTotal: credit, totalText: totalText);
  }

  String _formatMoney(int cents) {
    final yuan = cents / 100;
    return yuan.toStringAsFixed(2);
  }

  String _cnMoney(int cents) {
    // 简化版中文金额格式化
    final yuan = cents ~/ 100;
    final fen = cents % 100;
    if (fen == 0) return '$yuan 元整';
    return '$yuan.${fen.toString().padLeft(2, '0')} 元';
  }

  /// 审核
  Future<void> _doAudit() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final success = await AccountingVoucherApi().audit(widget.voucherId);
      if (!mounted) return;
      if (success) {
        _showToast('审核成功');
        await _loadData();
      } else {
        _showToast('审核失败，请重试');
      }
    } catch (e) {
      if (mounted) _showToast('审核失败：$e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// 驳回
  Future<void> _doReject() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final success = await AccountingVoucherApi().reject(widget.voucherId);
      if (!mounted) return;
      if (success) {
        _showToast('驳回成功');
        await _loadData();
      } else {
        _showToast('驳回失败，请重试');
      }
    } catch (e) {
      if (mounted) _showToast('驳回失败：$e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  /// 是否可以审核
  bool get _canAudit {
    if (_voucher == null) return false;
    if (_voucher!.state != VoucherState.s1) return false;
    final auditors = _voucher!.auditors;
    if (auditors == null || auditors.isEmpty) return false;
    return auditors.contains(_currentUserIdent);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('会计凭证详情'),
        trailing: _isProcessing
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _loadData(),
                child: const Icon(CupertinoIcons.refresh),
              ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
                ? Center(child: _buildError(_error!))
                : _voucher == null
                    ? Center(child: _buildError('凭证不存在'))
                    : _buildContent(),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.systemGrey),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: _loadData,
          child: const Text('重试'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final v = _voucher!;
    final total = _calcTotal();
    final isAudit = _canAudit;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 凭证编号和状态
              _InfoCard(
                children: [
                  _InfoRow('凭证编号', v.displayNumber),
                  _InfoRow('凭证状态', _buildStateBadge(v.state)),
                  _InfoRow('凭证字号', _voucherTypeLabel(v.type)),
                  _InfoRow('制单人', _UserChip(ident: v.creator)),
                  if (v.accountant != null)
                    _InfoRow('经手人', _UserChip(ident: v.accountant!)),
                  if (v.auditor != null &&
                      (v.state == VoucherState.s2 ||
                          v.state == VoucherState.s4 ||
                          v.state == VoucherState.s5))
                    _InfoRow('审核人', _UserChip(ident: v.auditor!)),
                  if (v.cashier != null) _InfoRow('出纳', _UserChip(ident: v.cashier!)),
                  _InfoRow('凭证日期', _formatDate(v.voucherTime)),
                  _InfoRow('创建日期', _formatDate(v.createdAt)),
                  if (v.auditedAt != null &&
                      v.state != VoucherState.s4)
                    _InfoRow('审核时间', _formatDate(v.auditedAt)),
                  _InfoRow(
                    '备注',
                    v.state == VoucherState.s4
                        ? '红冲'
                        : (v.remarks ?? '无'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 分录表
              _buildJournalSection(total),
            ],
          ),
        ),
        // 底部操作按钮
        if (isAudit)
          _buildBottomActions(),
      ],
    );
  }

  Widget _buildStateBadge(VoucherState state) {
    Color color;
    switch (state) {
      case VoucherState.s1:
        color = AppColors.warning;
        break;
      case VoucherState.s2:
        color = AppColors.success;
        break;
      case VoucherState.s3:
        color = CupertinoColors.systemGrey;
        break;
      case VoucherState.s4:
      case VoucherState.s5:
        color = CupertinoColors.destructiveRed;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        state.label,
        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _voucherTypeLabel(VoucherType type) {
    return '${type.label}字';
  }

  String _formatDate(int? unix) {
    if (unix == null) return '无';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════
  // 分录表
  // ═══════════════════════════════════════
  Widget _buildJournalSection(({int debitTotal, int creditTotal, String totalText}) total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('凭证分录'),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
          child: Column(
            children: [
              // 表头
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    _th('#', 0.5),
                    _th('摘要', 2.0),
                    _th('科目', 1.5),
                    _th('借方', 1.0),
                    _th('贷方', 1.0),
                  ],
                ),
              ),
              // 数据行（草稿）
              if (_drafts.isNotEmpty)
                ..._drafts.asMap().entries.map((e) => _buildDraftRow(e.key + 1, e.value)),
              // 数据行（已审核）
              if (_journals.isNotEmpty)
                ..._journals.asMap().entries.map((e) => _buildJournalRow(e.key + 1, e.value)),
              // 合计行
              _buildTotalRow(total),
            ],
          ),
        ),
        if (total.totalText.contains('不平衡'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              total.totalText,
              style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _th(String text, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDraftRow(int index, JournalDraft d) {
    final amountStr = _formatMoney(d.amount);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey5.withOpacity(0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Center(child: Text('$index', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 20, child: Text(d.description ?? '-', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2)),
          Expanded(flex: 15, child: Center(child: Text(d.account?.toString() ?? '-', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 10, child: Center(child: Text(d.loan == 1 ? amountStr : '', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 10, child: Center(child: Text(d.loan == 2 ? amountStr : '', style: const TextStyle(fontSize: 13)))),
        ],
      ),
    );
  }

  Widget _buildJournalRow(int index, JournalEntry j) {
    final amountStr = _formatMoney(j.amountCent);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey5.withOpacity(0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Center(child: Text('$index', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 20, child: Text(j.description ?? '-', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2)),
          Expanded(flex: 15, child: Center(child: Text(j.account?.toString() ?? '-', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 10, child: Center(child: Text(j.loan == 1 ? amountStr : '', style: const TextStyle(fontSize: 13)))),
          Expanded(flex: 10, child: Center(child: Text(j.loan == 2 ? amountStr : '', style: const TextStyle(fontSize: 13)))),
        ],
      ),
    );
  }

  Widget _buildTotalRow(({int debitTotal, int creditTotal, String totalText}) total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey4, width: 1)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 25, child: Center(child: Text('合计', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
          const Expanded(flex: 20, child: SizedBox()),
          Expanded(flex: 10, child: Center(child: Text(_formatMoney(total.debitTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
          Expanded(flex: 10, child: Center(child: Text(_formatMoney(total.creditTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // 底部操作栏
  // ═══════════════════════════════════════
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(color: CupertinoColors.separator.resolveFrom(context), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: CupertinoColors.destructiveRed.withOpacity(0.1),
              onPressed: _isProcessing ? null : _doReject,
              child: const Text('驳回', style: TextStyle(color: CupertinoColors.destructiveRed)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: _isProcessing ? null : _doAudit,
              child: _isProcessing
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('审核通过'),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 通用组件
// ════════════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.systemGrey5.withOpacity(0.5), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.centerRight, child: value)),
        ],
      ),
    );
  }
}

/// 用户标识展示（简化版）
class _UserChip extends StatelessWidget {
  final int ident;
  const _UserChip({required this.ident});

  @override
  Widget build(BuildContext context) {
    return Text(
      '[$ident]',
      style: const TextStyle(fontSize: 13, color: CupertinoColors.activeBlue),
    );
  }
}
