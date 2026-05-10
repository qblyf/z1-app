import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 任务模板详情页
/// 对应 PWA /pages/path-d/my-calendar/task-info.tsx
/// 显示任务模板信息（名称、权重、简介、说明、时间周期、附件、验收人）
class TaskInfoPage extends ConsumerStatefulWidget {
  final int taskId;

  const TaskInfoPage({super.key, required this.taskId});

  @override
  ConsumerState<TaskInfoPage> createState() => _TaskInfoPageState();
}

class _TaskInfoPageState extends ConsumerState<TaskInfoPage> {
  final ApiClient _client = ApiClient();

  TaskInfoData? _data;
  bool _isLoading = true;
  bool _showFullDescription = false;

  // 简介/说明弹窗
  bool _showIntroductionModal = false;
  bool _showDescriptionModal = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _client.get('/task/details', queryParameters: {
        'taskIDs': [widget.taskId],
      });
      final list = res.data['res'] as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _data = TaskInfoData.fromJson(list[0] as Map<String, dynamic>);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRepeatText() {
    final d = _data;
    if (d == null) return '';
    final startTs = d.giveStartAt ?? 0;
    final startDt = DateTime.fromMillisecondsSinceEpoch(startTs * 1000);
    final day = startDt.day;

    if (d.repeatCycle == '每天') {
      return '每天 ${_formatTime(startTs)}';
    } else if (d.repeatCycle == '每周') {
      if (d.giveDays != null && d.giveDays!.isNotEmpty) {
        final weeks = d.giveDays!.map((v) {
          switch (v) {
            case 1:
              return '一';
            case 2:
              return '二';
            case 3:
              return '三';
            case 4:
              return '四';
            case 5:
              return '五';
            case 6:
              return '六';
            case 7:
              return '日';
            default:
              return '$v';
          }
        }).toList();
        return '每周${weeks.join(',')} ${_formatTime(startTs)}';
      } else {
        final weekday = startDt.weekday;
        final weekLabels = ['', '一', '二', '三', '四', '五', '六', '日'];
        return '每周${weekLabels[weekday]} ${_formatTime(startTs)}';
      }
    } else if (d.repeatCycle == '每月') {
      if (d.giveDays != null && d.giveDays!.isNotEmpty) {
        return '每月 ${d.giveDays!.join(',')} 日 ${_formatTime(startTs)}';
      } else {
        return '每月$day 日 ${_formatTime(startTs)}';
      }
    } else {
      return _formatDateTime(startTs);
    }
  }

  String _formatDateTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String _getAllowCheckLabel() {
    final d = _data;
    if (d == null) return '-';
    switch (d.allowCheckType) {
      case '上级部门负责人':
        return '上级部门负责人';
      case '当前部门负责人':
        return '当前部门负责人';
      case '指定人员':
        return '指定人员';
      default:
        return d.allowCheckType ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('任务详情'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _data == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.doc_text,
                            size: 48, color: Color(0xFFDDDDE0)),
                        const SizedBox(height: 16),
                        Text('暂无数据', style: AppText.body),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 基本信息
              _buildSectionTitle('任务详情'),
              _buildCard([
                _InfoItem('名称', d.name ?? '-'),
                _InfoItem('权重', d.taskWeight != null ? '${d.taskWeight}' : '-'),
                _InfoItem('简介', d.introduction ?? '-',
                    onTap: d.introduction != null && d.introduction!.isNotEmpty
                        ? () => setState(() => _showIntroductionModal = true)
                        : null),
                _InfoItem('说明', d.description ?? '-',
                    onTap: d.description != null && d.description!.isNotEmpty
                        ? () => setState(() => _showDescriptionModal = true)
                        : null),
                _InfoItem('时间', _formatDateTime(d.giveStartAt ?? 0)),
                if (d.repeatCycle != '不重复') ...[
                  _InfoItem('重复周期', d.repeatCycle ?? '-'),
                  _InfoItem('重复规则', _formatRepeatText()),
                ],
              ]),

              const SizedBox(height: 16),

              // 验收信息
              _buildSectionTitle('验收信息'),
              _buildCard([
                _InfoItem('验收方式', _getAllowCheckLabel()),
                if (d.allowCheckEmployees != null &&
                    d.allowCheckEmployees!.isNotEmpty)
                  _InfoItem(
                    '验收人',
                    d.allowCheckEmployees!.join(', '),
                  ),
              ]),

              // 附件
              if (d.accessoriesUrls != null &&
                  d.accessoriesUrls!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('附件'),
                _buildCard(
                  d.accessoriesUrls!.asMap().entries.map<Widget>((entry) {
                    final url = entry.value;
                    return _AttachmentItem(
                      url: url,
                      index: entry.key,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppText.label.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoItem(this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMultiline = value.length > 20;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF999999)),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: onTap != null
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF333333),
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              const Icon(CupertinoIcons.chevron_right,
                  size: 14, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  final String url;
  final int index;

  const _AttachmentItem({required this.url, required this.index});

  String get _fileName {
    final parts = url.split('/');
    return parts.isNotEmpty ? parts.last : '附件${index + 1}';
  }

  bool get _isImage {
    final ext = _fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']
        .contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 预览图片或下载文件
        if (_isImage) {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('图片预览'),
              content: Column(
                children: [
                  const SizedBox(height: 12),
                  Image.network(url, height: 300, fit: BoxFit.contain),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('关闭'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        } else {
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('附件'),
              content: Text(_fileName),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isImage
                  ? CupertinoIcons.photo
                  : CupertinoIcons.doc_text,
              size: 20,
              color: const Color(0xFF666666),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fileName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _isImage ? '查看' : '下载',
              style: const TextStyle(fontSize: 12, color: Color(0xFF0A84FF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务详情数据模型
class TaskInfoData {
  final int taskId;
  final String? name;
  final String? introduction;
  final String? description;
  final int? taskWeight;
  final int? giveStartAt;
  final int? giveEndAt;
  final String? repeatCycle;
  final List<int>? giveDays;
  final List<String>? accessoriesUrls;
  final String? allowCheckType;
  final List<String>? allowCheckEmployees;

  TaskInfoData({
    required this.taskId,
    this.name,
    this.introduction,
    this.description,
    this.taskWeight,
    this.giveStartAt,
    this.giveEndAt,
    this.repeatCycle,
    this.giveDays,
    this.accessoriesUrls,
    this.allowCheckType,
    this.allowCheckEmployees,
  });

  factory TaskInfoData.fromJson(Map<String, dynamic> json) {
    return TaskInfoData(
      taskId: json['taskID'] as int? ?? 0,
      name: json['name'] as String?,
      introduction: json['introduction'] as String?,
      description: json['description'] as String?,
      taskWeight: json['taskWeight'] as int?,
      giveStartAt: json['giveStartAt'] as int?,
      giveEndAt: json['giveEndAt'] as int?,
      repeatCycle: json['repeatCycle'] as String?,
      giveDays: (json['giveDays'] as List<dynamic>?)?.cast<int>(),
      accessoriesUrls:
          (json['accessoriesUrls'] as List<dynamic>?)?.cast<String>(),
      allowCheckType: json['allowCheckType'] as String?,
      allowCheckEmployees:
          (json['allowCheckEmployees'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
