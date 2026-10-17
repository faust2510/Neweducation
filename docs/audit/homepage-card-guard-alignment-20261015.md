# 首页卡片可见性与控制器守卫对齐（藏卡）— 取证报告（2026-10-15）

治疗对象：`docs/audit/homepage-ux-diagnosis.md` 的 D1 / D8 ——「卡片显示得出来、点下去静默弹回」。
口径：**以控制器守卫为准收敛可见性**；不改守卫判定、不放开权限、不给任何角色新开权限；改动只落在
「卡片清单的可见性过滤」上，**未动路由注册**。

## 1. 三处点不通的入口（改前实测，2026-10-15）

四角色 + admin + 空档案账号，对 `/my/home` 首屏**每一个** `<a href>` 逐个 GET（带 session，
`NO_PROXY=localhost,127.0.0.1`），记录状态码与 `Location`：

| 角色 | 卡片文案 | href | 出现处 | 守卫（文件:行号） | 改前实测 |
|---|---|---|---|---|---|
| 教务 backoffice@local / admin | 打卡统计「学生每日打卡情况统计」 | `/checkins/stats` | 常用应用置顶条（`batch2.py` `_FAV_PRESETS['faculty']`） | `custom_addons/edu_life/controllers/life.py:466-474`（`if not fac: return redirect('/my/home')`） | 303 → `/my/home` |
| 教务 / admin | 打卡统计「查看学生每日打卡情况」 | `/checkins/stats` | 工作台宫格（`batch2.py` `_teacher_dashboard()`） | 同上 | 303 → `/my/home` |
| 教务 / admin | 报销申请「垫付的书费/车费/活动费申请报销」 | `/my/reimburse/apply` | 工作台宫格（`batch2.py` `_teacher_dashboard()`） | `custom_addons/edu_portal/controllers/fees.py:231-236`（`if not student and not fac: redirect('/my/home')`） | 303 → `/my/home` |
| 家长 parent@local | 请假「处理休假请求和缺勤」 | `/my/time_off` | 侧栏导航（`views/edu_portal_templates.xml`）+ 宫格「个人与设置」（`batch2.py` `portal_personal_category`） | `custom_addons/edu_portal/controllers/batch3.py:876-900`（家长 → 303 `/my/child`） | 303 → `/my/child` |

说明：`/checkins/stats` 的守卫**在 edu_life 不在 edu_portal**（`edu_life` 也注册了该路由），只读核对即可，
本轮未改该文件。第 4 条是同页**有意分流**（`batch3.py` 注释写明「不应改成 200」，家长在本页没有可用表单），
所以处置是「不作为可点入口出现」，而不是改守卫。

## 2. 处置（全部为「卡片可见性过滤」，逐条）

| # | 文件:行号（改后） | 处置 |
|---|---|---|
| 1 | `custom_addons/edu_portal/controllers/batch2.py:387-395` | 新增 `_FACULTY_ONLY_CARDS = ['checkins/stats']`（名单 + 口径注释） |
| 2 | `custom_addons/edu_portal/controllers/batch2.py:398-405` | 新增 `_PARENT_HIDDEN_CARDS = ['my/time_off']`（名单 + 口径注释） |
| 3 | `custom_addons/edu_portal/controllers/batch2.py:806-810` | 宫格 `cards()` 内新增 `if is_parent and href in _PARENT_HIDDEN_CARDS: continue` |
| 4 | `custom_addons/edu_portal/controllers/batch2.py:1958-1965` | 打卡统计卡包进 `if fac:`（无教师档案的账号不出） |
| 5 | `custom_addons/edu_portal/controllers/batch2.py:1975-1983` | 报销申请卡包进 `if fac:`（本函数只在 `not student` 分支被调用 ⇒ 判据退化为 `fac`） |
| 6 | `custom_addons/edu_portal/controllers/batch2.py:2040-2045` | `fav_cards` 预设过滤：`[c for c in _build_favorites('faculty') if fac or c.get('app_href') not in _FACULTY_ONLY_CARDS]` |
| 7 | `custom_addons/edu_portal/views/edu_portal_templates.xml:255-260` | 侧栏「请假」加 `t-if="not b11_par"`（`b11_par` 定义在同文件 line 15；不删元素、不动其他角色判据） |

未改：`edu_life/controllers/life.py`、`edu_portal/controllers/fees.py`、`batch3.py`、任何路由注册、
`scripts/check_*.py`、`docs/` 既有结论性文件。

## 3. 改后逐卡实测（状态码，2026-10-15）

