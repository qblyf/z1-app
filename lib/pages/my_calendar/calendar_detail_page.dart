import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../api/calendar_api.dart';
import '../../api/label_api.dart';
import '../../config/api_config.dart';
import '../../models/calendar.dart';
import '../../services/token_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 行事历详情页（完整版）
/// 对应 PWA /components/Calendar/Info.tsx
/// 支持：基础信息展示、任务标签、自评提交、验收/拒绝
class CalendarDetailPage extends ConsumerStatefulWidget {
  final String id;

  const CalendarDetailPage({super.key, required this.id});

  @override
  ConsumerState<CalendarDetailPage> createState() => _CalendarDetailPageState();
}

class _CalendarDetailPageState extends ConsumerState<CalendarDetailPage> {
  final CalendarApi _api = CalendarApi();
  final LabelApi _labelApi = LabelApi();
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();
  final ImagePicker _picker = ImagePicker();

  CalendarDetail? _detail;
  bool _isLoading = true;
  String? _error;
  List<String> _labelNames = [];

  // 自评编辑
  int _selfScore = 5;
  String _selfEvaluationText = '';
  List<String> _selfAccessories = []; // 已上传的附件
  List<String> _pendingLocalPaths = []; // 待上传的本地图片路径
  bool _isUploading = false;
  bool _isSubmitting = false;

  // 验收
  int _checkScore = 5;
  String _checkRemarks = '';

  // 图片预览
  bool _imagePreviewVisible = false;
  String? _previewImageUrl;

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
      // 尝试用数字ID获取详情
      final taskLogId = int.tryParse(widget.id);
      CalendarDetail? data;
      if (taskLogId != null && taskLogId > 0) {
        try {
          data = await _api.getCalendarDetail(taskLogId);
        } catch (_) {
          // 如果失败，尝试基础详情
        }
      }

      // 如果 CalendarDetail 获取失败，使用基础信息
      if (data == null) {
        final basic = await _api.getDetail(widget.id);
        // 转换为基础 CalendarDetail 格式
        data = CalendarDetail(
          name: basic.title,
          taskLogStatus: _statusToStr(basic.status),
          labelIDs: [],
          introduction: '',
          description: basic.description ?? '',
          duration: 0,
          startAt: basic.startTime,
          endAt: basic.endTime,
          responsibleEmployee: basic.assignee,
          taskLogID: int.tryParse(basic.taskLogIdent) ?? int.tryParse(basic.id) ?? 0,
          accessoriesUrls: basic.attachments?.map((a) => a.url).toList() ?? [],
        );
      }

      // data 在此处保证非空，提取局部变量以避免 setState 闭包内的空安全警告
      final detail = data;

      // 加载标签名称
      final labelNames = await _loadLabelNames(detail.labelIDs);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _labelNames = labelNames;
        _isLoading = false;
        // 预填充自评数据
        _selfAccessories = List<String>.from(detail.selfEvaluationAccessories);
        _selfScore = detail.taskScore ?? 5;
        _selfEvaluationText = detail.selfEvaluationContent ?? '';
        _checkScore = detail.checkScore ?? 5;
        _checkRemarks = detail.lastCheckRemarks ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _statusToStr(int status) {
    switch (status) {
      case 1: return '待执行';
      case 2: return '进行中';
      case 3: return '已完成';
      case 4: return '已取消';
      case 5: return '已过期';
      default: return '未知';
    }
  }

