# D2 修复取证：`/my/apps` 按角色渲染壳层（不再套学生首页壳）

> 出具：2026-10-15 ｜ 缺陷编号 **D2**（`docs/audit/homepage-ux-diagnosis.md:25`、`:158`、`:120`）
> 改动范围：`custom_addons/edu_portal/` 两文件（控制器渲染点 + 新增宫格模板）；本报告为新增取证。
> 环境：docker compose 项目 `edu19-clone`（容器 `edu19-clone-web-1` = odoo:19，`edu19-clone-db-1`，库 `edu19`，站点 `http://localhost:8069`）。
> 账号口令统一 `demo123`：`stu@local` / `faculty@local` / `backoffice@local` / `parent@local`。
> 所有本地探针均带 `NO_PROXY=localhost,127.0.0.1`（macOS 代理会让探针得到假 502）。

## 0. 一句话结论

`/my/apps` 改由**宫格专用壳** `edu_portal.edu_apps_grid` 渲染（角色页头带 + 分类卡 + 侧栏），
不再复用学生首页壳 `edu_dashboard_v2`；教务/管理员这一页**不再出现**学生的问候语、副标题、角色胶囊「学生」
与两张永远为空的考勤图表；可见 h1 由「2 个（1 可见）」收敛为**恰好 1 个且可见**；
可见 `a[href]` 多重集在两档视口下 **LOST=∅、ADDED=∅**；
`[data-fav-grid]` 收藏契约结构不变、收藏编辑按钮**实测可用**（点击进入编辑态、无 JS 报错）。

## 1. 病灶复述（改前实测，非推断）

`/my/apps` 由 `custom_addons/edu_portal/controllers/batch2.py:2188`（**改前**行号；改后为 `:2192-2193`）渲染
`edu_portal.edu_dashboard_v2`（学生首页壳）。改前 `backoffice@local` 打开该页实测到：

- 可见 h1 是 `👋 欢迎回来，教务专员`（学生首页问候语），DOM 里另有 1 个隐藏的 `欢迎 教务专员`（迷你头部）⇒ **可见 1 / DOM 2**；
- 副标题写着 `所有学习所需尽在一处——快速访问您的记录、课程与服务。`；
- 角色胶囊 `span.yy-head-role` 写着 **「学生」**：v2 的胶囊（`custom_addons/edu_portal/views/batch2.xml:747-753`）只有 `parent` → 家长 / `faculty` → 教师 两个分支，
  其余一律落 `t-else` = 学生（该处原注释自述「本页只服务 学生/家长/教师 三类」）⇒ 教务账号被叫成学生；
- 挂着两张图表 `出勤趋势` / `考勤`，两张都是空态（`暂无出勤记录，产生考勤后这里会显示近 6 个月趋势` / `暂无考勤统计`）；
- 同账号 `/my/home` 是另一套壳（`edu_dashboard_teacher`）⇒ 同一账号两页两套语言，正是 D2 记的「雷同 + 错位」。

## 2. 取证方法（可复现）

探针 = Playwright（chromium）逐角色 × 逐视口（**1440** / **360**）访问 `/my/apps`，全程 `NO_PROXY=localhost,127.0.0.1`：

1. 先 `GET /web/login`，用 `input[name=login]` / `input[name=password]` 填表后 `press(Enter)`
   （**不要点 `button[type=submit]`**：会命中顶栏搜索按钮而超时）；
2. `page.goto('/my/apps')`；记录 HTTP 状态、最终 URL、`document.title`、`h1` 文本与其可见性；
3. 「可见」判定不是看 DOM 里有没有，而是逐个元素
   `getBoundingClientRect()` 宽高 > 0 **且** `getComputedStyle` 的 `display!=='none' && visibility!=='hidden'` ⇒ 两档视口的差异能被真实量出；
4. 壳层元素按选择器计数：`.yy-head.oe-portal-hero` / `.oe-portal-hero` / `.oe-mhead` / `.oe-greeting` / `.oe-subtitle` /
   `span.yy-head-role` / `aside#b11-side, .oe-sidebar` / `.b11-tab` / `[data-fav-grid]` / `#oe_stats_slot` / `.oe-mhero` /
   `#oe_charts_row` / `#accountOffCanvas` / `#portal_alert_category` 等；
