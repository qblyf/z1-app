import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 筛选条件
class CustomerFilter {
  final String? name;           // 姓名关键词
  final String? phone;          // 手机号
  final String? gender;          // 性别: '女'/'男'/'保密'
  final String? status;          // 状态: 'unverified'/'normal'/'disabled'
  final int? minJoinTime;        // 注册时间下限（unix秒）
  final int? maxJoinTime;        // 注册时间上限（unix秒）
  final int? minLastBuyAt;       // 最后购买下限（unix秒）
  final int? maxLastBuyAt;       // 最后购买上限（unix秒）
  final int? minGrade;           // 最小等级
  final int? maxGrade;           // 最大等级
  final int? isShoppingGuide;    // 1=未绑定导购 2=已绑定导购
  final int? isWxopenid;         // 1=未绑定微信 2=已绑定微信
  final int? startMonth;         // 生日月份下限
  final int? endMonth;           // 生日月份上限
  final int? startDay;           // 生日日下限
  final int? endDay;             // 生日日上限
  final List<MemberOrderBy>? orderBy;

  const CustomerFilter({
    this.name,
    this.phone,
    this.gender,
    this.status,
    this.minJoinTime,
    this.maxJoinTime,
    this.minLastBuyAt,
    this.maxLastBuyAt,
    this.minGrade,
    this.maxGrade,
    this.isShoppingGuide,
    this.isWxopenid,
    this.startMonth,
    this.endMonth,
    this.startDay,
    this.endDay,
    this.orderBy,
  });

  CustomerFilter copyWith({
    String? name,
    String? phone,
    String? gender,
    String? status,
    int? minJoinTime,
    int? maxJoinTime,
    int? minLastBuyAt,
    int? maxLastBuyAt,
    int? minGrade,
    int? maxGrade,
    int? isShoppingGuide,
    int? isWxopenid,
    int? startMonth,
    int? endMonth,
    int? startDay,
    int? endDay,
    List<MemberOrderBy>? orderBy,
  }) {
    return CustomerFilter(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      minJoinTime: minJoinTime ?? this.minJoinTime,
      maxJoinTime: maxJoinTime ?? this.maxJoinTime,
      minLastBuyAt: minLastBuyAt ?? this.minLastBuyAt,
      maxLastBuyAt: maxLastBuyAt ?? this.maxLastBuyAt,
      minGrade: minGrade ?? this.minGrade,
      maxGrade: maxGrade ?? this.maxGrade,
      isShoppingGuide: isShoppingGuide ?? this.isShoppingGuide,
      isWxopenid: isWxopenid ?? this.isWxopenid,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      orderBy: orderBy ?? this.orderBy,
    );
  }

  /// 清空所有筛选项
  CustomerFilter clear() => const CustomerFilter();
}

/// Provider
final customerFilterProvider = StateProvider<CustomerFilter>((ref) => const CustomerFilter());

/// 顾客管理页面（会员列表 + 多条件筛选）
class MemberManagementPage extends ConsumerStatefulWidget {
  const MemberManagementPage({super.key});

  @override
  ConsumerState<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends ConsumerState<MemberManagementPage> {
  final _searchController = TextEditingController();
  List<Member> _members = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _total = 0;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) {
      _offset = 0;
      _members = [];
    }

    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      final filter = ref.read(customerFilterProvider);
      final api = MemberApi();

      // 计算总数据
      final total = await api.getCount(
        minJoinTime: filter.minJoinTime,
        maxJoinTime: filter.maxJoinTime,
        minLastBuyAt: filter.minLastBuyAt,
        maxLastBuyAt: filter.maxLastBuyAt,
        minGrade: filter.minGrade,
        maxGrade: filter.maxGrade,
        names: filter.name != null && filter.name!.isNotEmpty ? [filter.name!] : null,
        phone: filter.phone,
        mobilePhone: filter.phone,
        genders: filter.gender != null ? [filter.gender!] : null,
        state: filter.status,
        isShoppingGuide: filter.isShoppingGuide,
        isWxopenid: filter.isWxopenid,
        startMonth: filter.startMonth,
        endMonth: filter.endMonth,
        startDay: filter.startDay,
        endDay: filter.endDay,
      );

