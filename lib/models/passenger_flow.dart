/// 门店客流统计
class PassengerFlow {
  final int id;
  final String sn; // 摄像头编号
  final int storeID;
  final String? storeName;
  final int year;
  final int month;
  final int day;
  final int hour;
  final String timeSpan; // 时间段
  final String week; // 星期
  final int count; // 进店人数
  final int repeat; // 重复人数
  final int from; // 数据来源
  final String? equipmentType;

  const PassengerFlow({
    required this.id,
    required this.sn,
    required this.storeID,
    this.storeName,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.timeSpan,
    required this.week,
    required this.count,
    required this.repeat,
    required this.from,
    this.equipmentType,
  });

  factory PassengerFlow.fromJson(Map<String, dynamic> json) {
    return PassengerFlow(
      id: json['id'] as int? ?? 0,
      sn: json['sn'] as String? ?? '',
      storeID: json['store'] as int? ?? 0,
      storeName: json['storeName'] as String?,
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      day: json['day'] as int? ?? 0,
      hour: json['hour'] as int? ?? 0,
      timeSpan: json['timeSpan'] as String? ?? '',
      week: json['week'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      repeat: json['repeat'] as int? ?? 0,
      from: json['from'] as int? ?? 0,
      equipmentType: json['equipmentType'] as String?,
    );
  }

  String get formattedDate => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String get formattedTime => '${hour.toString().padLeft(2, '0')}:00';

  int get uniqueCount => count - repeat;
}
