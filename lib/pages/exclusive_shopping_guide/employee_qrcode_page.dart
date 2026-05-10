import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api/employee_api.dart';
import '../../models/employee.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// 职员二维码页面
/// 用于专属导购场景，生成员工专属二维码供顾客扫码
class EmployeeQrcodePage extends ConsumerStatefulWidget {
  const EmployeeQrcodePage({super.key});

  @override
  ConsumerState<EmployeeQrcodePage> createState() => _EmployeeQrcodePageState();
}

class _EmployeeQrcodePageState extends ConsumerState<EmployeeQrcodePage> {
  final EmployeeApi _api = EmployeeApi();
  Employee? _employee;
  String? _departmentName;
  bool _isLoading = true;
  String? _error;

  /// 微信商城基础地址（生成专属导购二维码用）
  static const String _wxMallBase = 'https://z1-fun.zsqk.com.cn';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        setState(() {
          _error = '未获取到用户信息';
          _isLoading = false;
        });
        return;
      }

      final employees = await _api.getByUserIdents([user.userIdent]);
      if (employees.isEmpty) {
        setState(() {
          _error = '未找到员工信息';
          _isLoading = false;
        });
        return;
      }

      final emp = employees.first;

      // 获取部门名称
      String? deptName;
      final deptId = emp.currentDepartmentId ?? emp.departmentId;
      if (deptId != null) {
        final depts = await _api.getDepartmentDetail([deptId]);
        if (depts.isNotEmpty) {
          deptName = depts.first.name;
        }
      }

      if (mounted) {
        setState(() {
          _employee = emp;
          _departmentName = deptName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String get _qrCodeUrl {
    if (_employee == null) return '';
    // 微信小程序专属导购跳转链接
    // path=pages/index, page=exclusive-shopping-guide, employeeID=员工ID
    return '$_wxMallBase/?path=pages/index&page=exclusive-shopping-guide&employeeID=${_employee!.id}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('职员二维码'),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadData,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 员工信息卡片
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  // 二维码区域
                  _buildQrCodeCard(),
                  const SizedBox(height: 16),
                  // 提示文字
                  Text(
                    '扫码关注专属导购',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5E5CE6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _employee!.name ?? '未知员工',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.building_2_fill,
                          size: 14,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _departmentName ?? '未知部门',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 员工头像
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                ),
                child: _employee!.dingAvatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _employee!.dingAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.person_fill,
                            color: CupertinoColors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.person_fill,
                        color: CupertinoColors.white,
                        size: 32,
                      ),
              ),
            ],
          ),
          if (_employee!.number != null) ...[
            const SizedBox(height: 12),
            Text(
              '工号: ${_employee!.number}',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 二维码
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: QrImageView(
                data: _qrCodeUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: CupertinoColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF063E87),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF063E87),
                ),
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '专属导购二维码',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
