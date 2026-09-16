# Service 接口与统计口径

## 1. 文档目标

这份文档冻结 Service 职责、输入输出、错误语义和统计公式。账单页、日历、详情页和统计页必须共享同一套口径，禁止各页面自行计算。

设计原则：

- View 只负责展示状态和接收交互。
- 所有写操作通过 Service 完成。
- 所有汇总和聚合由 StatisticsService 完成。
- 时间范围统一使用左闭右开区间。
- 金额汇总使用整数分；日均和占比这类派生结果可使用 Decimal。
- 日期计算通过 CalendarProvider 注入，测试时可以使用固定日历、时区和当前时间。

## 2. 分层职责

| 层 | 职责 | 不负责 |
| --- | --- | --- |
| View | 展示、导航、表单交互、状态切换 | 数据库写入、统计公式 |
| ViewModel | 页面状态、输入校验编排、调用 Service | 自己维护金额汇总副本 |
| Service | 业务校验、事务写入、查询聚合 | 页面布局和视觉格式 |
| ModelContext | 持久化执行 | 业务规则判断 |
| CalendarProvider | 月、日、年份和周期边界计算 | 金额和分类业务 |

简单列表读取可以使用 SwiftData 的观察式查询。新增、修改、删除、初始化和统计聚合必须通过 Service。

## 3. 核心数据传递对象

### 3.1 DateRange

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| start | Date | 包含该时刻 |
| end | Date | 不包含该时刻 |

规则：

- 所有查询满足 `start <= occurredAt < end`。
- 单日结束时间为次日开始。
- 月份结束时间为下月 1 日 00:00。
- 年份结束时为下一年 1 月 1 日 00:00。
- 自定义日期结束值按用户选择日期的下一日 00:00 处理。

### 3.2 TransactionDraft

用于新增账单。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| kind | TransactionKind | 是 | 支出或收入 |
| amountMinorUnits | Int64 | 是 | 大于 0，且不超过上限 |
| categoryID | UUID | 是 | 必须存在且类型匹配 |
| occurredAt | Date | 是 | 默认当前时间，不可晚于当前时间 |

### 3.3 TransactionPatch

用于修改账单，只提交发生变化或需要覆盖的字段。

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| kind | TransactionKind? | 否 | 修改时必须与最终分类类型一致 |
| amountMinorUnits | Int64? | 否 | 修改时重新校验金额 |
| categoryID | UUID? | 否 | 修改时重新校验分类类型 |
| occurredAt | Date? | 否 | 修改时重新校验日期 |
| note | String? | 否 | P1 预留，P0 不允许界面提交 |

### 3.4 TransactionSnapshot

Service 保存成功后返回不可变结果。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | UUID | 账单唯一标识 |
| kind | TransactionKind | 收支类型 |
| amountMinorUnits | Int64 | 实际保存金额 |
| categoryID | UUID | 分类 ID |
| occurredAt | Date | 实际保存时间 |
| createdAt | Date | 创建时间 |
| updatedAt | Date | 最后更新时间 |

### 3.5 StatisticsQuery

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| range | DateRange | 统计时间范围 |
| kind | TransactionKind? | 总览为空表示全部；分类占比必须指定 |
| categoryID | UUID? | 分类下钻时指定 |

## 4. Service 清单

### 4.1 AppBootstrapService

职责：首次初始化、默认数据检查和启动前置校验。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| prepare | 无 | BootstrapResult | 创建默认 Ledger 和 14 个内置分类 |
| validate | 无 | ValidationResult | 检查账本数量、分类完整性和关系合法性 |

行为要求：

- `prepare` 可重复调用。
- 已有完整数据时直接成功，不重复写入。
- 缺账本时创建账本。
- 缺内置分类时只补缺，不覆盖已有分类。
- 初始化失败必须返回明确错误，首次页面进入错误状态。

### 4.2 LedgerService

职责：提供 P0 默认账本。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| current | 无 | LedgerSnapshot | 返回唯一默认账本 |

P0 不提供创建、切换、重命名或删除账本的公开接口。

### 4.3 CategoryService

职责：读取分类并校验分类类型。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| list | kind | [CategorySnapshot] | 按 sortOrder 升序 |
| get | categoryID | CategorySnapshot | 不存在时返回 notFound |
| validate | categoryID, kind | 校验成功 | 必须存在且 kindRaw 匹配 |

行为要求：

- P0 不提供新增、修改、排序和删除分类的操作。
- 同一类型内按 `sortOrder` 升序返回。
- 分类查询结果必须稳定，不能依赖数据库默认顺序。

### 4.4 TransactionService

职责：新增、修改、删除和范围查询账单，是唯一的账单写入入口。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| create | TransactionDraft | TransactionSnapshot | 原子创建一笔账单 |
| update | transactionID, TransactionPatch | TransactionSnapshot | 原子更新并刷新 updatedAt |
| delete | transactionID | DeleteResult | 物理删除；重复删除视为成功 |
| query | DateRange, kind?, categoryID? | [TransactionSnapshot] | 按时间倒序返回 |
| get | transactionID | TransactionSnapshot | 用于详情页 |

创建流程：

