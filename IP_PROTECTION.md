# UFC 个人知识产权保护指南

> **IMPORTANT**: This document is provided for informational purposes only. It does not constitute legal advice. Consult a qualified intellectual property attorney in your jurisdiction before relying on any of the strategies described here.

---

## 一、问题背景

UFC (UniFieldCore) 是你在入职任何公司**之前**独立开发的个人项目。当你入职一家公司并可能在工作中使用 UFC 架构思想时，面临以下风险：

1. 公司可能主张你在雇佣期间对 UFC 的改进属于"职务作品"
2. 你的个人 UFC 代码库可能被污染（混入公司的工作成果）
3. 离职时可能产生知识产权归属纠纷

本文档提供一套完整的操作策略来隔离和保护你的个人知识产权。

---

## 二、三道防线

### 防线 1：入职前公开发布（建立 Prior Art）

**在入职前完成**，这是最关键的一步：

```bash
# 1. 在 GitHub 上创建公开仓库
# 2. 推送当前所有代码
git init
git add .
git commit -m "UFC v1.0: Initial public release — Unified Field Core Architecture"
git tag v1.0.0
git remote add origin https://github.com/<your-username>/ufc.git
git push -u origin main --tags
```

**为什么有效**：
- 公开的 git 历史为你建立了不可篡改的时间戳（prior art）
- Apache 2.0 许可证明确授予任何人使用、修改、分发的权利
- 公司可以使用你的开源版本，但不能主张对你的个人仓库的所有权

### 防线 2：雇佣合同 IP 条款

入职前，在劳动合同或补充协议中加入以下条款：

> **个人现有知识产权清单（附件）**
>
> 本人声明，以下项目系本人于入职前独立开发，不属于职务作品：
>
> | 项目名称 | 公开地址 | 许可证 | 说明 |
> |---------|---------|--------|------|
> | UFC (UniFieldCore) | https://github.com/<username>/ufc | Apache 2.0 | 通用有限元内核架构 |
>
> 本人在雇佣期间对该项目的任何非工作时间、非使用公司设备的改进，
> 继续归本人所有。公司可在 Apache 2.0 许可证范围内自由使用该开源版本。

**谈判要点**：
- 强调项目已公开开源，不会损害公司利益
- 公司可以在 Apache 2.0 下自由使用，甚至可以 fork 做内部版本
- 愿意为公司内部实现提供独立的架构建议（基于公开的 ARCHITECTURE_SPEC.md）

### 防线 3：物理与技术隔离

| 隔离维度 | 个人版 | 公司版 |
|---------|--------|--------|
| **代码仓库** | 个人 GitHub（公开） | 公司 GitLab/GitHub Enterprise（私有） |
| **开发设备** | 个人电脑 | 公司配发电脑 |
| **工作时间** | 非工作时间（晚上/周末） | 工作时间 |
| **项目命名** | UFC (UniFieldCore) | 不同名称（如 F-Kernel, PolyField 等） |
| **实现语言** | Fortran 90 | 可考虑 C++/Rust（增加区分度） |
| **代码来源** | 原创开发 | 仅参考 ARCHITECTURE_SPEC.md 做 Clean-Room 实现 |
| **提交者身份** | 个人 GitHub 账号 | 公司邮箱账号 |

---

## 三、Clean-Room 实现纪律

如果在公司需要基于 UFC 架构开发内部系统，严格遵守以下纪律：

### 绝对禁止（Red Lines）

1. ❌ 将个人 UFC 仓库的任何代码文件复制到公司仓库
2. ❌ 在公司设备上 clone 个人 UFC 仓库
3. ❌ 将公司开发的代码合并到个人 UFC 仓库
4. ❌ 在公司时间使用个人设备开发个人 UFC
5. ❌ 使用公司提供的任何资源（API key、许可证、数据集）开发个人 UFC

### 必须遵守（Green Rules）

