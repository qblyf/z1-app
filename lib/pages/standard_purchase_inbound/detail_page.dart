import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/standard_purchase_inbound_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 标品采购入库单详情页
/// 对应 PWA /pages/path-d/standard-purchase-inbound/order-detail.tsx
class StandardPurchaseInboundDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const StandardPurchaseInboundDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<StandardPurchaseInboundDetailPage> createState() =>
      _StandardPurchaseInboundDetailPageState();
}

class _StandardPurchaseInboundDetailPageState
    extends ConsumerState<StandardPurchaseInboundDetailPage> {
  final StandardPurchaseInboundApi _api = StandardPurchaseInboundApi();

  PurchaseInboundDetail? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final detail = await _api.detail(widget.orderId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('采购入库单详情'),
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
                        Text('未获取到采购入库单数据', style: AppText.caption),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final state = PurchaseInboundState.fromValue(detail.state);
    final stateColor = _getStateColor(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基础信息
          _SectionTitle('基础信息'),
          const SizedBox(height: 8),
          _InfoCard([
            _InfoRow('单号', detail.number ?? '-'),
            _InfoRow('状态', state.label, valueColor: stateColor),
            _InfoRow('往来单位', detail.vendorName ?? '往来单位${detail.vendorID}'),
            _InfoRow('入库仓库', detail.warehouseName ?? '仓库${detail.warehouseID}'),
            _InfoRow('制单人', detail.creatorName ?? '工号${detail.creatorIdent}'),
            _InfoRow('创建时间', detail.formattedCreatedAt),
            if (detail.remarks != null && detail.remarks!.isNotEmpty)
              _InfoRow('备注', detail.remarks!),
            if (detail.purchaseOrderNumber != null)
              _InfoRow('采购订单号', detail.purchaseOrderNumber!),
          ]),

          const SizedBox(height: AppSpacing.lg),

          // 商品信息
          if (detail.products.isNotEmpty) ...[
            _SectionTitle('商品信息'),
            const SizedBox(height: 8),
            ...detail.products.map((p) => _ProductCard(product: p)),

            // 统计
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(
              totalQuantity: detail.totalQuantity,
              totalAmount: detail.formattedAmount,
              totalLoss: detail.formattedLoss,
            ),
          ] else ...[
            _SectionTitle('商品信息'),
            const SizedBox(height: 8),
            _InfoCard([
              _InfoRow('无商品信息', ''),
            ]),
          ],

          const SizedBox(height: AppSpacing.lg),

          // 返回按钮
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => context.push('/standard-purchase-inbound'),
              child: const Text('返回入库单列表'),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Color _getStateColor(PurchaseInboundState state) {
    switch (state) {
      case PurchaseInboundState.normal:
        return const Color(0xFF30D158);
      case PurchaseInboundState.draft:
        return const Color(0xFF8E8E93);
      case PurchaseInboundState.undetermined:
        return const Color(0xFFFF9500);
    }
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

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
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

class _ProductCard extends StatelessWidget {
  final PurchaseInboundProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product.cent != null ? '¥${(product.cent! / 100).toStringAsFixed(2)}' : '-';
    final cost = product.costPrice != null ? '¥${(product.costPrice! / 100).toStringAsFixed(2)}' : '-';
    final loss = (product.cent != null && product.costPrice != null)
        ? '¥${((product.cent! - product.costPrice!) / 100).toStringAsFixed(2)}'
        : '-';
    final qty = product.quantity;

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
          Text(
            product.productName ?? '商品ID: ${product.product}',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('采购单价', style: AppText.caption),
                    Text(price, style: AppText.body.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF007AFF))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('采购数量', style: AppText.caption),
                    Text('$qty 件', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('库存单价', style: AppText.caption),
                    Text(cost, style: AppText.body),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('合计金额', style: AppText.caption),
                    Text(product.cent != null ? '¥${(qty * product.cent! / 100).toStringAsFixed(2)}' : '-',
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('单价损失', style: AppText.caption),
                    Text(loss, style: AppText.body.copyWith(color: const Color(0xFFFF3B30))),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),

          // 序列号信息
          if (product.serial != null && product.serial!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppColors.divider,
            ),
            const SizedBox(height: 8),
            Text('序列号信息', style: AppText.label),
            const SizedBox(height: 8),
            ...product.serial!.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${idx + 1}. ', style: AppText.caption),
                    if (s.serial != null) Text('序列号: ${s.serial}', style: AppText.caption),
                    if (s.meid != null) Text('  MEID: ${s.meid}', style: AppText.caption),
                    if (s.sn2 != null) Text('  SN2: ${s.sn2}', style: AppText.caption),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalQuantity;
  final String totalAmount;
  final String totalLoss;

  const _SummaryCard({
    required this.totalQuantity,
    required this.totalAmount,
    required this.totalLoss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('$totalQuantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                Text('采购总数量', style: AppText.caption),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                Text(totalAmount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF007AFF))),
                Text('采购总金额', style: AppText.caption),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                Text(totalLoss, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF3B30))),
                Text('预估调价损失', style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
