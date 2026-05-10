import 'api_client.dart';

/// 发票助手 API
/// 对接后端 /usci/* 接口
class InvoiceAssistantApi {
  final ApiClient _client = ApiClient();

  /// 税号详情查询
  /// 后端 GET /usci/detail?ids=X
  /// 返回 USCI 主体信息（含开票资料）
  Future<UsciDetail?> getUsciDetail(int id) async {
    final res = await _client.get(
      '/usci/detail',
      queryParameters: {'ids': id},
    );
    final data = res.data;
    final list = data is List ? data : (data['res'] as List?);
    if (list == null || list.isEmpty) return null;
    return UsciDetail.fromJson(list[0] as Map<String, dynamic>);
  }

  /// 税号列表（供选择）
  /// 后端 GET /usci/list
  Future<List<UsciItem>> getUsciList({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/usci/list',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = res.data;
    final list = data is List ? data : (data['res'] as List?);
    if (list == null) return [];
    return list.map((e) => UsciItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 税号主体项（列表用）
class UsciItem {
  final int id;
  final String? name;
  final String? taxID;

  const UsciItem({required this.id, this.name, this.taxID});

  factory UsciItem.fromJson(Map<String, dynamic> json) {
    return UsciItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      taxID: json['taxID'] as String?,
    );
  }
}

/// 税号详情（完整信息）
class UsciDetail {
  final int id;
  final String? name;
  final String? socialInsuranceDept;
  final String? taxID;
  final String? address;
  final String? phone;
  final String? bankAccountNumber;
  final String? openingBank;
  final List<String>? identificationPhoto;
  final bool isAllowViewInvoice;
  final String? remarks;
  final int? createdAt;
  final String? accountSettingID;
  final String? key;
  final UsciAccount? accounts;

  const UsciDetail({
    required this.id,
    this.name,
    this.socialInsuranceDept,
    this.taxID,
    this.address,
    this.phone,
    this.bankAccountNumber,
    this.openingBank,
    this.identificationPhoto,
    this.isAllowViewInvoice = true,
    this.remarks,
    this.createdAt,
    this.accountSettingID,
    this.key,
    this.accounts,
  });

  factory UsciDetail.fromJson(Map<String, dynamic> json) {
    final accountsData = json['accounts'];
    return UsciDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
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
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as int?,
      accountSettingID: json['accountSettingID']?.toString(),
      key: json['key'] as String?,
      accounts: accountsData != null
          ? UsciAccount.fromJson(accountsData as Map<String, dynamic>)
          : null,
    );
  }
}

/// 开票账号信息
class UsciAccount {
  final String? taobaoAccount;
  final String? taobaoPassword;
  final String? kdtID;
  final String? kdtName;
  final String? storeName;
  final String? remark;

  const UsciAccount({
    this.taobaoAccount,
    this.taobaoPassword,
    this.kdtID,
    this.kdtName,
    this.storeName,
    this.remark,
  });

  factory UsciAccount.fromJson(Map<String, dynamic> json) {
    return UsciAccount(
      taobaoAccount: json['taobaoAccount'] as String?,
      taobaoPassword: json['taobaoPassword'] as String?,
      kdtID: json['kdtID'] as String?,
      kdtName: json['kdtName'] as String?,
      storeName: json['storeName'] as String?,
      remark: json['remark'] as String?,
    );
  }
}
