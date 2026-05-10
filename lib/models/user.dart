import 'package:equatable/equatable.dart';

/// 性别枚举
enum Sex {
  secret('保密'),
  female('女'),
  male('男');

  const Sex(this.label);
  final String label;
}

/// 用户状态枚举
enum UserState {
  unverified('未验证用户'),
  normal('正常'),
  disabled('禁用');

  const UserState(this.label);
  final String label;
}

/// 会员信息模型
class Member extends Equatable {
  final int userIdent;
  final String? email;
  final String? mobilePhone;
  final String? realName;
  final String? birthDay;
  final Sex gender;
  final int coin;
  final int joinTime;
  final int lastTime;
  final UserState status;
  final int? storeFrontID;
  final int experience;
  final int? lastBuyAt;
  final int? shoppingGuide;
  final String? wxName;
  final String? wxAcatar;
  final String? gzhOpenID;
  final String? wxOpenID;
  final String? cellPhonePlan;
  final bool? isDataPlan;
  final bool? isNiceNumber;
  final bool? isBroadBand;
  final String? operator;
  final int grade;

  const Member({
    required this.userIdent,
    this.email,
    this.mobilePhone,
    this.realName,
    this.birthDay,
    this.gender = Sex.secret,
    this.coin = 0,
    this.joinTime = 0,
    this.lastTime = 0,
    this.status = UserState.normal,
    this.storeFrontID,
    this.experience = 0,
    this.lastBuyAt,
    this.shoppingGuide,
    this.wxName,
    this.wxAcatar,
    this.gzhOpenID,
    this.wxOpenID,
    this.cellPhonePlan,
    this.isDataPlan,
    this.isNiceNumber,
    this.isBroadBand,
    this.operator,
    this.grade = 0,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userIdent: json['userIdent'] as int,
      email: json['email'] as String?,
      mobilePhone: json['mobilePhone'] as String?,
      realName: json['realName'] as String?,
      birthDay: json['birthDay'] as String?,
      gender: Sex.values.firstWhere(
        (e) => e.name == json['gender'],
        orElse: () => Sex.secret,
      ),
      coin: json['coin'] as int? ?? 0,
      joinTime: json['joinTime'] as int? ?? 0,
      lastTime: json['lastTime'] as int? ?? 0,
      status: UserState.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserState.normal,
      ),
      storeFrontID: json['storeFrontID'] as int?,
      experience: json['experience'] as int? ?? 0,
      lastBuyAt: json['lastBuyAt'] as int?,
      shoppingGuide: json['shoppingGuide'] as int?,
      wxName: json['wxName'] as String?,
      wxAcatar: json['wxAcatar'] as String?,
      gzhOpenID: json['gzhOpenID'] as String?,
      wxOpenID: json['wxOpenID'] as String?,
      cellPhonePlan: json['cellPhonePlan'] as String?,
      isDataPlan: json['isDataPlan'] as bool?,
      isNiceNumber: json['isNiceNumber'] as bool?,
      isBroadBand: json['isBroadBand'] as bool?,
      operator: json['operator'] as String?,
      grade: json['grade'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userIdent': userIdent,
      'email': email,
      'mobilePhone': mobilePhone,
      'realName': realName,
      'birthDay': birthDay,
      'gender': gender.name,
      'coin': coin,
      'joinTime': joinTime,
      'lastTime': lastTime,
      'status': status.name,
      'storeFrontID': storeFrontID,
      'experience': experience,
      'lastBuyAt': lastBuyAt,
      'shoppingGuide': shoppingGuide,
      'wxName': wxName,
      'wxAcatar': wxAcatar,
      'gzhOpenID': gzhOpenID,
      'wxOpenID': wxOpenID,
      'cellPhonePlan': cellPhonePlan,
      'isDataPlan': isDataPlan,
      'isNiceNumber': isNiceNumber,
      'isBroadBand': isBroadBand,
      'operator': operator,
      'grade': grade,
    };
  }

  /// 是否已关注公众号
  bool get isSubscribed => gzhOpenID != null && gzhOpenID!.isNotEmpty;

  @override
  List<Object?> get props => [
        userIdent,
        email,
        mobilePhone,
        realName,
        birthDay,
        gender,
        coin,
        joinTime,
        lastTime,
        status,
        storeFrontID,
        experience,
        lastBuyAt,
        shoppingGuide,
        wxName,
        wxAcatar,
        gzhOpenID,
        wxOpenID,
        grade,
      ];
}
