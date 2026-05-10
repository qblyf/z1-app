import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../api/task_log_api.dart';
import '../../config/api_config.dart';
import '../../services/token_service.dart';
import '../../theme/app_theme.dart';

/// 任务日志详情页
/// 对应 PWA /pages/path-d/task-management/task-log-info.tsx
class TaskLogDetailPage extends ConsumerStatefulWidget {
  final int taskLogId;

  const TaskLogDetailPage({super.key, required this.taskLogId});

  @override
  ConsumerState<TaskLogDetailPage> createState() => _TaskLogDetailPageState();
}

class _TaskLogDetailPageState extends ConsumerState<TaskLogDetailPage> {
  final TaskLogApi _api = TaskLogApi();
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  final TokenService _tokenService = TokenService();

  TaskLogDetail? _detail;
  bool _isLoading = true;
  String? _errorMsg;

  // 自评编辑
  int _selfScore = 5;
  String _selfEvaluationText = '';
  List<String> _selfAccessories = []; // 已上传的附件URL
  final List<String> _pendingImages = []; // 待上传的图片路径
  bool _isSubmitting = false;

  // 验收
  int _checkScore = 5;
  String _checkRemarks = '';

  // 图片预览
  bool _imagePreviewVisible = false;
  String? _previewImageUrl;

