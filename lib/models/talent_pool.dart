/// 性别枚举
enum Sex {
  secret('保密'),
  female('女'),
  male('男');

  final String label;
  const Sex(this.label);

  static Sex? fromString(String? v) {
    if (v == null) return null;
    switch (v) {
      case 'secret':
      case '保密':
        return Sex.secret;
      case 'female':
      case '女':
        return Sex.female;
      case 'male':
      case '男':
        return Sex.male;
      default:
        return null;
    }
  }

  String get value {
    switch (this) {
      case Sex.secret:
        return 'secret';
      case Sex.female:
        return 'female';
      case Sex.male:
        return 'male';
    }
  }
}

/// 学历枚举
enum Education {
  初中及以下('junior'),
  高中('senior'),
  中专('technical'),
  大专('college'),
  本科('bachelor'),
  硕士('master'),
  博士('doctor');

  final String value;
  const Education(this.value);

  static Education? fromString(String? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.value == v) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case Education.初中及以下:
        return '初中及以下';
      case Education.高中:
        return '高中';
      case Education.中专:
        return '中专';
      case Education.大专:
        return '大专';
      case Education.本科:
        return '本科';
      case Education.硕士:
        return '硕士';
      case Education.博士:
        return '博士';
    }
  }
}

/// 学历性质枚举
enum EducationType {
  全日制('full_time'),
  非全日制('part_time');

  final String value;
  const EducationType(this.value);

  static EducationType? fromString(String? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.value == v) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case EducationType.全日制:
        return '全日制';
      case EducationType.非全日制:
        return '非全日制';
    }
  }
}

/// 人才库附件
class TalentPoolImages {
  final List<String>? fullFacedPhoto; // 个人照片：一寸免冠照
  final List<String>? idCardFront; // 身份证照片（正）
  final List<String>? idCardBack; // 身份证照片（反）
  final List<String>? bankCardFront; // 银行卡照片（正）
  final List<String>? bankCardBack; // 银行卡照片（反）
  final List<String>? education; // 个人学历照片

  const TalentPoolImages({
    this.fullFacedPhoto,
    this.idCardFront,
    this.idCardBack,
    this.bankCardFront,
    this.bankCardBack,
    this.education,
  });

  factory TalentPoolImages.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TalentPoolImages();
    }
    return TalentPoolImages(
      fullFacedPhoto: (json['fullFacedPhoto'] as List<dynamic>?)?.cast<String>(),
      idCardFront: (json['idCardFront'] as List<dynamic>?)?.cast<String>(),
      idCardBack: (json['idCardBack'] as List<dynamic>?)?.cast<String>(),
      bankCardFront: (json['bankCardFront'] as List<dynamic>?)?.cast<String>(),
      bankCardBack: (json['bankCardBack'] as List<dynamic>?)?.cast<String>(),
      education: (json['education'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullFacedPhoto != null) 'fullFacedPhoto': fullFacedPhoto,
      if (idCardFront != null) 'idCardFront': idCardFront,
      if (idCardBack != null) 'idCardBack': idCardBack,
      if (bankCardFront != null) 'bankCardFront': bankCardFront,
      if (bankCardBack != null) 'bankCardBack': bankCardBack,
      if (education != null) 'education': education,
    };
  }

  bool get isEmpty =>
      (fullFacedPhoto == null || fullFacedPhoto!.isEmpty) &&
      (idCardFront == null || idCardFront!.isEmpty) &&
      (idCardBack == null || idCardBack!.isEmpty) &&
      (bankCardFront == null || bankCardFront!.isEmpty) &&
      (bankCardBack == null || bankCardBack!.isEmpty) &&
      (education == null || education!.isEmpty);

  TalentPoolImages copyWith({
    List<String>? fullFacedPhoto,
    List<String>? idCardFront,
    List<String>? idCardBack,
    List<String>? bankCardFront,
    List<String>? bankCardBack,
    List<String>? education,
  }) {
    return TalentPoolImages(
      fullFacedPhoto: fullFacedPhoto ?? this.fullFacedPhoto,
      idCardFront: idCardFront ?? this.idCardFront,
      idCardBack: idCardBack ?? this.idCardBack,
      bankCardFront: bankCardFront ?? this.bankCardFront,
      bankCardBack: bankCardBack ?? this.bankCardBack,
      education: education ?? this.education,
    );
  }
}

/// 人才库（入职信息）
class TalentPool {
  final int id;
  final String uuid;
  final String name;
  final Sex sex;
  final String? nation;
  final int? height; // cm
  final int? weight; // kg
  final String? healthy;
  final String? idNumber;
  final int? birthday; // unix timestamp
  final String? nativePlace;
  final String phone;
  final String? email;
  final String? qqNumber;
  final String? political;
  final String? postalCode;
  final String? education; // Education value string
  final String? educationType; // EducationType value string
  final String? school;
  final String? speciality;
  final String? hobby;
  final String? personalRemarks;
  final String? contact;
  final String? contactPhone;
  final bool? maritalStatus;
  final String? contactAddress;
  final TalentPoolImages? images;
  final String? status;
  final String? interviewPosition;
  final String? interviewPositionType;
  final int? interviewTime;
  final int? interviewer;
  final int? principal;
  final String? interviewConclusion;
  final int? dutyID;
  final int? dutyLevelID;
  final String? emplCareType;
  final String? salaryLevel;
  final int? entryDate;
  final int? entryDepartment;
  final String? storeManagerRemarks;
  final String? managerRemarks;
  final String? directorRemarks;
  final int? probationPeriodSalary;
  final int? regularSalary;
  final String? salaryComposition;
  final int? trialPeriodLength;
  final int? registrationTime;
  final List<String>? bringingMaterials;
  final int? emplID;