5. `a[href]` **多重集**：`{href: 次数}`，分 `a_dom`（全部）与 `a_vis`（可见）两套；改前改后逐视口做多重集差集 ⇒ LOST / ADDED；
6. 逐 href 可达性：同一登录会话内对每个可见 http(s) href 发一次 `GET`，记录状态码；
7. 收藏契约功能测试：点 `.ux-fav-category .ux-fav-edit-toggle`，断言
   `[data-home-role]` 上出现 `ux-fav-editing` 类、按钮 `active`、页内 `[data-fav-act]` 控件被注入，并收集 `pageerror`。

> 原始探针 JSON（易失，未入库）：`/tmp/apps_probe_baseline.json`、`/tmp/apps_probe_after.json`、
> `/tmp/apps_redirect_baseline.json`、`/tmp/apps_redirect_after.json`。本报告已内嵌其中**全部实测数值**，不依赖它们复读。

## 3. 改前基线（四角色 + guest × 1440/360）

列含义：HTTP 状态 ｜ 最终 URL ｜ **可见 h1 数 / DOM h1 数** ｜ h1 文本 ｜ 壳层元素 ｜ 角色专属块 ｜ 可见 `a[href]` 条数。
`stu/faculty/parent` 三行的 URL 是 `/my/home`——它们访问 `/my/apps` 会被 **303 重定向**（见 §6），
因此这三行的回归说明是「**探针全部指标与改前逐项一致**」，而不是「它们的 `/my/apps` 壳层被改好了」。

| 角色 | 视口 | 状态 | 最终 URL | 可见/DOM h1 | h1 文本 | 壳层元素（n/可见） | 角色专属块 | 可见锚点数 |
|---|---|---|---|---|---|---|---|---|
| stu | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 王小明（隐藏） ｜ 👋 欢迎回来，王小明（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 88 |
| stu | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 王小明（可见） ｜ 👋 欢迎回来，王小明（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 61 |
| faculty | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 预备科导师【演示】（隐藏） ｜ 👋 欢迎回来，预备科导师【演示】（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「教师」／副标题 有／图表 ['出勤趋势', '考勤'] | 60 |
| faculty | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 预备科导师【演示】（可见） ｜ 👋 欢迎回来，预备科导师【演示】（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「教师」／副标题 有／图表 ['出勤趋势', '考勤'] | 45 |
| parent | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 家长【演示】（隐藏） ｜ 👋 欢迎回来，家长【演示】（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「家长」／副标题 有／图表 ['出勤趋势', '考勤'] | 52 |
| parent | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 家长【演示】（可见） ｜ 👋 欢迎回来，家长【演示】（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「家长」／副标题 有／图表 ['出勤趋势', '考勤'] | 40 |
| backoffice | 1440 | 200 | `/my/apps` | 1 / 2 | 欢迎 教务专员（隐藏） ｜ 👋 欢迎回来，教务专员（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 6/0 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 57 |
| backoffice | 360 | 200 | `/my/apps` | 1 / 2 | 欢迎 教务专员（可见） ｜ 👋 欢迎回来，教务专员（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 6/6 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 41 |
| guest（未登录） | 1440 | 200 | `/login?redirect=%2Fmy%2Fapps%3F` | 0 / 0 | （无 h1） | 问候区 - ｜ 侧栏 - ｜ 页签 - | - | 30 |
| guest（未登录） | 360 | 200 | `/login?redirect=%2Fmy%2Fapps%3F` | 0 / 0 | （无 h1） | 问候区 - ｜ 侧栏 - ｜ 页签 - | - | 13 |

改后同表：