  // 任务介绍/说明弹窗
  bool _introVisible = false;
  String? _introContent;
  bool _descVisible = false;
  String? _descContent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final detail = await _api.detail(widget.taskLogId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
          if (detail != null) {
            _selfScore = detail.selfScore ?? 5;
            _selfEvaluationText = detail.selfEvaluationContent ?? '';
            _selfAccessories = detail.selfEvaluationAccessories;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  /// 添加图片附件
  Future<void> _addAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null || !mounted) return;

    setState(() => _pendingImages.add(image.path));

    // 上传图片
    try {
      final url = await _uploadImage(image);
      if (mounted) {
        setState(() {
          _selfAccessories.add(url);
          _pendingImages.remove(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingImages.remove(image.path));
        _showToast('上传失败: $e');
      }
    }
  }

  Future<String> _uploadImage(XFile image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path,
          filename: image.name),
    });
    final token = await _tokenService.getToken();
    final resp = await _dio.post(
      '${ApiConfig.baseUrl}upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': token ?? '',
        },
      ),
    );
    final url = resp.data['res']?['url'] as String? ?? resp.data['res']?['path'] as String? ?? '';
    if (url.isEmpty) throw Exception('上传返回路径为空');
    return url;
  }

  /// 提交自评（预保存）
  Future<void> _preSubmitSelfEvaluation() async {
    if (_detail == null || _detail!.isNeedSelfEvaluation && _selfEvaluationText.trim().isEmpty) {
      _showToast('请填写自评内容');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.preSelfEvaluationFinished(
        taskLogId: widget.taskLogId,
        taskScore: _selfScore,
        selfEvaluationContent: _selfEvaluationText.isNotEmpty ? _selfEvaluationText : null,
        selfEvaluationAccessories: _selfAccessories.isNotEmpty ? _selfAccessories : null,
      );
      if (mounted) {
        if (ok) {
          _showToast('保存成功');
          _loadData();
        } else {
          _showToast('保存失败');
        }
      }
    } catch (e) {
      if (mounted) _showToast('保存失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 提交自评（正式提交，变更状态）
  Future<void> _submitSelfEvaluation() async {
    if (_detail == null) return;
    if (_detail!.isNeedSelfEvaluation && _selfEvaluationText.trim().isEmpty) {
      _showToast('请填写自评内容');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.selfEvaluationFinished(
        taskLogId: widget.taskLogId,
        score: _selfScore,
        content: _selfEvaluationText.isNotEmpty ? _selfEvaluationText : null,
        accessories: _selfAccessories.isNotEmpty ? _selfAccessories : null,
      );
      if (mounted) {
        if (ok) {
          _showToast('提交成功');
          _loadData();
        } else {
          _showToast('提交失败');
        }
      }
    } catch (e) {
      if (mounted) _showToast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 验收操作（通过）
  Future<void> _approveTask() async {
    if (_checkRemarks.trim().isEmpty) {
      _showToast('请填写验收备注');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.checkTaskLog(
        taskLogId: widget.taskLogId,
        checkScore: _checkScore,
        lastCheckRemarks: _checkRemarks,
        lastCheckResult: true,
      );
      if (mounted) {
        if (ok) {
          _showToast('验收通过');
          _loadData();
        } else {
          _showToast('验收失败');
        }
      }
    } catch (e) {
      if (mounted) _showToast('验收失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 验收操作（驳回）
  Future<void> _rejectTask() async {
    if (_checkRemarks.trim().isEmpty) {
      _showToast('请填写驳回原因');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await _api.checkTaskLog(
        taskLogId: widget.taskLogId,
        checkScore: _checkScore,
        lastCheckRemarks: _checkRemarks,
        lastCheckResult: false,
      );
      if (mounted) {
        if (ok) {
          _showToast('已驳回');
          _loadData();
        } else {
          _showToast('驳回失败');
        }
      }
    } catch (e) {
      if (mounted) _showToast('驳回失败: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  void _showIntroModal(String? content) {
    setState(() {
      _introContent = content;
      _introVisible = true;
    });
  }

  void _showDescModal(String? content) {
    setState(() {
      _descContent = content;
      _descVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_getTitle()),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: _buildBody(),
    );
  }

  String _getTitle() {
    if (_detail == null) return '任务详情';
    if (_detail!.taskLogStatus == 'unchecked') return '验收任务';
    return '任务详情';
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text('加载失败', style: AppText.caption),
            CupertinoButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }
    final detail = _detail!;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildStatusCard(detail),
                  const SizedBox(height: AppSpacing.md),
                  _buildTaskInfoCard(detail),
                  const SizedBox(height: AppSpacing.md),
                  _buildSelfEvaluationCard(detail),
                  const SizedBox(height: AppSpacing.md),
                  if (detail.lastCheckRemarks != null && detail.lastCheckRemarks!.isNotEmpty)
                    _buildCheckInfoCard(detail),
                  if (detail.lastCheckRemarks != null && detail.lastCheckRemarks!.isNotEmpty)
                    const SizedBox(height: AppSpacing.md),
                  const SizedBox(height: 80), // 底部留白
                ],
              ),
            ),
            _buildBottomActions(detail),
          ],
        ),
        // 任务介绍弹窗
        if (_introVisible)
          _ModalOverlay(
            title: '任务简介',
            content: _introContent ?? '',
            onClose: () => setState(() => _introVisible = false),
          ),
        if (_descVisible)
          _ModalOverlay(
            title: '任务说明',
            content: _descContent ?? '',
            onClose: () => setState(() => _descVisible = false),
          ),
        // 图片预览
        if (_imagePreviewVisible && _previewImageUrl != null)
          _ImagePreviewOverlay(
            url: _previewImageUrl!,
            onClose: () => setState(() => _imagePreviewVisible = false),
          ),
      ],
    );
  }

  Widget _buildStatusCard(TaskLogDetail detail) {
    final status = detail.status;
    final statusColor = status?.color ?? CupertinoColors.systemGrey;
    final statusLabel = status?.label ?? detail.taskLogStatus;
    final isStarted = detail.hasStarted;
    final displayStatus = !isStarted ? '未开始' : statusLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getStatusIcon(detail.taskLogStatus), color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayStatus, style: AppText.subtitle.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                if (detail.employeeName != null)
                  Text(detail.employeeName!, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfoCard(TaskLogDetail detail) {
    return _buildCard([
      _InfoRow('任务名称', detail.name ?? '-'),
      if (detail.taskWeight != null) _InfoRow('权重', '${detail.taskWeight}'),
      if (detail.taskScore != null || detail.lastScore != null)
        _InfoRow('得分', '${detail.lastScore ?? detail.taskScore ?? '-'}'),
      // 简介（可点击查看）
      if (detail.introduction != null && detail.introduction!.isNotEmpty)
        _TappableRow(
          label: '简介',
          value: detail.introduction!,
          onTap: () => _showIntroModal(detail.introduction),
        ),
      // 说明（可点击查看）
      if (detail.description != null && detail.description!.isNotEmpty)
        _TappableRow(
          label: '说明',
          value: detail.description!,
          onTap: () => _showDescModal(detail.description),
        ),
      // 时间
      if (detail.startAt != null || detail.endAt != null)
        _InfoRow(
          '时间',
          [
            if (detail.startAt != null) _formatTs(detail.startAt!),
            if (detail.startAt != null && detail.endAt != null) ' 至 ',
            if (detail.endAt != null) _formatTs(detail.endAt!),
          ].join(),
        ),
      if (detail.allowCheckType != null)
        _InfoRow('验收类型', _allowCheckTypeLabel(detail.allowCheckType!)),
      if (detail.isNeedSelfEvaluation)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('需要自评', style: TextStyle(fontSize: 12, color: Color(0xFFFF9500))),
              ),
            ],
          ),
        ),
    ]);
  }

  /// 自评区域（进行中/未完成状态，且当前用户是责任人）
  Widget _buildSelfEvaluationCard(TaskLogDetail detail) {
    final isDoingOrUnfinished =
        detail.taskLogStatus == 'doing' || detail.taskLogStatus == 'unfinished';
    final alreadySubmitted = detail.selfEvaluationContent != null && detail.selfEvaluationContent!.isNotEmpty;

    // 已完成状态 → 只显示自评内容
    if (detail.isFinished) {
      return _buildCard([
        _SectionHeader('自评内容'),
        _InfoRow('自评得分', '${detail.taskScore ?? '-'} 分'),
        if (detail.selfEvaluationContent != null && detail.selfEvaluationContent!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(detail.selfEvaluationContent!, style: AppText.body),
            ),
          ),
        if (detail.selfEvaluationAccessories.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAttachments(detail.selfEvaluationAccessories),
        ],
      ]);
    }

    // 待验收状态 → 显示提交内容 + 验收评分区域
    if (detail.taskLogStatus == 'unchecked') {
      return Column(
        children: [
          if (detail.selfEvaluationContent != null && detail.selfEvaluationContent!.isNotEmpty)
            _buildCard([
              _SectionHeader('自评内容'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(detail.selfEvaluationContent!, style: AppText.body),
                ),
              ),
              if (detail.selfEvaluationAccessories.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAttachments(detail.selfEvaluationAccessories),
              ],
            ]),
          if (detail.selfEvaluationContent != null && detail.selfEvaluationContent!.isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          _buildCheckSection(detail),
        ],
      );
    }

    // 进行中/未完成状态 → 编辑自评表单
    if (isDoingOrUnfinished) {
      return _buildCard([
        _SectionHeader('自评'),
        // 评分
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Text('自评得分', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              ...List.generate(5, (i) {
                final score = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selfScore = score),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      score <= _selfScore ? CupertinoIcons.star_fill : CupertinoIcons.star,
                      size: 22,
                      color: score <= _selfScore ? const Color(0xFFFF9500) : CupertinoColors.systemGrey4,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text('$_selfScore 分', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _scoreColor(_selfScore))),
            ],
          ),
        ),
        const Divider(height: 1),
        // 自评内容
        if (detail.isNeedSelfEvaluation || alreadySubmitted) ...[
          const SizedBox(height: 8),
          CupertinoTextField(
            placeholder: detail.selfEvaluationDesc ?? '请输入自评内容',
            maxLines: 4,
            controller: TextEditingController(text: _selfEvaluationText),
            onChanged: (v) => _selfEvaluationText = v,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // 附件
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selfAccessories.map((url) => _AttachmentChip(
              url: url,
              onRemove: () => setState(() => _selfAccessories.remove(url)),
              onTap: () => setState(() { _previewImageUrl = url; _imagePreviewVisible = true; }),
            )),
            ..._pendingImages.map((path) => _PendingAttachmentChip(
              path: path,
              onRemove: () => setState(() => _pendingImages.remove(path)),
            )),
            GestureDetector(
              onTap: _addAttachment,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: const Icon(CupertinoIcons.plus, color: CupertinoColors.systemGrey),
              ),
            ),
          ],
        ),
      ]);
    }

    return const SizedBox.shrink();
  }

  /// 验收评分区域
  Widget _buildCheckSection(TaskLogDetail detail) {
    return _buildCard([
      _SectionHeader('验收评分'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Text('验收得分', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            ...List.generate(5, (i) {
              final score = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _checkScore = score),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    score <= _checkScore ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    size: 22,
                    color: score <= _checkScore ? const Color(0xFFFF9500) : CupertinoColors.systemGrey4,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text('$_checkScore 分', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _scoreColor(_checkScore))),
          ],
        ),
      ),
      CupertinoTextField(
        placeholder: '请填写验收备注',
        maxLines: 3,
        controller: TextEditingController(text: _checkRemarks),
        onChanged: (v) => _checkRemarks = v,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      if (detail.lastCheckRemarks != null && detail.lastCheckRemarks!.isNotEmpty) ...[
        const SizedBox(height: 8),
        _InfoRow('上次验收备注', detail.lastCheckRemarks!),
      ],
    ]);
  }

  Widget _buildCheckInfoCard(TaskLogDetail detail) {
    return _buildCard([
      _SectionHeader('验收信息'),
      if (detail.lastCheckByName != null) _InfoRow('验收人', detail.lastCheckByName!),
      _InfoRow('验收得分', '${detail.checkScore ?? '-'} 分'),
      if (detail.lastCheckRemarks != null && detail.lastCheckRemarks!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('验收备注', style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text(detail.lastCheckRemarks!, style: AppText.body),
              ),
            ],
          ),
        ),
    ]);
  }

  Widget _buildAttachments(List<String> urls) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.map((url) => GestureDetector(
        onTap: () => setState(() { _previewImageUrl = url; _imagePreviewVisible = true; }),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemGrey5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.contains('image') || url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg') || url.endsWith('.gif')
                ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 24))
                : const Icon(CupertinoIcons.doc, size: 24),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildBottomActions(TaskLogDetail detail) {
    final isDoingOrUnfinished = detail.taskLogStatus == 'doing' || detail.taskLogStatus == 'unfinished';
    final isUnchecked = detail.taskLogStatus == 'unchecked';

    // 已完成状态，无操作按钮
    if (detail.isFinished) return const SizedBox.shrink();

    if (!isDoingOrUnfinished && !isUnchecked) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [BoxShadow(color: CupertinoColors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 进行中/未完成 → 预保存 + 正式提交
            if (isDoingOrUnfinished) ...[
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: CupertinoColors.systemGrey5,
                  onPressed: _isSubmitting ? null : _preSubmitSelfEvaluation,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator()
                      : const Text('保存', style: TextStyle(color: CupertinoColors.label)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _isSubmitting ? null : _submitSelfEvaluation,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(detail.isNeedSelfEvaluation ? '提交自评' : '完成任务'),
                ),
              ),
            ],
            // 待验收 → 驳回 + 通过
            if (isUnchecked) ...[
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFFFF3B30),
                  onPressed: _isSubmitting ? null : _rejectTask,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('驳回', style: TextStyle(color: CupertinoColors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _isSubmitting ? null : _approveTask,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('验收通过'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 工具方法 ─────────────────────────────────────────────────────────────

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'doing': return CupertinoIcons.clock;
      case 'unchecked': return CupertinoIcons.checkmark_circle;
      case 'finished': return CupertinoIcons.checkmark_seal_fill;
      case 'overdueFinished': return CupertinoIcons.exclamationmark_triangle;
      case 'unfinished': return CupertinoIcons.xmark_circle;
      default: return CupertinoIcons.circle;
    }
  }

  Color _scoreColor(int score) {
    switch (score) {
      case 1: return const Color(0xFFFF3B30);
      case 2: return const Color(0xFFFF9500);
      case 3: return const Color(0xFF5E5CE6);
      case 4: return const Color(0xFF30D158);
      case 5: return const Color(0xFF00C7BE);
      default: return CupertinoColors.systemGrey;
    }
  }

  String _allowCheckTypeLabel(String type) {
    switch (type) {
      case 'currentDeptManager': return '当前部门负责人';
      case 'superiorDeptManager': return '上级部门负责人';
      default: return type;
    }
  }

  String _formatTs(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── 小组件 ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(value, style: AppText.body),
          ),
        ],
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TappableRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: AppText.caption),
            ),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(color: AppColors.primary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// 已上传附件缩略图
class _AttachmentChip extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  const _AttachmentChip({required this.url, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGrey5,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(CupertinoIcons.photo, size: 24)),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark, size: 10, color: CupertinoColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 待上传图片（loading占位）
class _PendingAttachmentChip extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _PendingAttachmentChip({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemGrey5,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CupertinoActivityIndicator(color: CupertinoColors.white),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.xmark, size: 10, color: CupertinoColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 全屏弹窗（任务简介/说明）
class _ModalOverlay extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onClose;
  const _ModalOverlay({required this.title, required this.content, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: CupertinoColors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 防止点击内容关闭
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.systemGrey3, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(content, style: AppText.body),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 图片预览弹窗
class _ImagePreviewOverlay extends StatelessWidget {
  final String url;
  final VoidCallback onClose;
  const _ImagePreviewOverlay({required this.url, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: CupertinoColors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const CupertinoActivityIndicator(color: CupertinoColors.white),
                    errorBuilder: (_, __, ___) =>
                        const Icon(CupertinoIcons.photo, size: 64, color: CupertinoColors.systemGrey)),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

