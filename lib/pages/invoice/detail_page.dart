import 'package:flutter/cupertino.dart';
import '../../api/invoice_api.dart';
import '../../models/invoice.dart';
import '../../theme/app_theme.dart';

/// 发票详情页
class InvoiceDetailPage extends StatefulWidget {
  final int invoiceID;

  const InvoiceDetailPage({super.key, required this.invoiceID});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

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
      final api = InvoiceApi();
      final detail = await api.detail(widget.invoiceID);
      setState(() {
        _invoice = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('发票详情'),
        previousPageTitle: '返回',
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_circle,
                size: 48, color: CupertinoColors.systemRed),
            const SizedBox(height: 12),
            Text(_error!, style: AppText.body),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }
    if (_invoice == null) {
      return const Center(child: Text('未找到发票'));
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('申请详情'),
              _buildCard([
                _buildRow('申请人', '员工${_invoice!.applicant}'),
                _buildRow('部门', '部门${_invoice!.department}'),
                _buildRow('申请日期', _invoice!.formattedApplyTime),
                _buildRow('状态', _invoice!.status.label,
                    valueColor: _invoice!.status.color),
                if (_invoice!.orderNumbersList != null &&
                    _invoice!.orderNumbersList!.isNotEmpty)
                  _buildRow('订单编号', _invoice!.orderNumbersList!.first),
                _buildRow('发票类型', _invoice!.type.label),
                _buildRow('单位性质', _invoice!.unitProperties.label),
                _buildRow('开票方式', _invoice!.invoiceMethod.label),
                _buildRow('发票抬头', _invoice!.invoiceHeader, borderBottom: false),
              ]),
              _buildSectionTitle('开票信息'),
              _buildCard([
                _buildRow('开票金额', '¥${_invoice!.invoiceAmountYuan.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFFF9500), fontWeight: FontWeight.bold),
                _buildRow('开票日期', _invoice!.formattedInvoiceTime),
                _buildRow('发票号码', _invoice!.invoiceNumber ?? '--'),
                _buildRow('少开金额',
                    _invoice!.lessAmount != null && _invoice!.lessAmount! > 0
                        ? '¥${_invoice!.lessAmountYuan.toStringAsFixed(2)}'
                        : '--',
                    borderBottom: false),
              ]),
              _buildSectionTitle('发票信息'),
              _buildCard([
                _buildRow('联系电话', _invoice!.phone),
                _buildRow('电子邮箱', _invoice!.email ?? '--'),
                _buildRow('税号', _invoice!.taxID ?? '--'),
                _buildRow('银行账号', _invoice!.bankAccountNumber ?? '--'),
                _buildRow('公司电话', _invoice!.companyPhone ?? '--'),
                _buildRow('开户银行', _invoice!.openingBank ?? '--'),
                _buildRow('公司地址', _invoice!.companyAddress ?? '--', borderBottom: false),
              ]),
              // 附件
              if (_invoice!.attachment != null &&
                  _invoice!.attachment!.isNotEmpty) ...[
                _buildSectionTitle('附件'),
                _buildCard(
                  [
                    _buildAttachmentList(_invoice!.attachment!),
                  ],
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ],
              // 备注
              if (_invoice!.remarksList.isNotEmpty) ...[
                _buildSectionTitle('备注'),
                _buildCard(
                  _invoice!.remarksList.map((r) => _buildRemarkItem(r)).toList(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ],
              // 商品信息（无订单）
              if (_invoice!.orderInfo.isNotEmpty)
                ..._invoice!.orderInfo.expand((order) {
                  if (order.noOrder.isEmpty) return <Widget>[];
                  return [
                    _buildSectionTitle('商品信息'),
                    ...order.noOrder.map((item) => _buildCard([
                      _buildProductItem(item),
                    ])),
                  ];
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight fontWeight = FontWeight.normal,
    bool borderBottom = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: borderBottom
            ? const Border(
                bottom: BorderSide(color: Color(0xFFF2F2F7), width: 0.5),
              )
            : null,
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
                color: valueColor,
                fontWeight: fontWeight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentList(List<String> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((url) {
        final fileName = url.split('/').last;
        return GestureDetector(
          onTap: () {
            // TODO: 预览图片或下载文件
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text('附件'),
                content: Text(fileName),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('关闭'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.paperclip,
                    size: 12, color: Color(0xFF0A84FF)),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0A84FF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemarkItem(InvoiceRemark remark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: AppText.caption,
          children: [
            TextSpan(
              text: remark.formattedTime,
              style: const TextStyle(color: Color(0xFF8E8E93)),
            ),
            TextSpan(text: r' 【员工${'),
            TextSpan(
              text: '${remark.createdBy}】',
              style: const TextStyle(color: Color(0xFF0A84FF)),
            ),
            TextSpan(text: remark.content),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(InvoiceNoOrderItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildProductTag('数量 ${item.quantity}'),
            const SizedBox(width: 8),
            _buildProductTag('单价 ¥${item.amountYuan.toStringAsFixed(2)}'),
            const SizedBox(width: 8),
            _buildProductTag(
                '合计 ¥${(item.amount * item.quantity / 100).toStringAsFixed(2)}',
                color: const Color(0xFFFF9500)),
          ],
        ),
        if (item.attachment.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAttachmentList(item.attachment),
        ],
      ],
    );
  }

  Widget _buildProductTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF8E8E93)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color ?? const Color(0xFF8E8E93)),
      ),
    );
  }
}