| 角色 | 视口 | 状态 | 最终 URL | 可见/DOM h1 | h1 文本 | 壳层元素（n/可见） | 角色专属块 | 可见锚点数 |
|---|---|---|---|---|---|---|---|---|
| stu | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 王小明（隐藏） ｜ 👋 欢迎回来，王小明（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 88 |
| stu | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 王小明（可见） ｜ 👋 欢迎回来，王小明（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「学生」／副标题 有／图表 ['出勤趋势', '考勤'] | 61 |
| faculty | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 预备科导师【演示】（隐藏） ｜ 👋 欢迎回来，预备科导师【演示】（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「教师」／副标题 有／图表 ['出勤趋势', '考勤'] | 60 |
| faculty | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 预备科导师【演示】（可见） ｜ 👋 欢迎回来，预备科导师【演示】（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「教师」／副标题 有／图表 ['出勤趋势', '考勤'] | 45 |
| parent | 1440 | 200 | `/my/home` | 1 / 2 | 欢迎 家长【演示】（隐藏） ｜ 👋 欢迎回来，家长【演示】（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 5/0 | 角色胶囊「家长」／副标题 有／图表 ['出勤趋势', '考勤'] | 52 |
| parent | 360 | 200 | `/my/home` | 1 / 2 | 欢迎 家长【演示】（可见） ｜ 👋 欢迎回来，家长【演示】（隐藏） | 问候区 1/0 ｜ 侧栏 1/0 ｜ 页签 5/5 | 角色胶囊「家长」／副标题 有／图表 ['出勤趋势', '考勤'] | 40 |
| backoffice | 1440 | 200 | `/my/apps` | 1 / 1 | 全部应用（可见） | 问候区 1/1 ｜ 侧栏 1/1 ｜ 页签 6/0 | 角色胶囊「教务 / 管理员」／副标题 无／图表 无 | 57 |
| backoffice | 360 | 200 | `/my/apps` | 1 / 1 | 全部应用（可见） | 问候区 1/1 ｜ 侧栏 1/0 ｜ 页签 6/6 | 角色胶囊「教务 / 管理员」／副标题 无／图表 无 | 41 |
| guest（未登录） | 1440 | 200 | `/login?redirect=%2Fmy%2Fapps%3F` | 0 / 0 | （无 h1） | 问候区 - ｜ 侧栏 - ｜ 页签 - | - | 30 |
| guest（未登录） | 360 | 200 | `/login?redirect=%2Fmy%2Fapps%3F` | 0 / 0 | （无 h1） | 问候区 - ｜ 侧栏 - ｜ 页签 - | - | 13 |

**只有 `backoffice` 两档发生变化**；`stu/faculty/parent/guest` 四角色的 10 项指标（状态 / URL / 标题 / h1 文本与可见性 / `a_vis` 与 `a_dom` 多重集 / 全部 flags）逐项比对 **完全一致**。

## 4. 改动清单（`文件路径:行号`）

1. **`custom_addons/edu_portal/views/batch2.xml:963-1046`** —— 新增模板
   （注释 963-987；`<template id="edu_apps_grid" name="Edu Portal Apps Grid">` 990-1046），
   插在 `edu_dashboard_v2` 结束、教师工作台首页（1048 起）之前。
   骨架：`t-call="edu_portal.edu_page"` → `div.row.b11-home[data-home-role][data-csrf][data-fav-server]` →
   左列 `div.col-12.col-lg-9`：
   - 角色页头带 `div.yy-head.oe-portal-hero`：`span.yy-head-role`（`home_role` 四分支：家长 / 教师 / 学生 / 教务·管理员）
     + `h1.mb-0.h3.yy-head-title`（=`title`，即「全部应用」）+ `div.yy-head-meta`（当前账号 = `username` ／ 通知锚点 `#portal_alert_category` ／
     `t-if="bell"` 的 `form[method=post][action=/alerts/mark_read]`「全部标为已读」）；
   - 提醒分类折叠区：`categories` 中 `key == 'portal_alert_category'` 的走 `t-call="edu_portal.edu_one_cat"`；
   - 其余分类折叠区：`key != 'portal_alert_category'` 的走同一个 partial（「常用应用」在内）；
   - 右列 `div.d-none.d-lg-flex.justify-content-end.col-lg-3` → `div.mt-3.oe-sidebar` → `t-call="edu_portal.edu_sidebar"`。
2. **`custom_addons/edu_portal/controllers/batch2.py:2192-2193`** —— 渲染目标由 `edu_portal.edu_dashboard_v2`（改前 `:2188`）改为 `edu_portal.edu_apps_grid`
   （形参一行未改：仍 `self._apps_grid_values('全部应用', 'apps')`）。
3. **`custom_addons/edu_portal/controllers/batch2.py:2173-2179`** —— `edu_apps()` 的 docstring：把「刻意复用 v2」的旧理由
   改成本轮口径 +「上下文装配一字不改，两个模板共用同一份输入」；
   并顺带把 `_apps_grid_values()` 的 docstring 首行（`custom_addons/edu_portal/controllers/batch2.py:2127`）
   从「（模板 edu_dashboard_v2）」改成「（/my/home 合并页 edu_dashboard_v2 与 /my/apps 的 edu_apps_grid 共用）」，避免该行随本轮改动失真。

