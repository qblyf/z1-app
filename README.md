# Z1 App - Flutter 移动端

基于 z1-pwa 项目重构的 Flutter 移动端应用。

## 功能模块

### 1. 会员管理
- 手机号/姓名搜索会员
- 会员详情查看
- 会员订单记录
- 积分管理

### 2. 库存分配
- 库存查询
- 分配管理

### 3. 行事历
- 进行中行事历
- 已结束行事历
- 待验收行事历
- 签到/签退
- 行事历创建

### 4. 订单管理
- 商城订单
- 销售订单
- 回收订单
- 订单详情

### 5. 销售数据
- 订单统计
- 回收订单
- 业绩排行

### 6. 审批中心
- 待我审批
- 我发起的
- 审批详情
- 审批操作

## 技术栈

- **Flutter SDK**: 3.0+
- **状态管理**: Riverpod
- **路由**: GoRouter
- **网络**: Dio
- **本地存储**: SharedPreferences, FlutterSecureStorage
- **UI**: Material Design 3

## 项目结构

```
z1_app/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── api/                   # API 服务层
│   │   ├── api_client.dart    # HTTP 客户端
│   │   ├── member_api.dart     # 会员 API
│   │   ├── order_api.dart      # 订单 API
│   │   ├── calendar_api.dart   # 行事历 API
│   │   └── approval_api.dart   # 审批 API
│   ├── config/                # 配置文件
│   ├── models/                # 数据模型
│   │   ├── user.dart          # 用户模型
│   │   ├── order.dart         # 订单模型
│   │   ├── product.dart       # 商品模型
│   │   ├── calendar.dart      # 行事历模型
│   │   └── approval.dart      # 审批模型
│   ├── providers/              # 状态管理
│   ├── router/                # 路由配置
│   ├── services/               # 服务层
│   ├── pages/                  # 页面
│   │   ├── home_page.dart     # 首页
│   │   ├── login_page.dart    # 登录页
│   │   ├── clerk/             # 店员模块
│   │   ├── my_calendar/       # 行事历模块
│   │   ├── mall_order/        # 商城订单模块
│   │   ├── salesperson_data/  # 销售数据模块
│   │   └── approval/          # 审批模块
│   └── widgets/                # 通用组件
├── assets/                    # 资源文件
├── android/                   # Android 配置
└── ios/                       # iOS 配置
```

## 开发指南

### 环境要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# Debug 模式
flutter run

# Release 模式
flutter run --release

# 指定设备
flutter run -d <device_id>
```

### 构建

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## API 对接

项目通过 z1-mid 后端 SDK 进行 API 调用。确保：

1. 后端服务运行正常
2. API 配置正确（lib/config/api_config.dart）
3. Token 认证流程正常

## 参考项目

- [z1-pwa](https://github.com/zsqk/z1-pwa) - React 版本
- [z1-mid](https://github.com/zsqk/z1-mid) - 后端 SDK
