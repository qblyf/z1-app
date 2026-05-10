import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/clerk/member_management_page.dart';
import '../pages/clerk/member_detail_page.dart';
import '../pages/clerk/member_experience_edit_page.dart';
import '../pages/clerk/stock_distribution_page.dart';
import '../pages/clerk/order_page.dart';
import '../pages/clerk/clerk_order_page.dart';
import '../pages/my_calendar/calendar_list_page.dart';
import '../pages/my_calendar/calendar_detail_page.dart';
import '../pages/mall_order/order_list_page.dart';
import '../pages/mall_order/order_info_page.dart';
import '../pages/mall_order/recycle_order_info_page.dart';
import '../pages/mall_order/sales_order_list_page.dart';
import '../pages/salesperson_data/salesperson_page.dart';
import '../pages/salesperson_data/salesperson_recycle_order_info_page.dart';
import '../pages/approval/approval_center_page.dart';
import '../pages/store_retail/entry_page.dart';
import '../pages/store_retail/home_page.dart';
import '../pages/store_retail/sales_order_page.dart';
import '../pages/store_retail/coupon_packet_page.dart';
import '../pages/store_retail/member_info_page.dart';
import '../pages/store_retail/returns_page.dart';
import '../pages/store_retail/associated_order_page.dart';
import '../pages/store_retail/member_label_management_page.dart';
import '../pages/store_retail/sales_preference_page.dart';
import '../pages/store_retail/recycle_order_list_page.dart';
import '../pages/store_retail/recycle_order_detail_page.dart';
import '../pages/store_retail/recycle_order_create_page.dart';
import '../pages/store_retail/giveaway_select_page.dart';
import '../pages/employee_score/adjustment_page.dart';
import '../pages/employee_score/distribution_page.dart';
import '../pages/employee_score/management_page.dart';
import '../pages/employee_score/apply_page.dart';
import '../pages/employee_score/employee_score_info_page.dart';
import '../pages/employee_score/ranking_page.dart';
import '../pages/employee_score/reward_punishment_details_page.dart';
import '../pages/employee_score/employee_score_ranking_detail_page.dart';
import '../pages/cashier_daily_report/list_page.dart';
import '../pages/cashier_daily_report/detail_page.dart';
import '../pages/cashier_daily_report/create_page.dart';
import '../pages/purchase_order/list_page.dart';
import '../pages/purchase_order/detail_page.dart';
import '../pages/purchase_order/create_page.dart';
import '../pages/transfer_order/list_page.dart';
import '../pages/transfer_order/detail_page.dart';
import '../pages/transfer_order/create_page.dart';
import '../pages/invoice/list_page.dart';
import '../pages/invoice/detail_page.dart';
import '../pages/invoice/application_page.dart';
import '../pages/invoice/application_form_page.dart';
import '../pages/stocktaking/list_page.dart';
import '../pages/stocktaking/stocktaking_page.dart';
import '../pages/stocktaking/stocktaking_warehouses_page.dart';
import '../pages/stocktaking/stocktaking_my_log_page.dart';
import '../pages/stocktaking/stocktaking_log_list_page.dart';
import '../pages/stocktaking/stocktaking_dashboard_page.dart';
import '../pages/stocktaking/stocktaking_info_page.dart';
import '../pages/stocktaking/stocktaking_delivery_receipt_page.dart';
import '../pages/stocktaking/stocktake_page.dart';
import '../pages/customer_remind/list_page.dart';
import '../pages/return_visit/list_page.dart';
import '../pages/return_visit/detail_page.dart';
import '../pages/palm_recycle/dept_statistics_page.dart';
import '../pages/palm_recycle/employee_statistics_page.dart';
import '../pages/product_quotation/product_quotation_page.dart';
import '../pages/store_inspection/list_page.dart';
import '../pages/store_inspection/store_inspection_ready_page.dart';
import '../pages/store_inspection/store_inspection_info_page.dart';
import '../pages/store_inspection/store_inspection_logs_page.dart';
import '../pages/goods_request/list_page.dart';
import '../pages/goods_request/create_page.dart';
import '../pages/task_management/list_page.dart';
import '../pages/task_management/task_log_detail_page.dart';
import '../pages/task_management/task_allocation_info_page.dart';
import '../pages/task_management/task_template_edit_page.dart';
import '../pages/customer/customer_birthday_list_page.dart';
import '../pages/mall_activity/list_page.dart';
import '../pages/passenger_flow/list_page.dart';
import '../pages/price_difference/list_page.dart';
import '../pages/sales/list_page.dart';
import '../pages/standard_transfer/list_page.dart';
import '../pages/price_adjustment/list_page.dart';
import '../pages/storekeeper_data/list_page.dart';
import '../pages/storekeeper_data/store_ranking_page.dart';
import '../pages/storekeeper_data/store_overview_page.dart';
import '../pages/storekeeper_data/employee_sales_info_page.dart';
import '../pages/storekeeper_data/target_glance_page.dart';
import '../pages/storekeeper_data/capital_turnover_page.dart';
import '../pages/storekeeper_data/spu_ranking_page.dart';
import '../pages/storekeeper_data/sku_ranking_page.dart';
import '../pages/storekeeper_data/area_data_compare_page.dart';
import '../pages/storekeeper_data/employee_ranking_page.dart';
import '../pages/storekeeper_data/main_products_page.dart';
import '../pages/storekeeper_data/analyse_month_page.dart';
import '../pages/storekeeper_data/developing_task_progress_page.dart';
import '../pages/storekeeper_data/main_products_employee_page.dart';
import '../pages/coupon/list_page.dart';
import '../pages/coupon/batch_issue_page.dart';
import '../pages/financial_expense/list_page.dart';
import '../pages/financial_expense/detail_page.dart';
import '../pages/financial_expense/create_page.dart';
import '../pages/financial_expense/settlement_order_page.dart';
import '../pages/inventory_price/list_page.dart';
import '../pages/repair_order/list_page.dart';
import '../pages/repair_order/detail_page.dart';
import '../pages/appointment_booking/list_page.dart';
import '../pages/appointment_booking/detail_page.dart';
import '../pages/notice_center/list_page.dart';
import '../pages/notice_center/detail_page.dart';
import '../pages/accounting_voucher/audit_page.dart';
import '../pages/accounting_voucher/list_page.dart';
import '../pages/points_redeem_order/list_page.dart';
import '../pages/points_redeem_order/detail_page.dart';
import '../pages/flash_sale/flash_sale_order_list_page.dart';
import '../pages/flash_sale/flash_sale_order_detail_page.dart';
import '../pages/pre_sale/pre_sale_order_list_page.dart';
import '../pages/pre_sale/pre_sale_order_detail_page.dart';
import '../pages/store_management/booth_list_page.dart';
import '../pages/store_management/booth_operate_page.dart';
import '../pages/store_management/base_info_page.dart';
import '../pages/store_management/department_switch_page.dart';
import '../pages/transfer_order/entry_page.dart';
import '../pages/transfer_order/out_warehouse_page.dart';
import '../pages/transfer_order/in_warehouse_page.dart';
import '../pages/standard_purchase_inbound/list_page.dart';
import '../pages/standard_purchase_inbound/detail_page.dart';
import '../pages/standard_purchase_inbound/create_page.dart';
import '../pages/invoice_assistant/tax_id_query_page.dart';
import '../pages/invoice_assistant/license_inquiry_page.dart';
import '../pages/my_invoice/list_page.dart';
import '../pages/my_invoice/detail_page.dart';
import '../pages/exclusive_shopping_guide/my_customer_list_page.dart';
import '../pages/exclusive_shopping_guide/employee_qrcode_page.dart';
import '../pages/goods/serial_search_page.dart';
import '../pages/mall_order/payment_record_attachments_list_page.dart';
import '../pages/mall_order/payment_record_attachments_detail_page.dart';
import '../pages/mall_order/palm_recycle_order_detail_page.dart';
import '../pages/store_management/index_page.dart';
import '../pages/storekeeper_data/seller_sales_ranking_page.dart';
import '../pages/talent_pool/talent_pool_detail_page.dart';
import '../pages/zform/zform_pages.dart';
import '../pages/transfer_order/standard_transfer_draft_page.dart';
import '../pages/transfer_order/whole_order_stocking_page.dart';
import '../pages/my_calendar/calendar_send_list_page.dart';
import '../pages/my_calendar/calendar_allow_check_list_page.dart';
import '../pages/my_calendar/calendar_expired_list_page.dart';
import '../pages/my_calendar/calendar_check_list_page.dart';
import '../pages/goods/goods_tracking_page.dart';
import '../pages/task_management/task_info_page.dart';
import '../widgets/main_scaffold.dart';

