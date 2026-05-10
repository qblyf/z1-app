import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/employee_score_api.dart';
import '../../models/employee_score.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// 职员得分情况（分组排行）页面
/// 对应 PWA: /employee-score/statistic
class EmployeeScoreRankingDetailPage extends ConsumerStatefulWidget {
  const EmployeeScoreRankingDetailPage({super.key});

  @override
  ConsumerState<EmployeeScoreRankingDetailPage> createState() =>
      _EmployeeScoreRankingDetailPageState();
}

class _EmployeeScoreRankingDetailPageState
    extends ConsumerState<EmployeeScoreRankingDetailPage> {
  // ── 数据状态 ──────────────────────────────────────────────────
  List<DepartmentEmployeeScoreClassGroup> _allGroups = [];
  List<DepartmentEmployeeScoreClassGroup> _selectedGroups = [];
  List<EmployeeScoreGiveLogInfo> _rawData = [];
  bool _isLoading = true;
  String? _errorMsg;

  // ── 过滤状态 ──────────────────────────────────────────────────
  int? _selectedDeptId;
  String _orderByKey = '-1'; // 当前排序列（group id 或 -1 表示全部）
  String _orderBySort = 'desc'; // 排序方向
  bool _filterRedBlack = false; // false=全部展开 true=仅显示前三后三

  // ── 当前用户 ──────────────────────────────────────────────────
  int get _currentUserIdent =>
      ref.read(currentUserProvider).value?.userIdent ?? 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// 初始化：先加载分组列表，再加载数据
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final api = EmployeeScoreApi();

      // 1. 尝试从 URL 参数获取已选分组（压缩格式）
      // 2. 否则获取所有分组，取权重前三
      List<DepartmentEmployeeScoreClassGroup> groups = [];

      final uri = Uri.base;
      final groupIDs = uri.queryParameters['groupIDs'];
      if (groupIDs != null && groupIDs.isNotEmpty) {
        // 尝试解码
        try {
          // groupIDs 可能是 LZString 压缩的 base64，这里先尝试直接作为逗号分隔数字
          final parts = groupIDs.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
          if (parts.isNotEmpty) {
            groups = await api.getScoreClassGroupDetail(parts);
          }
        } catch (_) {}
      }

      if (groups.isEmpty) {
        // 获取工分类别列表，取关联分组ID
        final classes = await api.getScoreClassList(isHide: false);
        if (classes.isNotEmpty) {
          final groupIds = classes.map((c) => c.group).toSet().toList();
          groups = await api.getScoreClassGroupDetail(groupIds);
        }
      }

      if (groups.isEmpty) {
        // 获取所有分组
        groups = await api.getScoreClassGroupList();
      }

      // 按权重倒序，取前三
      groups.sort((a, b) => b.weight.compareTo(a.weight));
      final top3 = groups.take(3).toList();

      setState(() {
        _allGroups = groups;
        _selectedGroups = top3;
        _orderByKey = top3.isNotEmpty ? top3[0].id.toString() : '-1';
        _isLoading = false;
      });

      // 加载数据
      await _loadScoreData();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 加载积分数据
  Future<void> _loadScoreData() async {
    if (_selectedGroups.isEmpty) {
      setState(() => _rawData = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = EmployeeScoreApi();
      final data = await api.getScoreGiveLogInfo(
        deptIds: _selectedDeptId != null ? [_selectedDeptId!] : null,
        groupIds: _selectedGroups.map((g) => g.id).toList(),
      );

      setState(() {
        _rawData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── 计算排行 ──────────────────────────────────────────────────

  /// 根据当前选中分组和排序，计算完整排行
  List<EmployeeScoreRankingItem> get _computedRankings {
    final orderByGroupId = int.tryParse(_orderByKey) ?? -1;
    final isDesc = _orderBySort == 'desc';

    // 收集每个用户的分组得分
    final userMap = <int, _UserScoreEntry>{};
    for (final item in _rawData) {
      final entry = userMap.putIfAbsent(
        item.userIdent,
        () => _UserScoreEntry(
          ident: item.userIdent,
          name: item.name,
          number: item.number,
        ),
      );
      entry.scores[item.group] = item.totalScore;
    }

    // 计算当前分组下的排序
    final entries = userMap.values.toList();
    entries.sort((a, b) {
      final sa = a.scores[orderByGroupId] ?? 0;
      final sb = b.scores[orderByGroupId] ?? 0;
      int cmp = isDesc ? sb.compareTo(sa) : sa.compareTo(sb);
      if (cmp != 0) return cmp;
      // 分值相同按姓名排序
      return a.name.compareTo(b.name);
    });

    // 分配排名（并列处理）
    final result = <EmployeeScoreRankingItem>[];
    int rank = 1;
    int? prevScore;
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final score = e.scores[orderByGroupId] ?? 0;
      if (i > 0 && score != prevScore) {
        rank = i + 1;
      }
      result.add(EmployeeScoreRankingItem(
        rank: rank,
        ident: e.ident,
        name: e.name,
        number: e.number,
        score: score,
      ));
      prevScore = score;
    }

    return result;
  }

  /// 获取前三排行
  List<EmployeeScoreRankingItem> get _topRankings =>
      _computedRankings.take(3).toList();

  /// 获取后三排行
  List<EmployeeScoreRankingItem> get _bottomRankings {
    final all = _computedRankings;
    if (all.length <= 3) return [];
    return all.reversed.take(3).toList().reversed.toList();
  }

  /// 当前用户排行项
  EmployeeScoreRankingItem? get _currentUserRanking {
    final currentIdent = _currentUserIdent;
    if (currentIdent == 0) return null;
    final all = _computedRankings;
    try {
      return all.firstWhere((r) => r.ident == currentIdent);
    } catch (_) {
      return null;
    }
  }

  /// 判断当前用户是否已包含在前三或后三中
  bool get _currentUserInTop3 =>
      _currentUserRanking != null &&
      _topRankings.any((r) => r.ident == _currentUserRanking!.ident);

  bool get _currentUserInBottom3 =>
      _currentUserRanking != null &&
      _bottomRankings.any((r) => r.ident == _currentUserRanking!.ident);

  // ── UI 渲染 ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
        middle: const Text('职员得分情况'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 部门选择
            _buildDeptSelector(),

            // 切换控件行
            _buildControlBar(),

            // 切换分组按钮
            _buildSwitchGroupButton(),

            // 数据区域
            Expanded(
              child: _buildDataArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptSelector() {
    return GestureDetector(
      onTap: _showDeptPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedDeptId != null ? '部门 $_selectedDeptId' : '全部',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5586F6)),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: Color(0xFF5586F6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // 全部展开 / 仅显示前三后三 切换
          Expanded(
            child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: _filterRedBlack,
              children: const {
                false: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('全部展开', style: TextStyle(fontSize: 13)),
                ),
                true: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('仅显示前三后三', style: TextStyle(fontSize: 13)),
                ),
              },
              onValueChanged: (v) {
                if (v == true && _computedRankings.length < 6) {
                  _showToast('当前数据不足 6 条，无法显示前三后三');
                  return;
                }
                setState(() => _filterRedBlack = v ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchGroupButton() {
    return GestureDetector(
      onTap: _showGroupSelector,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '切换分组',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(width: 4),
            const Text('⋮', style: TextStyle(fontSize: 13, color: Color(0xFFB4B4B4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataArea() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMsg!, style: AppText.caption),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: _loadInitialData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_rawData.isEmpty || _selectedGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.chart_bar_square,
                color: AppColors.textTertiary, size: 64),
            const SizedBox(height: 12),
            Text('暂无得分数据', style: AppText.caption),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 表头
        _buildTableHeader(),
        // 数据
        Expanded(
          child: _buildTableBody(),
        ),
      ],
    );
  }

  /// 表头行
  Widget _buildTableHeader() {
    final sortedGroups = List<DepartmentEmployeeScoreClassGroup>.from(_selectedGroups)
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          // 姓名列
          Container(
            width: 100,
            padding: const EdgeInsets.only(left: 8),
            child: const Text(
              '姓名(工号)',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500),
            ),
          ),
          // 分组得分列
          ...sortedGroups.map((g) {
            final isActive = _orderByKey == g.id.toString();
            return Expanded(
              child: GestureDetector(
                onTap: () => _toggleSort(g.id),
                child: Container(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          g.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? const Color(0xFF1451DC) : const Color(0xFF999999),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_orderByKey != '-1')
                        Icon(
                          isActive
                              ? (_orderBySort == 'desc'
                                  ? CupertinoIcons.arrow_down
                                  : CupertinoIcons.arrow_up)
                              : CupertinoIcons.arrow_up,
                          size: 12,
                          color: isActive
                              ? const Color(0xFF1451DC)
                              : const Color(0xFFCCCCCC),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 表格体
  Widget _buildTableBody() {
    final all = _computedRankings;
    final top = _topRankings;
    final bottom = _bottomRankings;
    final current = _currentUserRanking;

    if (_filterRedBlack && all.length >= 6) {
      // 仅显示前三后三模式
      return _buildCompactTable(top, bottom, current);
    } else {
      // 全部展开模式
      return _buildFullTable(all, current);
    }
  }

  /// 全部展开表格
  Widget _buildFullTable(
    List<EmployeeScoreRankingItem> all,
    EmployeeScoreRankingItem? current,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: all.length,
      itemBuilder: (ctx, i) {
        final item = all[i];
        final isCurrentUser = item.ident == _currentUserIdent;
        return _buildTableRow(item, isCurrentUser: isCurrentUser, isTop3: i < 3);
      },
    );
  }

  /// 前三+当前用户+后三表格
  Widget _buildCompactTable(
    List<EmployeeScoreRankingItem> top,
    List<EmployeeScoreRankingItem> bottom,
    EmployeeScoreRankingItem? current,
  ) {
    final rows = <Widget>[];

    // 前三
    for (final item in top) {
      rows.add(_buildTableRow(item, isCurrentUser: item.ident == _currentUserIdent, isTop3: true));
    }

    // 中间分隔（仅当有当前用户且不在前三后三时）
    final showMiddle = current != null && !_currentUserInTop3 && !_currentUserInBottom3;
    if (showMiddle) {
      rows.add(_buildSeparator());
      rows.add(_buildTableRow(current, isCurrentUser: true, isTop3: false, isCurrentUserRow: true));
    }

    // 后三
    for (final item in bottom) {
      rows.add(_buildTableRow(item, isCurrentUser: item.ident == _currentUserIdent, isTop3: false));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: rows,
    );
  }

  Widget _buildSeparator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      alignment: Alignment.center,
      child: const Text(
        '⋮',
        style: TextStyle(color: Color(0xFFC5C5C5), fontSize: 14),
      ),
    );
  }

  /// 单行数据
  Widget _buildTableRow(
    EmployeeScoreRankingItem item, {
    required bool isCurrentUser,
    required bool isTop3,
    bool isCurrentUserRow = false,
  }) {
    final sortedGroups = List<DepartmentEmployeeScoreClassGroup>.from(_selectedGroups)
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrentUserRow
            ? const Color(0xFFE3F2FD)
            : (isTop3 ? const Color(0xFFFFF8E1) : null),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 姓名列
          SizedBox(
            width: 100,
            child: Row(
              children: [
                // 排名徽章
                _buildRankBadge(item.rank, isTop3: isTop3),
                const SizedBox(width: 6),
                // 姓名+工号
                Flexible(
                  child: Text(
                    '${item.name}(${item.number})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentUser ? const Color(0xFF1451DC) : CupertinoColors.label.darkColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // 分组得分列
          ...sortedGroups.map((g) {
            int score = 0;
            try {
              final raw = _rawData.firstWhere(
                (r) => r.userIdent == item.ident && r.group == g.id,
              );
              score = raw.totalScore;
            } catch (_) {}
            return Expanded(
              child: Text(
                score > 0 ? score.toString() : '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  color: score > 0 ? CupertinoColors.label.darkColor : AppColors.textTertiary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 排名徽章
  Widget _buildRankBadge(int rank, {required bool isTop3}) {
    Color color;
    String text;

    final lastRanks = _computeLastRanks();
    if (rank >= 1 && rank <= 3) {
      final colors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
      color = colors[rank - 1];
      text = '';
    } else if (lastRanks.contains(rank)) {
      color = const Color(0xFF8E8E93);
      text = '';
    } else {
      color = CupertinoColors.systemGrey4;
      text = rank.toString();
    }

    if (text.isNotEmpty) {
      return SizedBox(
        width: 24,
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: _RankMedalText(rank: rank, color: color),
      ),
    );
  }

  List<int> _computeLastRanks() {
    final all = _computedRankings;
    if (all.isEmpty) return [];
    final maxRank = all.map((r) => r.rank).reduce((a, b) => a > b ? a : b);
    return [maxRank - 2, maxRank - 1, maxRank].where((r) => r > 0).toList();
  }

  // ── 排序 ──────────────────────────────────────────────────────

  void _toggleSort(int groupId) {
    setState(() {
      if (_orderByKey == groupId.toString()) {
        _orderBySort = _orderBySort == 'desc' ? 'asc' : 'desc';
      } else {
        _orderByKey = groupId.toString();
        _orderBySort = 'desc';
      }
    });
  }

  // ── 分组选择器 ────────────────────────────────────────────────

  void _showGroupSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _GroupSelectorSheet(
        allGroups: _allGroups,
        selectedGroups: _selectedGroups,
        onConfirm: (groups) {
          if (groups.isEmpty) {
            _showToast('请选择工分分组');
            return;
          }
          setState(() {
            _selectedGroups = groups;
            _orderByKey = groups.isNotEmpty ? groups[0].id.toString() : '-1';
            _orderBySort = 'desc';
          });
          _loadScoreData();
        },
      ),
    );
  }

  // ── 部门选择器 ────────────────────────────────────────────────

  void _showDeptPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('选择部门'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedDeptId = null);
              _loadScoreData();
            },
            child: const Text('全部'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
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
}

/// 用户得分条目（内部用）
class _UserScoreEntry {
  final int ident;
  final String name;
  final String number;
  final Map<int, int> scores = {};

  _UserScoreEntry({required this.ident, required this.name, required this.number});
}

/// 排名徽章文字（Medal emoji 等效）
class _RankMedalText extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankMedalText({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (rank) {
      case 1:
        label = '🥇';
        break;
      case 2:
        label = '🥈';
        break;
      case 3:
        label = '🥉';
        break;
      default:
        return Text(
          rank.toString(),
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
        );
    }
    return Text(label, style: const TextStyle(fontSize: 14));
  }
}

/// 分组选择器底部弹窗
class _GroupSelectorSheet extends StatefulWidget {
  final List<DepartmentEmployeeScoreClassGroup> allGroups;
  final List<DepartmentEmployeeScoreClassGroup> selectedGroups;
  final ValueChanged<List<DepartmentEmployeeScoreClassGroup>> onConfirm;

  const _GroupSelectorSheet({
    required this.allGroups,
    required this.selectedGroups,
    required this.onConfirm,
  });

  @override
  State<_GroupSelectorSheet> createState() => _GroupSelectorSheetState();
}

class _GroupSelectorSheetState extends State<_GroupSelectorSheet> {
  late List<int> _selectedIds;
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedGroups.map((g) => g.id).toList();
  }

  List<DepartmentEmployeeScoreClassGroup> get _filteredGroups {
    final sorted = List<DepartmentEmployeeScoreClassGroup>.from(widget.allGroups)
      ..sort((a, b) => b.weight.compareTo(a.weight));
    if (_searchText.isEmpty) return sorted;
    return sorted.where((g) => g.name.toLowerCase().contains(_searchText.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGroups;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '请选择3个显示内容',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      size: 22, color: Color(0xFF0575FF)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: '点击输入工分分组名称',
              onChanged: (v) => setState(() => _searchText = v),
            ),
          ),
          // 列表
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('无数据', style: TextStyle(color: AppColors.textTertiary)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final g = filtered[i];
                      final selected = _selectedIds.contains(g.id);
                      return GestureDetector(
                        onTap: () => _toggleGroup(g.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: CupertinoColors.systemGrey5,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: selected
                                        ? CupertinoColors.label.darkColor
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0575FF),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.checkmark,
                                    size: 14,
                                    color: CupertinoColors.white,
                                  ),
                                )
                              else
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFB9B9B9)),
                                    borderRadius: BorderRadius.circular(3),
                                    color: const Color(0xFFF5F5F5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // 确认按钮
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {
                  if (_selectedIds.isEmpty) {
                    _showToast('请选择工分分组');
                    return;
                  }
                  final groups = widget.allGroups
                      .where((g) => _selectedIds.contains(g.id))
                      .toList()
                    ..sort((a, b) => b.weight.compareTo(a.weight));
                  Navigator.pop(context);
                  widget.onConfirm(groups);
                },
                child: const Text('确认', style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleGroup(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 3) {
          _showToast('工分分组最多可选择 3 个');
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(
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
}