**没改**：`_apps_grid_values()`（`custom_addons/edu_portal/controllers/batch2.py:2126` 起）的上下文装配、
角色守卫与 303 分支（`custom_addons/edu_portal/controllers/batch2.py:2181-2191`）、`edu_page` / `edu_one_cat` / `edu_sidebar`
三个共用 partial、任何 `scripts/**`、任何权限判定或菜单/组配置。

### 为什么抽新模板而不是给 v2 加条件

- v2 的页头（`h1.oe-greeting` + `p.oe-subtitle` + 学生胶囊）与首页统计块是**学生首页的组成部分**，在 v2 里加 `t-if`
  会让「首页」与「宫格页」的模板纠缠，且 v2 已被 `/my/home`（学生/家长）与教师合并首页共用；
- 新模板逐字段复用了与 `/my/home` 教师变体**同一套页头类**（`.yy-head.oe-portal-hero`、`.yy-head-role`、`.yy-head-title`、`.yy-head-meta`），
  所以品牌壳层在同一账号的两页之间是同一种语言（这正是 D2 判据要的「按角色分化」）。

## 5. 收藏契约：引用处与保全方式

**谁在依赖 `[data-fav-grid]`（静态资源引用处，grep `custom_addons/edu_portal/static/src/**`）**：

| 引用处 | 要求 |
|---|---|
| `custom_addons/edu_portal/static/src/js/home_favs.js:14` | `var wrap = document.querySelector("[data-home-role]")`，**取不到就直接 return**（整段收藏 JS 静默失效） |
| `custom_addons/edu_portal/static/src/js/home_favs.js:20` | `var favGrid = wrap.querySelector("[data-fav-grid]")`，取不到又 return |
| `custom_addons/edu_portal/static/src/js/home_favs.js:49/55/60` | 用 `a[data-app-href]` 作为收藏项的**身份键**（去重、判存在） |
| `custom_addons/edu_portal/static/src/js/home_favs.js:70-73` | 编辑态 = 在 `wrap` 上加 `ux-fav-editing`，并给 `.ux-fav-edit-toggle` 切 `active` |
| `custom_addons/edu_portal/static/src/js/home_favs.js:101-107/147/191-196` | 用 favGrid 内的 `a[data-app-href]` 重排卡片、克隆、同步角标 `[data-msg-badge]` |
| `custom_addons/edu_portal/static/src/js/home_favs.js:239-256/273-276` | 给每个 `.o_portal_index_card` 注入编辑/移动控件 |
| `custom_addons/edu_portal/static/src/js/home_favs.js:112` | `wrap.getAttribute("data-csrf")` → POST `/my/favorites/save` |
| `custom_addons/edu_portal/static/src/css/portal.css:103-107` | `.o_portal_wrap .ux-fav-grid .o_portal_index_card > a .oe_count` 等三条角标规范（选择器是 `.ux-fav-grid` 类，不是 `data-fav-grid`） |

**既有教训（必须遵守，`custom_addons/edu_portal/views/batch2.xml:1107-1111` 原注释）**：一页里存在**两条** `[data-fav-grid]`
会让 `home_favs.js` 的 `querySelector` 抓错容器，宫格那条的「编辑」变成死按钮。

**本轮的保全方式（结构不变，只换壳）**：

1. 外层 `div.row.b11-home` 一字不差保留 `data-home-role` / `data-csrf` / `data-fav-server`（`views/batch2.xml:992-995`）；
2. 「常用应用」分类仍由**同一个** `edu_one_cat` partial 渲染，因此 `data-fav-grid="1" id="fav-grid"`
   （`views/batch2.xml:1309` 的 `t-att-data-fav-grid`；全仓另一处收藏容器是教师工作台的 `views/batch2.xml:1120-1121`）与
   `.ux-fav-category`、`.ux-fav-edit-toggle`、`li.oe-fav-item`、`[data-fav-empty]` 全部照旧；
3. 新模板只渲染 `categories` 一次（两个 `t-foreach` 互斥：`== 'portal_alert_category'` 与 `!=`），
   **不存在第二条 `[data-fav-grid]`**；
4. **不改控制器上下文**：`self._apps_grid_values(...)` 仍是唯一输入源 ⇒ 卡片的 `app_href` 身份键一字不变。

**改后实测（功能级的契约验证，不只是「DOM 里有这个词」）**：