/// 安全返回方法 - 如果可以 pop 则返回上一页，否则返回首页
/// 解决全屏页面（非 ShellRoute 内）点击返回按钮时 "There is nothing to pop" 的问题
void safePop(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    context.pop();
  } else {
    context.go(Routes.home);
  }
}

/// 路由名称
class Routes {
  static const String login = '/login';
  static const String home = '/';
  static const String memberManagement = '/member-management';
  static const String memberDetail = '/member/:id';
  // 店员开单
  static const String clerkOrder = '/clerk/order';
  static const String memberExperienceEdit = '/member-experience-edit';
  static const String stockDistribution = '/stock-distribution';
  static const String order = '/order';
  static const String calendar = '/calendar';
  static const String calendarDetail = '/calendar/:id';
  static const String mallOrderList = '/mall-order';
  static const String mallOrderDetail = '/mall-order/:id';
  static const String mallOrderInfo = '/mall-order/order-info/:orderNumber';
  static const String mallOrderRecycleOrderInfo = '/mall-order/recycle-order-info/:orderNumber';
  static const String mallOrderSalesList = '/mall-order/sales-order-list';
  static const String salespersonData = '/salesperson-data';
  static const String salespersonOrderInfo = '/salesperson-data/order/:number';
  static const String salespersonRecycleOrderInfo = '/salesperson-data/recycle-order/:number';
  static const String approvalCenter = '/approval';
  static const String approvalDetail = '/approval/:id';
  // 门店零售
  static const String storeRetailEntry = '/store-retail';
  static const String storeRetailHome = '/store-retail/home/:userIdent';
  static const String storeRetailOrder = '/store-retail/order/:userIdent';
  static const String giveawaySelect = '/store-retail/giveaway-select';
  static const String storeRetailCoupons = '/store-retail/coupons/:userIdent';
  static const String storeRetailMemberInfo = '/store-retail/member-info/:userIdent';
  static const String storeRetailReturns = '/store-retail/returns/:userIdent';
  static const String storeRetailOrders = '/store-retail/orders/:userIdent';
  static const String memberLabelManagement = '/store-retail/labels/:userIdent';
  static const String salesPreference = '/store-retail/preference/:userIdent';
  // 回收订单
  static const String recycleOrderList = '/store-retail/recycle-orders';
  static const String recycleOrderDetail = '/store-retail/recycle-order/detail/:number';
  static const String recycleOrderCreate = '/store-retail/recycle-order/create/:userIdent';
  // 员工积分
  static const String employeeScore = '/employee-score';
  static const String employeeScoreDistribution = '/employee-score/distribution';
  static const String employeeScoreManagement = '/employee-score/management';
  static const String employeeScoreApply = '/employee-score/apply';
  static const String employeeScoreRanking = '/employee-score/ranking';
  static const String employeeScoreRankingDetail = '/employee-score/ranking-detail';
  static const String employeeScoreInfo = '/employee-score/info/:id';
  static const String rewardPunishmentDetails = '/employee-score/reward-punishment-details';
  // 收银日报
  static const String cashierDailyReportList = '/cashier-daily-report';
  static const String cashierDailyReportDetail = '/cashier-daily-report/detail/:deptId/:date';
  static const String cashierDailyReportCreate = '/cashier-daily-report/create';
  // 采购订单
  static const String purchaseOrderList = '/purchase-order';
  static const String purchaseOrderDetail = '/purchase-order/detail/:id';
  static const String purchaseOrderCreate = '/purchase-order/create';
  // 调拨单
  static const String transferOrderList = '/transfer-order/list';
  static const String transferOrderDetail = '/transfer-order/detail/:id';
  static const String transferOrderCreate = '/transfer-order/create';
  // 发票
  static const String invoiceList = '/invoice';
  static const String invoiceDetail = '/invoice/detail/:id';
  static const String invoiceApplication = '/invoice/application';
  static const String invoiceApplicationForm = '/invoice/application/form';
  // 库存盘点
  static const String stocktakingPlan = '/stocktaking/plan';
  static const String stocktakingWarehouses = '/stocktaking/plan/:planId/warehouses';
  static const String stocktakingMyLog = '/stocktaking/my-log';
  static const String stocktakingLogList = '/stocktaking/log-list';
  static const String stocktakingDashboard = '/stocktaking/dashboard';
  static const String stocktakingInfo = '/stocktaking/info/:id';
  static const String stocktakingDeliveryReceipt = '/stocktaking/delivery-receipt';
  static const String stocktakingList = '/stocktaking/list';
  // 商品报价单
  static const String productQuotation = '/product-quotation';
  // 门店巡店
  static const String storeInspectionList = '/store-inspection';
  // 门店巡店 - 开始巡店
  static const String storeInspectionReady = '/store-inspection/ready';
  // 门店巡店 - 记录列表
  static const String storeInspectionLogs = '/store-inspection/logs';
  // 门店巡店 - 详情
  static const String storeInspectionInfo = '/store-inspection/info/:logID';
  // 报货单
  static const String goodsRequestList = '/goods-request';
  static const String goodsRequestCreate = '/goods-request/create';
  // 岗位任务
  static const String taskManagement = '/task-management';
  static const String taskLogDetail = '/task-management/log/:id';
  static const String taskInfo = '/task-management/task-info/:id';
  static const String taskAllocationInfo = '/task-management/allocation-info/:id';
  static const String taskTemplateEdit = '/task-management/template/edit/:id?';
  // 客户生日关怀
  static const String customerBirthday = '/customer/birthday';
  // 商城活动
  static const String mallActivity = '/mall-activity';
  // 门店客流统计
  static const String passengerFlowList = '/passenger-flow';
  // 差异调整单
  static const String priceDifferenceList = '/price-difference';
  // 销售查询
  static const String salesList = '/sales';
  // 标准调拨
  static const String standardTransferList = '/standard-transfer';
  // 标准价格调整
  static const String priceAdjustmentList = '/price-adjustment';
  // 店长助手
  static const String storekeeperData = '/storekeeper-data';
  static const String storekeeperDataStoreRanking = '/storekeeper-data/store-ranking';
  static const String storekeeperDataStoreOverview = '/storekeeper-data/store-overview/:deptId';
  static const String storekeeperDataEmplSalesInfo = '/storekeeper-data/empl-sales-info';
  static const String storekeeperDataTargetGlance = '/storekeeper-data/target-glance';
  static const String storekeeperDataCapitalTurnover = '/storekeeper-data/capital-turnover';
  static const String storekeeperDataSPURanking = '/storekeeper-data/spu-ranking';
  static const String storekeeperDataSKURanking = '/storekeeper-data/sku-ranking/:spuId';
  static const String storekeeperDataAreaCompare = '/storekeeper-data/area-compare';
  static const String storekeeperDataEmployeeRanking = '/storekeeper-data/employee-ranking';
  static const String storekeeperDataMainProducts = '/storekeeper-data/main-products';
  static const String storekeeperDataMainProductsEmployee = '/storekeeper-data/main-products/employee/:productId';
  static const String storekeeperDataAnalyseMonth = '/storekeeper-data/analyse-month';
  // 任务进度组件演示
  static const String developingTaskProgress = '/storekeeper-data/task-progress-demo';
  // 优惠券
  static const String couponList = '/coupon';
  static const String couponBatchIssue = '/coupon/batch-issue';
  // 客户提醒
  static const String customerRemindList = '/customer-remind';
  static const String customerRemindDetail = '/customer-remind/detail/:id';
  // 客户回访
  static const String returnVisitList = '/return-visit';
  static const String returnVisitDetail = '/return-visit/detail/:number';
  // 掌上回收统计
  static const String palmRecycleDeptStatistics = '/palm-recycle/dept-statistics';
  static const String palmRecycleEmplStatistics = '/palm-recycle/empl-statistics';
  // 财务支出
  static const String financialExpenseList = '/financial-expense';
  static const String financialExpenseDetail = '/financial-expense/detail/:id';
  static const String financialExpenseCreate = '/financial-expense/create';
  static const String financialExpenseSettlement = '/financial-expense/settlement/:id';
  // 库存价格
  static const String inventoryPriceList = '/inventory-price';
  // 维修单
  static const String repairOrderList = '/repair-order';
  static const String repairOrderDetail = '/repair-order/:id';
  // 国补预约
  static const String appointmentBookingList = '/appointment-booking';
  static const String appointmentBookingDetail = '/appointment-booking/:id';
  // 通知中心
  static const String noticeCenter = '/notice-center';
  static const String noticeDetail = '/notice-center/detail:logId';
  // 会计凭证
  static const String accountingVoucherList = '/accounting-voucher';
  static const String accountingVoucherAudit = '/accounting-voucher/audit/:id';
  // 积分兑换
  static const String pointsRedeemOrderList = '/points-redeem-order';
  static const String pointsRedeemOrderDetail = '/points-redeem-order/detail/:id';
  // 秒杀订单
  static const String flashSaleOrderList = '/flash-sale/orders';
  static const String flashSaleOrderDetail = '/flash-sale/order/detail/:id';
  // 预售订单
  static const String preSaleOrderList = '/pre-sale/orders';
  static const String preSaleOrderDetail = '/pre-sale/order/detail/:id';
  // 门店管理 - 展位
  static const String boothList = '/store-management/booth';
  static const String boothAdd = '/store-management/booth/add';
  static const String boothEdit = '/store-management/booth/edit/:id';
  // 门店基础信息
  static const String storeBaseInfo = '/store-management/base-info';
  // 门店管理首页
  static const String storeManagementIndex = '/store-management/index';
  // 部门切换
  static const String departmentSwitch = '/store-management/department-switch';
  // 盘库操作
  static const String stocktake = '/stocktaking/take/:id';
  // 调拨单入口
  static const String transferOrderEntry = '/transfer-order';
  // 调拨出库
  static const String transferOutWarehouse = '/transfer-order/out-warehouse';
  // 调拨入库
  static const String transferInWarehouse = '/transfer-order/in-warehouse';
  // 标品采购入库
  static const String standardPurchaseInboundList = '/standard-purchase-inbound';
  static const String standardPurchaseInboundDetail = '/standard-purchase-inbound/detail/:id';
  static const String standardPurchaseInboundCreate = '/standard-purchase-inbound/create';
  // 发票助手
  static const String invoiceAssistantTaxIdQuery = '/invoice-assistant/tax-id-query';
  static const String invoiceAssistantLicenseInquiry = '/invoice-assistant/license-inquiry';
  // 我的发票申请
  static const String myInvoiceList = '/my-invoice';
  static const String myInvoiceDetail = '/my-invoice/detail/:id';
  // 专属导购
  static const String exclusiveShoppingGuideMyCustomer = '/exclusive-shopping-guide/my-customer';
  // 职员二维码
  static const String employeeQrcode = '/employee-qrcode';
  // 序列号搜索
  static const String serialSearch = '/goods/serial-search';
  // 支付记录附件
  static const String paymentRecordAttachments = '/mall-order/payment-record-attachments';
  static const String paymentRecordAttachmentDetail = '/mall-order/payment-record-attachment/:number';
  // 掌上回收单详情
  static const String palmRecycleOrderDetail = '/mall-order/palm-recycle-order/:number';
  // 员工销售排行
  static const String sellerSalesRanking = '/storekeeper-data/seller-sales-ranking';
  // 标品调拨草稿
  static const String standardTransferDraft = '/transfer-order/standard-draft';
  // 整单备货
  static const String wholeOrderStocking = '/transfer-order/whole-order-stocking';
  // 行事历 - 抄送列表
  static const String calendarSendList = '/calendar/send-list';
  // 行事历 - 待验收列表
  static const String calendarAllowCheckList = '/calendar/allow-check';
  // 行事历 - 已过期列表
  static const String calendarExpiredList = '/calendar/expired';
  // 行事历 - 我验收的列表
  static const String calendarCheckList = '/calendar/check-list';
  // 货品流转追踪
  static const String goodsTracking = '/goods/tracking/:goodsId';
  // 人才池详情
  static const String talentPoolDetail = '/talent-pool/detail';
  static const String talentPoolNew = '/talent-pool/new';
  // 电子表单
  static const String zformSubmitted = '/zform/submitted/:tableId';
  static const String zformEdit = '/zform/edit/:tableId';
}

