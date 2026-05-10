import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/usci_api.dart';
import '../../theme/app_theme.dart';

/// 发票助手 - 证照查询页面
/// 对应 PWA /pages/path-d/invoice-assistant/license-inquiry.tsx
class LicenseInquiryPage extends ConsumerStatefulWidget {
  final int? preselectedUsciId;

  const LicenseInquiryPage({super.key, this.preselectedUsciId});

  @override
  ConsumerState<LicenseInquiryPage> createState() => _LicenseInquiryPageState();
}

class _LicenseInquiryPageState extends ConsumerState<LicenseInquiryPage> {
  final UsciApi _api = UsciApi();

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
        _usciList = list.where((u) => u.isAllowViewLicence).toList();
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
    try {
      final list = await _api.detail([usci.id]);
      if (list.isNotEmpty) {
        setState(() => _selectedUsci = list.first);
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _showImageViewer(String imageUrl) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ImageViewerPage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('证照查看'),
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
                        ? _buildLicenseContent()
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

  Widget _buildLicenseContent() {
    final usci = _selectedUsci!;
    final photos = usci.identificationPhoto ?? [];

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
              color: const Color(0xFF34C759).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.2)),
            ),
            child: Text(
              usci.name,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF34C759),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 证照照片
          if (photos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  Icon(CupertinoIcons.photo, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text('暂无证件照', style: AppText.caption),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('证照照片（${photos.length}张）',
                        style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () => _showImageViewer(photos[i]),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            color: CupertinoColors.systemGrey6,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: photos[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(CupertinoIcons.photo,
                                  color: CupertinoColors.systemGrey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(20),
          onPressed: _showUsciPicker,
          child: const Text('搜索单位', style: TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

/// 图片查看器（全屏）
class _ImageViewerPage extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerPage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.8),
        middle: const Text('查看大图',
            style: TextStyle(color: CupertinoColors.white)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
            errorWidget: (_, __, ___) => const Icon(
              CupertinoIcons.photo,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
    );
  }
}