- 结构：`[data-home-role]="internal"`、`data-csrf` 非空、`data-fav-server="0"`、
  全页 `[data-fav-grid]` **恰好 1 个**（`id="fav-grid"`）、网格内 `a[href]` 3 条且 `[data-app-href]` 3 条、
  `.ux-fav-category` 内 `.ux-fav-edit-toggle` 存在且可见；
- 交互：`/my/apps` 点「编辑」→ `[data-home-role]` 获得 `ux-fav-editing`、按钮 `active=true`、页内 `[data-fav-act]` 控件 78 个；
  再点一次 → 编辑态关闭；全程 `pageerror` **0 条**；
- 网格 HTML 与改前**同源同形**：改前 / 改后 `[data-fav-grid]` 容器开头均为
  `<div class="row g-2 w-100" data-fav-grid="1" id="fav-grid">` 后接 `.o_portal_index_card.col-md-6` 卡片。

## 6. 改后对照：壳层元素与「学生专属块」逐项

`backoffice` 角色，`1440` 与 `360` 两档（`n/可见`，取自探针 flags；`-` = 该选择器 0 命中）：

| 元素 | 改前@1440 | 改后@1440 | 改前@360 | 改后@360 |
|---|---|---|---|---|
| 角色页头带 `.yy-head.oe-portal-hero` | 0/0 | 1/1 | 0/0 | 1/1 |
| `.oe-portal-hero` 合计 | 1/1 | 1/1 | 1/0 | 1/1 |
| 学生问候 `h1.oe-greeting` | 1/1 | 0/0 | 1/0 | 0/0 |
| 学生副标题 `p.oe-subtitle` | 1/1 | 0/0 | 1/0 | 0/0 |
| 角色胶囊 `span.yy-head-role` | 1/1 | 1/1 | 1/0 | 1/1 |
| 迷你头部 `.oe-mhead` | 1/0 | 0/0 | 1/1 | 0/0 |
| 迷你头部铃铛 | 1/0 | 0/0 | 1/1 | 0/0 |
| Hero 铃铛 | 1/1 | 0/0 | 1/0 | 0/0 |
| 「全部标为已读」表单 | 1/0 | 1/1 | 1/1 | 1/1 |
| 头像按钮 → `#accountOffCanvas` | 1/0 | 0/0 | 1/1 | 0/0 |
| `#accountOffCanvas` 本体 | 0/0 | 0/0 | 0/0 | 0/0 |
| `#oe_stats_slot`（KPI） | 1/0 | 0/0 | 1/0 | 0/0 |
| 考勤英雄块 `.oe-mhero` | 1/0 | 0/0 | 1/1 | 0/0 |
| `#oe_charts_row`（两张图） | 1/1 | 0/0 | 1/1 | 0/0 |
| `[data-fav-grid]` 容器 | 1/1 | 1/1 | 1/1 | 1/1 |
| `[data-fav-grid="1"]` | 1/1 | 1/1 | 1/1 | 1/1 |
| 侧栏卡 `.oe-sidebar` | 1/1 | 1/1 | 1/0 | 1/0 |
| 提醒分类 `#portal_alert_category` | 1/1 | 1/1 | 1/1 | 1/1 |
| 铃铛角标 `.oe_count` | 1/1 | 1/1 | 1/1 | 1/1 |
| 窄屏页签 `.b11-tab` | 6/0 | 6/0 | 6/6 | 6/6 |

读数：

- **消失（本轮目的）**：学生问候 `h1.oe-greeting`、学生副标题 `p.oe-subtitle`、`.oe-mhead` 迷你头部及其铃铛、
  Hero 铃铛、`#oe_stats_slot`、`.oe-mhero`、`#oe_charts_row`（两张空考勤图）、头像按钮 `→ #accountOffCanvas`；
- **保留**：侧栏（1440 档）、窄屏页签 `.b11-tab`（**6 个，与改前同数**）、提醒分类 `#portal_alert_category` 与铃铛角标 `.oe_count`、
  `[data-fav-grid]` 容器；
- **新增可见**：角色页头带 `.yy-head.oe-portal-hero`（**两档都可见**，承载唯一 h1 与账号行）、
  「全部标为已读」表单（改前只在 ≤767.98 档的迷你头部里可见，**现在两档都可见**）；
- **换文字**：角色胶囊由「学生」→「教务 / 管理员」；`h1` 由「👋 欢迎回来，教务专员」→「全部应用」
  （`document.title` 本来就是「全部应用」，现在页内 h1 与标题一致）。

### href 多重集对账（可见锚点）

