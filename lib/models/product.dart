import 'package:equatable/equatable.dart';

/// 商品模型
class Product extends Equatable {
  final int id;
  final String name;
  final String? subtitle;
  final String? description;
  final int categoryId;
  final String? categoryName;
  final int price;
  final int? originalPrice;
  final String? imageUrl;
  final List<String> images;
  final List<ProductSku> skus;
  final int stock;
  final bool isOnSale;
  final int salesCount;
  final String? brand;
  final Map<String, dynamic>? attributes;

  const Product({
    required this.id,
    required this.name,
    this.subtitle,
    this.description,
    required this.categoryId,
    this.categoryName,
    this.price = 0,
    this.originalPrice,
    this.imageUrl,
    this.images = const [],
    this.skus = const [],
    this.stock = 0,
    this.isOnSale = true,
    this.salesCount = 0,
    this.brand,
    this.attributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? json['spuId'] as int? ?? json['spu_id'] as int? ?? 0,
      name: json['name'] as String? ?? json['spuName'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int? ?? json['category_id'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? json['category_name'] as String?,
      price: json['price'] as int? ?? 0,
      originalPrice: json['originalPrice'] as int? ?? json['original_price'] as int?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      skus: (json['skus'] as List<dynamic>?)
              ?.map((e) => ProductSku.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stock: json['stock'] as int? ?? 0,
      isOnSale: json['isOnSale'] as bool? ?? json['is_on_sale'] as bool? ?? true,
      salesCount: json['salesCount'] as int? ?? json['sales_count'] as int? ?? 0,
      brand: json['brand'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
    );
  }

  String get formattedPrice => '¥${(price / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, name, categoryId, price, stock];
}

/// 商品 SKU 模型
class ProductSku extends Equatable {
  final int id;
  final String name;
  final int price;
  final int stock;
  final String? imageUrl;
  final Map<String, String> specifications; // 规格属性

  const ProductSku({
    required this.id,
    required this.name,
    this.price = 0,
    this.stock = 0,
    this.imageUrl,
    this.specifications = const {},
  });

  factory ProductSku.fromJson(Map<String, dynamic> json) {
    return ProductSku(
      id: json['id'] as int? ?? json['skuId'] as int? ?? json['sku_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      specifications: (json['specifications'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
    );
  }

  String get formattedPrice => '¥${(price / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, name, price, stock];
}
