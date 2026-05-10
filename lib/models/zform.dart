import 'package:equatable/equatable.dart';

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
class ZFormColumn extends Equatable {
  final int id;
  final String fieldType;
  final String? name;
  final String? field;
  final String? placeholder;
  final bool? isRequired;
  final String? defaultValue;
  final List<Map<String, dynamic>>? options; // for choice fields

  const ZFormColumn({
    required this.id,
    required this.fieldType,
    this.name,
    this.field,
    this.placeholder,
    this.isRequired,
    this.defaultValue,
    this.options,
  });

  ZFormFieldType get fieldTypeInfo => ZFormFieldType.fromString(fieldType) ?? ZFormFieldType.singleLineText;

  factory ZFormColumn.fromJson(Map<String, dynamic> json) {
    return ZFormColumn(
      id: json['id'] as int? ?? 0,
      fieldType: json['fieldType'] as String? ?? '',
      name: json['name'] as String?,
      field: json['field'] as String?,
      placeholder: json['placeholder'] as String?,
      isRequired: json['isRequired'] as bool?,
      defaultValue: json['defaultValue'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
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
  final int formId;
  final int? createdBy;
  final int? createdAt;
  final int? updatedAt;
  final List<ZFormFieldValue> fields;

  const ZFormRecord({
    required this.id,
    this.tableName,
    this.formId = 0,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.fields = const [],
  });

  factory ZFormRecord.fromJson(Map<String, dynamic> json) {
    return ZFormRecord(
      id: json['id'] as int? ?? 0,
      tableName: json['tableName'] as String?,
      formId: json['formID'] as int? ?? 0,
      createdBy: json['createdBy'] as int?,
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => ZFormFieldValue.fromJson(e as Map<String, dynamic>))
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
  final String? backImage;
  final List<ZFormColumn> columns;
  final int? createdBy;

  const ZForm({
    required this.id,
    required this.name,
    this.desc,
    this.backImage,
    this.columns = const [],
    this.createdBy,
  });

  factory ZForm.fromJson(Map<String, dynamic> json) {
    return ZForm(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      desc: json['desc'] as String?,
      backImage: json['backImage'] as String?,
      columns: (json['tableColumns'] as List<dynamic>?)
              ?.map((e) => ZFormColumn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] as int?,
    );
  }

  @override
  List<Object?> get props => [id];
}