| 视口 | 改前可见锚点 | 改后可见锚点 | LOST | ADDED |
|---|---|---|---|---|
| 1440 | 57 | 57 | **∅（空）** | **∅（空）** |
| 360 | 41 | 41 | **∅（空）** | **∅（空）** |

- 两档 **LOST = ∅**（没有丢入口）；
- 两档 **ADDED = ∅**（没有多出入口）——包括 `#portal_alert_category`：改前 1440 档由 Hero 铃铛承载 1 条、360 档由迷你头部铃铛承载 1 条，
  改后统一由页头带的「通知」承载 1 条，**可见多重集不变**；
- **未纳入对账**的是不可见锚点（`a_dom` 139 → 138，少的正是被删掉的迷你头部铃铛），
  以及本报告不把「同页锚点」当入口（§7 单列）。

### 非学生角色为什么「无变化」

`custom_addons/edu_portal/controllers/batch2.py:2185-2192`（未改）依次做：未登录 → 登录页；
学生 → 303 `/my/home`；家长 → 303 `/my/home`；教师非教务 → 303 `/my/home`。
所以真正走到本页渲染的只有**教务处/管理员**（以及极少数未命中上述分支的账号）。
`/my/apps` 上「学生壳 / 教师壳 / 家长壳」在**路由层**就被分流掉了——本轮的「按角色分化」因此落在
「**教务/管理员这一页不再冒充学生首页**」+「壳层自身按 `home_role` 分流胶囊」（家长/教师/学生/教务四分支都写了，见 §4）。
`/tmp/apps_redirect_baseline.json` 与 `/tmp/apps_redirect_after.json` 记录的 303 目标两轮一致：

| 账号 | 改前 | 改后 |
|---|---|---|
| stu | `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` | `303` → `/my/home` |
| faculty | `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` | `303` → `/my/home` |
| parent | `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` | `303` → `/my/home` |
| backoffice | `303`（渲染本页） | `200`（渲染本页） |
| guest | `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` | `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` |

> **订正（2026-10-17 03:09，来源：Lead 2026-10-17 独立复核实测；本会话同日复测）** —— 上表**改前列**的 `303` → `/web/login?redirect=%2Fmy%2Fapps%3F` **不成立**：
> 它是**未登录（会话丢失）探针**的产物，与实际守卫实现（`custom_addons/edu_portal/controllers/batch2.py:2185-2192`，按 `base.group_user` 判定）自相矛盾。
> 可复现口径（本会话实测：登录走 JSON-RPC `POST /web/session/authenticate`、带 `NO_PROXY=localhost,127.0.0.1`、不跟随重定向、遍历排除 `/logout`）：
> - `backoffice@local`：`/my/home` → `200`，`/my/apps` → **`200`**（改前改后都是 `200`；本轮只换壳层、不换状态码）⇒ 上表 backoffice 行「改前 `303`（渲染本页）」应为 **`200`**（§1 的改前渲染证据亦支持）；
> - `stu@local` / `faculty@local` / `parent@local`：`/my/home` → `200`，`/my/apps` → `303`，`Location: /my/home`（**不是** `/web/login`；与 §3 表内最终 URL 一致）；
> - 因此「记录的 303 目标两轮一致」的说法不成立（改前列的 `/web/login` 是假 303）。上表原句保留，仅为留痕。

## 7. 可见 href 逐个实测状态码（backoffice@1440）

对页面内**每一个可见** http(s) href 在同一会话内发一次 GET：

- **36 / 40 条 → `200`**（含宫格里的每一条应用入口、分类折叠、侧栏链接、页签链接）；

  > **订正（2026-10-17 03:09，来源：Lead 2026-10-17 独立复核实测；本会话同日复测，两轮数字一致）** —— 原句的**分母与分子都不准**，可复现口径：
  > ① **全 href 分母：63 条内部 href = 62×`200` + 1×`302`**；唯一 302 是 `/openeducat/apps_menu` → `/apps`（活跳转，非死链）。
  >    63 的来历（本会话实测）：全页 `a[href]` DOM **138** 条、内部路径 href **唯一 66** 条；去掉 `/logout`、认证路由 `/login`（`303` → `/apps`）与含 `#` 的 `/#contact`（`404`，指向站点根）后为 **63**。
  > ② **可见锚点分母：36 条 = 35×`200` + 1×`302`**（同上那一条）。本会话复测（backoffice@1440，Playwright 同会话）：`a[href]` 可见 **57** 条，其中非路径 4 条（`#`、`#portal_alert_category`、`#wrap`、`mailto:scrtsschool@gmail.com`）⇒ 可见路径 href **唯一 36** 条，逐条 `GET`（不跟随重定向、排除 `/logout`）得 **35×`200` + 1×`302`**。
  > ③ 原句的「40」不对应任何分母（全 href = 63 / 可见锚点 = 36），**作废**；原句保留仅为留痕。
