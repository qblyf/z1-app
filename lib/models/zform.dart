import 'package:equatable/equatable.dart';

/// 字段在表单中的显示状态（对应 PWA InFormState）
enum ZFormInFormState {
  invisible('不可见', 0),
  viewNoRequire('可见非必填', 1),
  viewRequire('可见必填', 2);

  final String label;
  final int value;
  const ZFormInFormState(this.label, this.value);

  static ZFormInFormState fromValue(int? v) {
    return ZFormInFormState.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ZFormInFormState.viewNoRequire,
    );
  }
}

/// 字段类型
enum ZFormFieldType {
  singleLineText('single-line-text', '单行文字'),
  multipleLinesText('multiple-lines-text', '多行文字'),
  integer('integer', '整数'),
  decimal('decimal', '小数'),
  amount('amount', '金额'),
  date('date', '日期'),
  time('time', '时间'),
  dateTime('date-time', '日期时间'),
  singleChoice('single-choice', '单选'),
  multipleChoices('multiple-choices', '多选'),
  skuSingleChoice('sku-single-choice', 'SKU单选'),
  skuMultipleChoices('sku-multiple-choices', 'SKU多选'),
  spuSingleChoice('spu-single-choice', 'SPU单选'),
  spuMultipleChoices('spu-multiple-choices', 'SPU多选'),
  cateSingleChoice('cate-single-choice', '商品分类单选'),
  cateMultipleChoices('cate-multiple-choices', '商品分类多选'),
  deptSingleChoice('dept-single-choice', '部门单选'),
  deptMultipleChoices('dept-multiple-choices', '部门多选'),
  emplSingleChoice('empl-single-choice', '职员单选'),
  emplMultipleChoices('empl-multiple-choices', '职员多选'),
  vendorMultipleChoices('vendor-multiple-choices', '往来单位多选'),
  attachments('attachments', '附件');

  final String value;
  final String label;
  const ZFormFieldType(this.value, this.label);

  static ZFormFieldType? fromString(String? v) {
    if (v == null) return null;
    return ZFormFieldType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ZFormFieldType.singleLineText,
    );
  }
}

/// 表格列（字段定义）
/// 对应 PWA TableColumn 类型
class ZFormColumn extends Equatable {
  final int id;
  final String fieldType;
  final String? name;       // 字段标题（对应 PWA title）
  final String? field;
  final String? placeholder;
  final String? desc;       // 字段描述/说明
  final String? unit;       // 单位（如"元"、"kg"）
  final int? maxValue;      // 最大值（文本最大长度 / 附件最大数量）
  final int? minValue;      // 最小值
  final int? keepDecimalNum; // 小数位数
  final String? defaultValue;
  final List<Map<String, dynamic>>? options; // 选项（单选/多选字段）
  final List<String>? whiteList; // 白名单（如SKU ID列表，用于SKU/SPU选择）
  final int? inFormState;   // 表单中状态（0=不可见, 1=可见非必填, 2=可见必填）

  const ZFormColumn({
    required this.id,
    required this.fieldType,
    this.name,
    this.field,
    this.placeholder,
    this.desc,
    this.unit,
    this.maxValue,
    this.minValue,
    this.keepDecimalNum,
    this.defaultValue,
    this.options,
    this.whiteList,
    this.inFormState,
  });

  /// 兼容 PWA title 字段
  String get title => name ?? field ?? '字段';

  /// 是否必填（综合 isRequired 和 inFormState）
  bool get isRequiredField => inFormState == ZFormInFormState.viewRequire.value;

  /// 是否可见
  bool get isVisible => inFormState != ZFormInFormState.invisible.value;

  ZFormFieldType get fieldTypeInfo => ZFormFieldType.fromString(fieldType) ?? ZFormFieldType.singleLineText;

