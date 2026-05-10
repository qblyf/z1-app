import 'package:flutter/cupertino.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// 订单来源选择底部弹窗
/// 对应 PWA SelectSalesChannel.tsx
class SelectSalesChannelSheet extends StatefulWidget {
  /// 当前选中的值（int 类型，对应 NetSalePlatformType.value）
  final int? value;

  /// 确认回调
  final void Function(int? selected) onConfirm;

  const SelectSalesChannelSheet({
    super.key,
    this.value,
    required this.onConfirm,
  });

  /// 显示底部弹窗，返回选中的 NetSalePlatformType.value（int?）
  static Future<int?> show(BuildContext context, {int? currentValue}) async {
    return showCupertinoModalPopup<int?>(
      context: context,
      builder: (ctx) => SelectSalesChannelSheet(
        value: currentValue,
        onConfirm: (selected) => Navigator.pop(ctx, selected),
      ),
    );
  }

  @override
  State<SelectSalesChannelSheet> createState() => _SelectSalesChannelSheetState();
}

class _SelectSalesChannelSheetState extends State<SelectSalesChannelSheet> {
  late int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Spacer(),
                  const Text(
                    '订单来源',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: CupertinoColors.systemGrey3,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 选项列表
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: NetSalePlatformType.values.map((type) {
                    final isSelected = _selected == type.value;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _selected = isSelected ? null : type.value;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                type.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF333333)
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ),
                            _buildRadio(isSelected),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // 确认按钮
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () => widget.onConfirm(_selected),
                  child: const Text(
                    '确认',
                    style: TextStyle(fontSize: 15, color: CupertinoColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(bool selected) {
    if (selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: const Icon(
          CupertinoIcons.checkmark,
          size: 12,
          color: CupertinoColors.white,
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB9B9B9), width: 1),
      ),
    );
  }
}
