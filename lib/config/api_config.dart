/// API 配置
///
/// 使用说明：
/// - 各 API 文件中路径直接以 /members/, /order/, /calendar/ 等开头
///   （ApiClient baseUrl 已包含完整地址）
class ApiConfig {
  // 基础 URL - z1-mid 后端（deno deploy）
  static const String baseUrl = 'https://z1-fun.zsqk.com.cn/deno/';

  // 超时时间（毫秒）
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // API 端点（仅作文档参考，各 API 文件中直接使用）
  static const String membersEndpoint = '/members';
  static const String ordersEndpoint = '/order';
  static const String productsEndpoint = '/products';
  static const String calendarEndpoint = '/calendar';
  static const String approvalEndpoint = '/approval';
}
