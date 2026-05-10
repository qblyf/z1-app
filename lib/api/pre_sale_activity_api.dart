import 'api_client.dart';

/// 预售活动内容
class PreSaleActivityContent {
  final String? thumbnail;
  final List<String> mainImages;
  final List<String> detailsImages;
  final String? priceExplain;
  final String? deliveryExplain;
  final String? content;
  final String? description;

  PreSaleActivityContent({
    this.thumbnail,
    this.mainImages = const [],
    this.detailsImages = const [],
    this.priceExplain,
    this.deliveryExplain,
    this.content,
    this.description,
  });

  factory PreSaleActivityContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PreSaleActivityContent();
    return PreSaleActivityContent(
      thumbnail: json['thumbnail'] as String?,
      mainImages: (json['mainImages'] as List<dynamic>?)?.cast<String>() ?? [],
      detailsImages: (json['detailsImages'] as List<dynamic>?)?.cast<String>() ?? [],
      priceExplain: json['priceExplain'] as String?,
      deliveryExplain: json['deliveryExplain'] as String?,
      content: json['content'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// 预售活动
class PreSaleActivity {
  final int id;
  final String title;
  final String? describe;
  final List<int> skuIDs;
  final int amount; // 分为单位
  final int expandAmount; // 膨胀金额（分）
  final int startAt;
  final int endAt;
  final PreSaleActivityContent content;
  final String? transport;
  final List<int> departments;
  final String? remarks;
  final bool isRelease;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;
  final int magnifyQuantity;
  final int virtualQuantity;

  PreSaleActivity({
    required this.id,
    required this.title,
    this.describe,
    required this.skuIDs,
    required this.amount,
    required this.expandAmount,
    required this.startAt,
    required this.endAt,
    required this.content,
    this.transport,
    required this.departments,
    this.remarks,
    required this.isRelease,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.magnifyQuantity,
    required this.virtualQuantity,
  });

  String get amountYuan => (amount / 100).toStringAsFixed(2);
  String get expandAmountYuan => (expandAmount / 100).toStringAsFixed(2);

  factory PreSaleActivity.fromJson(Map<String, dynamic> json) {
    return PreSaleActivity(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      describe: json['describe'] as String?,
      skuIDs: (json['skuIDs'] as List<dynamic>?)?.cast<int>() ?? [],
      amount: json['amount'] as int? ?? 0,
      expandAmount: json['expandAmount'] as int? ?? 0,
      startAt: json['startAt'] as int? ?? 0,
      endAt: json['endAt'] as int? ?? 0,
      content: PreSaleActivityContent.fromJson(
          json['content'] as Map<String, dynamic>?),
      transport: json['transport'] as String?,
      departments: (json['departments'] as List<dynamic>?)?.cast<int>() ?? [],
      remarks: json['remarks'] as String?,
      isRelease: json['isRelease'] == true || json['isRelease'] == 1,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
      magnifyQuantity: json['magnifyQuantity'] as int? ?? 1,
      virtualQuantity: json['virtualQuantity'] as int? ?? 0,
    );
  }
}

/// 预售活动 API
/// 后端路径: /pre-sale-activity/*
class PreSaleActivityApi {
  final ApiClient _client = ApiClient();

  /// 获取预售活动详情
  /// GET /pre-sale-activity/detail?id=X
  Future<PreSaleActivity?> getDetail(int activityId) async {
    final res = await _client.get(
      '/pre-sale-activity/detail',
      queryParameters: {'id': activityId},
    );
    final data = res.data;
    if (data['code'] == 10000 && data['res'] != null) {
      return PreSaleActivity.fromJson(data['res'] as Map<String, dynamic>);
    }
    return null;
  }
}