  const TalentPool({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sex,
    this.nation,
    this.height,
    this.weight,
    this.healthy,
    this.idNumber,
    this.birthday,
    this.nativePlace,
    required this.phone,
    this.email,
    this.qqNumber,
    this.political,
    this.postalCode,
    this.education,
    this.educationType,
    this.school,
    this.speciality,
    this.hobby,
    this.personalRemarks,
    this.contact,
    this.contactPhone,
    this.maritalStatus,
    this.contactAddress,
    this.images,
    this.status,
    this.interviewPosition,
    this.interviewPositionType,
    this.interviewTime,
    this.interviewer,
    this.principal,
    this.interviewConclusion,
    this.dutyID,
    this.dutyLevelID,
    this.emplCareType,
    this.salaryLevel,
    this.entryDate,
    this.entryDepartment,
    this.storeManagerRemarks,
    this.managerRemarks,
    this.directorRemarks,
    this.probationPeriodSalary,
    this.regularSalary,
    this.salaryComposition,
    this.trialPeriodLength,
    this.registrationTime,
    this.bringingMaterials,
    this.emplID,
  });

  factory TalentPool.fromJson(Map<String, dynamic> json) {
    return TalentPool(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sex: Sex.fromString(json['sex'] as String?) ?? Sex.secret,
      nation: json['nation'] as String?,
      height: (json['height'] is num)
          ? (json['height'] as num).toInt()
          : int.tryParse(json['height']?.toString() ?? ''),
      weight: (json['weight'] is num)
          ? (json['weight'] as num).toInt()
          : int.tryParse(json['weight']?.toString() ?? ''),
      healthy: json['healthy'] as String?,
      idNumber: json['idNumber'] as String?,
      birthday: json['birthday'] as int?,
      nativePlace: json['nativePlace'] as String?,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      qqNumber: json['qqNumber'] as String?,
      political: json['political'] as String?,
      postalCode: json['postalCode'] as String?,
      education: json['education'] as String?,
      educationType: json['educationType'] as String?,
      school: json['school'] as String?,
      speciality: json['speciality'] as String?,
      hobby: json['hobby'] as String?,
      personalRemarks: json['personalRemarks'] as String?,
      contact: json['contact'] as String?,
      contactPhone: json['contactPhone'] as String?,
      maritalStatus: json['maritalStatus'] as bool?,
      contactAddress: json['contactAddress'] as String?,
      images: json['images'] != null
          ? TalentPoolImages.fromJson(json['images'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
      interviewPosition: json['interviewPosition'] as String?,
      interviewPositionType: json['interviewPositionType'] as String?,
      interviewTime: json['interviewTime'] as int?,
      interviewer: json['interviewer'] as int?,
      principal: json['principal'] as int?,
      interviewConclusion: json['interviewConclusion'] as String?,
      dutyID: json['dutyID'] as int?,
      dutyLevelID: json['dutyLevelID'] as int?,
      emplCareType: json['emplCareType'] as String?,
      salaryLevel: json['salaryLevel'] as String?,
      entryDate: json['entryDate'] as int?,
      entryDepartment: json['entryDepartment'] as int?,
      storeManagerRemarks: json['storeManagerRemarks'] as String?,
      managerRemarks: json['managerRemarks'] as String?,
      directorRemarks: json['directorRemarks'] as String?,
      probationPeriodSalary: json['probationPeriodSalary'] as int?,
      regularSalary: json['regularSalary'] as int?,
      salaryComposition: json['salaryComposition'] as String?,
      trialPeriodLength: json['trialPeriodLength'] as int?,
      registrationTime: json['registrationTime'] as int?,
      bringingMaterials:
          (json['bringingMaterials'] as List<dynamic>?)?.cast<String>(),
      emplID: json['emplID'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'sex': sex.value,
      if (nation != null) 'nation': nation,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (healthy != null) 'healthy': healthy,
      if (idNumber != null) 'idNumber': idNumber,
      if (birthday != null) 'birthday': birthday,
      if (nativePlace != null) 'nativePlace': nativePlace,
      'phone': phone,
      if (email != null) 'email': email,
      if (qqNumber != null) 'qqNumber': qqNumber,
      if (political != null) 'political': political,
      if (postalCode != null) 'postalCode': postalCode,
      if (education != null) 'education': education,
      if (educationType != null) 'educationType': educationType,
      if (school != null) 'school': school,
      if (speciality != null) 'speciality': speciality,
      if (hobby != null) 'hobby': hobby,
      if (personalRemarks != null) 'personalRemarks': personalRemarks,
      if (contact != null) 'contact': contact,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (maritalStatus != null) 'maritalStatus': maritalStatus,
      if (contactAddress != null) 'contactAddress': contactAddress,
      if (images != null) 'images': images!.toJson(),
    };
  }
}
