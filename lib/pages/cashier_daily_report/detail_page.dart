import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/cashier_daily_report_api.dart';
import '../../models/cashier_daily_report.dart';
import '../../theme/app_theme.dart';

/// 收银日报详情页
class CashierDailyReportDetailPage extends ConsumerStatefulWidget {
  final int departmentID;
  final String date;

  const CashierDailyReportDetailPage({
    super.key,
    required this.departmentID,
    required this.date,
  });

  @override
  ConsumerState<CashierDailyReportDetailPage> createState() =>
      _CashierDailyReportDetailPageState();
}

class _CashierDailyReportDetailPageState
    extends ConsumerState<CashierDailyReportDetailPage> {
  CashierDailyReport? _report;
  bool _isLoading = true;
  bool _isAuditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = CashierDailyReportApi();
      final report = await api.detail(
        date: widget.date,
        departmentID: widget.departmentID,
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _audit() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('确认审核'),
        content: const Text('确认审核通过此收银日报表？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text('确认'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isAuditing = true);
    try {
      final api = CashierDailyReportApi();
      final ok = await api.audit(
        date: widget.date,
        departmentIDs: [widget.departmentID],
      );
      if (ok) {
        _showMsg('审核成功');
        _loadData();
      } else {
        _showMsg('审核失败');
      }
    } catch (e) {
      _showMsg('审核失败：$e');
    } finally {
      setState(() => _isAuditing = false);
    }
  }

  void _showMsg(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text('收银日报 · ${widget.date}'),
        trailing: _report?.state.value == 'unaudited'
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isAuditing ? null : _audit,
                child: _isAuditing
                    ? const CupertinoActivityIndicator()
                    : const Text('审核',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _report == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.doc_text,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        Text('未找到日报详情', style: AppText.caption),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final report = _report!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 基本信息卡片
          _InfoCard(report: report),

          const SizedBox(height: AppSpacing.md),

          // 总收入统计
          _TotalIncomeCard(report: report),

          const SizedBox(height: AppSpacing.md),

          // POS进账
          if (report.paymentPos.isNotEmpty) ...[
            _SectionTitle('POS进账'),
            const SizedBox(height: 8),
            ...report.paymentPos.map((p) => _PosIncomeItem(item: p)),
            const SizedBox(height: AppSpacing.md),
          ],

          // 银行存款
          if (report.bankAccountInfo.isNotEmpty) ...[
            _SectionTitle('银行存款'),
            const SizedBox(height: 8),
            ...report.bankAccountInfo.map((b) => _BankIncomeItem(item: b)),
            const SizedBox(height: AppSpacing.md),
          ],

          // 其他收入
          if (report.otherIncome.isNotEmpty) ...[
            _SectionTitle('其他收入'),
            const SizedBox(height: 8),
            ...report.otherIncome.map((o) => _OtherIncomeItem(item: o)),
          ],

          // 备注
          if (report.remarks != null && report.remarks!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SectionTitle('备注'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Text(report.remarks!, style: AppText.body),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppText.label);
  }
}

class _InfoCard extends StatelessWidget {
  final CashierDailyReport report;

  const _InfoCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: report.state.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  report.state.value == 'audited'
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.clock,
                  color: report.state.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.date, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      report.state.label,
                      style: TextStyle(color: report.state.color, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoItem(label: '部门', value: report.departmentName ?? '部门${report.departmentID}'),
              _InfoItem(label: '提交人', value: report.creatorName ?? '-'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(label: '创建时间', value: report.formattedCreatedAt),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text('$label：', style: AppText.caption),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }
}

class _TotalIncomeCard extends StatelessWidget {
  final CashierDailyReport report;

  const _TotalIncomeCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A84FF).withValues(alpha: 0.1),
            const Color(0xFF5E5CE6).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFF0A84FF).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Text('总收款合计', style: TextStyle(color: Color(0xFF0A84FF))),
          const SizedBox(height: 4),
          Text(
            '¥${report.totalIncomeYuan.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0A84FF),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TotalItem(
                  label: 'POS进账',
                  value: '¥${report.posIncomeYuan.toStringAsFixed(2)}'),
              Container(width: 1, height: 30, color: const Color(0xFF0A84FF).withValues(alpha: 0.3)),
              _TotalItem(
                  label: '银行存款',
                  value: '¥${report.bankIncomeYuan.toStringAsFixed(2)}'),
              Container(width: 1, height: 30, color: const Color(0xFF0A84FF).withValues(alpha: 0.3)),
              _TotalItem(
                  label: '其他收入',
                  value: '¥${report.totalOtherYuan.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;

  const _TotalItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
          color: Color(0xFF0A84FF),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        )),
      ],
    );
  }
}

class _PosIncomeItem extends StatelessWidget {
  final PaymentPos item;

  const _PosIncomeItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.creditcard,
                color: Color(0xFF0A84FF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('POS终端 ${item.posClientID}', style: AppText.body),
          ),
          Text(
            '¥${item.amountYuan.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF0A84FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankIncomeItem extends StatelessWidget {
  final BankAccountInfo item;

  const _BankIncomeItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF30D158).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.square_stack,
                color: Color(0xFF30D158), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('银行账户 ${item.bankAccountID}', style: AppText.body),
          ),
          Text(
            '¥${item.amountYuan.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF30D158),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherIncomeItem extends StatelessWidget {
  final OtherIncomeItem item;

  const _OtherIncomeItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.money_dollar_circle,
                color: Color(0xFFFF9500), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支付方式 ${item.paymentTypeID}', style: AppText.body),
                if (item.remarks != null)
                  Text(item.remarks!, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            '¥${item.amountYuan.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFFF9500),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
