import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';

/// 企业微信登录服务
class WechatWorkLoginService {
  static final WechatWorkLoginService _instance = WechatWorkLoginService._internal();
  factory WechatWorkLoginService() => _instance;
  WechatWorkLoginService._internal();

  // 企业微信配置
  static const String _corpId = 'ww00cc4c12ff49ae86';
  static const String _agentId = '1000003';
  static const String _agentSecret = 'PZXyqnzJGdPbnhmm2ik2nEW7rF5vyOkK2dJ9eINTlg8';

  /// 企业微信扫码登录（浏览器方式）
  ///
  /// 打开企业微信 OAuth 授权页面，用户扫码后回调到 z1app://wework?code=XXX
  Future<bool> openAuthPage() async {
    try {
      // 构建企业微信 OAuth URL
      final redirectUri = Uri.encodeComponent('z1app://wework');
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      final authUrl = Uri.parse(
        'https://open.work.weixin.qq.com/wwopen/sso/qrConnect'
        '?appid=$_corpId'
        '&agentid=$_agentId'
        '&redirect_uri=$redirectUri'
        '&state=$state'
        '&lang=zh_CN'
        '&fun=implicit'
        '&param=',
      );

      // 使用外部浏览器打开企业微信授权页面
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      debugPrint('企业微信授权失败: $e');
      return false;
    }
  }

  /// 通过授权码获取企业微信访问令牌
  Future<String> getAccessToken() async {
    final tokenUrl = 'https://qyapi.weixin.qq.com/cgi-bin/gettoken'
        '?corpid=$_corpId'
        '&corpsecret=$_agentSecret';

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(tokenUrl));
      final response = await request.close();
      final tokenData = json.decode(await response.transform(utf8.decoder).join());
      httpClient.close();

      if (tokenData['errcode'] != 0) {
        throw Exception(tokenData['errmsg']);
      }

      return tokenData['access_token'] as String;
    } catch (e) {
      httpClient.close();
      rethrow;
    }
  }

  /// 获取企业微信用户信息
  Future<Map<String, dynamic>> getUserInfo(String code) async {
    final accessToken = await getAccessToken();

    final userUrl = 'https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo'
        '?access_token=$accessToken'
        '&code=$code';

    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(userUrl));
      final response = await request.close();
      final userData = json.decode(await response.transform(utf8.decoder).join());
      httpClient.close();

      return userData as Map<String, dynamic>;
    } catch (e) {
      httpClient.close();
      rethrow;
    }
  }

  /// 解析企业微信回调 URL
  static Map<String, String> parseCallbackUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters;
  }
}
