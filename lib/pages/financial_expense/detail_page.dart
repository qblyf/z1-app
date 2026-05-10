import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/financial_expense_api.dart';
import '../../models/financial_expense.dart';
import '../../theme/app_theme.dart';

final _expenseDetailProvider = FutureProvider.autoDispose.family<FinancialExpenseItem?, int>((ref, id) async {
  return financialExpenseApi.detail(id);
});

class FinancialExpenseDetailPage extends ConsumerWidget {
  final int orderID;

  const FinancialExpenseDetailPage({super.key, required this.orderID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_expenseDetailProvider(orderID));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('支出单详情'),
      ),
      child: detailAsync.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('未找到该支出单'));
          }
          return _DetailContent(item: item);
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text('加载失败: $e', style: const TextStyle(color: CupertinoColors.systemRed)),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final FinancialExpenseItem item;

  const _DetailContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.status.colorValue);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withValues(alpha: 0.8), statusColor],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status.label,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.amountDisplay,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 基本信息
            _SectionCard(
              title: '基本信息',
              children: [
                _InfoRow(label: '单号', value: item.number),
                _InfoRow(label: '标题', value: item.title),
                if (item.financialExpensesTypeName != null)
                  _InfoRow(label: '支出类型', value: item.financialExpensesTypeName!),
                if (item.creatorName != null)
                  _InfoRow(label: '创建人', value: item.creatorName!),
                if (item.createdAt > 0)
                  _InfoRow(label: '创建时间', value: _formatTime(item.createdAt)),
              ],
            ),

            if (item.remark != null && item.remark!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: '备注',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      item.remark!,
                      style: AppText.body.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: CupertinoColors.separator.resolveFrom(context)),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppText.caption.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }
}