| 角色 | 卡片 | href | 处置 | 改后实测 |
|---|---|---|---|---|
| faculty | 打卡统计（宫格 + 置顶条） | `/checkins/stats` | 保留 | 页面上 ×2，实测 **200** |
| faculty | 报销申请 | `/my/reimburse/apply` | 保留 | 页面上 ×1，实测 **200** |
| faculty | 请假 | `/my/time_off` | 保留 | 页面上 ×2，实测 **200** |
| stu | 报销申请 | `/my/reimburse/apply` | 保留（学生专属名单只对非学生生效） | 页面上 ×1，实测 **200** |
| stu | 请假 | `/my/time_off` | 保留 | 页面上 ×3，实测 **200** |
| parent | 我的孩子（替代路径） | `/my/child` | 保留 | 页面上 ×2，实测 **200** |
| parent | 请假 | `/my/time_off` | **移除** | 页面上 0 处；直连仍 303 → `/my/child`（守卫未动） |
| backoffice / admin | 打卡统计 | `/checkins/stats` | **移除** | 页面上 0 处；直连仍 303 → `/my/home`（守卫未动） |
| backoffice / admin | 报销申请 | `/my/reimburse/apply` | **移除** | 页面上 0 处；直连仍 303 → `/my/home`（守卫未动） |
| backoffice / admin | 请假 | `/my/time_off` | 保留 | 页面上 ×1，实测 **200** |

判据：「**可见即点得通**」——首屏出现的入口，逐个 GET 全部 200（唯一例外见 §5 的 `/login`）。

## 4. href 集合对账（两档 × 6 对象，LOST 必须为 0）

口径：`docs/audit/homepage-ui-visual-acceptance.md` §6.1 —— `#wrapwrap a[href]` 且锚文本非空、排除 `#`/`javascript:`，
按空格/标点归一化，**多重集**（记录 href → 锚文本）。BASE = 改动前，REV = 改动后，同一探针同一口径。

| 对象 \ 视口 | desktop 1440×900 | phone 360×640 |
|---|---|---|
| guest `/` | base 64 → rev 64，**LOST 0 / ADDED 0** | 64 → 64，**LOST 0 / ADDED 0** |
| stu `/my/home` | 143 → 143，**LOST 0 / ADDED 0** | 143 → 143，**LOST 0 / ADDED 0** |
| parent `/my/home` | 104 → 102，LOST 2（`/my/time_off` ×2，**即目标卡**） | 同左 |
| faculty `/my/home` | 113 → 113，**LOST 0 / ADDED 0** | 113 → 113，**LOST 0 / ADDED 0** |
| backoffice `/my/home` | 97 → 94，LOST 3（`/checkins/stats` ×2 + `/my/reimburse/apply` ×1，**即目标卡**） | 同左 |
| empty `/my/home` | 198 → 198，**LOST 0 / ADDED 0** | 198 → 198，**LOST 0 / ADDED 0** |

**LOST 合计 10，全部是本次要打消的目标卡实例；非目标 LOST = 0；ADDED = 0**（本轮无 skip-link /
empty_home 抖动类新增，churn 0.0）。12 行（6 对象 × 2 档）逐行对账，无一项丢失预期外入口。

## 5. 未做与未验证（不许估算）

- **窗口宽度不可观测**：探针是 DOM 式提取，360 与 1440 得到同一多重集（响应式/offcanvas 副本在 DOM 里存在、
  只是 CSS 隐藏）⇒ 「两档读数相同」是**工具性质**，不是「两档真的样」。视觉层面的两档差异**未验证**。
- 提取器读数相对 §7.6 记录的 REV 数字在 stu/parent/faculty/backoffice 上**各少 1**（143/113/113/97 vs
  144/114/114/98；guest 与 empty 完全一致）。这是**口径细节差**（对锚文本/`#wrapwrap` 的选择），本次
  BASE↔REV 用同一提取器 ⇒ 对账结论不受影响；该 ±1 的成因**未验证**。
- 每个角色首屏仍有 **1 类非 200**：`/login` ×2 → 303（`/my/home` 或 `/apps`）。它对**所有角色（含未登录 guest）
  一律存在**、与本次改动无关、改前改后一致，本轮**未处置**（属另行议题，不在 D1/D8 范围）。
- empty_home（uid=820）的 15 条 `/my/study/<id>` → 303 `/my/study`，是**数据依赖的实时抖动**（改前改后
  完全相同）；按委托口径属「已知允许」，本轮**未处置**。
- 数据结构变更：无。故**未涉及** `init()` 迁移 / savepoint / `information_schema` 检查。
- 部署：**未跑**任何部署命令（本仓无生产凭据）。
- `docs/audit/README.md` 的「份数」在我动手前已漂移：表头写 65，实测（表头自带的复核命令）
  为 **69**（本报告落盘后 **70**）。我只按实测值把表头更正为 `2026-10-15 / 70` 并把本报告登记进
  「其他（29→30 份）」，**未**去逐个补登那 4 份别人新增且未登记的文件（不属本轮范围，也未核实其归属）。