      final list = await api.getList(
        minJoinTime: filter.minJoinTime,
        maxJoinTime: filter.maxJoinTime,
        minLastBuyAt: filter.minLastBuyAt,
        maxLastBuyAt: filter.maxLastBuyAt,
        minGrade: filter.minGrade,
        maxGrade: filter.maxGrade,
        names: filter.name != null && filter.name!.isNotEmpty ? [filter.name!] : null,
        phone: filter.phone,
        mobilePhone: filter.phone,
        genders: filter.gender != null ? [filter.gender!] : null,
        state: filter.status,
        isShoppingGuide: filter.isShoppingGuide,
        isWxopenid: filter.isWxopenid,
        startMonth: filter.startMonth,
        endMonth: filter.endMonth,
        startDay: filter.startDay,
        endDay: filter.endDay,
        orderBy: filter.orderBy,
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        if (reset) {
          _members = list;
        } else {
          _members.addAll(list);
        }
        _total = total;
        _offset += list.length;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    if (_members.length >= _total) return;
    await _loadData(reset: false);
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    ref.read(customerFilterProvider.notifier).state =
        ref.read(customerFilterProvider).copyWith(
              name: query.isNotEmpty ? query : null,
              phone: query.isNotEmpty ? query : null,
            );
    _loadData();
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _FilterSheet(
        onApply: (filter) {
          ref.read(customerFilterProvider.notifier).state = filter;
          _loadData();
        },
        initialFilter: ref.read(customerFilterProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(customerFilterProvider);
    final hasActiveFilter = filter.name != null ||
        filter.gender != null ||
        filter.status != null ||
        filter.minJoinTime != null ||
        filter.maxJoinTime != null ||
        filter.minLastBuyAt != null ||
        filter.maxLastBuyAt != null ||
        filter.minGrade != null ||
        filter.maxGrade != null ||
        filter.isShoppingGuide != null ||
        filter.isWxopenid != null ||
        filter.startMonth != null ||
        filter.endMonth != null;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('顾客管理'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  const Icon(CupertinoIcons.slider_horizontal_3, size: 24),
                  if (hasActiveFilter)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: '搜索姓名或手机号',
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: _onSearch,
                    child: const Text('搜索'),
                  ),
                ],
              ),
            ),

