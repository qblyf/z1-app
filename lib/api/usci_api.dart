import 'api_client.dart';

/// 社保主体（USCI）API
/// 对应后端 /usci/* 系列接口
/// z1func 后端: GET /usci/detail?ids=
class UsciApi {
  final ApiClient _client = ApiClient();

  /// 获取社保主体详情
  /// z1func GET /usci/detail?ids=1,2,3
  Future<List<UsciInfo>> detail(List<int> ids) async {
    if (ids.isEmpty) return [];
    final res = await _client.get(
      '/usci/detail',
      queryParameters: {'ids': ids.join(',')},
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => UsciInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取社保主体列表
  /// z1func GET /usci/list
  Future<List<UsciInfo>> list({
    String? keyword,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final res = await _client.get('/usci/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => UsciInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// 社保主体信息
class UsciInfo {
  final int id;
  final String name;
  final String? socialInsuranceDept;
  final String? taxID;
  final String? address;
  final String? phone;
  final String? bankAccountNumber;
  final String? openingBank;
  final List<String>? identificationPhoto;
  final bool isAllowViewInvoice;
  final bool isMakeOutInvoice;
  final bool isAllowViewLicence;
  final List<String>? accountOpeningPermit;
  final List<String>? legalPersonIdCard;
  final List<String>? generalTaxpayerCertificate;
  final List<String>? articlesOfAssociation;

  const UsciInfo({
    required this.id,
    required this.name,
    this.socialInsuranceDept,
    this.taxID,
    this.address,
    this.phone,
    this.bankAccountNumber,
    this.openingBank,
    this.identificationPhoto,
    this.isAllowViewInvoice = true,
    this.isMakeOutInvoice = true,
    this.isAllowViewLicence = true,
    this.accountOpeningPermit,
    this.legalPersonIdCard,
    this.generalTaxpayerCertificate,
    this.articlesOfAssociation,
  });

  factory UsciInfo.fromJson(Map<String, dynamic> json) {
    return UsciInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      socialInsuranceDept: json['socialInsuranceDept'] as String?,
      taxID: json['taxID'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      openingBank: json['openingBank'] as String?,
      identificationPhoto: (json['identificationPhoto'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isAllowViewInvoice: json['isAllowViewInvoice'] as bool? ?? true,
      isMakeOutInvoice: json['isMakeOutInvoice'] as bool? ?? true,
      isAllowViewLicence: json['isAllowViewLicence'] as bool? ?? true,
      accountOpeningPermit: (json['accountOpeningPermit'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      legalPersonIdCard: (json['legalPersonIdCard'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      generalTaxpayerCertificate:
          (json['generalTaxpayerCertificate'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      articlesOfAssociation: (json['articlesOfAssociation'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