## 6. 门禁与闭环

- `bash scripts/safe_upgrade.sh edu_portal` → **EXIT=0**，无 Traceback、无 CRITICAL
  （日志 `/tmp/edu19_upgrade.20261015-164511.log`；`grep -ci "traceback\|CRITICAL"` = 0）。
- 四角色冒烟：见 §3（backoffice 与 parent 首屏逐卡实测）。
- `python3 scripts/check_english.py` → **EXIT=0**，汇总行 `TOTAL must-fix = 0 条 / brand = 0 条 /
  路由状态违规 = 0 条 / 夹具残留 = 0 条`。
- 回归保险（全部 EXIT=0）：`check_qweb_dict_foreach` / `check_recordset_none` / `check_shell_exitcode` /
  `check_manifest_order` / `check_manifest_tracking` / `check_alias_not_extended` / `check_ui_surface` /
  `check_po_sanity` / `check_docs_index` / `check_odoo_trace`。

### 取证脚本（临时，未入库）

- 逐卡状态探针：逐角色登录取 session，对 `/my/home` 上每个 `<a href>` 发一次 GET 并把 `redirect_url`
  记下来；同时输出非 200 项的 href / 出现次数 / 锚文本。
- href 多重集提取器：playwright（`--no-proxy-server`）登录取 cookie 后，两档视口抓 `#wrapwrap a[href]`，
  输出 href → 锚文本的多重集与落地 URL，供 BASE↔REV 多重集相减。

---

## 7. Lead 独立复核（2026-10-15 16:5x，不采信实施方自述）

**方式**：不跑实施方的探针，另写一份独立探针（`urllib` + `CookieJar` 各自登录、`NO_PROXY=localhost,127.0.0.1`），对四角色分别测两项——「`/my/home` 页面内这三个 href 各出现几次」与「直连（不带 referer）落到哪里」。

| 角色 | `/my/home` | `/checkins/stats` | `/my/reimburse/apply` | `/my/time_off` | 直连落点（三个 href） |
|---|---|---|---|---|---|
| `backoffice@local` | 200 | **0** | **0** | 1 | → `/my/home` 200 · → `/my/home` 200 · → `/my/time_off` **200** |
| `parent@local` | 200 | 0 | 0 | **0** | → `/my/home` 200 · → `/my/home` 200 · → `/my/child` 200（303 分流，守卫未动） |
| `faculty@local` | 200 | **2** | **1** | 2 | → `/checkins/stats` 200 · → `/my/reimburse/apply` 200 · → `/my/time_off` 200 |
| `stu@local` | 200 | 0 | **1** | 3 | → `/my/checkins` 200 · → `/my/reimburse/apply` 200 · → `/my/time_off` 200 |

**结论**：① 三个 href 在四个角色上「页面内出现的每一处」直连均为 **200**——唯一例外是家长 `/my/time_off`，正是本轮**有意移除**的那条，其直连仍 303 → `/my/child`，证明**守卫判定未被放宽**、只收敛了可见性；② 教师侧三张卡**全部保留且可进**（藏卡没有误杀）；③ 逐格与实施方报告一致。

**diff 逐行核**：`git show 7f3543c` 全文 64 行，改动只落在 `custom_addons/edu_portal/controllers/batch2.py`（两张名单 + `if fac:` 两处包卡 + `fav_cards` 过滤）与 `custom_addons/edu_portal/views/edu_portal_templates.xml:260` 的一个 `t-if="not b11_par"`；`fees.py` / `life.py` / `batch3.py` / `security/` 在本提交中**零改动**；`b11_par` 定义在同文件 line 15（变量存在，非未定义引用）。

**门禁复跑**：AGENTS.md §4 的 16 条命令在本提交后**全 rc=0**（含 `check_view_xpath` RESULT=OK）。

**跨页面复核**（承实施方补充证据，Lead 未另测）：`/my/apps` 上 backoffice 的两个 href 与 parent 的 `/my/time_off` 同样为 0 —— 与「同一套 `_home_categories` + 同一侧栏模板」的结构判断一致。`/my/apps` 的**壳层**问题由单独立的一轮处置，不在本报告范围。

**Lead 未复核的**：两档视觉差异（实施方已自陈为 DOM 式提取的工具性质 ⇒ 未验证）；提取器与验收文档 §7.6 的 ±1 口径差（成因未验证）；`/login` ×2→303 与 `empty_home` 的 `/my/study/<id>` 抖动（双方都判为既有现象，未处置）。三项均**不写估算**。
