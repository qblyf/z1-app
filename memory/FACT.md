# 项目上下文

## 项目路径
- Flutter App: `/Users/fan/www/Ai/Phone/Flutter/z1_app/`
- 目标PWA: `/Users/fan/www/z1/z1-pwa/`
- 后端中间层: `/Users/fan/www/z1/z1-mid/`
- 后端API Base: `https://z1-fun.zsqk.com.cn/deno`

## 技术栈
- Flutter App: Provider + Riverpod, GoRouter, Dio, Cupertino风格
- PWA: React + TypeScript + Ionic, React Router
- 后端: Deno + TypeScript/Node.js

## 业务域
零售门店管理系统，包含：门店零售、会员管理、销售统计、员工积分、行事历、任务管理、审批、采购、调拨、盘点、巡店、客流、财务、积分兑换等模块

## API设计规范
- 请求格式: JSON POST body
- 认证: Bearer Token (从token_service获取)
- 错误处理: 统一的错误码响应
- 分页: offset/limit参数
