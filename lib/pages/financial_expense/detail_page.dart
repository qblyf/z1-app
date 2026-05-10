import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/financial_expense_api.dart';
import '../../models/financial_expense.dart';
import '../../theme/app_theme.dart';

final _expenseDetailProvider = FutureProvider.autoDispose.family<FinancialExpense?, int>((ref, id) async {
  return financialExpenseApi.fullDetail(id);
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
  final FinancialExpense item;

  const _DetailContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.status.colorValue);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
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
                          item.totalAmountDisplay,
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
                      _InfoRow(label: '内容', value: item.content.isEmpty ? '-' : item.content),
                      _InfoRow(label: '业务类型', value: item.businessType),
                      if (item.createdAt > 0)
                        _InfoRow(label: '创建时间', value: _formatTime(item.createdAt)),
                    ],
                  ),

                  // 预支款项内容
                  if (item.infos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '预支款项内容（${item.infos.length}项）',
                      children: item.infos.asMap().entries.map((entry) {
                        final info = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (info.remarks != null && info.remarks!.isNotEmpty)
                                      Text(info.remarks!, style: AppText.caption),
                                  ],
                                ),
                              ),
                              Text(
                                info.amountDisplay,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (item.content.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '备注',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            item.content,
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
          ),
          // 底部结算按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  child: const Text('去结算'),
                  onPressed: () {
                    context.push('/financial-expense/settlement/${item.id}');
                  },
                ),
              ),
            ),
          ),
        ],
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

