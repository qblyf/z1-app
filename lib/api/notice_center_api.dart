import 'api_client.dart';
import '../models/notice_center.dart';

class NoticeCenterApi {
  final _client = ApiClient();

  /// 通知记录列表
  Future<List<NoticeLog>> list({
    ReceiverType? receiverType,
    ReadStatus? readStatus,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
    bool descending = true,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'orderBy': [
        {'key': 'created_at', 'sort': descending ? 'DESC' : 'ASC'}
      ],
    };
    if (receiverType != null) body['receiverType'] = receiverType.value;
    if (readStatus != null) body['readStatus'] = readStatus.value;
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/notice-log/list', queryParameters: body);
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => NoticeLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 我的通知统计
  Future<NoticeCount> myCount() async {
    final res = await _client.get('/notice-log/my-count');
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return const NoticeCount(carbonCopyCount: 0, receiverCount: 0);
    return NoticeCount.fromJson(data);
  }

  /// 通知详情
  Future<Map<String, dynamic>?> detail(int noticeLogId) async {
    final res = await _client.get('/notice-log/detail', queryParameters: {'id': noticeLogId});
    return res.data['res'] as Map<String, dynamic>?;
  }

  /// 批量已读
  Future<bool> batchRead() async {
    final res = await _client.post('/notice-log/batch-read');
    return (res.data['res'] as bool?) ?? false;
  }
}
