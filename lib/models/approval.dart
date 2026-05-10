import 'package:equatable/equatable.dart';

/// 审批状态
enum ApprovalStatus {
  pending('待审批', 1),
  approved('已通过', 2),
  rejected('已拒绝', 3),
  cancelled('已撤回', 4);

  const ApprovalStatus(this.label, this.value);
  final String label;
  final int value;
}

/// 审批类型
enum ApprovalType {
  leave('请假', 'leave'),
  expense('报销', 'expense'),
  purchase('采购', 'purchase'),
  overtime('加班', 'overtime'),
  other('其他', 'other');

  const ApprovalType(this.label, this.value);
  final String label;
  final String value;
}

/// 审批记录模型
class Approval extends Equatable {
  final String id;
  final String title;
  final String? description;
  final ApprovalType type;
  final ApprovalStatus status;
  final int applicantId;
  final String? applicantName;
  final String? applicantAvatar;
  final int departmentId;
  final String? departmentName;
  final int createdAt;
  final int? processedAt;
  final int? currentApproverId;
  final String? currentApproverName;
  final List<ApprovalStep> steps;
  final Map<String, dynamic>? formData;

  const Approval({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.status = ApprovalStatus.pending,
    required this.applicantId,
    this.applicantName,
    this.applicantAvatar,
    required this.departmentId,
    this.departmentName,
    this.createdAt = 0,
    this.processedAt,
    this.currentApproverId,
    this.currentApproverName,
    this.steps = const [],
    this.formData,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: ApprovalType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ApprovalType.other,
      ),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      applicantId: json['applicantId'] as int? ?? json['applicant_id'] as int? ?? 0,
      applicantName: json['applicantName'] as String? ?? json['applicant_name'] as String?,
      applicantAvatar: json['applicantAvatar'] as String? ?? json['applicant_avatar'] as String?,
      departmentId: json['departmentId'] as int? ?? json['department_id'] as int? ?? 0,
      departmentName: json['departmentName'] as String? ?? json['department_name'] as String?,
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int? ?? 0,
      processedAt: json['processedAt'] as int? ?? json['processed_at'] as int?,
      currentApproverId: json['currentApproverId'] as int? ?? json['current_approver_id'] as int?,
      currentApproverName: json['currentApproverName'] as String? ?? json['current_approver_name'] as String?,
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => ApprovalStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      formData: json['formData'] as Map<String, dynamic>? ?? json['form_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'status': status.value,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantAvatar': applicantAvatar,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'createdAt': createdAt,
      'processedAt': processedAt,
      'currentApproverId': currentApproverId,
      'currentApproverName': currentApproverName,
      'steps': steps.map((e) => e.toJson()).toList(),
      'formData': formData,
    };
  }

  @override
  List<Object?> get props => [id, title, type, status, createdAt];
}

/// 审批步骤
class ApprovalStep extends Equatable {
  final int stepIndex;
  final int approverId;
  final String? approverName;
  final String? approverAvatar;
  final int status; // 1: 待审批, 2: 已通过, 3: 已拒绝
  final int? operatedAt;
  final String? comment;

  const ApprovalStep({
    required this.stepIndex,
    required this.approverId,
    this.approverName,
    this.approverAvatar,
    this.status = 1,
    this.operatedAt,
    this.comment,
  });

  factory ApprovalStep.fromJson(Map<String, dynamic> json) {
    return ApprovalStep(
      stepIndex: json['stepIndex'] as int? ?? json['step_index'] as int? ?? 0,
      approverId: json['approverId'] as int? ?? json['approver_id'] as int? ?? 0,
      approverName: json['approverName'] as String? ?? json['approver_name'] as String?,
      approverAvatar: json['approverAvatar'] as String? ?? json['approver_avatar'] as String?,
      status: json['status'] as int? ?? 1,
      operatedAt: json['operatedAt'] as int? ?? json['operated_at'] as int?,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepIndex': stepIndex,
      'approverId': approverId,
      'approverName': approverName,
      'approverAvatar': approverAvatar,
      'status': status,
      'operatedAt': operatedAt,
      'comment': comment,
    };
  }

  String get statusLabel {
    switch (status) {
      case 1:
        return '待审批';
      case 2:
        return '已通过';
      case 3:
        return '已拒绝';
      default:
        return '未知';
    }
  }

  @override
  List<Object?> get props => [stepIndex, approverId, status];
}
