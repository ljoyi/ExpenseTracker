# 记账 App

一个面向个人用户的 iOS 记账应用，当前按 `P0 v1.0` 需求建立工程。

## 当前工程

- 平台：iOS 17+
- 客户端：SwiftUI
- 本地数据：SwiftData
- 图表：Swift Charts
- 产品文档：[docs/README.md](docs/README.md)

当前 P0 已实现：

- Xcode 工程和共享 Scheme
- App、Core、Features、Shared、Resources 分层
- Ledger、Category、Transaction SwiftData 模型
- 默认账本和 28 个内置分类初始化
- 金额、日期区间、账单 CRUD 和统计 Service
- 首页：账本封面卡、周期选择、按日账单卡片滚动列表
- 底部导航：账单、中间加号、我的；统计从账本封面卡进入
- 独立日历页：月份切换、每日收支数字和选中日明细
- 记一笔：全屏页面、液态玻璃顶部、分类圆形图标、紧凑金额键盘、过去或未来日期时间
- 账务管理：详情、编辑、删除和二次确认
- 统计页：周期筛选、收支总览、日均支出、分类饼图和分类下钻
- Unit Test 和 UI Test Target

P0 暂未包含备注、自定义分类、趋势图、日/月报表、预算、账户和云同步。

## 打开工程

使用完整版 Xcode 打开：

```text
JiZhang.xcodeproj
```

选择 `JiZhang` Scheme 和一个 iOS 17+ 模拟器后运行。

## 命令行验证

完整安装 Xcode 并执行 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` 后，可以运行：

```bash
xcodebuild \
  -project JiZhang.xcodeproj \
  -scheme JiZhang \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

```bash
xcodebuild \
  -project JiZhang.xcodeproj \
  -scheme JiZhang \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

模拟器名称以 `xcodebuild -showdestinations` 的结果为准。
