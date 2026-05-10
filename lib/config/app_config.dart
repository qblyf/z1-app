/// 应用配置
class AppConfig {
  // 应用名称
  static const String appName = 'Z1 助手';

  // 应用版本
  static const String version = '1.0.0';

  // 环境配置
  static const bool isProduction = false;
  static const bool isDebug = true;

  // API 配置
  static const String apiBaseUrl = 'https://api.z1.com.cn';
  static const String apiPrefix = '/z1func';

  // WebSocket 配置
  static const String wsUrl = 'wss://api.z1.com.cn/ws';

  // 钉钉配置
  static const String dingtalkAppId = '';
  static const String dingtalkAgentId = '';

  // 微信配置
  static const String wechatAppId = '';

  // 极光配置
  static const String jiguangAppKey = '';
  static const String jiguangAppSecret = '';

  // 友盟配置
  static const String umengAppKey = '';
}
