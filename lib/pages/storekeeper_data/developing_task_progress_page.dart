import 'package:flutter/cupertino.dart';
import '../../widgets/task_progress.dart';
import '../../router/app_router.dart';

/// 任务进度组件演示页面
/// 对应 PWA storekeeper-data/developing-task-progress
///
/// 作者: zhaoxuxu (zhaoxuxujc@gmail.com)
class DevelopingTaskProgressPage extends StatelessWidget {
  const DevelopingTaskProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('任务进度组件演示'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle('基础使用'),
            const TaskProgress(ratio: 0.45),
            _gap(),

            _SectionTitle('左侧文字'),
            const TaskProgress(ratio: 0.05, barTextLeft: '¥5000/100000'),
            _gap(),
            const TaskProgress(ratio: 0.45, barTextLeft: '¥45000/100000'),
            _gap(),

            _SectionTitle('隐藏右侧百分比'),
            const TaskProgress(ratio: 0.45, showPercentText: false),
            _gap(),

            _SectionTitle('不同颜色套装'),
            const TaskProgress(ratio: 0.15, colorSuit: TaskProgressColorSuit.grey),
            _gap(),
            const TaskProgress(ratio: 0.35, colorSuit: TaskProgressColorSuit.red),
            _gap(),
            const TaskProgress(ratio: 0.65, colorSuit: TaskProgressColorSuit.blue),
            _gap(),
            const TaskProgress(ratio: 0.85, colorSuit: TaskProgressColorSuit.green),
            _gap(),
            const TaskProgress(ratio: 1.0, colorSuit: TaskProgressColorSuit.green),
            _gap(),

            _SectionTitle('自定义颜色'),
            const TaskProgress(
              ratio: 0.44,
              colorBg: Color(0xFFfdeca3),
              colorStart: Color(0xFFff69b4),
              colorCurrent: Color(0xFFffcf00),
            ),
            _gap(),

            _SectionTitle('期望任务进度'),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.45,
              expectText: '45000',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 1.0,
              expectText: '100000',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0,
              expectText: '0',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.green,
            ),
            _gap(),

            _SectionTitle('改变宽、高、字体大小'),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              barHeight: 10,
              fontSize: 10,
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              barHeight: 20,
              fontSize: 15,
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              barHeight: 30,
              fontSize: 20,
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              barHeight: 30,
              fontSize: 20,
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              barHeight: 50,
              fontSize: 30,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              width: 150,
            ),
            _gap(),
            const TaskProgress(ratio: 0.45, width: 250),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              width: 250,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.6,
              expectText: '60000',
              width: double.infinity,
            ),
            _gap(),

            _SectionTitle('当进度超过100%时，展示100%'),
            const TaskProgress(ratio: 1.45),
            _gap(),
            const TaskProgress(
              ratio: 1.45,
              expectRatio: 1.0,
              expectText: '100000',
              barTextLeft: '¥145000/100000',
            ),
            _gap(),

            _SectionTitle('期望文字不要超出整体渲染框宽度'),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0,
              expectText: '123456',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.green,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.05,
              expectText: '123456',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.green,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 0.95,
              expectText: '123456',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            _gap(),
            const TaskProgress(
              ratio: 0.45,
              expectRatio: 1.0,
              expectText: '123456',
              barTextLeft: '¥45000/100000',
              colorSuit: TaskProgressColorSuit.red,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _gap() => const SizedBox(height: 16);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label,
        ),
      ),
    );
  }
}
