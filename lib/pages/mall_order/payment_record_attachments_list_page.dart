import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/payment_detail_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// 支付记录附件列表页
/// 对应 PWA /pages/path-d/mall-order/payment-record-attachments-list.tsx
class PaymentRecordAttachmentsListPage extends ConsumerStatefulWidget {
  const PaymentRecordAttachmentsListPage({super.key});

  @override
  ConsumerState<PaymentRecordAttachmentsListPage> createState() =>
      _PaymentRecordAttachmentsListPageState();
}

class _PaymentRecordAttachmentsListPageState
    extends ConsumerState<PaymentRecordAttachmentsListPage> {
  final PaymentDetailApi _api = PaymentDetailApi();

  // 加载状态
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 10;

  // 数据
  List<PaymentAttachRecord> _list = [];

  // 筛选条件
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _orderNumber = '';
  String _phone = '';
  String? _attachState;
  int? _paymentTypeId;
  bool _searchVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData(refresh: true);
  }

  Future<void> _loadData({bool refresh = false, bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (refresh) { _page = 0; _hasMore = true; }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final minTs = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0).millisecondsSinceEpoch ~/ 1000;
      final maxTs = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

      // 总数
      final total = await _api.getAttachCount(
        orderStatus: ['3', '4', '5', '6', '7'], // 部分支付=3,已支付=4,已出库=5,已完成=6,已评价=7
        minCreatedAt: minTs,
        maxCreatedAt: maxTs,
        mallOrderNumbers: _orderNumber.isNotEmpty ? [_orderNumber] : null,
        phone: _phone.isNotEmpty ? _phone : null,
        attachState: _attachState != null ? [_attachState!] : null,
        paymentTypeIDs: _paymentTypeId != null ? [_paymentTypeId!] : null,
        sellerIdents: [user.userIdent],
      );

      if (total == 0) {
        setState(() { _list = []; _isLoading = false; _hasMore = false; });
        return;
      }

      // 列表
      final data = await _api.getAttachList(
        orderStatus: ['3', '4', '5', '6', '7'],
        minCreatedAt: minTs,
        maxCreatedAt: maxTs,
        mallOrderNumbers: _orderNumber.isNotEmpty ? [_orderNumber] : null,
        phone: _phone.isNotEmpty ? _phone : null,
        attachState: _attachState != null ? [_attachState!] : null,
        paymentTypeIDs: _paymentTypeId != null ? [_paymentTypeId!] : null,
        sellerIdents: [user.userIdent],
        limit: _pageSize,
        offset: refresh ? 0 : _page * _pageSize,
        orderBy: 'created_at',
        sort: 'DESC',
      );

      setState(() {
        if (refresh || _page == 0) {
          _list = data;
        } else {
          _list.addAll(data);
        }
        _hasMore = data.length >= _pageSize;
        _isLoading = false;
        if (!loadMore) _page++;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('支付记录附件'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _searchVisible ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
            size: 20,
          ),
          onPressed: () => setState(() => _searchVisible = !_searchVisible),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_searchVisible) _buildSearchBar(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: CupertinoColors.white,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showDateRangePicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('付款日期', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  const Spacer(),
                  Text('${_formatDate(_startDate)}-${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF999999)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 16),
          GestureDetector(
            onTap: () => _showAttachStatePicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('附件状态', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  const Spacer(),
                  Text(_attachStateLabel(_attachState),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF999999)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 16),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFF0F0F5),
                    onPressed: () {
                      setState(() {
                        _startDate = DateTime.now().subtract(const Duration(days: 7));
                        _endDate = DateTime.now();
                        _orderNumber = '';
                        _phone = '';
                        _attachState = null;
                        _paymentTypeId = null;
                      });
                      _loadData(refresh: true);
                    },
                    child: const Text('重置', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: () => _loadData(refresh: true),
                    child: const Text('查询', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _list.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.doc_text, size: 48, color: Color(0xFFDDDDE0)),
            const SizedBox(height: 16),
            Text('暂无数据', style: AppText.body),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification && n.metrics.extentAfter < 100 && _hasMore && !_isLoading) {
          setState(() => _page++);
          _loadData(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _list.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _list.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final item = _list[i];
          return _AttachCard(
            item: item,
            onTap: () => context.push(
                '/mall-order/payment-record-attachment/${Uri.encodeComponent(item.paymentDetailNumber)}'),
          );
        },
      ),
    );
  }

  void _showDateRangePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _DateRangePickerSheet(
        startDate: _startDate,
        endDate: _endDate,
        onApply: (start, end) => setState(() { _startDate = start; _endDate = end; }),
      ),
    );
  }

  void _showAttachStatePicker() {
    final options = [
      ('全部', null),
      ('待上传', 'wait'),
      ('不需要审核', 'not_required'),
      ('待审核', 'pending'),
      ('已通过', 'approved'),
      ('已驳回', 'rejected'),
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('选择附件状态'),
        actions: options.map((o) => CupertinoActionSheetAction(
          onPressed: () { setState(() => _attachState = o.$2); Navigator.pop(context); },
          child: Text(o.$1),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  String _attachStateLabel(String? s) {
    if (s == null) return '全部';
    switch (s) {
      case 'wait': return '待上传';
      case 'not_required': return '不需要审核';
      case 'pending': return '待审核';
      case 'approved': return '已通过';
      case 'rejected': return '已驳回';
      default: return '全部';
    }
  }
}

class _AttachCard extends StatelessWidget {
  final PaymentAttachRecord item;
  final VoidCallback onTap;
  const _AttachCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    '订单编号: ${item.mallOrderNumber}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.attachStateColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.attachStateLabel, style: TextStyle(fontSize: 12, color: item.attachStateColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              '顾客手机号  ${item.phone ?? '-'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 4),
            Text(
              '支付方式  ID: ${item.paymentTypeID}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangePickerSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onApply;
  const _DateRangePickerSheet({required this.startDate, required this.endDate, required this.onApply});

  @override
  State<_DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<_DateRangePickerSheet> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      color: CupertinoColors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('取消', style: TextStyle(color: Color(0xFF666666))),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('确定', style: TextStyle(color: Color(0xFF0A84FF))),
                  onPressed: () {
                    widget.onApply(_start, _end);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _start,
                  onDateTimeChanged: (d) => setState(() => _start = d),
                )),
                const Text('至', style: TextStyle(fontSize: 14)),
                Expanded(child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _end,
                  onDateTimeChanged: (d) => setState(() => _end = d),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
