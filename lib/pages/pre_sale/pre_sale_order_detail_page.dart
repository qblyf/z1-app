import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/dept_api.dart';
import '../../api/employee_api.dart';
import '../../api/invoice_api.dart';
import '../../api/pre_sale_activity_api.dart';
import '../../api/pre_sale_order_api.dart';
import '../../api/warehouse_api.dart';
import '../../models/product.dart';
import '../../models/pre_sale_order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../clerk/product_select_page.dart';
import '../../router/app_router.dart';

/// 预售订单详情页
class PreSaleOrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const PreSaleOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<PreSaleOrderDetailPage> createState() =>
      _PreSaleOrderDetailPageState();
}

class _PreSaleOrderDetailPageState
    extends ConsumerState<PreSaleOrderDetailPage> {
  final PreSaleOrderApi _api = PreSaleOrderApi();
  final DeptApi _deptApi = DeptApi();
  final PreSaleActivityApi _activityApi = PreSaleActivityApi();

  PreSaleOrder? _order;
  DeptInfo? _dept;
  PreSaleActivity? _activity;
  bool _isLoading = true;
  bool _isOperating = false;
  bool _privilegedToEditDept = false; // 当前用户是否有权限修改部门
  List<DeptInfo> _deptList = []; // 部门列表（选择用）
  List<int> _warehouseIds = []; // 部门绑定仓库ID列表

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadDeptEditPrivilege();
  }

  /// 加载当前用户是否有权限修改部门
  Future<void> _loadDeptEditPrivilege() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;
      final invoiceApi = InvoiceApi();
      final settings = await invoiceApi.getSysSetting(keys: ['preSaleOrderSetting']);
      if (settings == null) return;
      final setting = settings['preSaleOrderSetting'];
      if (setting == null) return;
      // 结构: { key, value: { emplIdents: [...] } }
      final settingMap = setting is Map<String, dynamic> ? setting as Map<String, dynamic> : null;
      if (settingMap == null) return;
      final valueMap = settingMap['value'] is Map<String, dynamic>
          ? settingMap['value'] as Map<String, dynamic>
          : null;
      if (valueMap == null) return;
      final identValue = valueMap['emplIdents'];
      if (identValue is List) {
        final idents = identValue.map((e) => int.tryParse(e.toString()) ?? 0).toList();
        if (mounted) {
          setState(() {
            _privilegedToEditDept = idents.contains(currentUser.userIdent);
          });
        }
      }
    } catch (_) {}
  }

  /// 获取当前用户部门的绑定仓库ID列表（用于更换预订商品选择）
  Future<void> _loadWarehouseIds() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;
    int? deptId;
    try {
      final empApi = EmployeeApi();
      final employees = await empApi.getByUserIdents([currentUser.userIdent]);
      if (employees.isNotEmpty) {
        deptId = employees.first.currentDepartmentId;
      }
    } catch (_) {}
    if (deptId == null) return;
    try {
      final warehouseApi = WarehouseApi();
      final ids = await warehouseApi.getWarehouseIdsByMainDeptId(deptId);
      if (mounted && ids.isNotEmpty) {
        setState(() => _warehouseIds = ids);
      }
    } catch (_) {}
  }

  /// 更换预订商品：打开商品选择 → SKU选择 → 调用API更新 → 刷新
  Future<void> _showChangePresaleSheet() async {
    if (_isOperating) return;
    // 确保仓库ID已加载
    if (_warehouseIds.isEmpty) {
      await _loadWarehouseIds();
      if (!mounted || _warehouseIds.isEmpty) {
        _showError('无法获取仓库信息，请稍后重试');
        return;
      }
    }

    // 打开商品选择页面（仓库绑定模式），返回商品+SKU
    final result = await ProductSelectPage.selectProductWithResult(
      context,
      _warehouseIds,
    );
    if (result == null || !mounted) return;

    // 更新预售商品（使用 SKU 的 ID）
    final skuId = result.sku?.id ?? result.product.id;
    setState(() => _isOperating = true);
    try {
      final ok = await _api.edit(
        id: _order!.id,
        preSaleProduct: skuId,
      );
      if (mounted) {
        if (ok) {
          _showTip('更换成功');
          _loadData();
        } else {
          _showError('更换失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('更换失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final order = await _api.detail(widget.orderId);
      if (!mounted) return;

      if (order == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 并行加载部门名称和活动信息
      final futures = <Future<void>>[];

      if (order.department != null) {
        futures.add(
          _deptApi.getDeptDetail(order.department!).then((dept) {
            if (mounted) setState(() => _dept = dept);
          }).catchError((_) {}),
        );
      }

      if (order.activity > 0) {
        futures.add(
          _activityApi.getDetail(order.activity).then((activity) {
            if (mounted) setState(() => _activity = activity);
          }).catchError((_) {}),
        );
      }

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _doAction(
    String title,
    String confirmText,
    Future<bool> Function() action,
  ) async {
    if (_isOperating) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(confirmText),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOperating = true);
    try {
      final success = await action();
      if (mounted) {
        if (success) {
          await _loadData();
        } else {
          _showError('操作失败');
        }
      }
    } catch (_) {
      if (mounted) _showError('操作失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showTip(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCanBuy = _order?.canBuy == true;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
                leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
        middle: Text(isCanBuy ? '预订购买' : '预订订单详情'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _order == null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('加载失败，请重试', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _loadData,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动信息（缩略图 + 标题 + 描述）
          if (_activity != null) _buildActivitySection(),

          // 订单信息
          _SectionTitle(title: '订单信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '预订单号', value: order.number),
              _InfoRow(
                label: '状态',
                value: _getStatusDisplayText(order),
                valueColor: _getStatusColor(order.statusEnum),
              ),
              _InfoRow(label: '创建时间', value: _formatTime(order.createdAt)),
              _InfoRow(label: '订金', value: '¥${order.amountYuan}'),
              _InfoRow(label: '可抵扣金额', value: '¥${order.totalAmountYuan}'),
              if (_dept != null)
                _DeptSelectableRow(
                  label: '预订部门',
                  value: _dept!.name,
                  editable: _privilegedToEditDept && _order!.status != 'completed',
                  onTap: () => _showDeptSelectSheet(_order!.department ?? 0),
                ),
              if (order.mallOrderNumber != null)
                _InfoRow(
                  label: '商城订单号',
                  value: order.mallOrderNumber!,
                  valueColor: const Color(0xFF0A84FF),
                ),
              if (order.payAt != null)
                _InfoRow(label: '支付时间', value: _formatTime(order.payAt)),
              if (order.toOrderAt != null)
                _InfoRow(label: '转单时间', value: _formatTime(order.toOrderAt)),
            ],
          ),

          // 用户信息
          _SectionTitle(title: '用户信息'),
          _InfoCard(
            children: [
              _InfoRow(label: '用户ID', value: '${order.customer}'),
              if (order.sharer != null)
                _InfoRow(label: '分享人ID', value: '${order.sharer}'),
            ],
          ),

          // 备注信息
          _SectionTitle(title: '备注信息'),
          _InfoCard(
            children: [
              _InfoRow(
                label: '顾客备注',
                value: order.remarks?.isNotEmpty == true
                    ? order.remarks!
                    : '-',
              ),
              _EmplRemarksRow(
                label: '职员备注',
                value: order.emplRemarks?.isNotEmpty == true
                    ? order.emplRemarks!
                    : '-',
                onEdit: () => _showEditEmplRemarksDialog(context),
              ),
              if (order.refundReason != null &&
                  order.refundReason!.isNotEmpty)
                _InfoRow(label: '退款原因', value: order.refundReason!),
            ],
          ),

          // 活动详情
          _SectionTitle(title: '活动信息'),
          _InfoCard(
            children: [
              if (_activity != null) ...[
                _InfoRow(label: '活动标题', value: _activity!.title),
                if (_activity!.describe?.isNotEmpty == true)
                  _InfoRow(label: '活动描述', value: _activity!.describe!),
                _InfoRow(label: '膨胀金额', value: '¥${_activity!.expandAmountYuan}'),
                _InfoRow(label: '膨胀倍数', value: 'x${_activity!.magnifyQuantity}'),
              ] else ...[
                _InfoRow(label: '活动ID', value: '${order.activity}'),
                _InfoRow(label: '活动商品ID', value: '${order.activityProduct}'),
              ],
              if (order.preSaleProduct != null)
                _InfoRow(label: '预订商品SKU', value: '${order.preSaleProduct}'),
              if (order.products.isNotEmpty)
                _InfoRow(
                  label: '捆绑商品',
                  value: order.products.join(', '),
                ),
              if (order.services.isNotEmpty)
                _InfoRow(
                  label: '捆绑服务',
                  value: order.services.join(', '),
                ),
            ],
          ),

          // 支付信息
          _SectionTitle(title: '支付信息'),
          _InfoCard(
            children: [
              _InfoRow(
                label: '实付金额',
                value: order.isPaid ? '¥${order.amountYuan}' : '¥0.00',
                valueColor: order.isPaid
                    ? const Color(0xFFFE9E2D)
                    : const Color(0xFF8E8E93),
              ),
              if (order.payment != null)
                _InfoRow(label: '支付流水号', value: order.payment!.content),
            ],
          ),

          // 操作按钮
          _buildActionButtons(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 活动信息卡片（带缩略图）
  Widget _buildActivitySection() {
    final activity = _activity!;
    final thumbnail = activity.content.thumbnail;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Image.network(
                thumbnail,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: CupertinoColors.systemGrey5,
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 40,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.bold),
                ),
                if (activity.describe?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    activity.describe!,
                    style: AppText.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '订金 ¥${activity.amountYuan}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '膨胀 ¥${activity.expandAmountYuan}',
                        style: const TextStyle(
                          color: Color(0xFFFF9500),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '抵扣 ¥${(activity.amount + activity.expandAmount) / 100}',
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final order = _order!;
    final buttons = <Widget>[];

    if (order.status == 'apply-refund') {
      // 申请退款状态
      buttons.add(_ActionButton(
        label: '确认退款',
        color: const Color(0xFF34C759),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '确认退款',
          '确认同意退款？',
          () => _api.auditRefund(order.id),
        ),
      ));
      buttons.add(_ActionButton(
        label: '取消退款',
        color: const Color(0xFF8E8E93),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '取消退款',
          '确认取消退款申请？',
          () => _api.cancelRefund(order.id),
        ),
      ));
    }

    if (order.canBuy) {
      // 已支付但未转商城单 → 更换预订 + 创建零售单
      buttons.add(_ActionButton(
        label: '更换预订',
        color: const Color(0xFF8E8E93),
        isLoading: _isOperating,
        onPressed: () => _showChangePresaleSheet(),
      ));
      buttons.add(_ActionButton(
        label: '完成预订购买',
        color: const Color(0xFF007AFF),
        isLoading: _isOperating,
        onPressed: () => _startPreSalePurchase(context, order),
      ));
    }

    if (order.status == 'unpaid') {
      buttons.add(_ActionButton(
        label: '取消订单',
        color: const Color(0xFFFF3B30),
        isLoading: _isOperating,
        onPressed: () => _doAction(
          '取消订单',
          '确认取消此预订订单？',
          () => _api.cancel(order.id),
        ),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            buttons[i],
            if (i < buttons.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  /// 开始预订购买流程 - 导航到门店零售入口
  Future<void> _startPreSalePurchase(BuildContext context, PreSaleOrder order) async {
    // 导航到零售单页面，预填充预售商品SKU和捆绑服务
    final params = <String, String>{
      'ident': '${order.customer}',
      'preSaleOrderSkuID': '${order.preSaleProduct ?? 0}',
      'preSaleOrderNumber': order.number,
    };
    // 捆绑服务（JSON 字符串数组）
    if (order.services.isNotEmpty) {
      params['preSaleServices'] = '${order.services}';
    }
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    context.push('/store-retail/order/${order.customer}?$query');
  }

  /// 部门选择弹窗
  Future<void> _showDeptSelectSheet(int currentDeptId) async {
    if (_isOperating) return;
    List<DeptInfo> depts;
    if (_deptList.isNotEmpty) {
      depts = _deptList;
    } else {
      try {
        depts = await _deptApi.getDepartmentList();
        if (mounted) setState(() => _deptList = depts);
      } catch (_) {
        _showError('加载部门列表失败');
        return;
      }
    }

    if (!mounted || depts.isEmpty) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('选择部门'),
        actions: depts.map((dept) {
          final isSelected = dept.id == currentDeptId;
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              if (!isSelected) {
                _changeDept(dept.id, dept.name);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Text(dept.name, textAlign: TextAlign.center)),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.checkmark_alt, size: 18, color: Color(0xFF007AFF)),
                  ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _changeDept(int deptId, String deptName) async {
    if (_order == null || _isOperating) return;
    final oldDept = _dept;
    // 乐观更新
    setState(() {
      _isOperating = true;
      _dept = oldDept != null
          ? DeptInfo(
              id: deptId,
              number: oldDept.number,
              name: deptName,
              spell: oldDept.spell,
              pid: oldDept.pid,
              type: oldDept.type,
              chain: oldDept.chain,
              state: oldDept.state,
              createdAt: oldDept.createdAt,
              isStore: oldDept.isStore,
            )
          : null;
    });
    try {
      final ok = await _api.changeDept(id: _order!.id, department: deptId);
      if (mounted) {
        if (!ok) {
          // 回滚
          setState(() {
            _dept = oldDept;
            _isOperating = false;
          });
          _showError('切换部门失败');
        } else {
          setState(() => _isOperating = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _dept = oldDept;
          _isOperating = false;
        });
        _showError('切换部门失败');
      }
    }
  }

  /// 编辑职员备注弹窗
  Future<void> _showEditEmplRemarksDialog(BuildContext context) async {
    if (_order == null) return;
    final controller = TextEditingController(text: _order!.emplRemarks ?? '');

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('编辑职员备注'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '请输入职员备注',
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveEmplRemarks(controller.text);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _saveEmplRemarks(String remarks) async {
    if (_order == null) return;
    setState(() => _isOperating = true);
    try {
      final ok = await _api.edit(
        id: _order!.id,
        emplRemarks: remarks,
      );
      if (!mounted) return;
      if (ok) {
        await _loadData();
      } else {
        _showError('保存失败');
      }
    } catch (_) {
      if (mounted) _showError('保存失败');
    } finally {
      if (mounted) setState(() => _isOperating = false);
    }
  }

  String _getStatusDisplayText(PreSaleOrder order) {
    switch (order.statusEnum) {
      case PreSaleOrderStatus.paid:
        return order.mallOrderNumber != null ? '已完成' : '已支付';
      default:
        return order.statusLabel;
    }
  }

  Color _getStatusColor(PreSaleOrderStatus? status) {
    switch (status) {
      case PreSaleOrderStatus.unpaid:
        return const Color(0xFFFF9500);
      case PreSaleOrderStatus.paid:
        return const Color(0xFF007AFF);
      case PreSaleOrderStatus.completed:
        return const Color(0xFF34C759);
      case PreSaleOrderStatus.applyRefund:
        return const Color(0xFFFF3B30);
      case PreSaleOrderStatus.refunded:
        return const Color(0xFF8E8E93);
      case PreSaleOrderStatus.canceled:
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

/// 区块标题
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
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

/// 信息卡片
class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Text(label, style: AppText.body),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF636366),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 可选中的部门行（带 chevron 指示器）
class _DeptSelectableRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;
  final VoidCallback onTap;

  const _DeptSelectableRow({
    required this.label,
    required this.value,
    required this.editable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF636366),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (editable) ...[
              const SizedBox(width: 4),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Color(0xFFC7C7CC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 职员备注行（带编辑按钮）
class _EmplRemarksRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _EmplRemarksRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Text(label, style: AppText.body),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF636366),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.pencil,
              size: 16,
              color: Color(0xFF0A84FF),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: color,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
