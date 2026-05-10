import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_inspection_api.dart';
import '../../models/store_inspection.dart';
import '../../theme/app_theme.dart';

/// 巡店/自检 - 开始巡店页面
/// 对应 PWA /pages/path-d/store-inspection/ready.tsx
/// 选择门店、巡店类型、项目后开始巡店
class StoreInspectionReadyPage extends ConsumerStatefulWidget {
  const StoreInspectionReadyPage({super.key});

  @override
  ConsumerState<StoreInspectionReadyPage> createState() => _StoreInspectionReadyPageState();
}

class _StoreInspectionReadyPageState extends ConsumerState<StoreInspectionReadyPage> {
  final StoreInspectionApi _api = StoreInspectionApi();

  // 选中的门店
  int? _selectedDeptID;
  String? _selectedDeptName;

  // 巡店类型
  StoreInspectionType? _selectedType;

  // 巡店项目
  int? _selectedInspectionID;
  String? _selectedInspectionName;

  bool _isSubmitting = false;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('开始巡店'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 巡店类型选择
                    _buildSectionTitle('巡店类型'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTypeSelector(),
                    const SizedBox(height: AppSpacing.lg),

                    // 选择门店
                    _buildSectionTitle('选择门店'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildDeptSelector(),
                    const SizedBox(height: AppSpacing.lg),

                    // 巡店项目（如果类型已选）
                    if (_selectedType != null) ...[
                      _buildSectionTitle('巡店项目'),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInspectionSelector(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_circle,
                                color: Color(0xFFFF9500), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMsg!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFFE65100))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 底部开始按钮
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: _canSubmit ? _submit : null,
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('开始巡店', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedType != null &&
      _selectedDeptID != null &&
      _selectedInspectionID != null &&
      !_isSubmitting;

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: StoreInspectionType.values.map((type) {
        final isSelected = _selectedType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
                _selectedInspectionID = null;
                _selectedInspectionName = null;
                _errorMsg = null;
              });
            },
            child: Container(
              margin: EdgeInsets.only(
                  right: type == StoreInspectionType.shopInspection ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0A84FF)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeptSelector() {
    return GestureDetector(
      onTap: _showDeptPicker,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.building_2_fill,
                color: Color(0xFF0A84FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDeptName ?? '请选择门店',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedDeptName != null
                      ? const Color(0xFF333333)
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionSelector() {
    return GestureDetector(
      onTap: _showInspectionPicker,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.doc_text,
                color: Color(0xFF5856D6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedInspectionName ?? '请选择巡店项目',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedInspectionName != null
                      ? const Color(0xFF333333)
                      : AppColors.textTertiary,
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  void _showDeptPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _DeptPickerSheet(
        onSelected: (id, name) {
          setState(() {
            _selectedDeptID = id;
            _selectedDeptName = name;
            _errorMsg = null;
          });
        },
      ),
    );
  }

  void _showInspectionPicker() {
    if (_selectedType == null) return;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _InspectionPickerSheet(
        type: _selectedType!,
        onSelected: (id, name) {
          setState(() {
            _selectedInspectionID = id;
            _selectedInspectionName = name;
            _errorMsg = null;
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _errorMsg = null;
    });
    try {
      final logID = await _api.addLog(
        departmentID: _selectedDeptID!,
        storeInspectionID: _selectedInspectionID!,
      );
      if (mounted) {
        context.pushReplacement('/store-inspection/info/$logID');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = '创建失败：$e';
        });
      }
    }
  }
}

/// 门店选择器
class _DeptPickerSheet extends StatefulWidget {
  final void Function(int id, String name) onSelected;
  const _DeptPickerSheet({required this.onSelected});

  @override
  State<_DeptPickerSheet> createState() => _DeptPickerSheetState();
}

class _DeptPickerSheetState extends State<_DeptPickerSheet> {
  List<_DeptItem> _depts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDepts();
  }

  Future<void> _loadDepts() async {
    try {
      // 使用通用的部门列表API
      final api = StoreInspectionApi();
      final list = await api.logList(limit: 300);
      // 从记录中提取不重复的部门
      final seen = <int>{};
      final depts = <_DeptItem>[];
      for (final log in list) {
        if (!seen.contains(log.departmentID) && log.departmentID > 0) {
          seen.add(log.departmentID);
          depts.add(_DeptItem(log.departmentID, log.departmentName ?? '部门${log.departmentID}'));
        }
      }
      if (mounted) {
        setState(() {
          _depts = depts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择门店', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFFCCCCCC)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _depts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.building_2_fill,
                                size: 48, color: Color(0xFFDDDDDD)),
                            const SizedBox(height: 8),
                            Text('暂无可选门店', style: AppText.caption),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _depts.length,
                        itemBuilder: (_, i) {
                          final dept = _depts[i];
                          return CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onPressed: () {
                              widget.onSelected(dept.id, dept.name);
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.building_2_fill,
                                    size: 18, color: Color(0xFF0A84FF)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(dept.name,
                                      style: const TextStyle(
                                          fontSize: 15, color: Color(0xFF333333))),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 巡店项目选择器
class _InspectionPickerSheet extends StatefulWidget {
  final StoreInspectionType type;
  final void Function(int id, String name) onSelected;
  const _InspectionPickerSheet({required this.type, required this.onSelected});

  @override
  State<_InspectionPickerSheet> createState() => _InspectionPickerSheetState();
}

class _InspectionPickerSheetState extends State<_InspectionPickerSheet> {
  List<_InspectionItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      // 通过日志列表获取所有可用的巡店项目
      final api = StoreInspectionApi();
      final list = await api.logList(
        storeInspectionType: widget.type.value,
        limit: 300,
      );
      final seen = <int>{};
      final items = <_InspectionItem>[];
      for (final log in list) {
        if (!seen.contains(log.inspectionID) && log.inspectionID > 0) {
          seen.add(log.inspectionID);
          items.add(_InspectionItem(
              log.inspectionID, log.inspectionName ?? '项目${log.inspectionID}'));
        }
      }
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择巡店项目', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill,
                      color: Color(0xFFCCCCCC)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.doc_text,
                                size: 48, color: Color(0xFFDDDDDD)),
                            const SizedBox(height: 8),
                            Text('暂无可选项目', style: AppText.caption),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onPressed: () {
                              widget.onSelected(item.id, item.name);
                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.doc_text,
                                    size: 18, color: Color(0xFF5856D6)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(item.name,
                                      style: const TextStyle(
                                          fontSize: 15, color: Color(0xFF333333))),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DeptItem {
  final int id;
  final String name;
  _DeptItem(this.id, this.name);
}

class _InspectionItem {
  final int id;
  final String name;
  _InspectionItem(this.id, this.name);
}
