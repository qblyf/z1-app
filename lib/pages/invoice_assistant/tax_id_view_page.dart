import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api/invoice_assistant_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 发票助手 - 税号查看页
class TaxIdViewPage extends ConsumerStatefulWidget {
  final int? usciId;

  const TaxIdViewPage({super.key, this.usciId});

  @override
  ConsumerState<TaxIdViewPage> createState() => _TaxIdViewPageState();
}

class _TaxIdViewPageState extends ConsumerState<TaxIdViewPage> {
  final InvoiceAssistantApi _api = InvoiceAssistantApi();

  List<UsciItem> _usciList = [];
  int? _selectedId;
  UsciDetail? _detail;
  bool _isLoadingList = true;
  bool _isLoadingDetail = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.usciId;
    _loadUsciList();
  }

  Future<void> _loadUsciList() async {
    try {
      final list = await _api.getUsciList();
      if (mounted) {
        setState(() {
          _usciList = list;
          _isLoadingList = false;
        });
        // 如果有预选ID，直接加载详情
        if (_selectedId != null) {
          _loadDetail(_selectedId!);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _loadDetail(int id) async {
    setState(() {
      _isLoadingDetail = true;
      _hasError = false;
    });
    try {
      final detail = await _api.getUsciDetail(id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _showUsciPicker() async {
    if (_usciList.isEmpty) return;

    int? tempSelected;
    final initialIndex = _usciList.indexWhere((e) => e.id == _selectedId);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
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
                  child: const Text('确认'),
                  onPressed: () {
                    if (tempSelected != null) {
                      Navigator.pop(ctx);
                      _selectUsci(tempSelected!);
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: initialIndex >= 0 ? initialIndex : 0,
                ),
                onSelectedItemChanged: (index) {
                  tempSelected = _usciList[index].id;
                },
                children: _usciList.map((e) {
                  return Center(
                    child: Text(
                      e.name ?? '主体${e.id}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectUsci(int id) {
    setState(() => _selectedId = id);
    _loadDetail(id);
  }

  void _copyToClipboard() {
    if (_detail == null) return;
    final text = '主体名称: ${_detail!.name ?? '-'}\n'
        '单位税号: ${_detail!.taxID ?? '-'}\n'
        '单位地址: ${_detail!.address ?? '-'}\n'
        '单位电话: ${_detail!.phone ?? '-'}\n'
        '银行账号: ${_detail!.bankAccountNumber ?? '-'}\n'
        '开户银行: ${_detail!.openingBank ?? '-'}';
    Clipboard.setData(ClipboardData(text: text));
    _showToast('复制成功');
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('税号查看'),
      ),
      child: SafeArea(
        child: _isLoadingList && _detail == null
            ? const Center(child: CupertinoActivityIndicator())
            : _detail == null && !_isLoadingDetail
                ? _buildEmptyState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            '请选择公司主体',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: _showUsciPicker,
            child: const Text('选择主体'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主体名称
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1677FF), Color(0xFF5E5CE6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.building_2_fill,
                          color: CupertinoColors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d.name ?? '-',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // 税号信息卡片
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('单位税号', d.taxID ?? '-'),
                      _buildDivider(),
                      _buildInfoRow('单位地址', d.address ?? '-'),
                      _buildDivider(),
                      _buildInfoRow('单位电话', d.phone ?? '-'),
                      _buildDivider(),
                      _buildInfoRow('银行账号', d.bankAccountNumber ?? '-'),
                      _buildDivider(),
                      _buildInfoRow('开户银行', d.openingBank ?? '-', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // 二维码
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.card,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: 'taxid:${d.taxID ?? ''}',
                          version: QrVersions.auto,
                          size: 176,
                          backgroundColor: CupertinoColors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF063E87),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF063E87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '扫码查看税号',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 底部工具栏
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  onPressed: _showUsciPicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.search, size: 18, color: CupertinoColors.activeBlue),
                      const SizedBox(width: 6),
                      Text(
                        '搜索单位',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.activeBlue.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: _detail != null
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
                  onPressed: _detail != null ? _copyToClipboard : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_on_clipboard, size: 18, color: CupertinoColors.white),
                      SizedBox(width: 6),
                      Text('一键复制', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      color: CupertinoColors.systemGrey5.resolveFrom(context),
    );
  }
}
