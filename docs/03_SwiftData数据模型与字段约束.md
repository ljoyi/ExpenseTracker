# SwiftData 数据模型与字段约束

## 1. 文档目标

这份文档冻结 P0 的本地数据结构和业务约束，作为 SwiftData Model、初始化数据、查询和测试的共同依据。

设计目标：

- 支撑“记账、回看、修改、删除、统计”完整闭环。
- 保证金额计算精确，不使用浮点数。
- 保证账单与分类类型始终一致。
- 为 P1 的备注、自定义分类、账户和多账本保留低风险扩展空间。
- P0 不持久化可由明细推导出的汇总字段，避免多份数据不一致。

## 2. 数据关系

```text
┌──────────────┐
│ Ledger       │
│ 默认账本      │
└──────┬───────┘
       │ 1 : N
       ▼
┌──────────────┐        N : 1        ┌────────────────┐
│ Transaction  │────────────────────>│ Category       │
│ 收入/支出账单 │                     │ 内置分类        │
└──────────────┘                     └────────────────┘
```

P0 虽然只有一个默认账本，但仍保留 `Ledger` 实体。这样 P1 增加多账本时不需要重构所有账单关系。

## 3. SwiftData 模型清单

### 3.1 Ledger

表示一个账本。P0 固定只存在一个可用账本。

| 字段 | Swift 类型 | 可空 | 默认值 | 约束与说明 |
| --- | --- | --- | --- | --- |
| id | UUID | 否 | 新建 UUID | 主唯一标识，创建后不可修改 |
| name | String | 否 | “我的账本” | 去除首尾空格后长度为 1-30 个字符 |
| createdAt | Date | 否 | 当前时间 | 创建后不可修改 |
| updatedAt | Date | 否 | 当前时间 | 名称变更时更新 |
| transactions | [Transaction] | 否 | 空数组 | 与 Transaction 的一对多关系 |

SwiftData 关系规则：

- `id` 使用唯一属性约束。
- 删除 Ledger 时级联删除其所有 Transaction。
- P0 不提供删除 Ledger 的入口。
- P0 查询默认 Ledger 时按 `createdAt` 升序取得第一条；初始化逻辑必须保证只有一条。

### 3.2 Category

表示内置的支出或收入分类。

| 字段 | Swift 类型 | 可空 | 默认值 | 约束与说明 |
| --- | --- | --- | --- | --- |
| id | UUID | 否 | 新建 UUID | 主唯一标识，创建后不可修改 |
| name | String | 否 | 无 | 去除首尾空格后长度为 1-12 个字符 |
| kindRaw | String | 否 | 无 | 只允许 `expense` 或 `income` |
| iconName | String | 否 | 无 | 必须是可解析的 SF Symbol 名称 |
| colorHex | String | 否 | 无 | 格式必须为 `#RRGGBB` |
| sortOrder | Int | 否 | 无 | 同一类型内非负，建议以 10 为步长 |
| isBuiltIn | Bool | 否 | `true` | P0 全部为 true |
| createdAt | Date | 否 | 当前时间 | 创建后不可修改 |
| updatedAt | Date | 否 | 当前时间 | P0 创建后不更新 |
| transactions | [Transaction] | 否 | 空数组 | 与 Transaction 的一对多关系 |

业务唯一性：

- `(kindRaw, name)` 必须唯一。
- `(kindRaw, sortOrder)` 必须唯一。
- `id` 必须唯一。

删除规则：

- P0 不允许删除分类。
- 即使 P1 开放删除，已被账单引用的分类也不能直接删除。
- 分类只能关联同类型的账单。

### 3.3 Transaction

表示一笔收入或支出。