- **3 条是同页锚点**（不产生请求）：`#`、`#portal_alert_category`、`#wrap`；
- **1 条未计可达性**：`mailto:scrtsschool@gmail.com`（`mailto:`，Playwright 不导航；非本页入口）。

两个**改前改后都在**、且算不上「入口」的近似空锚点（**非本轮引入**，如实记录）：

| href | 是什么 | 判定 |
|---|---|---|
| `#wrap` | 核心 Odoo 的「跳至内容」跳转链接（`a.o_skip_to_content.visually-hidden`，键盘聚焦才可见） | 同页锚点，非入口 |
| `#` | 核心 Odoo 的「转到您的应用」按钮（`a.o_frontend_to_backend_apps_btn.fa.fa-th`，`title="转到您的应用"`，前端→后台由 JS 接管） | 核心控件，非本模块入口 |

⇒ **本轮新增的可见入口为 0 条，因此「可见即点得通」成立（原句：36/36 全部 200）**。

  > **订正（2026-10-17 03:09，同上）**：可见锚点 36 条中 **35 条 `200` + 1 条 `302`**（`/openeducat/apps_menu` → `/apps`，活跳转）⇒「36/36 全部 200」不成立，应为「**35/36 → `200`，另 1 条 302 到活页**」；「0 条点不通」的结论不变。
`/my/apps` 上未发现「本模块渲染出来、却点不通」的入口。

## 8. 判据逐条核对

| 判据（任务书） | 结果 |
|---|---|
| 1. `/my/apps` 用角色对应壳层渲染 | ✅ 教务/管理员走新壳 `edu_apps_grid`（角色页头带 + 胶囊四分支）；非学生角色的 `/my/apps` 在路由层 303（两轮一致） |
| 2. 保留 `[data-fav-grid]` 契约 | ✅ 结构断言 + 交互实测（§5），容器 HTML 与改前同形 |
| 3. 不得出现该角色点不通的入口 | ✅ 原句「可见 http(s) 入口 36/36 → 200」；**订正（2026-10-17 03:09，同上）：35/36 → `200` + 1×`302`（`/openeducat/apps_menu` → `/apps`，非死链）**；仅剩 2 个核心非入口（§7） |
| 4. 不得因改壳丢入口（LOST=0，ADDED 逐条说明） | ✅ LOST=∅ / ADDED=∅（两档） |
| 5. 每页可见 h1 恰好 1 个 | ✅ 1440 与 360 档均 h1 可见 1 / DOM 1（改前可见 1 / DOM 2） |
| 6. 不得为让宫格渲染而改权限判定 | ✅ `batch2.py:2185-2192` 的守卫与 303 未改；未建组、未改菜单/组配置 |
| 7. 只动 `custom_addons/edu_portal/` + 新增 `docs/audit/` | ✅ 见 §4 与 git diff |

## 9. 升级与门禁（原始输出尾部）

`bash scripts/safe_upgrade.sh edu_portal` ⇒ **EXIT=0**（最终态日志 `/tmp/edu19_upgrade.20261015-172246.log`）：

```
2026-10-15 09:22:52,693 60 INFO edu19 odoo.modules.loading: Module edu_portal loaded in 2.38s, 4221 queries (+4221 other)
2026-10-15 09:22:54,303 60 INFO edu19 odoo.modules.loading: Modules loaded.
2026-10-15 09:22:54,325 60 INFO edu19 odoo.registry: Registry loaded in 5.923s
[safe_upgrade] 重启 web 以清进程内缓存…
[safe_upgrade] 就绪：/web/login?db=edu19 → 302
[safe_upgrade] 结束：edu_portal（无失败特征；完整日志 /tmp/edu19_upgrade.20261015-172246.log）
```