1. ✅ 公司版本的开发**仅参考** `ARCHITECTURE_SPEC.md`（纯架构描述，无代码）
2. ✅ 公司版本从空仓库开始，第一个 commit 是新建的空白项目结构
3. ✅ 个人 UFC 的改进只在非工作时间、在个人设备上进行
4. ✅ 保留个人 UFC 的完整 git 历史，所有 commit 都有非工作时间的可信时间戳
5. ✅ 如果公司的实现中发现通用架构改进，将其写为 ARCHITECTURE_SPEC.md 的更新（纯描述），然后在个人时间、个人设备上实现

### 灰色地带处理

如果遇到不确定的情况，问自己：
- 这段代码是在什么时间写的？（工作时间 = 公司）
- 这段代码是在什么设备上写的？（公司设备 = 公司）
- 这段代码是为了解决什么问题？（公司业务问题 = 公司）
- 这段代码是否使用了公司专有数据/算法？（是 = 公司）

**"三不"原则**：不在公司设备上写、不在工作时间内写、不使用公司数据。

---

## 四、开源项目后续维护策略

### 入职后的维护

1. 只在个人时间、个人设备上维护
2. 不接受公司同事的 PR（避免污染）
3. 不接受在公司工作时间内产出的贡献
4. Commit 时间戳保持在晚上/周末

### 社区贡献管理

如果项目有外部贡献者，在 CONTRIBUTING.md 中添加：

```markdown
## Contributor IP Declaration

By submitting a contribution to this project, you certify that:
1. The contribution was created entirely on your own time
2. The contribution was not created using any employer's equipment, supplies, 
   facilities, or trade secrets
3. You have the right to license the contribution under Apache 2.0
```

### DCO (Developer Certificate of Origin)

要求所有提交使用 `Signed-off-by` 来建立 DCO 链：

```bash
git commit -s -m "your message"
```

---

## 五、离职时的注意事项

1. **离职前**：确保公司仓库中的所有代码提交历史清楚，没有混入个人代码
2. **离职审计**：如果公司要求签署 IP 确认文件，仔细核对其中是否涉及你的个人项目
3. **冷静期**：离职后立即检查个人仓库，确认没有需要移除的公司相关引用
4. **入职下一家**：同样需要在合同中声明 UFC 为已有个人 IP

---

## 六、文件清单

| 文件 | 用途 |
|------|------|
| `LICENSE` | Apache 2.0 许可证全文 |
| `NOTICE` | 版权声明，明确声明为个人独立创作 |
| `README.md` | 项目说明，含 IP 声明链接 |
| `ARCHITECTURE_SPEC.md` | 纯架构规格，Clean-Room 实现的唯一参考源 |
| `IP_PROTECTION.md` | 本文件 — IP 保护操作指南 |
| `CONTRIBUTING.md` | 贡献指南（含 IP 声明要求） |

---

## 七、常见问题

### Q: 如果公司说"你用了开源的 UFC，所以你的改进归公司"怎么办？

A: Apache 2.0 许可证不要求你将修改贡献回上游。你在个人时间、个人设备上做的改进是你自己的衍生作品，不属于公司。但前提是：你真的没有用公司设备、公司时间、公司数据。

### Q: 如果公司让我在工作时间基于 UFC 开发内部工具怎么办？

A: 你可以为公司做一个 Clean-Room 实现（基于 ARCHITECTURE_SPEC.md 从头写），这个实现归公司所有。你个人 UFC 仓库不受影响。两个代码库完全独立。

### Q: 架构思想本身能保护吗？

A: 纯粹的架构思想/方法论通常不受版权保护（但可能涉及专利）。这就是为什么要开源代码本身（版权保护）+ 用 ARCHITECTURE_SPEC.md 公开描述架构（确保它成为公开知识，而非商业秘密）。

### Q: 公司能不能禁止我维护开源项目？

A: 取决于合同条款。有些公司有"不得从事副业"或"所有发明归公司"的条款。这就是为什么**入职前**就要在合同中把 UFC 列为现有 IP 例外。如果已经入职且有不利条款，需要与法务/HR 协商修改。

---

*最后更新：2026-05-18*
*本文件不构成法律建议。请咨询知识产权律师。*