| 字段 | Swift 类型 | 可空 | 默认值 | 约束与说明 |
| --- | --- | --- | --- | --- |
| id | UUID | 否 | 新建 UUID | 主唯一标识，创建后不可修改 |
| kindRaw | String | 否 | `expense` | 只允许 `expense` 或 `income` |
| amountMinorUnits | Int64 | 否 | 无 | 金额按“分”存储，范围 `1...9_999_999_999` |
| occurredAt | Date | 否 | 当前时间 | 用户选择的实际发生日期和时间 |
| note | String? | 是 | `nil` | P1 预留字段，P0 界面不采集 |
| createdAt | Date | 否 | 当前时间 | 创建后不可修改 |
| updatedAt | Date | 否 | 当前时间 | 每次修改时更新 |
| ledger | Ledger | 否 | 无 | 每笔账单必须属于一个账本 |
| category | Category | 否 | 无 | 每笔账单必须属于一个分类 |

SwiftData 关系规则：

- `id` 使用唯一属性约束。
- `ledger` 与 `Ledger.transactions` 互为反向关系。
- `category` 与 `Category.transactions` 互为反向关系。
- Ledger 删除时 Transaction 级联删除。
- Category 使用拒绝删除或等效保护规则，不能被已有账单引用时删除。
- Transaction 删除采用物理删除，不增加 `isDeleted` 软删除字段。

业务约束：

- `amountMinorUnits` 必须大于 0。
- 展示金额时始终为绝对值；收入使用 `+`，支出使用 `-`。
- `kindRaw` 必须与 `category.kindRaw` 完全一致。
- `occurredAt` 允许选择过去或当前时间；P0 默认不允许未来时间。
- `note` 若未来启用，最多 100 个字符并去除首尾空格。
- `createdAt`、`updatedAt` 由 Service 统一维护，界面不能直接覆盖。

## 4. 枚举定义

### 4.1 TransactionKind

| 枚举值 | Raw Value | 展示名称 | 金额方向 |
| --- | --- | --- | --- |
| expense | `expense` | 支出 | 负向 |
| income | `income` | 收入 | 正向 |

约束：

- Raw Value 一旦发布不可修改。
- 未知 Raw Value 视为数据损坏，读取时进入错误状态，不能静默转换为支出。

### 4.2 CategoryKind

分类使用与 TransactionKind 相同的两个 Raw Value。

约束：

- 账单类型切换时，原分类必须清除。
- 保存前必须重新检查分类类型，避免并发状态或旧界面数据造成不一致。

## 5. 首次初始化数据

### 5.1 初始化顺序

初始化必须在一个逻辑事务中完成：

1. 查询是否已存在 Ledger。
2. 若存在，校验默认分类是否完整。
3. 若不存在，创建“我的账本”。
4. 创建全部支出分类。
5. 创建全部收入分类。
6. 只有全部写入成功后才把初始化标记为完成。

若中途失败，下次启动可以重新执行；重复执行不能创建重复账本或重复分类。

### 5.2 默认支出分类

| 排序 | 名称 | SF Symbol | 颜色建议 |
| --- | --- | --- | --- |
| 10 | 餐饮 | `fork.knife` | `#E76F51` |
| 20 | 交通 | `car.fill` | `#2A9D8F` |
| 30 | 购物 | `cart.fill` | `#E9C46A` |
| 40 | 居住 | `house.fill` | `#457B9D` |
| 50 | 娱乐 | `gamecontroller.fill` | `#9B5DE5` |
| 60 | 医疗 | `cross.case.fill` | `#F15BB5` |
| 70 | 通讯 | `phone.fill` | `#00A8E8` |
| 80 | 其他 | `ellipsis.circle.fill` | `#6C757D` |

### 5.3 默认收入分类

| 排序 | 名称 | SF Symbol | 颜色建议 |
| --- | --- | --- | --- |
| 10 | 工资 | `banknote.fill` | `#2A9D8F` |
| 20 | 奖金 | `gift.fill` | `#F4A261` |
| 30 | 兼职 | `briefcase.fill` | `#457B9D` |
| 40 | 理财 | `chart.line.uptrend.xyaxis` | `#43AA8B` |
| 50 | 红包 | `envelope.fill` | `#E76F51` |
| 60 | 其他 | `ellipsis.circle.fill` | `#6C757D` |

### 5.4 初始化幂等规则