> 升级跑了**两次**：第一次 `/tmp/edu19_upgrade.20261015-171117.log`（功能改动落盘后，EXIT=0）之后，
> 我只再改了**注释与 docstring**（模板注释里的行号自引用、`_apps_grid_values` docstring 首行），
> 为让「容器里跑的」与「磁盘上的」一致，又原样重跑一次 ⇒ 上表是**最终态**那一次。
> 两次日志均 **0 处 `Traceback` / `CRITICAL`**，两次的冒烟结果逐项一致（§6 的对账即取自最终态）。

该日志唯一 `ERROR` 行是**既有**的、与本轮无关的
`edu_admit_invite` 视图告警：`<string>:16: (ERROR/3) Unexpected indentation.`
（`/mnt/custom-addons/edu_admit_invite/views/application_views.xml`，模块 `edu_admit_invite`，未修）。

`python3 scripts/check_english.py` ⇒ **EXIT=0**：

```
================ 汇总（验收口径：must-fix = 0 且 brand = 0）================
guest       must-fix 0    brand 0    白名单 22   数据 29   主题 40   路由违规 0   夹具残留 0  （路由 21 条）
student     must-fix 0    brand 0    白名单 64   数据 286  主题 124  路由违规 0   夹具残留 0  （路由 73 条）
faculty     must-fix 0    brand 0    白名单 74   数据 271  主题 142  路由违规 0   夹具残留 0  （路由 89 条）
parent      must-fix 0    brand 0    白名单 57   数据 69   主题 110  路由违规 0   夹具残留 0  （路由 73 条）
backoffice  must-fix 0    brand 0    白名单 76   数据 286  主题 146  路由违规 0   夹具残留 0  （路由 89 条）
TOTAL must-fix = 0 条 / brand = 0 条 / **路由状态违规 = 0 条** / **夹具残留 = 0 条**
```

其余离线门禁（`AGENTS.md` §4 清单）本轮亦全绿：

```
check_odoo_trace      EXIT=0  PASS：Odoo / 基座品牌痕迹 0 命中
check_ui_surface      EXIT=0
check_nav_reachable   EXIT=0  PASS | 20 条导航目标全部 200（游客态 + 登录态）
check_manifest_tracking EXIT=0
check_shell_exitcode  EXIT=0
check_po_sanity       EXIT=0  RESULT=OK（0 处重复）
check_alias_not_extended EXIT=0  RESULT=OK（没有「被继承的薄别名」）
check_docs_index      EXIT=0
```

（`docs/code-map.md:47` 模块数、`check_md_tables.py`、`check_menu_data_sync.py`、`check_nav_jobs_entries.py` 是
`AGENTS.md` §4 明列的**已知红**，与本轮无关，未动。）

## 10. 未验证 / 没做（不许估算）

1. **人眼视觉验收未做**：本轮只做 DOM/计算样式/状态码级取证，没有截图比对，**色值、间距、字重、对齐是否美观「未验证」**；
2. **`check_ui_usability.py` / `check_accessibility.py` / in-page link 门禁未跑**：`AGENTS.md` §4 列为「跑不了、别跑」（playwright），
   因此**焦点顺序、对比度、键盘可达性在本页「未验证」**；
3. **多语言档未测**：探针只用默认中文档（`lang=zh-CN`），**zh_TW / en_US 下 h1 与胶囊文案「未验证」**（新模板文案全部是中文可见串，已过 `check_english`）；
4. **学生 / 教师 / 家长 的 `/my/apps` 壳层未实测**：这三类账号被 303 送走（§6），**它们根本走不到该模板**，
   所以「学生=学生壳 / 教师=教师壳 / 家长=家长壳」在本轮**没有可观测样本**——新模板里的胶囊分支是靠 `home_role` 分流写的，**未验证**；
5. **`#accountOffCanvas` 按钮被删的替代路径只做了静态核对**：实测该页两档 `#accountOffCanvas` 命中数均为 **0**（改前改后都是 0），
   因此改前那个按钮没有可开启的对象（**未做真实点击手测**）；个人资料入口改由侧栏资料卡承担，**跳转是否成功未逐条实测**；
6. **`mailto:` 链接未计可达性**（1 条，`scrtsschool@gmail.com`）；
7. **未跑任何部署命令**（本仓不含生产凭据，禁区）；
8. **`edu_admit_invite` 的既有 ERROR/告警未修**（不属于本轮范围）；
9. **原始探针 JSON 未入库**（在 `/tmp`，易失）；报告已内嵌全部数值，但**探针脚本本体也未入库**（按任务书只允许新增取证报告）。
