# L4_PH Material + Element 子程序分级清单（v0.1）

- 文档类型：执行清单
- 适用范围：`UFC/ufc_core/L4_PH`（Material、Element）
- 版本：v0.1
- 状态：启用
- 日期：2026-04-17

## 1. 使用规则

- 每个子程序必须标记：`TEMPLATE` / `WRAPPER` / `CORE`（三选一）。
- `CORE` 必须填写“关键计算段（证据）”，为空视为不合格。
- `TEMPLATE` 不得进入生产调用链（`是否生产路径` 只能为“否”）。
- 同语义多个 `WRAPPER` 时，必须填写“重复实现指向”，只保留一个主实现。

## 2. 字段说明


| 字段        | 说明                              |
| --------- | ------------------------------- |
| 域         | `Material` 或 `Element`          |
| 文件/模块     | 模块名或文件名                         |
| 子程序       | 过程名                             |
| 分级        | `TEMPLATE` / `WRAPPER` / `CORE` |
| 是否生产路径    | 是 / 否                           |
| 关键计算段（证据） | 算法核心（如返回映射、积分、装配、判据）            |
| 重复实现指向    | 若重复，指向唯一主实现                     |
| 当前判断      | 合格 / 待核查 / 不合格                  |
| 整改动作      | 合并/降级/补算法/移出生产路径                |
| Owner     | 负责人                             |
| 截止        | 日期                              |


## 3. 首批样表示例（可直接改填）


| 域        | 文件/模块                    | 子程序                          | 分级       | 是否生产路径 | 关键计算段（证据）                 | 重复实现指向                 | 当前判断 | 整改动作      | Owner | 截止  |
| -------- | ------------------------ | ---------------------------- | -------- | ------ | ------------------------- | ---------------------- | ---- | --------- | ----- | --- |
| Material | `PH_Mat_PLM_J2`          | `PH_Mat_PLM_J2_UpdateStress` | CORE     | 是      | 屈服判据 + 返回映射 + 应力更新 + 一致切线 | 无                      | 合格   | 保持单核实现    | TBD   | TBD |
| Material | `PH_Mat_Compute_UMAT`    | `PH_Mat_Compute_UMAT`        | WRAPPER  | 是      | 参数整形与下发                   | 指向 `PH_Mat_PLM_J2_*`   | 可接受  | 保持薄转发     | TBD   | TBD |
| Material | `PH_Mat_StateManagement` | `PH_Mat_State_Update`        | CORE     | 是      | statev/history 演化与边界处理    | 无                      | 合格   | 增加写回白名单注释 | TBD   | TBD |
| Material | `PH_Mat_XXX`             | `PH_Mat_XXX_Compute`         | TEMPLATE | 否      | 无                         | 应指向具体模型核               | 待核查  | 清理生产引用    | TBD   | TBD |
| Element  | `PH_Elem_*`              | `PH_Elem_Compute_Ke`         | CORE     | 是      | 刚度积分 + B 矩阵 + 积分点循环       | 无                      | 合格   | 标注积分阶与假设  | TBD   | TBD |
| Element  | `PH_Elem_*`              | `PH_Elem_Compute_Fint`       | CORE     | 是      | 内力积分与应力回代                 | 无                      | 合格   | 标注材料调用锚点  | TBD   | TBD |
| Element  | `PH_XXX_UEL`             | `PH_XXX_UEL`                 | WRAPPER  | 是      | UEL 形参适配 + 分发             | 指向 `PH_Elem_Compute_*` | 可接受  | 禁止复制算法    | TBD   | TBD |
| Element  | `PH_Elem_XXX`            | `PH_Elem_XXX_Compute`        | TEMPLATE | 否      | 无                         | 应被具体单元替换               | 待核查  | 清理生产引用    | TBD   | TBD |


## 4. 巡检门槛（v0.1）

- `TemplateLeak = 0`：生产路径中的 `TEMPLATE` 数量为 0。
- `NoAlgoCore = 0`：无关键计算段的 `CORE` 数量为 0。
- `WrapperDup` 按域持续下降：同语义 `WRAPPER` 重复数每周减少。

## 5. 执行节奏（两周）

### 第 1 周（止血）

- 完成 `L4_PH/Material` 全量标级。
- 清零 `TemplateLeak`。
- 标注全部 `CORE` 的关键计算段证据。

### 第 2 周（收敛）

- 合并重复 `WRAPPER`。
- 对“伪 CORE”执行“降级为 WRAPPER”或“补算法”二选一。
- 输出一版域内统计：`CoreRatio`、`WrapperDup`、`NoAlgoCore`。