  factory ZFormColumn.fromJson(Map<String, dynamic> json) {
    return ZFormColumn(
      id: json['id'] is String ? int.tryParse(json['id'] as String) ?? 0 : (json['id'] as int? ?? 0),
      fieldType: json['fieldType'] as String? ?? '',
      name: (json['name'] as String?) ?? (json['title'] as String?),
      field: json['field'] as String?,
      placeholder: json['placeholder'] as String?,
      desc: json['desc'] as String?,
      unit: json['unit'] as String?,
      maxValue: json['maxValue'] as int?,
      minValue: json['minValue'] as int?,
      keepDecimalNum: json['keepDecimalNum'] as int?,
      defaultValue: json['defaultValue'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      whiteList: (json['whiteList'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      inFormState: json['inFormState'] as int?,
    );
  }

  @override
  List<Object?> get props => [id];
}

/// 表单记录值
class ZFormFieldValue extends Equatable {
  final int? columnId;
  final String? value;
  final List<String>? values; // for multiple choices

  const ZFormFieldValue({this.columnId, this.value, this.values});

  factory ZFormFieldValue.fromJson(Map<String, dynamic> json) {
    return ZFormFieldValue(
      columnId: json['columnID'] as int?,
      value: json['value'] as String?,
      values: (json['values'] as List<dynamic>?)?.cast<String>(),
    );
  }

  @override
  List<Object?> get props => [columnId, value];
}

/// 表单记录
class ZFormRecord extends Equatable {
  final int id;
  final String? tableName;
  final int tableId;    // 表格ID
  final int formId;
  final int? createdBy;
  final String? createdByName;
  final int? createdAt;
  final int? updatedAt;
  final List<ZFormFieldValue> fields;

  const ZFormRecord({
    required this.id,
    this.tableName,
    this.tableId = 0,
    this.formId = 0,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.fields = const [],
  });

  factory ZFormRecord.fromJson(Map<String, dynamic> json) {
    return ZFormRecord(
      id: json['id'] as int? ?? 0,
      tableName: json['tableName'] as String?,
      tableId: json['tableID'] as int? ?? json['formID'] as int? ?? 0,
      formId: json['formID'] as int? ?? 0,
      createdBy: json['createdBy'] as int?,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => ZFormFieldValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['columns'] as List<dynamic>?) // PWA 兼容：columns 格式
              ?.map((e) {
                final colId = e['columnID'] as int? ?? e['columnId'] as int? ?? 0;
                final val = e['value'];
                return ZFormFieldValue(
                  columnId: colId,
                  value: val?.toString(),
                  values: (val as List<dynamic>?)?.map((v) => v.toString()).toList(),
                );
              })
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id];
}

/// 表格表单（含字段定义）
class ZForm extends Equatable {
  final int id;
  final String name;
  final String? desc;
  final String? backImage;   // 背景图片
  final String? coverImage;   // 封面图片
  final List<ZFormColumn> columns;
  final int? createdBy;
  final int? status;          // 状态
  final int? maxCommitNum;   // 最大提交次数
  final bool? allowUpdate;    // 是否允许修改
  final int? commitPermission; // 提交权限

  const ZForm({
    required this.id,
    required this.name,
    this.desc,
    this.backImage,
    this.coverImage,
    this.columns = const [],
    this.createdBy,
    this.status,
    this.maxCommitNum,
    this.allowUpdate,
    this.commitPermission,
  });

  factory ZForm.fromJson(Map<String, dynamic> json) {
    return ZForm(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      desc: json['desc'] as String?,
      backImage: json['backImage'] as String?,
      coverImage: json['coverImage'] as String? ?? json['cover_image'] as String?,
      columns: (json['tableColumns'] as List<dynamic>?)
              ?.map((e) => ZFormColumn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] as int?,
      status: json['status'] as int?,
      maxCommitNum: json['maxCommitNum'] as int? ?? json['max_commit_num'] as int?,
      allowUpdate: json['allowUpdate'] as bool? ?? json['allow_update'] as bool?,
      commitPermission: json['commitPermission'] as int?,
    );
  }

  @override
  List<Object?> get props => [id];
}
