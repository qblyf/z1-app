import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api/usci_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 发票助手 - 税号查询页面
/// 对应 PWA /pages/path-d/invoice-assistant/tax-id-number-query.tsx
class TaxIdQueryPage extends ConsumerStatefulWidget {
  final int? preselectedUsciId;

  const TaxIdQueryPage({super.key, this.preselectedUsciId});

  @override
  ConsumerState<TaxIdQueryPage> createState() => _TaxIdQueryPageState();
}

class _TaxIdQueryPageState extends ConsumerState<TaxIdQueryPage> {
  final UsciApi _api = UsciApi();

  // 主体列表
  List<UsciInfo> _usciList = [];
  UsciInfo? _selectedUsci;
  bool _isLoading = false;
  bool _isListLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsciList();
    if (widget.preselectedUsciId != null) {
      _loadPreselected();
    }
  }

  Future<void> _loadUsciList() async {
    setState(() => _isListLoading = true);
    try {
      final list = await _api.list(limit: 100);
      setState(() {
        _usciList = list.where((u) => u.isAllowViewInvoice).toList();
        _isListLoading = false;
      });
    } catch (_) {
      setState(() => _isListLoading = false);
    }
  }

  Future<void> _loadPreselected() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.detail([widget.preselectedUsciId!]);
      if (list.isNotEmpty) {
        setState(() => _selectedUsci = list.first);
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectUsci(UsciInfo usci) async {
    setState(() {
      _isLoading = true;
      _selectedUsci = usci;
    });
    setState(() => _isLoading = false);
  }

  void _showUsciPicker() {
    if (_usciList.isEmpty) return;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择公司主体', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: Color(0xFFC7C7CC), size: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _usciList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final usci = _usciList[i];
                  final isSelected = _selectedUsci?.id == usci.id;
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onPressed: () {
                      _selectUsci(usci);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            usci.name,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1C1C1E),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(CupertinoIcons.checkmark_alt,
                              color: Color(0xFF007AFF), size: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() {
    if (_selectedUsci == null) return;
    final usci = _selectedUsci!;
    final text = '主体名称: ${usci.name}\n'
        '单位税号: ${usci.taxID ?? ''}\n'
        '单位地址: ${usci.address ?? ''}\n'
        '单位电话: ${usci.phone ?? ''}\n'
        '银行账号: ${usci.bankAccountNumber ?? ''}\n'
        '开户银行: ${usci.openingBank ?? ''}';
    Clipboard.setData(ClipboardData(text: text));
    _showToast('复制成功');
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String get _shareUrl {
    final baseUrl = 'https://z1-fun.zsqk.com.cn'; // APP base URL
    final path = '/tax-id-query';
    final id = _selectedUsci?.id;
    if (id == null) return baseUrl;
    return '$baseUrl$path?usciID=$id';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('税号查看'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isListLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _selectedUsci != null
                        ? _buildUsciDetail()
                        : _buildEmptyState(),
                  ),
                  _buildBottomToolbar(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.doc_text, size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('点击下方搜索单位...', style: AppText.body),
        ],
      ),
    );
  }

  Widget _buildUsciDetail() {
    final usci = _selectedUsci!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主体名称
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2)),
            ),
            child: Text(
              usci.name,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007AFF),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 信息卡片
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _DetailRow('单位税号', usci.taxID ?? '-'),
                _DetailRow('单位地址', usci.address ?? '-', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _DetailRow('单位电话', usci.phone ?? '-'),
                _DetailRow('银行账号', usci.bankAccountNumber ?? '-', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _DetailRow('开户银行', usci.openingBank ?? '-', isLast: true),
              ],
            ),
          ),

          // QR码区域
          if (widget.preselectedUsciId == null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Text('分享税号信息', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.md),
                  QrImageView(
                    data: _shareUrl,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: CupertinoColors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1C1C1E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('扫码查看税号信息', style: AppText.caption),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final hasData = _selectedUsci != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(20),
              onPressed: _showUsciPicker,
              child: const Text('搜索单位', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: hasData ? const Color(0xFF007AFF) : CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(20),
              onPressed: hasData ? _copyToClipboard : null,
              child: const Text('一键复制', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
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
              style: AppText.body,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