  Future<List<String>> _loadLabelNames(List<int> labelIds) async {
    if (labelIds.isEmpty) return [];
    try {
      final labels = await _labelApi.listByIds(labelIds);
      return labels.map((l) => l.name).toList();
    } catch (_) {
      return labelIds.map((id) => '标签#$id').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('行事历详情'),
        ),
        child: const LoadingWidget(message: '加载中...'),
      );
    }

    if (_error != null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('行事历详情'),
        ),
        child: AppErrorWidget(message: _error!, onRetry: _loadData),
      );
    }

    if (_detail == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('行事历详情'),
        ),
        child: const Center(child: Text('未找到行事历')),
      );
    }

    final detail = _detail!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('行事历详情'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: () => _showActionSheet(context),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === 任务基本信息 ===
                _buildHeader(detail),
                const SizedBox(height: 12),

                // === 基本信息区块 ===
                _buildSection('基本信息', [
                  if (detail.labelIDs.isNotEmpty)
                    _buildLabelRow(detail),
                  if (detail.giveTaskWeight != null)
                    _buildInfoRow('任务权重', '${detail.giveTaskWeight}'),
                  if (detail.taskLogStatus == '已完成' && detail.lastScore != null)
                    _buildInfoRow('任务得分', '${detail.lastScore}分'),
                  if (detail.categoryName != null)
                    _buildInfoRow('所属项目', detail.categoryName!),
                  _buildInfoRow('开始时间', _formatDateTime(detail.startAt)),
                  if (detail.duration > 0)
                    _buildInfoRow('任务时长', detail.formattedDuration),
                  _buildInfoRow('责任人', '职员 #${detail.responsibleEmployee}'),
                  _buildInfoRow('需要自评', detail.isNeedSelfEvaluation ? '是' : '否'),
                  _buildInfoRow('验收类型', detail.allowCheckTypeLabel),
                ]),
                const SizedBox(height: 12),

                // === 任务说明 ===
                if (detail.introduction.isNotEmpty) ...[
                  _buildSection('任务简介', [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(detail.introduction, style: AppText.body),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],

                if (detail.description.isNotEmpty) ...[
                  _buildSection('详细说明', [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(detail.description, style: AppText.body),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],

                // === 任务附件 ===
                if (detail.accessoriesUrls.isNotEmpty) ...[
                  _buildSection('任务附件', [
                    _buildAttachmentGrid(detail.accessoriesUrls),
                  ]),
                  const SizedBox(height: 12),
                ],

                // === 自评区域（责任人 + 进行中状态可见）===
                if (detail.taskLogStatus == '进行中') ...[
                  _buildSection('自评', [
                    _buildSelfEvaluationSection(detail),
                  ]),
                  const SizedBox(height: 12),
                ],

                // === 验收区域（待验收 + 当前用户可验收）===
                if (detail.taskLogStatus == '待验收') ...[
                  _buildSection('验收评价', [
                    _buildCheckSection(detail),
                  ]),
                  const SizedBox(height: 12),
                ],

                // === 已完成验收结果 ===
                if (detail.taskLogStatus == '已完成' || detail.taskLogStatus == '未完成') ...[
                  _buildSection('验收结果', [
                    if (detail.lastCheckBy != null)
                      _buildInfoRow('验收人', '职员 #${detail.lastCheckBy}'),
                    if (detail.checkScore != null)
                      _buildInfoRow('验收评分', '${detail.checkScore}分'),
                    if (detail.lastCheckRemarks != null && detail.lastCheckRemarks!.isNotEmpty)
                      _buildInfoRow('验收评论', detail.lastCheckRemarks!),
                    if (detail.lastCheckBy == null && detail.lastCheckRemarks == null)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('暂无验收记录', style: TextStyle(color: CupertinoColors.secondaryLabel)),
                      ),
                  ]),
                  const SizedBox(height: 12),
                ],

                // === 已读人员 ===
                if (detail.readUser.isNotEmpty) ...[
                  _buildSection('已读', [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${detail.readUser.length} 人已读', style: AppText.body),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 80),
              ],
            ),

            // 图片预览
            if (_imagePreviewVisible)
              _buildImagePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CalendarDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(detail.name, style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
              ),
              _buildStatusBadge(detail.taskLogStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case '进行中': color = CupertinoColors.activeOrange; break;
      case '已完成': color = CupertinoColors.activeGreen; break;
      case '待验收': color = const Color(0xFF2D6EC9); break;
      case '未完成': color = CupertinoColors.destructiveRed; break;
      default: color = CupertinoColors.systemGrey;
    }
    return StatusBadge(label: status, color: color);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            )),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelRow(CalendarDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 80,
            child: Text('任务标签', style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            )),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (int i = 0; i < detail.labelIDs.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      i < _labelNames.length ? _labelNames[i] : '标签#${detail.labelIDs[i]}',
                      style: const TextStyle(fontSize: 12, color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentGrid(List<String> urls) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: urls.map((url) {
          return GestureDetector(
            onTap: () => _showImagePreview(url),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(url),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.contains('image') == false && (url.endsWith('.jpg') || url.endsWith('.png') || url.contains('.jpg') || url.contains('.png') || url.contains('jpeg'))) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
      );
    }
    return const Center(child: Icon(CupertinoIcons.doc, color: CupertinoColors.systemGrey));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 自评区域
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSelfEvaluationSection(CalendarDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 满意度评分
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('满意度评分', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _buildStarSelector(_selfScore, (v) => setState(() => _selfScore = v)),
            ],
          ),
        ),

        const Divider(height: 1),

        // 自评文字
        Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoTextField(
            placeholder: detail.isNeedSelfEvaluation ? '请填写自评说明（必填）' : '请填写自评说明（选填）',
            controller: TextEditingController(text: _selfEvaluationText),
            maxLines: 4,
            onChanged: (v) => _selfEvaluationText = v,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // 附件上传
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('相关文件', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
              const SizedBox(height: 8),
              _buildAttachmentUploader(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 提交按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _isSubmitting || _isUploading ? null : () => _submitSelfEvaluation(detail),
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Text(detail.allowCheckType == 'nocheck' ? '完成' : '提交验收'),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 验收区域（待验收状态）
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCheckSection(CalendarDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 验收评分
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('验收评分', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _buildStarSelector(_checkScore, (v) => setState(() => _checkScore = v)),
            ],
          ),
        ),

        const Divider(height: 1),

        // 验收评论
        Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoTextField(
            placeholder: '请填写验收评论（必填）',
            controller: TextEditingController(text: _checkRemarks),
            maxLines: 4,
            onChanged: (v) => _checkRemarks = v,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 通过/拒绝按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  onPressed: _isSubmitting ? null : () => _handleReject(detail),
                  child: const Text('验收拒绝'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _isSubmitting ? null : () => _handleApprove(detail),
                  child: const Text('验收通过'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 附件上传
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAttachmentUploader() {
    final allUrls = [
      ..._selfAccessories,
      ..._pendingLocalPaths,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...allUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              final isLocal = index >= _selfAccessories.length;
              return _buildAttachmentChip(url, isLocal: isLocal);
            }),
            // 添加按钮
            if (allUrls.length < 5)
              GestureDetector(
                onTap: _showAttachmentSource,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
                  ),
                  child: const Icon(CupertinoIcons.camera, color: CupertinoColors.systemGrey),
                ),
              ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              CupertinoActivityIndicator(),
              SizedBox(width: 8),
              Text('上传中...', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentChip(String url, {required bool isLocal}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isLocal
                ? Image.file(File(url), width: 72, height: 72, fit: BoxFit.cover)
                : _buildImageWidget(url),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => _removeAttachment(url, isLocal: isLocal),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0x8A000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark, size: 12, color: CupertinoColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentSource() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: const Text('拍照'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('从相册选择'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;
      setState(() => _pendingLocalPaths.add(image.path));
    } catch (e) {
      if (mounted) _showTip('选择图片失败: $e');
    }
  }

  void _removeAttachment(String url, {required bool isLocal}) {
    setState(() {
      if (isLocal) {
        _pendingLocalPaths.remove(url);
      } else {
        _selfAccessories.remove(url);
      }
    });
  }

  Future<String?> _uploadImage(XFile image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final token = await _tokenService.getToken();
    final resp = await _dio.post(
      '${ApiConfig.baseUrl}upload',
      data: formData,
      options: Options(headers: {'Authorization': token ?? ''}),
    );
    if (resp.data['code'] == 10000 || resp.data['code'] == 0) {
      final url = resp.data['res']?['url'] ?? resp.data['url'] ?? resp.data['res'];
      return url?.toString();
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 自评提交
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _submitSelfEvaluation(CalendarDetail detail) async {
    if (detail.isNeedSelfEvaluation && _selfEvaluationText.trim().isEmpty) {
      _showTip('请填写自评说明');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 上传待上传的附件
      final uploadedUrls = List<String>.from(_selfAccessories);
      for (final localPath in _pendingLocalPaths) {
        final url = await _uploadImage(XFile(localPath));
        if (url != null) uploadedUrls.add(url);
      }

      // 调用自评完成API
      final token = await _tokenService.getToken();
      final resp = await _dio.post(
        '${ApiConfig.baseUrl}task-log/self-evaluation-finished',
        data: {
          'id': detail.taskLogID,
          'taskScore': _selfScore,
          'selfEvaluationContent': _selfEvaluationText,
          'selfEvaluationAccessories': uploadedUrls,
        },
        options: Options(headers: {'Authorization': token ?? ''}),
      );

      if (resp.data['code'] == 10000 || resp.data['code'] == 0 || resp.data['res'] == true) {
        if (mounted) {
          _showTip(detail.allowCheckType == 'nocheck' ? '已完成' : '已提交验收');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) _loadData();
        }
      } else {
        if (mounted) _showTip('提交失败: ${resp.data['message'] ?? '未知错误'}');
      }
    } catch (e) {
      if (mounted) _showTip('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 验收/拒绝
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleApprove(CalendarDetail detail) async {
    if (_checkRemarks.trim().isEmpty) {
      _showTip('请填写验收评论');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _tokenService.getToken();
      final resp = await _dio.post(
        '${ApiConfig.baseUrl}task-log/check',
        data: {
          'id': detail.taskLogID,
          'checkScore': _checkScore,
          'lastCheckRemarks': _checkRemarks,
          'lastCheckResult': true,
        },
        options: Options(headers: {'Authorization': token ?? ''}),
      );

      if (resp.data['code'] == 10000 || resp.data['code'] == 0 || resp.data['res'] == true) {
        if (mounted) {
          _showTip('验收通过');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.pop();
        }
      } else {
        if (mounted) _showTip('验收失败: ${resp.data['message'] ?? '未知错误'}');
      }
    } catch (e) {
      if (mounted) _showTip('验收失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReject(CalendarDetail detail) async {
    if (_checkRemarks.trim().isEmpty) {
      _showTip('请填写拒绝原因');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _tokenService.getToken();
      final resp = await _dio.post(
        '${ApiConfig.baseUrl}task-log/check',
        data: {
          'id': detail.taskLogID,
          'lastCheckRemarks': _checkRemarks,
          'lastCheckResult': false,
        },
        options: Options(headers: {'Authorization': token ?? ''}),
      );

      if (resp.data['code'] == 10000 || resp.data['code'] == 0 || resp.data['res'] == true) {
        if (mounted) {
          _showTip('已拒绝');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.pop();
        }
      } else {
        if (mounted) _showTip('拒绝失败: ${resp.data['message'] ?? '未知错误'}');
      }
    } catch (e) {
      if (mounted) _showTip('拒绝失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 辅助方法
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStarSelector(int value, ValueChanged<int> onChanged) {
    return Row(
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              i < value ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: i < value ? CupertinoColors.systemYellow : CupertinoColors.systemGrey3,
              size: 28,
            ),
          ),
        );
      }),
    );
  }

  void _showImagePreview(String url) {
    setState(() {
      _imagePreviewVisible = true;
      _previewImageUrl = url;
    });
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () => setState(() => _imagePreviewVisible = false),
      child: Container(
        color: CupertinoColors.black.withValues(alpha: 0.85),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: _previewImageUrl != null
                    ? (_previewImageUrl!.startsWith('/')
                        ? Image.file(File(_previewImageUrl!), fit: BoxFit.contain)
                        : Image.network(_previewImageUrl!, fit: BoxFit.contain))
                    : const SizedBox.shrink(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _imagePreviewVisible = false),
                child: const Icon(CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 分享
            },
            child: const Text('分享'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showTip(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(int unix) {
    if (unix == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