            // 筛选标签（显示已选筛选项）
            if (hasActiveFilter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                color: CupertinoColors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (filter.gender != null)
                        _FilterTag(
                          label: filter.gender!,
                          onRemove: () {
                            ref.read(customerFilterProvider.notifier).state =
                                filter.copyWith(gender: null);
                            _loadData();
                          },
                        ),
                      if (filter.status != null)
                        _FilterTag(
                          label: _statusLabel(filter.status!),
                          onRemove: () {
                            ref.read(customerFilterProvider.notifier).state =
                                filter.copyWith(status: null);
                            _loadData();
                          },
                        ),
                      if (filter.isShoppingGuide != null)
                        _FilterTag(
                          label: filter.isShoppingGuide == 2 ? '已绑定导购' : '未绑定导购',
                          onRemove: () {
                            ref.read(customerFilterProvider.notifier).state =
                                filter.copyWith(isShoppingGuide: null);
                            _loadData();
                          },
                        ),
                      if (filter.isWxopenid != null)
                        _FilterTag(
                          label: filter.isWxopenid == 2 ? '已绑定微信' : '未绑定微信',
                          onRemove: () {
                            ref.read(customerFilterProvider.notifier).state =
                                filter.copyWith(isWxopenid: null);
                            _loadData();
                          },
                        ),
                      if (filter.startMonth != null || filter.endMonth != null)
                        _FilterTag(
                          label: '${filter.startMonth ?? 1}-${filter.endMonth ?? 12}月生日',
                          onRemove: () {
                            ref.read(customerFilterProvider.notifier).state =
                                filter.copyWith(startMonth: null, endMonth: null);
                            _loadData();
                          },
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        child: Text(
                          '清除全部',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.destructiveRed.resolveFrom(context),
                          ),
                        ),
                        onPressed: () {
                          ref.read(customerFilterProvider.notifier).state = const CustomerFilter();
                          _searchController.clear();
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // 结果统计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Text(
                    '共 $_total 人',
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingMore)
                    const CupertinoActivityIndicator(radius: 8),
                ],
              ),
            ),

            const Divider(height: 1),

            // 列表
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载中...');
    }

    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: () => _loadData(),
      );
    }

    if (_members.isEmpty) {
      return const EmptyWidget(
        message: '未找到顾客',
        icon: CupertinoIcons.person_2,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
            _loadMore();
          }
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async => _loadData(),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = _members[index];
                  return _CustomerCard(
                    member: member,
                    onTap: () => context.push('/member/${member.userIdent}'),
                  );
                },
                childCount: _members.length,
              ),
            ),
          ),
          // 加载更多
          if (_members.length < _total)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: _isLoadingMore
                      ? const CupertinoActivityIndicator()
                      : CupertinoButton(
                          child: const Text('加载更多'),
                          onPressed: _loadMore,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'normal':
        return '正常';
      case 'unverified':
        return '未验证';
      case 'disabled':
        return '禁用';
      default:
        return status;
    }
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class Divider extends StatelessWidget {
  final double height;

  const Divider({super.key, this.height = 0.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

/// 筛选底部弹窗
class _FilterSheet extends StatefulWidget {
  final CustomerFilter initialFilter;
  final ValueChanged<CustomerFilter> onApply;

  const _FilterSheet({required this.initialFilter, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CustomerFilter _filter;
  String? _selectedGender;
  String? _selectedStatus;
  int? _selectedGuide;    // 1=未绑定 2=已绑定
  int? _selectedWx;       // 1=未绑定 2=已绑定

  // 日期选择
  DateTime? _minJoinDate;
  DateTime? _maxJoinDate;
  DateTime? _minBuyDate;
  DateTime? _maxBuyDate;

  // 生日月份
  int? _minBirthMonth;
  int? _maxBirthMonth;

  // 等级
  int? _minGrade;
  int? _maxGrade;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _selectedGender = _filter.gender;
    _selectedStatus = _filter.status;
    _selectedGuide = _filter.isShoppingGuide;
    _selectedWx = _filter.isWxopenid;
    _minBirthMonth = _filter.startMonth;
    _maxBirthMonth = _filter.endMonth;
    _minGrade = _filter.minGrade;
    _maxGrade = _filter.maxGrade;
  }

  void _apply() {
    final filter = CustomerFilter(
      name: _filter.name,
      phone: _filter.phone,
      gender: _selectedGender,
      status: _selectedStatus,
      minJoinTime: _minJoinDate != null ? _minJoinDate!.millisecondsSinceEpoch ~/ 1000 : null,
      maxJoinTime: _maxJoinDate != null
          ? _maxJoinDate!.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000 - 1
          : null,
      minLastBuyAt: _minBuyDate != null ? _minBuyDate!.millisecondsSinceEpoch ~/ 1000 : null,
      maxLastBuyAt: _maxBuyDate != null
          ? _maxBuyDate!.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000 - 1
          : null,
      minGrade: _minGrade,
      maxGrade: _maxGrade,
      isShoppingGuide: _selectedGuide,
      isWxopenid: _selectedWx,
      startMonth: _minBirthMonth,
      endMonth: _maxBirthMonth,
      orderBy: _filter.orderBy,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _selectedGender = null;
      _selectedStatus = null;
      _selectedGuide = null;
      _selectedWx = null;
      _minJoinDate = null;
      _maxJoinDate = null;
      _minBuyDate = null;
      _maxBuyDate = null;
      _minBirthMonth = null;
      _maxBirthMonth = null;
      _minGrade = null;
      _maxGrade = null;
    });
  }

  void _showDatePicker(bool isMin, VoidCallback onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    onChanged();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isMin ? (_minJoinDate ?? DateTime.now()) : (_maxJoinDate ?? DateTime.now()),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    if (isMin) {
                      _minJoinDate = date;
                    } else {
                      _maxJoinDate = date;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 顶部栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '筛选条件',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),

          // 筛选内容
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 性别
                _SectionTitle('性别'),
                _SegmentedSelector(
                  options: const [null, '女', '男', '保密'],
                  labels: const ['全部', '女', '男', '保密'],
                  selectedValue: _selectedGender,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 会员状态
                _SectionTitle('会员状态'),
                _SegmentedSelector(
                  options: const [null, 'normal', 'unverified', 'disabled'],
                  labels: const ['全部', '正常', '未验证', '禁用'],
                  selectedValue: _selectedStatus,
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 专属导购绑定
                _SectionTitle('专属导购绑定'),
                _SegmentedSelector(
                  options: const [null, 2, 1],
                  labels: const ['全部', '已绑定', '未绑定'],
                  selectedValue: _selectedGuide,
                  onChanged: (v) => setState(() => _selectedGuide = v),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 微信绑定
                _SectionTitle('微信绑定'),
                _SegmentedSelector(
                  options: const [null, 2, 1],
                  labels: const ['全部', '已绑定', '未绑定'],
                  selectedValue: _selectedWx,
                  onChanged: (v) => setState(() => _selectedWx = v),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 入会日期
                _SectionTitle('入会日期'),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerButton(
                        label: '开始日期',
                        date: _minJoinDate,
                        onTap: () => _showDatePicker(true, () {}),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('至'),
                    ),
                    Expanded(
                      child: _DatePickerButton(
                        label: '结束日期',
                        date: _maxJoinDate,
                        onTap: () => _showDatePicker(false, () {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 最后购买日期
                _SectionTitle('最后购买日期'),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerButton(
                        label: '开始日期',
                        date: _minBuyDate,
                        onTap: () => _showBuyDatePicker(true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('至'),
                    ),
                    Expanded(
                      child: _DatePickerButton(
                        label: '结束日期',
                        date: _maxBuyDate,
                        onTap: () => _showBuyDatePicker(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 等级
                _SectionTitle('会员等级'),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        placeholder: '最小等级',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _minGrade = int.tryParse(v),
                        controller: TextEditingController(text: _minGrade?.toString()),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('至'),
                    ),
                    Expanded(
                      child: CupertinoTextField(
                        placeholder: '最大等级',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _maxGrade = int.tryParse(v),
                        controller: TextEditingController(text: _maxGrade?.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 生日月份
                _SectionTitle('生日月份'),
                Row(
                  children: [
                    Expanded(
                      child: _MonthPickerButton(
                        label: '开始月',
                        month: _minBirthMonth,
                        onChanged: (m) => setState(() => _minBirthMonth = m),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('至'),
                    ),
                    Expanded(
                      child: _MonthPickerButton(
                        label: '结束月',
                        month: _maxBirthMonth,
                        onChanged: (m) => setState(() => _maxBirthMonth = m),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 底部按钮
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              top: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoColors.systemGrey5,
                    onPressed: _reset,
                    child: Text(
                      '重置',
                      style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _apply,
                    child: const Text('应用筛选'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyDatePicker(bool isMin) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isMin
                    ? (_minBuyDate ?? DateTime.now())
                    : (_maxBuyDate ?? DateTime.now()),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    if (isMin) {
                      _minBuyDate = date;
                    } else {
                      _maxBuyDate = date;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppText.body.copyWith(
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }
}

class _SegmentedSelector<T> extends StatelessWidget {
  final List<T?> options;
  final List<String> labels;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;

  const _SegmentedSelector({
    required this.options,
    required this.labels,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 找到选中项的索引
    int selectedIndex = options.indexOf(selectedValue);
    if (selectedIndex < 0) selectedIndex = 0;

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: selectedIndex,
        children: {
          for (int i = 0; i < labels.length; i++)
            i: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(labels[i], style: const TextStyle(fontSize: 13)),
            ),
        },
        onValueChanged: (index) {
          if (index == null) return;
          onChanged(options[index]);
        },
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontSize: 14,
                  color: date != null
                      ? CupertinoColors.label.resolveFrom(context)
                      : CupertinoColors.placeholderText.resolveFrom(context),
                ),
              ),
            ),
            const Icon(CupertinoIcons.calendar, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerButton extends StatelessWidget {
  final String label;
  final int? month;
  final ValueChanged<int?> onChanged;

  const _MonthPickerButton({
    required this.label,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMonthPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                month != null ? '$month 月' : label,
                style: TextStyle(
                  fontSize: 14,
                  color: month != null
                      ? CupertinoColors.label.resolveFrom(context)
                      : CupertinoColors.placeholderText.resolveFrom(context),
                ),
              ),
            ),
            const Icon(CupertinoIcons.calendar, size: 18),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(
                  initialItem: (month ?? 1) - 1,
                ),
                onSelectedItemChanged: (index) => onChanged(index + 1),
                children: List.generate(
                  12,
                  (i) => Center(child: Text('${i + 1} 月')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顾客卡片
class _CustomerCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _CustomerCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              UserAvatar(
                name: member.realName,
                avatarUrl: member.wxAcatar,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.realName ?? '未知',
                          style: AppText.subtitle,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _GenderTag(gender: member.gender),
                        const SizedBox(width: AppSpacing.sm),
                        _StatusTag(status: member.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.mobilePhone ?? '-',
                      style: AppText.caption.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoTag(label: '等级 ${member.grade}'),
                        const SizedBox(width: AppSpacing.sm),
                        _InfoTag(label: '积分 ${member.coin}'),
                        if (member.lastBuyAt != null && member.lastBuyAt! > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _InfoTag(
                            label: '最近购买 ${_formatLastBuy(member.lastBuyAt!)}',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastBuy(int unix) {
    final now = DateTime.now();
    final buyDate = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    final diff = now.difference(buyDate);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}月前';
    return '${(diff.inDays / 365).floor()}年前';
  }
}

class _GenderTag extends StatelessWidget {
  final Sex gender;

  const _GenderTag({required this.gender});

  @override
  Widget build(BuildContext context) {
    final color = gender == Sex.male
        ? const Color(0xFF0A84FF)
        : gender == Sex.female
            ? const Color(0xFFFF2D55)
            : CupertinoColors.systemGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        gender.label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final UserState status;

  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == UserState.normal
        ? AppColors.success
        : status == UserState.disabled
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;

  const _InfoTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
