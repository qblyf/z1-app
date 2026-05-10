/// 预约上门状态（与 PWA StateSubsidyBookingStatus 对应）
enum BookingStatus {
  processing('processing', '待处理'),
  accepted('accepted', '已接单'),
  canceled('canceled', '已取消'),
  closed('closed', '已关闭'),
  completed('completed', '已完成');

  const BookingStatus(this.value, this.label);
  final String value;
  final String label;

  static BookingStatus? fromValue(String? v) {
    if (v == null) return null;
    return BookingStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => BookingStatus.processing,
    );
  }
}

/// 预约上门备注
class AppointmentRemark {
  final int employee;
  final String remark;
  final int createdAt;
  final String statusBefore;
  final String statusCurrent;

  const AppointmentRemark({
    required this.employee,
    required this.remark,
    required this.createdAt,
    required this.statusBefore,
    required this.statusCurrent,
  });

  factory AppointmentRemark.fromJson(Map<String, dynamic> json) {
    return AppointmentRemark(
      employee: json['employee'] as int? ?? 0,
      remark: json['remark'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      statusBefore: json['statusBefore'] as String? ?? '',
      statusCurrent: json['statusCurrent'] as String? ?? '',
    );
  }
}

/// 预约上门类型
enum BookingType {
  stateSubsidies('state-subsidies', '国补');

  const BookingType(this.value, this.label);
  final String value;
  final String label;

  static BookingType? fromValue(String? v) {
    if (v == null) return null;
    return BookingType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => BookingType.stateSubsidies,
    );
  }
}

/// 预约上门
class AppointmentBooking {
  final int id;
  final String number;
  final BookingType type;
  final int sku;
  final String? mallOrderNumber;
  final String phone;
  final String name;
  final String province;
  final String city;
  final String district;
  final String address;
  final int appointmentStartTime;
  final int appointmentEndTime;
  final String? remarks;
  final int client;
  final int? dispatcher;
  final int? editor;
  final int? handler;
  final BookingStatus status;
  final int? acceptedAt;
  final int? completedAt;
  final List<AppointmentRemark> appointmentRemarks;
  final int createdAt;
  final int createdBy;

  const AppointmentBooking({
    required this.id,
    required this.number,
    required this.type,
    required this.sku,
    this.mallOrderNumber,
    required this.phone,
    required this.name,
    required this.province,
    required this.city,
    required this.district,
    required this.address,
    required this.appointmentStartTime,
    required this.appointmentEndTime,
    this.remarks,
    required this.client,
    this.dispatcher,
    this.editor,
    this.handler,
    required this.status,
    this.acceptedAt,
    this.completedAt,
    this.appointmentRemarks = const [],
    required this.createdAt,
    required this.createdBy,
  });

  String get fullAddress => '$province$city$district$address';

  factory AppointmentBooking.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final appointmentTime = json['appointmentTime'] as Map<String, dynamic>? ?? {};
    return AppointmentBooking(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      type: BookingType.fromValue(json['type'] as String?) ?? BookingType.stateSubsidies,
      sku: content['sku'] as int? ?? 0,
      mallOrderNumber: content['mallOrderNumber'] as String?,
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      province: address['province'] as String? ?? '',
      city: address['city'] as String? ?? '',
      district: address['district'] as String? ?? '',
      address: address['address'] as String? ?? '',
      appointmentStartTime: appointmentTime['startTime'] as int? ?? 0,
      appointmentEndTime: appointmentTime['endTime'] as int? ?? 0,
      remarks: json['remarks'] as String?,
      client: json['client'] as int? ?? 0,
      dispatcher: json['dispatcher'] as int?,
      editor: json['editor'] as int?,
      handler: json['handler'] as int?,
      status: BookingStatus.fromValue(json['status'] as String?) ?? BookingStatus.processing,
      acceptedAt: json['acceptedAt'] as int?,
      completedAt: json['completedAt'] as int?,
      appointmentRemarks: (json['appointmentRemarks'] as List?)
              ?.map((e) => AppointmentRemark.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
    );
  }
}