- 以 `isBuiltIn`、`kindRaw` 和稳定名称识别内置分类。
- 缺失的内置分类可以补齐。
- 已存在的内置分类不重复创建。
- 不覆盖用户未来修改过的颜色、图标或排序，除非产品明确要求恢复默认。

## 6. 查询约束

### 6.1 账单页

- 月度查询范围：`monthStart <= occurredAt < nextMonthStart`。
- 日期查询范围：`dayStart <= occurredAt < nextDayStart`。
- 排序：`occurredAt` 倒序，若完全相同则 `createdAt` 倒序。
- 每日卡片只由该月实际存在的 Transaction 分组生成。
- 月度概要基于同一月份范围内的全部 Transaction 计算。

### 6.2 统计页

- 所有范围查询统一使用左闭右开时间区间。
- 分类统计先按 `kindRaw` 过滤，再按 `category.id` 聚合。
- 分类账单明细必须同时限定时间范围、收支类型和分类。
- 同一时间范围在账单页和统计页使用相同边界规则。

### 6.3 数据量假设

- 首年单账本账单目标不超过 20,000 条。
- P0 验收基线为 1,000 条账单。
- 不为每条账单维护持久化汇总，统计按需计算。
- 查询时避免逐条读取关系对象；应按分类或金额进行聚合后再生成展示模型。

## 7. 数据一致性与并发

- 所有写入通过 Service 执行，View 不直接构造或修改 `Transaction`。
- ModelContext 的使用应限制在明确的执行上下文中，避免多个上下文同时写入同一记录。
- 一次新增、修改或删除必须作为单个保存操作提交。
- 删除分类、删除账本等未开放操作不能通过临时调试入口进入生产环境。
- 保存失败时回滚本次修改，用户输入由页面状态保留。
- 统计结果只读取已成功保存的数据。

## 8. 字段与界面映射

| 数据库字段 | 记账页 | 账单卡片 | 详情页 | 统计页 |
| --- | --- | --- | --- | --- |
| kindRaw | 支出/收入切换 | 金额正负和颜色 | 类型 | 支出/收入筛选 |
| amountMinorUnits | 金额键盘 | 金额 | 主金额 | 汇总与聚合 |
| occurredAt | 日期时间选择 | 日期分组和时间 | 日期时间 | 时间范围过滤 |
| category | 分类网格 | 分类名称和图标 | 分类名称 | 分类聚合和占比 |
| ledger | 不可见 | 不可见 | 不可见 | 数据范围 |
| note | P0 不展示 | P0 不展示 | P0 不展示 | P0 不参与 |
| createdAt | 不展示 | 同日排序辅助 | 不展示 | 不参与统计 |
| updatedAt | 不展示 | 不展示 | 不展示 | 不参与统计 |

## 9. 迁移策略

P0 基线：

- 将当前三实体结构作为 Schema V1。
- 初始化后记录 Schema Version，防止未来误判。

V1 后的兼容原则：

- 新增可选字段优先，避免必须填充默认值。
- 不修改已有枚举 Raw Value。
- 不删除仍在使用中的字段。
- 重命名字段必须提供显式迁移。
- 多账本、账户、预算和备注等 P1/P2 功能只能增加新实体或可选关系，不能改变 P0 含义。

不建议在 P0 实现迁移框架；但所有字段命名和关系应避免明显的一次性设计。

## 10. 数据层验收

- [ ] 首次启动只创建一个 Ledger。
- [ ] 首次启动完整创建 14 个内置分类。
- [ ] 初始化重复执行不会产生重复账本或重复分类。
- [ ] 任意 Transaction 都有 Ledger、Category 和合法金额。
- [ ] Transaction 与 Category 的收支类型始终一致。
- [ ] 金额在数据库、编辑页、列表和统计之间转换无精度损失。
- [ ] 删除 Transaction 后不会被任何查询重新统计。
- [ ] 修改 Transaction 后 `updatedAt` 更新，`createdAt` 不变。
- [ ] App 重启后模型关系和查询结果保持一致。
- [ ] 1,000 条数据下月份查询和分类聚合满足性能要求。