1. 校验金额。
2. 校验发生时间。
3. 查询并校验分类。
4. 校验分类类型与账单类型一致。
5. 创建 Transaction 并建立 Ledger、Category 关系。
6. 保存 ModelContext。
7. 只有保存成功才返回结果。

修改流程：

1. 查找账单；不存在则返回 transactionNotFound。
2. 合并 Patch，形成最终完整状态。
3. 对最终类型、金额、分类、日期重新执行完整校验。
4. 更新字段和 `updatedAt`。
5. 原子保存并返回最新快照。

删除流程：

1. 查找账单。
2. 已不存在时直接返回成功，保证删除接口幂等。
3. 存在时物理删除。
4. 保存失败时恢复原状态并返回错误。

查询规则：

- `kind` 为空表示收入和支出都查询。
- `categoryID` 为空表示全部分类。
- 同时指定时，两个条件都必须满足。
- 排序为 `occurredAt` 倒序，再按 `createdAt` 倒序。

### 4.5 CalendarService

职责：把产品周期转换为统一 DateRange。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| range | PresetPeriod, customRange?, now | DateRange | 生成左闭右开区间 |
| monthRange | year, month | DateRange | 当前日历的月初到下月月初 |
| dayRange | date | DateRange | 当日开始到次日开始 |
| elapsedDays | DateRange, now | Int | 统计日均的分母 |
| monthGrid | DateRange | [CalendarDay] | 生成页面日历所需日期 |

P0 周期定义：

| 周期 | 开始 | 结束 |
| --- | --- | --- |
| 本月 | 当前月 1 日 00:00 | 下月 1 日 00:00 |
| 上月 | 上月 1 日 00:00 | 当前月 1 日 00:00 |
| 今年 | 1 月 1 日 00:00 | 明年 1 月 1 日 00:00 |
| 去年 | 去年 1 月 1 日 00:00 | 今年 1 月 1 日 00:00 |
| 近一年 | 当前日期减一年后的当日 00:00 | 明日 00:00 |
| 全部 | 最早账单所在日 00:00 | 明日 00:00 |
| 自定义 | 用户开始日期 00:00 | 用户结束日期的次日 00:00 |

没有账单时，“全部”使用今天作为唯一天范围，结果仍为全零。

### 4.6 StatisticsService

职责：计算所有统计展示值，不直接修改数据。

| 操作 | 输入 | 输出 | 主要规则 |
| --- | --- | --- | --- |
| summary | DateRange | StatisticsSummary | 收入、支出、结余、日均支出 |
| categoryBreakdown | DateRange, kind | [CategoryBreakdownItem] | 分类金额、占比和排序 |
| categoryTransactions | DateRange, kind, categoryID | [TransactionSnapshot] | 分类下钻账单 |

建议结果结构：

| 结构 | 字段 |
| --- | --- |
| StatisticsSummary | totalIncomeMinorUnits、totalExpenseMinorUnits、balanceMinorUnits、dailyAverageExpense、elapsedDays |
| CategoryBreakdownItem | categoryID、categoryName、iconName、colorHex、amountMinorUnits、share |
| CategoryBreakdownResult | kind、totalMinorUnits、items、hasData |

## 5. 统计口径

### 5.1 总支出

定义：

`总支出 = 时间范围内所有 expense 账单的 amountMinorUnits 之和`

展示：

- 始终显示正数绝对值。
- 颜色和 `-` 前缀只用于账单条目；汇总卡片显示“支出 ¥X”。
- 没有支出时为 `¥0.00`。

### 5.2 总收入

定义：

`总收入 = 时间范围内所有 income 账单的 amountMinorUnits 之和`

展示：

- 显示正数。
- 汇总卡片显示“收入 ¥X”。
- 没有收入时为 `¥0.00`。

### 5.3 结余

定义：

`结余 = 总收入 - 总支出`

规则：

- 结余可以为负数。
- 正结余显示 `+` 和收入色。
- 负结余显示 `-` 和支出色。
- 零结余显示 `¥0.00`，不强制使用收入或支出色。

### 5.4 日均支出

定义：

`日均支出 = 总支出 / 已发生自然天数`

已发生自然天数定义：

- 历史完整周期：使用周期内完整自然天数。
- 包含当前日期的周期：从周期开始日计算到当前日，包含当前日。
- 周期开始日晚于今天：天数为 0，日均支出为 0。
- 未来日期不增加分母。

计算规则：

- 使用 Decimal 计算，不使用 Double。
- 中间精度至少保留 4 位小数。
- 展示时按四舍五入保留 2 位小数。
- 分母为 0 时返回 `¥0.00`。

示例：

- 9 月 1 日至 9 月 30 日且今天是 9 月 10 日，总支出 `¥1,000.00`，日均约 `¥100.00`。
- 2026 年全年历史周期共 365 天，总支出 `¥3,650.00`，日均 `¥10.00`。

### 5.5 分类金额

定义：

`分类金额 = 指定类型和分类下所有账单的 amountMinorUnits 之和`

规则：

- 支出分类只聚合 expense。
- 收入分类只聚合 income。
- 同一账单只归入一个分类。
- 所有分类金额之和必须等于对应类型的总额。

