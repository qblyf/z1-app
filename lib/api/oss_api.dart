import 'package:dio/dio.dart';
import 'package:z1_app/api/api_client.dart';

/// OSS上传凭证
class OssUploadParams {
  final String accessKeyId;
  final String policy;
  final String signature;
  final String host;
  final String dir;

  const OssUploadParams({
    required this.accessKeyId,
    required this.policy,
    required this.signature,
    required this.host,
    required this.dir,
  });

  factory OssUploadParams.fromJson(Map<String, dynamic> json) {
    return OssUploadParams(
      accessKeyId: json['OSSAccessKeyId'] as String? ?? '',
      policy: json['policy'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      host: json['host'] as String? ?? '',
      dir: json['dir'] as String? ?? '',
    );
  }
}

/// OSS上传结果
class OssUploadResult {
  final String url;
  final String path;

  const OssUploadResult({required this.url, required this.path});
}

/// OSS API - 阿里云OSS文件上传
/// 使用policy-based上传，无需前端计算签名
class OssApi {
  static const String _cdnDomain = 'cdn.zsqk.com.cn';
  static const String _bucket = 'z1-cdn-test';

  Dio get _dio => Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 60),
  ));

  /// 获取OSS上传凭证
  Future<OssUploadParams> getUploadParams() async {
    final client = ApiClient();
    final response = await client.get('/mp-oss');
    final result = response.data['result'] as Map<String, dynamic>? ?? {};
    return OssUploadParams(
      accessKeyId: result['OSSAccessKeyId'] as String? ?? '',
      policy: result['policy'] as String? ?? '',
      signature: result['signature'] as String? ?? '',
      host: '$_bucket.$_cdnDomain',
      dir: '',
    );
  }

  /// 上传文件到OSS
  /// [fileBytes] 文件字节数据
  /// [fileName] 文件名（含扩展名）
  /// [onProgress] 上传进度回调 (sent, total)
  Future<OssUploadResult> upload({
    required List<int> fileBytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    // 获取上传凭证
    final params = await getUploadParams();

    // 生成OSS路径
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final path = '${params.dir}$dateStr/${now.millisecondsSinceEpoch}_$fileName';

    // 构建form-data
    final formData = FormData.fromMap({
      'key': path,
      'OSSAccessKeyId': params.accessKeyId,
      'policy': params.policy,
      'signature': params.signature,
      'success_action_status': '200',
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    // 上传到OSS
    await _dio.post<String>(
      'https://${params.host}',
      data: formData,
      onSendProgress: onProgress,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.plain,
      ),
    );

    final url = 'https://$_cdnDomain/$path';
    return OssUploadResult(url: url, path: path);
  }
}