/// 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.home,
  redirect: (context, state) async {
    // 跳过登录页本身的检查
    if (state.uri.path == Routes.login) {
      return null;
    }

    // 检查是否已登录
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('has_token') ?? false;

    // 如果未登录，跳转到登录页
    if (!isLoggedIn) {
      return Routes.login;
    }

    return null;
  },
  routes: [
    // 登录页
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginPage(),
    ),

    // 主框架
    ShellRoute(
      builder: (context, state, child) => MainScaffold(
        currentPath: state.uri.path,
        child: child,
      ),
      routes: [
        // 首页
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const HomePage(),
        ),

        // 会员管理
        GoRoute(
          path: Routes.memberManagement,
          builder: (context, state) => const MemberManagementPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return MemberDetailPage(userIdent: id);
              },
            ),
          ],
        ),

        // 修改会员经验值
        GoRoute(
          path: Routes.memberExperienceEdit,
          builder: (context, state) => const MemberExperienceEditPage(),
        ),

        // 库存分配
        GoRoute(
          path: Routes.stockDistribution,
          builder: (context, state) => const StockDistributionPage(),
        ),

        // 订单页面
        GoRoute(
          path: Routes.order,
          builder: (context, state) => const OrderPage(),
        ),

        // 店员开单
        GoRoute(
          path: Routes.clerkOrder,
          builder: (context, state) => const ClerkOrderPage(),
        ),

        // 行事历
        GoRoute(
          path: Routes.calendar,
          builder: (context, state) => const CalendarListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return CalendarDetailPage(id: id);
              },
            ),
          ],
        ),

        // 商城订单
        GoRoute(
          path: Routes.mallOrderList,
          builder: (context, state) => const MallOrderListPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return MallOrderDetailPage(orderNumber: id);
              },
            ),
          ],
        ),

        // 商城订单详情（完整版）
        GoRoute(
          path: '/mall-order/order-info/:orderNumber',
          builder: (context, state) {
            final orderNumber = state.pathParameters['orderNumber'] ?? '';
            return OrderInfoPage(orderNumber: orderNumber);
          },
        ),

        // 商城回收单详情
        GoRoute(
          path: '/mall-order/recycle-order-info/:orderNumber',
          builder: (context, state) {
            final orderNumber = state.pathParameters['orderNumber'] ?? '';
            return RecycleOrderInfoPage(orderNumber: orderNumber);
          },
        ),

        // 商城销售订单列表
        GoRoute(
          path: '/mall-order/sales-order-list',
          builder: (context, state) => const SalesOrderListPage(),
        ),

        // 商城回收单列表（复用门店零售的回收单列表）
        GoRoute(
          path: '/mall-order/recycle-order-list',
          builder: (context, state) => const RecycleOrderListPage(),
        ),

        // 销售人员数据
        GoRoute(
          path: Routes.salespersonData,
          builder: (context, state) => const SalespersonPage(),
          routes: [
            GoRoute(
              path: 'order/:number',
              builder: (context, state) {
                final number = state.pathParameters['number'] ?? '';
                return SalespersonOrderInfoPage(orderNumber: number);
              },
            ),
            GoRoute(
              path: 'recycle-order/:number',
              builder: (context, state) {
                final number = state.pathParameters['number'] ?? '';
                return SalespersonRecycleOrderInfoPage(orderNumber: number);
              },
            ),
          ],
        ),

        // 审批中心
        GoRoute(
          path: Routes.approvalCenter,
          builder: (context, state) => const ApprovalCenterPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return ApprovalDetailPage(id: id);
              },
            ),
          ],
        ),
      ],
    ),

    // 门店零售路由（不在 ShellRoute 内，全屏页面）
    GoRoute(
      path: Routes.storeRetailEntry,
      builder: (context, state) => const StoreRetailEntryPage(),
    ),
    GoRoute(
      path: Routes.storeRetailHome,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return StoreRetailHomePage(userIdent: id);
      },
    ),
    GoRoute(
      path: Routes.storeRetailOrder,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        final bookingIdStr = state.uri.queryParameters['appointmentBookingId'];
        final bookingId = bookingIdStr != null ? int.tryParse(bookingIdStr) : null;
        final bookingSkuIdStr = state.uri.queryParameters['appointmentBookingSkuID'];
        final bookingSkuId = bookingSkuIdStr != null ? int.tryParse(bookingSkuIdStr) : null;
        final redeemIdStr = state.uri.queryParameters['pointsRedeemOrderID'];
        final redeemId = redeemIdStr != null ? int.tryParse(redeemIdStr) : null;
        final redeemSkuStr = state.uri.queryParameters['pointsRedeemOrderSkuID'];
        final redeemSku = redeemSkuStr != null ? int.tryParse(redeemSkuStr) : null;
        final redeemSvcStr = state.uri.queryParameters['pointsRedeemOrderServiceID'];
        final redeemSvc = redeemSvcStr != null ? int.tryParse(redeemSvcStr) : null;
        final preSaleSkuStr = state.uri.queryParameters['preSaleOrderSkuID'];
        final preSaleSku = preSaleSkuStr != null ? int.tryParse(preSaleSkuStr) : null;
        final preSaleNumber = state.uri.queryParameters['preSaleOrderNumber'];
        final preSaleServices = state.uri.queryParameters['preSaleServices'];
        return SalesOrderPage(
          userIdent: id,
          appointmentBookingId: bookingId,
          appointmentBookingSkuId: bookingSkuId,
          pointsRedeemOrderId: redeemId,
          pointsRedeemOrderSkuId: redeemSku,
          pointsRedeemOrderServiceId: redeemSvc,
          preSaleOrderSkuId: preSaleSku,
          preSaleOrderNumber: preSaleNumber,
          preSaleOrderServices: preSaleServices,
        );
      },
    ),
    GoRoute(
      path: Routes.giveawaySelect,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return GiveawaySelectPage(
          itemKey: extra?['itemKey'] ?? '',
          skuId: extra?['skuId'] as int?,
          serviceId: extra?['serviceId'] as int?,
          itemId: extra?['itemId'] as int?,
          itemName: extra?['itemName'] as String?,
          qty: extra?['qty'] as int? ?? 1,
        );
      },
    ),
    GoRoute(
      path: Routes.storeRetailCoupons,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return CouponPacketPage(userIdent: id);
      },
    ),
    GoRoute(
      path: Routes.storeRetailMemberInfo,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return MemberInfoPage(userIdent: id);
      },
    ),
    GoRoute(
      path: Routes.storeRetailReturns,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return ReturnsPage(userIdent: id);
      },
    ),
    GoRoute(
      path: Routes.storeRetailOrders,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return AssociatedOrderPage(userIdent: id);
      },
    ),
    GoRoute(
      path: Routes.memberLabelManagement,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        final name = state.uri.queryParameters['name'] ?? '';
        return MemberLabelManagementPage(memberIdent: id, memberName: name);
      },
    ),
    GoRoute(
      path: Routes.salesPreference,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        final name = state.uri.queryParameters['name'] ?? '';
        return SalesPreferencePage(memberIdent: id, memberName: name);
      },
    ),

    // 回收订单路由
    GoRoute(
      path: Routes.recycleOrderList,
      builder: (context, state) => const RecycleOrderListPage(),
    ),
    GoRoute(
      path: Routes.recycleOrderDetail,
      builder: (context, state) {
        final number = state.pathParameters['number'] ?? '';
        return RecycleOrderDetailPage(orderNumber: number);
      },
    ),
    GoRoute(
      path: Routes.recycleOrderCreate,
      builder: (context, state) {
        final userIdent = int.tryParse(state.pathParameters['userIdent'] ?? '') ?? 0;
        return RecycleOrderCreatePage(userIdent: userIdent);
      },
    ),

    // 员工积分路由（不在 ShellRoute 内，全屏页面）
    GoRoute(
      path: Routes.employeeScore,
      builder: (context, state) => const EmployeeScoreAdjustmentPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreDistribution,
      builder: (context, state) => const DistributionPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreManagement,
      builder: (context, state) => const ManagementPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreApply,
      builder: (context, state) => const ApplyPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreRanking,
      builder: (context, state) => const RankingPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreRankingDetail,
      builder: (context, state) => const EmployeeScoreRankingDetailPage(),
    ),
    GoRoute(
      path: Routes.employeeScoreInfo,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EmployeeScoreInfoPage(applyId: id);
      },
    ),
    GoRoute(
      path: Routes.rewardPunishmentDetails,
      builder: (context, state) => const RewardPunishmentDetailsPage(),
    ),

    // 收银日报路由（不在 ShellRoute 内，全屏页面）
    GoRoute(
      path: Routes.cashierDailyReportList,
      builder: (context, state) => const CashierDailyReportListPage(),
    ),
    GoRoute(
      path: Routes.cashierDailyReportDetail,
      builder: (context, state) {
        final deptId = int.tryParse(state.pathParameters['deptId'] ?? '') ?? 0;
        final date = state.pathParameters['date'] ?? '';
        return CashierDailyReportDetailPage(departmentID: deptId, date: date);
      },
    ),
    GoRoute(
      path: Routes.cashierDailyReportCreate,
      builder: (context, state) => const CashierDailyReportCreatePage(),
    ),

    // 采购订单路由
    GoRoute(
      path: Routes.purchaseOrderList,
      builder: (context, state) => const PurchaseOrderListPage(),
    ),
    GoRoute(
      path: Routes.purchaseOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PurchaseOrderDetailPage(orderID: id);
      },
    ),
    GoRoute(
      path: Routes.purchaseOrderCreate,
      builder: (context, state) => const PurchaseOrderCreatePage(),
    ),

    // 调拨单路由
    GoRoute(
      path: '/transfer-order/list',
      builder: (context, state) => const TransferOrderListPage(),
    ),
    GoRoute(
      path: Routes.transferOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TransferOrderDetailPage(orderID: id);
      },
    ),
    GoRoute(
      path: Routes.transferOrderCreate,
      builder: (context, state) => const TransferOrderCreatePage(),
    ),

    // 发票路由
    GoRoute(
      path: Routes.invoiceList,
      builder: (context, state) => const InvoiceListPage(),
    ),
    GoRoute(
      path: Routes.invoiceDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return InvoiceDetailPage(invoiceID: id);
      },
    ),
    GoRoute(
      path: Routes.invoiceApplication,
      builder: (context, state) {
        final orderNumber = state.uri.queryParameters['orderNumber'];
        return InvoiceApplicationPage(orderNumber: orderNumber);
      },
    ),
    GoRoute(
      path: Routes.invoiceApplicationForm,
      builder: (context, state) {
        final applyType = state.uri.queryParameters['type'] ?? 'no-order';
        final orderNumber = state.uri.queryParameters['orderNumber'];
        return InvoiceApplicationFormPage(
          applyType: applyType,
          orderNumber: orderNumber,
        );
      },
    ),

    // 库存盘点路由
    GoRoute(
      path: Routes.stocktakingPlan,
      builder: (context, state) => const StocktakingPage(),
    ),
    GoRoute(
      path: Routes.stocktakingWarehouses,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['planId'] ?? '') ?? 0;
        return StocktakingWarehousesPage(planId: id);
      },
    ),
    GoRoute(
      path: Routes.stocktakingMyLog,
      builder: (context, state) => const StocktakingMyLogPage(),
    ),
    GoRoute(
      path: Routes.stocktakingLogList,
      builder: (context, state) => const StocktakingLogListPage(),
    ),
    GoRoute(
      path: Routes.stocktakingDashboard,
      builder: (context, state) => const StocktakingDashboardPage(),
    ),
    GoRoute(
      path: Routes.stocktakingInfo,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return StocktakingInfoPage(stocktakingId: id);
      },
    ),
    GoRoute(
      path: Routes.stocktakingDeliveryReceipt,
      builder: (context, state) => const StocktakingDeliveryReceiptPage(),
    ),
    GoRoute(
      path: Routes.stocktakingList,
      builder: (context, state) => const StocktakingListPage(),
    ),
    GoRoute(
      path: Routes.productQuotation,
      builder: (context, state) => const ProductQuotationPage(),
    ),
    GoRoute(
      path: Routes.stocktake,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return StocktakePage(stocktakingId: id);
      },
    ),

    // 门店巡店路由
    GoRoute(
      path: Routes.storeInspectionList,
      builder: (context, state) => const StoreInspectionListPage(),
    ),
    GoRoute(
      path: Routes.storeInspectionReady,
      builder: (context, state) => const StoreInspectionReadyPage(),
    ),
    GoRoute(
      path: Routes.storeInspectionLogs,
      builder: (context, state) => const StoreInspectionLogsPage(),
    ),
    GoRoute(
      path: Routes.storeInspectionInfo,
      builder: (context, state) {
        final logID = int.tryParse(state.pathParameters['logID'] ?? '') ?? 0;
        return StoreInspectionInfoPage(logID: logID);
      },
    ),

    // 报货单路由
    GoRoute(
      path: Routes.goodsRequestList,
      builder: (context, state) => const GoodsRequestListPage(),
    ),
    GoRoute(
      path: Routes.goodsRequestCreate,
      builder: (context, state) => const GoodsRequestCreatePage(),
    ),

    // 岗位任务路由
    GoRoute(
      path: Routes.taskManagement,
      builder: (context, state) => const TaskManagementPage(),
    ),
    GoRoute(
      path: Routes.taskLogDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TaskLogDetailPage(taskLogId: id);
      },
    ),
    GoRoute(
      path: Routes.taskInfo,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TaskInfoPage(taskId: id);
      },
    ),
    GoRoute(
      path: Routes.taskAllocationInfo,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return TaskAllocationInfoPage(allocationId: id);
      },
    ),
    GoRoute(
      path: Routes.taskTemplateEdit,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return TaskTemplateEditPage(templateId: id);
      },
    ),
    // 客户生日关怀路由
    GoRoute(
      path: Routes.customerBirthday,
      builder: (context, state) {
        final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
        final day = int.tryParse(state.uri.queryParameters['day'] ?? '');
        return CustomerBirthdayListPage(birthdayMonth: month, birthdayDay: day);
      },
    ),
    // 商城活动路由
    GoRoute(
      path: Routes.mallActivity,
      builder: (context, state) => const MallActivityListPage(),
    ),

    // 门店客流统计路由
    GoRoute(
      path: Routes.passengerFlowList,
      builder: (context, state) => const PassengerFlowListPage(),
    ),

    // 差异调整单路由
    GoRoute(
      path: Routes.priceDifferenceList,
      builder: (context, state) => const PriceDifferenceListPage(),
    ),

    // 销售查询路由
    GoRoute(
      path: Routes.salesList,
      builder: (context, state) => const SalesListPage(),
    ),

    // 标准调拨路由
    GoRoute(
      path: Routes.standardTransferList,
      builder: (context, state) => const StandardTransferListPage(),
    ),

    // 标准价格调整路由
    GoRoute(
      path: Routes.priceAdjustmentList,
      builder: (context, state) => const PriceAdjustmentListPage(),
    ),

    // 店长助手路由
    GoRoute(
      path: Routes.storekeeperData,
      builder: (context, state) => const StorekeeperDataPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataStoreRanking,
      builder: (context, state) => const StoreRankingPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataStoreOverview,
      builder: (context, state) {
        final deptId = int.tryParse(state.pathParameters['deptId'] ?? '') ?? 0;
        return StoreOverviewPage(deptId: deptId);
      },
    ),
    GoRoute(
      path: Routes.storekeeperDataEmplSalesInfo,
      builder: (context, state) {
        final deptId = int.tryParse(state.uri.queryParameters['departmentID'] ?? '') ?? 0;
        final seller = int.tryParse(state.uri.queryParameters['seller'] ?? '');
        return EmployeeSalesInfoPage(departmentId: deptId, sellerIdent: seller);
      },
    ),
    GoRoute(
      path: Routes.storekeeperDataTargetGlance,
      builder: (context, state) => const TargetGlancePage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataCapitalTurnover,
      builder: (context, state) => const CapitalTurnoverPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataSPURanking,
      builder: (context, state) => const SPURankingPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataSKURanking,
      builder: (context, state) {
        final spuId = int.tryParse(state.pathParameters['spuId'] ?? '') ?? 0;
        final spuName = state.uri.queryParameters['spuName'] ?? '';
        return SKURankingPage(spuId: spuId, spuName: spuName);
      },
    ),
    GoRoute(
      path: Routes.storekeeperDataAreaCompare,
      builder: (context, state) => const AreaDataComparePage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataEmployeeRanking,
      builder: (context, state) => const EmployeeRankingPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataMainProducts,
      builder: (context, state) => const MainProductsPage(),
    ),
    GoRoute(
      path: Routes.storekeeperDataMainProductsEmployee,
      builder: (context, state) {
        final productId = int.tryParse(state.pathParameters['productId'] ?? '') ?? 0;
        final productName = state.uri.queryParameters['productName'] ?? '';
        return MainProductsEmployeePage(productId: productId, productName: productName);
      },
    ),
    GoRoute(
      path: Routes.storekeeperDataAnalyseMonth,
      builder: (context, state) => const AnalyseMonthPage(),
    ),
    GoRoute(
      path: Routes.developingTaskProgress,
      builder: (context, state) => const DevelopingTaskProgressPage(),
    ),

    // 优惠券路由
    GoRoute(
      path: Routes.couponList,
      builder: (context, state) => const CouponListPage(),
    ),
    GoRoute(
      path: Routes.couponBatchIssue,
      builder: (context, state) => const BatchIssueCouponsPage(),
    ),

    // 客户提醒路由
    GoRoute(
      path: Routes.customerRemindList,
      builder: (context, state) => const CustomerRemindListPage(),
    ),

    // 客户回访路由
    GoRoute(
      path: Routes.returnVisitList,
      builder: (context, state) => const ReturnVisitListPage(),
    ),
    GoRoute(
      path: Routes.returnVisitDetail,
      builder: (context, state) {
        final number = state.pathParameters['number'] ?? '';
        return ReturnVisitDetailPage(number: Uri.decodeComponent(number));
      },
    ),

    // 掌上回收统计路由
    GoRoute(
      path: Routes.palmRecycleDeptStatistics,
      builder: (context, state) => const PalmRecycleDeptStatisticsPage(),
    ),
    GoRoute(
      path: Routes.palmRecycleEmplStatistics,
      builder: (context, state) => const PalmRecycleEmplStatisticsPage(),
    ),

    // 财务支出路由
    GoRoute(
      path: Routes.financialExpenseList,
      builder: (context, state) => const FinancialExpenseListPage(),
    ),
    GoRoute(
      path: Routes.financialExpenseDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return FinancialExpenseDetailPage(orderID: id);
      },
    ),
    GoRoute(
      path: Routes.financialExpenseCreate,
      builder: (context, state) => const FinancialExpenseCreatePage(),
    ),
    GoRoute(
      path: Routes.financialExpenseSettlement,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return SettlementOrderPage(expenseId: id);
      },
    ),

    // 库存价格路由
    GoRoute(
      path: Routes.inventoryPriceList,
      builder: (context, state) => const InventoryPriceListPage(),
    ),

    // 维修单路由
    GoRoute(
      path: Routes.repairOrderList,
      builder: (context, state) => const RepairOrderListPage(),
    ),
    GoRoute(
      path: Routes.repairOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return RepairOrderDetailPage(repairID: id);
      },
    ),

    // 国补预约路由
    GoRoute(
      path: Routes.appointmentBookingList,
      builder: (context, state) => const AppointmentBookingListPage(),
    ),
    GoRoute(
      path: Routes.appointmentBookingDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AppointmentBookingDetailPage(bookingID: id);
      },
    ),

    // 通知中心路由
    GoRoute(
      path: Routes.noticeCenter,
      builder: (context, state) => const NoticeCenterListPage(),
      routes: [
        GoRoute(
          path: 'detail:logId',
          builder: (context, state) {
            final logId = int.tryParse(state.pathParameters['logId'] ?? '') ?? 0;
            return NoticeDetailPage(noticeLogId: logId);
          },
        ),
      ],
    ),

    // 会计凭证路由
    GoRoute(
      path: Routes.accountingVoucherList,
      builder: (context, state) => const AccountingVoucherListPage(),
    ),
    GoRoute(
      path: Routes.accountingVoucherAudit,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AccountingVoucherAuditPage(voucherId: id);
      },
    ),

    // 积分兑换路由
    GoRoute(
      path: Routes.pointsRedeemOrderList,
      builder: (context, state) => const PointsRedeemOrderListPage(),
    ),
    GoRoute(
      path: Routes.pointsRedeemOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PointsRedeemOrderDetailPage(orderId: id);
      },
    ),

    // 秒杀订单路由
    GoRoute(
      path: Routes.flashSaleOrderList,
      builder: (context, state) => const FlashSaleOrderListPage(),
    ),
    GoRoute(
      path: Routes.flashSaleOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return FlashSaleOrderDetailPage(orderId: id);
      },
    ),

    // 预售订单路由
    GoRoute(
      path: Routes.preSaleOrderList,
      builder: (context, state) => const PreSaleOrderListPage(),
    ),
    GoRoute(
      path: Routes.preSaleOrderDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PreSaleOrderDetailPage(orderId: id);
      },
    ),

    // 门店管理 - 展位路由
    GoRoute(
      path: Routes.boothList,
      builder: (context, state) => const BoothListPage(),
    ),
    GoRoute(
      path: Routes.boothAdd,
      builder: (context, state) => const BoothOperatePage(),
    ),
    GoRoute(
      path: Routes.boothEdit,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return BoothOperatePage(caseId: id);
      },
    ),

    // 门店基础信息路由
    GoRoute(
      path: Routes.storeBaseInfo,
      builder: (context, state) => const StoreBaseInfoPage(),
    ),
    // 门店管理首页路由
    GoRoute(
      path: Routes.storeManagementIndex,
      builder: (context, state) => const StoreManagementIndexPage(),
    ),
    // 部门切换路由
    GoRoute(
      path: Routes.departmentSwitch,
      builder: (context, state) => const DepartmentSwitchPage(),
    ),

    // 调拨单入口路由
    GoRoute(
      path: Routes.transferOrderEntry,
      builder: (context, state) => const TransferOrderEntryPage(),
    ),
    GoRoute(
      path: Routes.transferOutWarehouse,
      builder: (context, state) => const TransferOutWarehousePage(),
    ),
    GoRoute(
      path: Routes.transferInWarehouse,
      builder: (context, state) {
        final num = state.uri.queryParameters['num'];
        final transferId = num != null ? int.tryParse(num) : null;
        return TransferInWarehousePage(transferId: transferId);
      },
    ),

    // 标品采购入库路由
    GoRoute(
      path: Routes.standardPurchaseInboundList,
      builder: (context, state) => const StandardPurchaseInboundListPage(),
    ),
    GoRoute(
      path: Routes.standardPurchaseInboundDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return StandardPurchaseInboundDetailPage(orderId: id);
      },
    ),
    GoRoute(
      path: Routes.standardPurchaseInboundCreate,
      builder: (context, state) {
        final preId = state.uri.queryParameters['prePurchaseOrderID'];
        final prePurchaseOrderId = preId != null ? int.tryParse(preId) : null;
        return StandardPurchaseInboundCreatePage(prePurchaseOrderId: prePurchaseOrderId);
      },
    ),

    // 发票助手路由
    GoRoute(
      path: Routes.invoiceAssistantTaxIdQuery,
      builder: (context, state) {
        final usciId = state.uri.queryParameters['usciID'];
        final preselectedId = usciId != null ? int.tryParse(usciId) : null;
        return TaxIdQueryPage(preselectedUsciId: preselectedId);
      },
    ),
    GoRoute(
      path: Routes.invoiceAssistantLicenseInquiry,
      builder: (context, state) {
        final usciId = state.uri.queryParameters['usciID'];
        final preselectedId = usciId != null ? int.tryParse(usciId) : null;
        return LicenseInquiryPage(preselectedUsciId: preselectedId);
      },
    ),

    // 我的发票申请路由
    GoRoute(
      path: Routes.myInvoiceList,
      builder: (context, state) => const MyInvoiceListPage(),
    ),
    GoRoute(
      path: Routes.myInvoiceDetail,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return MyInvoiceDetailPage(invoiceId: id);
      },
    ),
    // 专属导购路由
    GoRoute(
      path: Routes.exclusiveShoppingGuideMyCustomer,
      builder: (context, state) => const MyCustomerListPage(),
    ),
    // 职员二维码路由
    GoRoute(
      path: Routes.employeeQrcode,
      builder: (context, state) => const EmployeeQrcodePage(),
    ),
    // 序列号搜索路由
    GoRoute(
      path: Routes.serialSearch,
      builder: (context, state) => const SerialSearchPage(),
    ),
    // 支付记录附件列表路由
    GoRoute(
      path: Routes.paymentRecordAttachments,
      builder: (context, state) => const PaymentRecordAttachmentsListPage(),
    ),
    // 支付记录附件详情路由
    GoRoute(
      path: Routes.paymentRecordAttachmentDetail,
      builder: (context, state) {
        final number = state.pathParameters['number'] ?? '';
        return PaymentRecordAttachmentDetailPage(paymentDetailNumber: number);
      },
    ),
    // 掌上回收单详情路由
    GoRoute(
      path: Routes.palmRecycleOrderDetail,
      builder: (context, state) {
        final number = state.pathParameters['number'] ?? '';
        return PalmRecycleOrderDetailPage(orderNumber: number);
      },
    ),
    // 员工销售排行路由
    GoRoute(
      path: Routes.sellerSalesRanking,
      builder: (context, state) {
        final deptId = state.uri.queryParameters['departmentID'];
        return SellerSalesRankingPage(
          departmentId: deptId != null ? int.tryParse(deptId) : null,
        );
      },
    ),
    // 标品调拨草稿路由
    GoRoute(
      path: Routes.standardTransferDraft,
      builder: (context, state) => const StandardTransferDraftPage(),
    ),
    // 整单备货路由
    GoRoute(
      path: Routes.wholeOrderStocking,
      builder: (context, state) {
        final draftIdStr = state.uri.queryParameters['draftId'] ?? '';
        final draftId = int.tryParse(draftIdStr) ?? 0;
        return WholeOrderStockingPage(draftId: draftId);
      },
    ),
    // 行事历 - 抄送列表路由
    GoRoute(
      path: Routes.calendarSendList,
      builder: (context, state) => const CalendarSendListPage(),
    ),
    // 行事历 - 待验收列表路由
    GoRoute(
      path: Routes.calendarAllowCheckList,
      builder: (context, state) => const CalendarAllowCheckListPage(),
    ),
    // 行事历 - 已过期列表路由
    GoRoute(
      path: Routes.calendarExpiredList,
      builder: (context, state) => const CalendarExpiredListPage(),
    ),
    // 行事历 - 我验收的列表路由
    GoRoute(
      path: Routes.calendarCheckList,
      builder: (context, state) => const CalendarCheckListPage(),
    ),
    // 货品流转追踪路由
    GoRoute(
      path: Routes.goodsTracking,
      builder: (context, state) {
        final goodsId = int.tryParse(state.pathParameters['goodsId'] ?? '') ?? 0;
        return GoodsTrackingPage(goodsId: goodsId);
      },
    ),

    // 人才池详情路由（查看/编辑已有记录）
    GoRoute(
      path: Routes.talentPoolDetail,
      builder: (context, state) {
        final uuid = state.uri.queryParameters['uuid'] ?? '';
        return TalentPoolDetailPage(uuid: uuid);
      },
    ),
    // 人才池新建路由
    GoRoute(
      path: Routes.talentPoolNew,
      builder: (context, state) => const TalentPoolDetailPage(),
    ),
    // 电子表单 - 提交的记录列表
    GoRoute(
      path: Routes.zformSubmitted,
      builder: (context, state) {
        final tableId = int.tryParse(state.pathParameters['tableId'] ?? '') ?? 0;
        return ZFormSubmittedListPage(tableId: tableId);
      },
    ),
    // 电子表单 - 新建/编辑记录
    GoRoute(
      path: Routes.zformEdit,
      builder: (context, state) {
        final tableId = int.tryParse(state.pathParameters['tableId'] ?? '') ?? 0;
        final recordId = state.uri.queryParameters['recordId'];
        return ZFormEditPage(
          tableId: tableId,
          recordId: recordId != null ? int.tryParse(recordId) : null,
        );
      },
    ),
  ],

  // 错误处理
  errorBuilder: (context, state) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(
      middle: Text('页面不存在'),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 64,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            '页面 ${state.uri} 不存在',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: () => context.go(Routes.home),
            child: const Text('返回首页'),
          ),
        ],
      ),
    ),
  ),
);