### 5.6 分类占比

定义：

`分类占比 = 分类金额 / 对应类型总额`

规则：

- 图表使用原始精确比例绘制。
- 文字按百分数展示，四舍五入保留 1 位小数。
- 若所有分类展示值相加不等于 `100.0%`，将差值调整到金额最大的分类，仅影响显示。
- 只有 1 个分类时显示 `100.0%`。
- 总额为 0 时返回空数据，不生成 0 除计算。

示例：

| 分类 | 金额 | 精确占比 | 展示占比 |
| --- | --- | --- | --- |
| 餐饮 | ¥40.00 | 40% | 40.0% |
| 交通 | ¥30.00 | 30% | 30.0% |
| 购物 | ¥30.00 | 30% | 30.0% |

### 5.7 排序规则

分类统计排序优先级：

1. 金额从高到低。
2. 金额相同时，按 Category.sortOrder 从小到大。
3. 仍相同时，按分类名称本地化升序。
4. 最后按 UUID 字符串升序，确保结果稳定。

账单列表排序优先级：

1. `occurredAt` 从晚到早。
2. 相同时 `createdAt` 从晚到早。
3. 最后按 UUID 字符串升序。

### 5.8 数据范围

以下数据不进入统计：

- 尚未成功保存的表单数据。
- 已删除账单。
- 损坏且无法解析类型的账单。
- P1 才可能出现的不计入预算、不计入收支标记。

### 5.9 时间边界

- 使用设备当前 Calendar 和 TimeZone。
- 月份、年份和日期切换统一通过 CalendarService。
- Service 不自行拼接 `yyyy-MM` 字符串作为查询依据。
- 范围结束值始终为下一周期开始，禁止使用 23:59:59 近似。

## 6. 错误语义

| 错误 | 触发场景 | 用户可见行为 | 数据结果 |
| --- | --- | --- | --- |
| notInitialized | 默认账本或分类缺失 | 显示初始化失败，提供重试 | 无写入 |
| invalidAmount | 金额为空、为 0、超上限或精度错误 | 标记金额错误 | 无写入 |
| categoryRequired | 未选择分类 | 标记分类错误 | 无写入 |
| categoryNotFound | 分类 ID 不存在 | 提示重新选择分类 | 无写入 |
| categoryKindMismatch | 收支类型与分类不一致 | 清除分类并要求重选 | 无写入 |
| futureDateNotAllowed | 发生时间晚于当前时间 | 标记时间错误 | 无写入 |
| invalidDateRange | 自定义开始晚于结束 | 禁用确认并提示 | 无写入 |
| transactionNotFound | 修改或读取不存在的账单 | 显示记录已被删除 | 无修改 |
| persistenceFailure | 数据库保存或删除失败 | 保留当前状态，提供重试 | 回滚本次操作 |
| corruptData | 枚举或关系数据损坏 | 显示错误，不展示错误统计 | 不自动改写 |

删除接口对“记录已不存在”返回成功，不视为错误。

## 7. Service 调用边界

| 页面行为 | 可调用 Service |
| --- | --- |
| App 启动 | AppBootstrapService、LedgerService |
| 账单页按月读取 | 直接观察查询或 TransactionService.query |
| 记一笔保存 | TransactionService.create |
| 编辑保存 | TransactionService.update |
| 详情读取 | TransactionService.get |
| 删除确认后 | TransactionService.delete |
| 分类网格 | CategoryService.list |
| 月份和日期范围 | CalendarService |
| 统计总览 | StatisticsService.summary |
| 饼图与占比 | StatisticsService.categoryBreakdown |
| 分类下钻 | StatisticsService.categoryTransactions |

禁止事项：

- View 不得直接执行金额求和。
- View 不得根据当前页面缓存自行推导结余。
- 记一笔页不得直接创建 Category。
- 统计页不得读取全部账单后在 View 中分组。
- 删除和修改后不得依赖手动刷新多个独立缓存副本。

## 8. 测试口径

必须覆盖：

- 月首、月末、年初、年末和闰日边界。
- 同一实时时刻在不同月份查询中不会重复或遗漏。
- 空数据、只有收入、只有支出、结余为负。
- `0.01`、`0.10`、`99,999,999.99` 等金额边界。
- 两个分类金额相同情况下的稳定排序。
- 分类占比显示总和为 100.0%。
- 当前月日均只除以已发生天数。
- 修改类型后旧分类不再参与统计。
- 删除后总金额和分类占比立即变化。
- 1,000 条账单按月份查询、按日查询和分类聚合的性能。

## 9. Service 层完成定义

- [ ] 所有写接口都执行完整业务校验并原子保存。
- [ ] 所有读取接口返回稳定排序。
- [ ] 时间范围只通过 CalendarService 定义。
- [ ] 金额汇总只使用整数分和 Decimal。
- [ ] 统计页展示值全部来自 StatisticsService。
- [ ] 错误语义能够映射到明确页面状态。
- [ ] 修改和删除成功后，账单页与统计页读取到同一份最新数据。
- [ ] Service 可以在固定 Calendar、固定时区和内存数据库中独立测试。
