# 首页美化 · 验收契约与现状基线

> **用途**：本轮「首页美化」实施完成后，逐项对照本文件验收。每一项都给了**判定手段**（可复跑命令/探针）、**现状基线值**（2026-10-15 实测）、**不合格判据**（机械判据，不依赖人眼口味）。
> **写入面声明**：本轮只读代码与站点；仓库内**唯一写入文件就是本文件**。未改 `custom_addons/` 任何文件，未改 `scripts/check_*.py` 任何判定口径，未跑任何部署命令（`scripts/deploy_myedu.sh` 连生产，全程未执行）。
> **取证时刻**：2026-10-15 08:14 – 09:2x（Asia/Shanghai），全部读数均出自该时段。
> **取证环境**：`docker compose` 项目 `edu19-clone`；站点 `http://localhost:8069`；数据库 `edu19`；浏览器 Playwright chromium（探测脚本一律 `NO_PROXY=localhost,127.0.0.1`，否则 macOS 代理会返回假 502）；四个角色口令统一 `demo123`。
> **⚠️ 时序声明（读数字前必看）**：本文件所有读数**采集于并行实施动工之前**，且都在 web 容器上一次重启之前：
>
> | 事件 | 时刻（2026-10-15, Asia/Shanghai） |
> |---|---|
> | 基线截图 18 张 + `baseline.json`（布局/规模/英文/入口/Tab） | 08:14 |
> | `structure.json`（分类/卡片/标题阶梯） | 08:17 |
> | `judge_probes.json`（像素对比度、文本快照） | 08:19 |
> | `pixel2.json` / `upstream_provenance.json` | 08:22 |
> | `a11y_tap.json`（可点目标、h 阶梯、`/my/child`） | 08:26 |
> | 并行实施方最早的文件写入（`home_v4.css` / `__manifest__.py`） | 08:23 |
> | **`edu19-clone-web-1` 重启（新代码开始生效）** | **08:28:31** |
>
> ⇒ 全部读数 = **改动前基线**（CSS/DOM 相关读数均在 08:22 前完成，早于任何实施写入）。**从现在起站点已在跑改动后的代码**；§4 的探针复跑得到的是「改动后」状态，必须与本文档数字逐列对比，而不是拿来覆盖基线。
> **权威来源**：`docs/code-map.md`（§6 硬约定）、`AGENTS.md`（离线门禁）、`CLAUDE.md`（铁律 0）。本文件是这三者的**下位验收契约**，冲突时以上位为准。

---

## 0 · 验收对象与现状口径

### 0.1 对象矩阵（6 个）

| 代号 | 登录账号 | uid | 路由 | 页面 `<title>` | 取证时 HTML 字节 |
|---|---|---|---|---|---|
| `stu_home` | `stu@local` | 8 | `/my/home` | 我的主页 | 115 629 |
| `parent_home` | `parent@local` | 10 | `/my/home` | 我的主页 | 83 731 |
| `faculty_home` | `faculty@local` | 11 | `/my/home` | 我的主页 | 89 056 |
| `backoff_home` | `backoffice@local` | 12 | `/my/home` | **教师工作台** | 57 450 |
| `empty_home` | `empty@local` | 820 | `/my/home` | 我的主页 | — |
| `guest_root` | 匿名 | — | `/`（公开站首页） | — | 35 207 |

补充对象（空态取证用）：`/my/child`（家长视角「我的孩子」）。

### 0.2 路由真相（决定「同一组件」到底指哪一份模板）

- `/my/home` 在 `custom_addons/edu_portal/controllers/main.py`（`EduPortalHome.edu_home` → 旧 `edu_portal.edu_dashboard`）与 `custom_addons/edu_portal/controllers/batch2.py`（同名 `edu_home`）各注册一次；Odoo 按**后加载叶子覆盖**，**实际渲染 batch2 分支**，旧 v1 模板 `edu_dashboard` 不参与线上渲染。验收必须以线上渲染结果为准，不得以 `main.py` 的模板为改造对象。
- batch2 分支分流：
  - 教师（有 op.faculty 档案、非管理员/教务）→ 合并工作台 + 宫格（`edu_dashboard_v2`，合并去重后的应用宫格）；
  - 管理员 / 教务处 / 无教师档案者 → `edu_dashboard_teacher`（`backoff_home` 即此分支，标题「教师工作台」）；
  - 学生 / 家长 → `edu_dashboard_v2` 宫格（与 `/my/apps` 同源 `markup`）。
- 家长（存在 `op.parent` 记录）会在学业分类首位插入 `/my/child`；学生/家长隐藏 `my/checkins`、`my/journals`、`assess/my`；教务/管理员不渲染 `my/fees`。
- ⇒ **「跨角色视觉一致性」的合理解释**：四个角色共用同一套品牌壳层（`.b11-*`）与分类宫格组件，差异只允许来自**数据**（分类条数、卡片条数、徽标数），不允许来自**样式**（字号/色/间距/圆角另起一套）。

### 0.3 本契约的两种判据

1. **现状即不合格**（本轮必须修掉，见 §1.13 速览）：副标题对比度、无 h1、可见英文串、小可点目标、图标无命名、「通知」角标无焦点指示。
2. **不得回退**（现状合格，改版后必须保持）：入口 href 全集、分类/卡片/页签数量、图片 alt=0 缺失、横向溢出 0px、`—` 空态口径、品牌真实性。

---

## 1 · 现状基线取证（只读）

### 1.0 前置与命令

```bash
# 站点探活（必须显式绕代理）
curl -s -o /dev/null -w '%{http_code} %{size_download}\n' --noproxy '*' http://localhost:8069/
# → 200 35207
curl -s -o /dev/null -w '%{http_code}\n' --noproxy '*' 'http://localhost:8069/web/login?db=edu19'
# → 302

# 角色登录与页面落盘（JSON-RPC，db=edu19）
POST /web/session/authenticate  {"jsonrpc":"2.0","params":{"db":"edu19","login":"<账号>","password":"demo123"}}
# uid 回读：stu=8 parent=10 faculty=11 backoffice=12 empty=820

# 只读数据库通道
docker exec edu19-clone-db-1 psql -U odoo -d edu19 -tA -c "<SQL>"
```

浏览器侧读数由 4 段本地探针产生（脚本与 JS 片段见 §4）：`baseline.json`（布局/规模/英文/入口/Tab）、`structure.json`（分类与卡片、标题阶梯）、`judge_probes.json`（像素对比度、文本快照）、`a11y_tap.json`（可点目标、h 阶梯、`/my/child`）。

### 1.1 断点响应式读数（A 表：3 视口 × 6 对象）

`inW`=视口宽 / `scW`=`documentElement.scrollWidth` / `溢出`=`scW-inW` / `越界`= 右边界超出视口 >1px 的非 fixed 元素数。

| 对象 | 视口 | inW | scW | 溢出 | 越界 | 卡片 | 分类 | 导航 | 页签 | 搜索框 | 图无 alt | 图标无命名 | 可聚焦 | Tab 采样 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| guest_root | 1440×900 | 1440 | 1440 | **0** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 2 | 43 | 40 |
| guest_root | 390×844 | 390 | 390 | **0** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 21 | 26 | — |
| guest_root | 360×640 | 360 | 360 | **0** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 21 | 26 | — |
| stu_home | 1440×900 | 1440 | 1440 | **0** | 0 | 45 | 8 | 22 | 5 | 3 | 0 | 2 | 95 | 40 |
| stu_home | 390×844 | 390 | 390 | **0** | 0 | 45 | 8 | 22 | 5 | 3 | 0 | 3 | 69 | — |
| stu_home | 360×640 | 360 | 360 | **0** | 0 | 45 | 8 | 22 | 5 | 3 | 0 | 3 | 69 | — |
| parent_home | 1440×900 | 1440 | 1440 | **0** | 0 | 28 | 7 | 12 | 5 | 3 | 0 | 2 | 61 | 40 |
| parent_home | 390×844 | 390 | 390 | **0** | 0 | 28 | 7 | 12 | 5 | 3 | 0 | 3 | 49 | — |
| parent_home | 360×640 | 360 | 360 | **0** | 0 | 28 | 7 | 12 | 5 | 3 | 0 | 3 | 49 | — |
| faculty_home | 1440×900 | 1440 | 1440 | **0** | 0 | 27 | 7 | 16 | 5 | 3 | 0 | 2 | 66 | 40 |
| faculty_home | 390×844 | 390 | 390 | **0** | 0 | 27 | 7 | 16 | 5 | 3 | 0 | 3 | 52 | — |
| faculty_home | 360×640 | 360 | 360 | **0** | 0 | 27 | 7 | 16 | 5 | 3 | 0 | 3 | 52 | — |
| backoff_home | 1440×900 | 1440 | 1440 | **0** | **2** | 3 | 0 | 15 | 6 | 3 | 0 | 2 | 48 | 40 |
| backoff_home | 390×844 | 390 | 390 | **0** | **2** | 3 | 0 | 15 | 6 | 3 | 0 | 3 | 38 | — |
| backoff_home | 360×640 | 360 | 360 | **0** | **2** | 3 | 0 | 15 | 6 | 3 | 0 | 3 | 38 | — |
| empty_home | 1440×900 | 1440 | 1440 | **0** | 0 | 39 | 8 | 22 | 5 | 3 | 0 | 2 | 155 | 40 |
| empty_home | 390×844 | 390 | 390 | **0** | 0 | 39 | 8 | 22 | 5 | 3 | 0 | 3 | 129 | — |
| empty_home | 360×640 | 360 | 360 | **0** | 0 | 39 | 8 | 22 | 5 | 3 | 0 | 3 | 129 | — |

**读法**（这三条是「不得回退」的量化底线）：
- **横向滚动：18/18 组合全部 `溢出 = 0px`** —— 现状窄屏不横向滚动，改版后任一组合出现 >0px 即不合格。
- **越界元素唯一例外**：`backoff_home` 三档都有 2 个越界元素，为 `.o_frontend_to_backend_apps_btn`（`left=-88`、宽 20px，Odoo 核心「转到您的应用」屏外装饰按钮），**不产生滚动条**，记为已知例外；新版本**越界元素数不得超过基线**。
- **可聚焦数**是键盘可达性的下限：`stu 95 / parent 61 / faculty 66 / backoffice 48 / empty 155 / guest 43`（桌面）。

### 1.2 截图清单（18 张，落盘路径）

`/tmp/hp_baseline/shots/`（命名 `<对象>_<宽>x<高>.png`，3 视口 × 6 对象 = 18 张，共 9.5 MB）：

```
backoff_home_1440x900.png   backoff_home_390x844.png   backoff_home_360x640.png
empty_home_1440x900.png     empty_home_390x844.png     empty_home_360x640.png
faculty_home_1440x900.png   faculty_home_390x844.png   faculty_home_360x640.png
guest_root_1440x900.png     guest_root_390x844.png     guest_root_360x640.png
parent_home_1440x900.png    parent_home_390x844.png    parent_home_360x640.png
stu_home_1440x900.png       stu_home_390x844.png       stu_home_360x640.png
parent_child_1440x1000.png   # 家长「我的孩子」页整页，空态取证用
```

> ⚠️ `/tmp` 可能被系统清理。截图**路径是本文档的取证记录**，复跑命令见 §4.3；若目录已空，先跑 §4.3 再对照本文件数字。

### 1.3 分类与卡片数（B 表，桌面渲染）

| 对象 | 分类标题（项数） | 卡片总数 |
|---|---|---|
| `stu_home` | 常用应用 3 / 学业 Academics 15 / 资源与学习 Resources 7 / 成长 Growth 3 / 财务 Finance 2 / 社区 Community 4 / 个人与设置 3（另有未标题组 7） | **45** |
| `parent_home` | 常用应用 3 / 学业 Academics 8 / 资源与学习 Resources 6 / 财务 Finance 1 / 社区 Community 4 / 个人与设置 3（另有未标题组 2） | **28** |
| `faculty_home` | 常用应用 3 / 学业 Academics 7 / 资源与学习 Resources 6 / 财务 Finance 1 / 社区 Community 4 / 个人与设置 3（另有未标题组 2） | **27** |
| `empty_home` | 同 `stu_home` 全部 8 类（学业 15 / 资源 7 / 成长 3 / 财务 2 / 社区 4 / 个人 3 / 常用 3） | **39** |
| `backoff_home` | 无 `.o_portal_category`（工作台形态，标题「教师工作台」） | **3** |

分类标题的 DOM 同源证据（四角色一致）：`div.o_portal_category[<id>] > .oe-cat-head > span.oe-cat-dot + h3.oe-cat-title + span.oe-cat-count`；卡片为 Odoo 核心门户类 `button.accordion-button.o_portal_index_card.collapsed`，图标 `i.fa.<name>` 带 `aria-hidden="true"`，标题 `span.fs-5`，计数徽标（如「通知 104」）。

### 1.4 标题层级读数（H 基线）

| 对象 | h1 | h2 | h3 | h4 | 各级字号/字重 |
|---|---|---|---|---|---|
| guest_root | **1** | 5 | 13 | 0 | h1 44px/700、h2 32px 与 28px、h3 20px |
| stu_home | **0** | 1 | 7 | 0 | h2 27.4px、h3 20px |
| parent_home | **0** | 1 | 6 | 0 | h2 27.4px、h3 20px |
| faculty_home | **0** | 1 | 6 | 0 | h2 27.4px、h3 20px |
| backoff_home | **0** | **0** | 1 | 0 | h3 24.44px |
| empty_home | **0** | 1 | 7 | 0 | h2 27.4px、h3 20px |

**现状不合格**：四个门户首页 + 空夹具 + 工作台**没有 h1**（页面标题「欢迎回来，王小明」是 h2）。文档大纲只有一个 `<h2>` 起点，对屏幕阅读器是「无一级标题的页面」。

### 1.5 对比度（像素真值，非 computed 推断）

方法：对文字元素截图 → 取众数底色（排除与前景色每通道差 <40 的像素）→ 取「与底色距离最大的 5% 像素的众数」作为**合成前景**（含 `opacity`）→ WCAG 相对亮度比。

| 对象 | 选择器 | 合成前景 | 实测底色 | **实测比** | 纯色口径上限 | 判定 |
|---|---|---|---|---|---|---|
| stu_home | `p.oe-subtitle` | `#ECF4FB` | `#0E7FE6` | **3.64 : 1** | 4.04 : 1 | **FAIL**（14.5px 正文需 4.5） |
| parent_home | `p.oe-subtitle` | `#ECF4FB` | `#0E7FE6` | **3.64 : 1** | 4.04 : 1 | **FAIL** |
| faculty_home | `p.oe-subtitle` | 同族 | `#0E7CEF` | ≈4.08（纯白） | — | **FAIL** |
| empty_home | `p.oe-subtitle` | 同族 | `#0E7CEE` | ≈4.09（纯白） | — | **FAIL** |
| guest_root | `a.btn.yylc-btn-gold` | `#241D10` | `#C5A56E` | **7.14 : 1** | — | PASS |
| backoff_home | 全页 computed 扫描最低值 | — | — | 5.02（桌面）/ 4.09（窄屏） | — | 需按 H1 复测 |

> `p.oe-subtitle` 文案为「所有学习所需尽在一处——快速访问您的记录、课程与服务。」（模板 `custom_addons/edu_portal/views/batch2.xml` 的 `div.oe-hero-text > p.oe-subtitle`）。它压在 `.oe-portal-hero` 的 `linear-gradient(135deg, var(--brand-600), var(--brand-500) 45%, var(--teal-500))` 上，且规则里带了 `opacity:.92`——**这就是 3.64 与 4.04 的差额来源**。

**令牌侧的独立佐证**（`custom_addons/edu_brand/static/src/scss/brand_tokens.scss` 自带的注释即官方口径）：

| 令牌 | 值 | 注释声明 |
|---|---|---|
| `$brand-500` | `#0E7BF2` | 「**禁承载文字/链接**（白底 4.09、`--bg` 上 3.80）」 |
| `$brand-400` | `#3C8FF7` | 同上禁用档 |
| `$brand-600` | `#0A63CC` | 与 `$brand-action-hover` 同值 |
| `$brand-700` | `#084CA0` | 「蓝色调面上的文字唯一档」 |
| `$brand-action` | `#0C6DD7` | 「交互面唯一色（白底 5.02 / 白字压底 5.02）」 |
| `$teal-500` | `#0F9B91` | 「**仅限装饰**（白底 3.43 ✗）」 |
| `$teal-600` | `#0C7D75` | 「teal 作文字/白字底的唯一档（4.99）」 |

⇒ 首页 hero 用「白字 + `--brand-500`/`--teal-500` 渐变」**同时违反令牌注释与 WCAG**。这是本轮最该修、也最好验收的一条。

### 1.6 键盘可达 / 命名 / 替代文本 / 可点目标

| 对象 | 可点元素 | `<44×44` 个数 | 典型小目标（文字/尺寸） | 图片无 alt | 图标按钮无名称 | Tab 采样中「无 focus 指示」站数 |
|---|---|---|---|---|---|---|
| stu_home | 68 | **24** | 跳至内容 1×36、家 13×16、帮助 66×36、搜索 26×36 | 0 | 2–3 | 0 |
| parent_home | 48 | **16** | 同上 | 0 | 2–3 | **1**（「通知」角标站） |
| faculty_home | 51 | **17** | 同上 | 0 | 2–3 | **1**（「通知 38」角标站） |
| backoff_home | 37 | **17** | （含 20×40 的屏外按钮） | 0 | 2–3 | 0 |
| empty_home | 128 | **84** | 同上 | 0 | 2–3 | 0 |
| guest_root | 47 | **11** | 跳至内容 1×1、切换导航 40×41、关闭 32×32 | 0 | 2–21 | 0 |

- **好消息**：Tab 前 40 站里 238/240 站都能测到 focus 指示（`outline` / `box-shadow` 至少一项变化），**图片 alt 缺失 = 0**，且首站是 `a.o_skip_to_content`（跳至内容）。
- **现状不合格**：① 小可点目标成堆（`guest 11/47` 到 `empty 84/128`）——`家`、`搜索`、`帮助`、`关闭` 这些高频操作全在 44px 以下；② 每页有 2–3 个**只有图标没有可访问名称**的按钮（`iconOnlyNoName`）；③ 窄屏（360/390）时 `iconOnlyNoName` 升到 3（桌面 2），说明窄屏会出现额外的裸图标按钮（`guest_root` 从 2 暴涨到 21，需单列整改）；④ **`parent_home` 与 `faculty_home` 的「通知」角标入口 100% 无焦点指示**（`outline:none 0px` 且 `box-shadow` 无变化），共 2/240 站。

### 1.7 空态与长文案现状

能否造「空数据路径」，先看手里有什么：

| 路径 | 现状事实 | 可否当空态对象 |
|---|---|---|
| `parent@local` 的 `/my/child` | 有 **1** 个孩子（`op_parent_op_student_rel` 关联 `op_student` id=5「小明」，学号 `PRP26-001`，48 条考勤） | ❌ 不是空 |
| `parent@local` 首页 | 有子女 → 走正常分支 | ❌ 不是空 |
| `empty@local`（uid 820，「【演示】空态测试学生」） | 首页 **39 张卡 / 8 个分类 / 22 个导航项 / 课表节次 / 通知 7** | ❌ **名不副实**，不是空 |
| `/my/child` 内的评估子块 | 线上真实空态：**「暂无已结束的评估记录（进行中的评估不在此处显示）。评估结束后会出现在这里。」** | ✅ 文案先例，可作样板 |
| 考勤无记录 | 口径先例（三处一致）：无数据给文本态 **「—」**，不给 `0%` | ✅ 口径先例 |
| 学生首页课表无课 | 真实空态：**「今日无课，查看本周课表」**（按钮指向 `/student/timetable?view=day`） | ✅ 文案先例 |

> ⚠️ **验收阻断点**：任务书点名的「家长无学生档案」空态，**当前站点没有天然空对象**（家长必有 1 个孩子，`empty@local` 有满数据）。因此该项验收只能二选一：**(a)** 新建一个无子女的 `op.parent` 夹具（属于写数据，需单独授权，本轮只读未做）；**(b)** 退化为**静态分支审读**——读 `custom_addons/edu_portal/controllers/roles.py` 的 `my_child/_child_summary` 与模板 `edu_portal.edu_my_child` 的 `t-if`/`t-foreach` 分支，确认 `kids` 为空时渲染空态文案、`att_pct_txt` 走「—」。**这条必须由实施方在验收报告里写明选了哪条**，不得默认跳过。

### 1.8 可见英文串现状（含门禁盲区）

**门禁现状**：`python3 scripts/check_english.py` 在 2026-10-15 08:1x 运行时 **must-fix = 0 / brand = 0 / 路由违规 = 0 / 夹具残留 = 0**（guest 21 条路由、student 73、faculty 89、parent 73、backoffice 89，`/my/home` 单行读数 whitelist=1 data=2 theme=2）。即**门禁全绿**。

**但门禁看不到分类标题里的英文**——`scripts/check_english.py` 的 `classify()` 对**任何含中日韩字符的串直接 `return None`（跳过）**，只保留 `BRAND_RE`（`odoo|openeducat`）例外。⇒ 「学业 Academics」这类中英混排标签**结构性失明**，`check_english` 绿 ≠ 没有可见英文。

**自定义抽取口径**（去标签、去 `script/style/template`、正则 `[A-Za-z][A-Za-z-.&]{1,}`）实测：

| 对象 | 英文条目数 | 出现次数 | 其中**分类标题英文尾巴** |
|---|---|---|---|
| guest_root | 19 | 21 | — （无宫格） |
| stu_home | 18 | 20 | **Academics / Resources / Growth / Finance / Community** |
| parent_home | 17 | 19 | **Academics / Resources / Finance / Community**（无 Growth） |
| faculty_home | 17 | 19 | **Academics / Resources / Finance / Community** |
| empty_home | 17 | 19 | **Academics / Resources / Growth / Finance / Community** |
| backoff_home | 10 | 11 | 无（工作台无宫格） |

其余英文条目（全部对象共有）：`SCRTS`×2、`JPG`、`PNG`、`Zoom`×3、`COVENANT`、`REFORMED`、`SEMINARY`、`scrtsschool@gmail.com`、`Soli`、`Deo`、`Gloria`，以及**登录名本身**（`stu@local` / `parent@local` / `faculty@local` 出现在顶栏用户菜单）。

与白名单的关系（`scripts/check_english.py` 的 `WHITELIST`）：`SCRTS`/`COVENANT…` 品牌串、`Zoom`、`English`、`EN`、`Telegram` 属**允许**；`JPG`/`PNG` 是上传控件后缀；登录名属账号数据。**只有 5 个分类英文尾巴是「无正当理由的可见英文」**。

### 1.9 上游同源率（「雷同」度量基线）

方法：把仓库内 `openeducat_erp/**`（本地快照）+ 容器内 `/usr/lib/python3/dist-packages/odoo/addons` 作为上游语料（1 477 文件 / 157.9 MB），对首页可见文本切片（CJK ≥3 字或拉丁 ≥5 字符）做子串命中统计。

| 对象 | 候选串 | 与上游同源 | 同源率 |
|---|---|---|---|
| guest_root | 86 | 5 | 5.8 % |
| stu_home | 121 | 10 | 8.3 % |
| parent_home | 81 | 8 | 9.9 % |
| faculty_home | 95 | 7 | 7.4 % |
| backoff_home | 62 | 4 | 6.5 % |
| empty_home | 186 | 10 | 5.4 % |

同源串集中在通用控件词（如「修改密码」「帮助中心」「联系我们」「个人资料」「学生档案」）；**品牌化文案（课程中心、每日打卡、我的周记、我的评估、一体化校历、一键入会、课程编排、周期排课【教务处】等）均非上游原文**。⇒ 现状文案层面**不构成**「可被任意模板替换」的证据；风险在**结构层**（见 §3）。

### 1.10 功能入口基线（「不得回退」的比对基准）

| 对象 | 链接元素 | 唯一 `href` | 页面内 `<a>` 全集（导出为基准集） |
|---|---|---|---|
| guest_root | 71 | 34 | 公开站导航/页脚 + 品牌资料 |
| stu_home | 153 | **65** | 含 `/my/study`、`/student/assignment/details`、`/student/exam`、`/subject/enroll`、`/student/attendance`、`/grade-book`、`/course/change/request`、`/subject/registration`、`/my/thesis`、`/quiz`、`/my-library`、`/library/media`、`/subject/details`、`/meeting/information`、`/online/meeting`、`/my/asset-request`、`/downloads`、`/my/checkins`、`/my/journals`、`/assess/my`、`/my/fees`、`/my/reimburse/apply`、`/my/notice_board/notice`、`/my/contacts`、`/my/messages`、`/my/grievances`、`/my/time_off`、`/my/addresses`、`/my/password` … |
| parent_home | 114 | **53** | 同上 + `/my/child`（家长专属首卡） |
| faculty_home | 122 | **60** | 含 `/leave/approvals`、`/grievances/approvals`、`/registrar/subject/approvals`、`/journals/review`、`/checkins/stats`、`/timetable/bulk`、`/apps` … |
| backoff_home | 105 | **50** | 含 `/ledger`、`/ledger/reimburse`、`/registrar/curriculum`、`/odoo/action-720`（财务管理）、`/grade-entry`、`/apps`、`/my/notify` … |
| empty_home | 207 | **79** | 学生全集 + 课节深链 `/my/study/54…69` |

同时基线固定：页签（Tab 条）5 项（`backoff_home` 6 项）、侧栏 `navItems` 22/12/16/15/22。

### 1.11 承自既有审计的、与本轮重叠的已知项

（来源 `docs/audit/ui-visual-review/report.md`，2026-10-02/03 人眼复核，**本轮不重复审**，只登记为「改版不得让它变差」）

- V1 新手上手清单压在页面标题之上；V2 手机顶栏「帮助」折两行；V3 手机搜索 placeholder 截断；V4 手机底栏第 5 项是「修改密码」（待裁定）；V5 `/my/home` 同屏两个搜索框；V6 同屏两个「通知 104」角标；V7 侧栏「课程/课程中心/报课选科」三入口重叠（待裁定）；V8 `/subject/enroll` 截止日后无「已截止」提示。
- 已修（防回退）：核心 `.o_frontend_to_backend_nav` 曾 40×40 钉在 `(0,0)` 压住 `.b11-brandmark`(12,6)，修后位置 `(12,728)`。
- 编辑自查口径：手机搜索 placeholder 全文本应为「搜索应用 / 作业 / 课程 / 公告 / 账单」（截断即不合格）。

### 1.12 源码侧基线（符号 + 行号，取证块 · 2026-10-15）

> 按 `docs/code-map.md` §6 第 15 条，正文只写「文件 + 符号名」；**行号仅在本取证块内出现**，且已标注取证时刻。

```text
# 2026-10-15 09:0x 取证（只读）
custom_addons/edu_portal/static/src/css/custom_home.css
  :272  .oe-portal-hero  background: linear-gradient(135deg, var(--brand-600) 0%, var(--brand-500) 45%, var(--teal-500) 100%)
  :289  … .oe-portal-hero .oe-subtitle{color:#fff; …}
  :290  … .oe-portal-hero .oe-subtitle{opacity:.92; letter-spacing:.02em;}
  :585  .oe-mhero  background: linear-gradient(135deg, #0E7BF2, #0F9B91)   ← 移动端 hero，同族问题
custom_addons/edu_portal/static/src/css/enterprise.css
  :9    … .oe-portal-hero .oe-subtitle{margin:7px 0 0; font-size:14.5px; line-height:1.5; color: var(--text-3);}
        （与 custom_home.css 的 color:#fff 同特异性，实际生效为 #fff）
  :221  .oe-mhero{… background: linear-gradient(135deg, var(--brand-500), var(--brand-600)); color:#fff; …}
custom_addons/edu_brand/static/src/scss/brand_tokens.scss
  :25   「通道令牌一律逗号分隔：--brand-500-rgb: 14, 123, 242」
  :55-69 $brand-400/500/600/700、$brand-action、$teal-400/500/600 及其对比度注释（见 §1.5 表）
custom_addons/edu_portal/views/batch2.xml
  :738  <div class="oe-hero-text">
  :748  <p class="oe-subtitle">所有学习所需尽在一处——快速访问您的记录、课程与服务。</p>
  :750  <a class="oe-hero-bell" … title="通知" aria-label="通知">
custom_addons/edu_portal/controllers/batch2.py
  :1654 out = {'att_pct': 0, 'att_pct_txt': '—', …}
  :1712 out['att_pct_txt'] = ('%d%%' % att_pct) if total_lines else '—'
  :210  _OPENEDUCAT_CARDS = [ … ]（:756 与 _COMMON_CARDS 合并；:905 注释「_OPENEDUCAT_CARDS 里的条目本身保留（隐藏≠删除）」）
custom_addons/edu_portal/controllers/roles.py
  :383-385  注释 + 'att_pct_txt': ('%d%%' % round(att_ok*100.0/att_total)) if att_total else '—'
             （原文：「**「没有考勤记录」不等于「出勤率 0%」**」）
custom_addons/edu_portal/views/edu_portal_templates.xml   品牌壳层 .b11-shell / .b11-topbar / .b11-nav-item / .b11-tab 模板所在
custom_addons/edu_brand/static/src/css/backend_b11.css    后台 b11 壳层（--brand-500-rgb 通道用法）
```

### 1.13 现状速览（本轮必须修 / 必须保）

| # | 结论 | 证据（本文档节） | 性质 |
|---|---|---|---|
| 1 | hero 副标题白字压品牌渐变 **3.64:1**（上限 4.04）< 4.5 | §1.5 | **必修** |
| 2 | 四个角色首页 + 工作台 **无 h1**（h2 27.4 / h3 20） | §1.4 | **必修** |
| 3 | 可见英文串 10–19 条/对象，含 5 个分类英文尾巴；`check_english` 对此失明 | §1.8 | **必修** |
| 4 | 小可点目标 11/47 … 84/128（`<44×44`） | §1.6 | **必修（移动端）** |
| 5 | 每页 2–3 个图标按钮无可访问名称 | §1.6 | **必修** |
| 6 | 「家长无学生档案」无天然空对象；`empty@local` 名不副实 | §1.7 | **验收阻断点（需夹具或静态审读）** |
| 7 | 横向溢出 0px / 越界例外仅 2 个屏外按钮 | §1.1 | 不得回退 |
| 8 | 入口 href 34/65/53/60/50/79、分类 0–8、卡片 3–45、页签 5–6 | §1.3 §1.10 | 不得回退 |
| 9 | 图片 alt 缺失 = 0；焦点指示 238/240 站达标（例外：`parent_home`/`faculty_home` 的「通知」角标各 1 站无指示，**属必修**） | §1.6 | 不得回退 / 必修 |
| 10 | 上游同源率 5.4–9.9% | §1.9 | 不得上升 |

---

## 2 · 验收清单（逐项打勾）

用法：每项打 ☑ 时**必须贴证据**（命令 + 输出尾部，或截图路径 + 数字）。**「我看过了觉得没问题」不算证据。**

### V · 视觉一致性（同源同貌）

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| V1 | 四个角色首页共用同一品牌壳层，差异只来自数据 | 在 4 个对象上取同一组选择器的 computed 样式指纹（`fontFamily/fontSize/fontWeight/color/backgroundColor/padding/borderRadius/boxShadow`），逐字段比对 | 壳层选择器：`.b11-topbar` `.b11-brandmark` `.b11-nav-item` `.b11-tab` `.b11-shell` `.o_portal_category` `.oe-cat-title` `.oe-cat-count` `.o_portal_index_card` | 任一选择器在 4 角色间出现**样式指纹不等**（容差 0）即不合格 | ☐ |
| V2 | 分类宫格与卡片由**同一模板**生成，不得出现角色一次性样式 | 比对各对象 `.o_portal_category` 的 DOM 结构签名（`tag>class` 路径）与卡片类名集合 | 签名：`div.o_portal_category > .oe-cat-head > span.oe-cat-dot & h3.oe-cat-title & span.oe-cat-count`；卡片 `button.accordion-button.o_portal_index_card[.collapsed]`；图标 `i.fa[aria-hidden=true]`；标题 `span.fs-5` | 结构签名出现第 2 种形态，或新增 `!important` 的角色专用覆盖 | ☐ |
| V3 | 色板唯一：新增/改动颜色必须取自品牌令牌 | 抽查改版后首页所有 `color`/`background-color`/`border-color` 非透明值，必须 ∈ 令牌集合（`brand_tokens.scss` + `--text-*`/`--bg` 体系） | 令牌见 §1.5 表；两套色板（公开站 / 门户）的显式覆盖关系见 `docs/code-map.md` §10.2 | 出现令牌外的硬编码色（如 `#1a73e8`、`rgba(0,0,0,.5)`） | ☐ |
| V4 | 页脚/品牌信息在 4 角色 + 公开站一致，且不新增联系方式 | 对 5 个对象导出页脚可见文本并 diff | `SCRTS`、`Soli Deo Gloria`、`scrtsschool@gmail.com`（`mailto:`） | 出现第 2 种页脚文案、或新增电话/地址/社交链接（**红线**） | ☐ |
| V5 | 图标体系唯一 | 统计首页 `i.fa-*` 使用的前缀与名称集合 | 全部 `fa` / `fa-solid` 体系，`aria-hidden="true"` 装饰 | 混入 emoji 当图标、或同一语义两个图标名混用 | ☐ |

### H · 层级与对比

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| H1 | 正文/链接文字对比度 ≥ **4.5:1**；≥24px 或 ≥18.66px 粗体 ≥ **3:1** | **像素实测**（§4.2 S4）：元素截图 → 众数底色 + 与底色距离最大的 5% 像素众数作合成前景 → 比值 | `p.oe-subtitle` = **3.64**（上限 4.04）；`a.btn.yylc-btn-gold` = 7.14 | 任一正文/链接实测 < 4.5，或大字/大色块 < 3.0 | ☐ |
| H2 | 承载文字/白字的底色不得用禁用档令牌 | 校验承载文字的 `background`/`background-image` 不落在 `$brand-400/$brand-500/$teal-400/$teal-500`；白字压底必须用 `$brand-action`(5.02) / `$brand-600` / `$teal-600`(4.99) / `$brand-700` | hero 渐变含 `--brand-500`、`--teal-500`（**现状违规**） | 渐变 stop 仍含 `--brand-500`/`--teal-500` 且其上压白字 | ☐ |
| H3 | 标题阶梯：h1 > h2 > h3，且首页有**唯一 h1** | 遍历可见 `h1..h4`，记录个数与 computed `fontSize/fontWeight` | 门户 5 对象 **h1=0**；h2 27.4px、h3 20px；公开站 h1 44px/700 | h1 个数 ≠ 1；或相邻层级「同字号同字重」（差 <2px 且字重差 <200） | ☐ |
| H4 | 焦点可见：任何可聚焦元素得到焦点时必须有可测量的视觉变化 | Tab 走完首屏 40 站，每站读 `outlineStyle/outlineWidth/boxShadow/borderColor` | 6 对象各 40 站，**无指示站数 = 0/1/1/0/0/0**（`parent_home`/`faculty_home` 的「通知」角标） | 出现 ≥1 站 `outline:none` 且 `box-shadow` 无变化（本轮目标：240/240） | ☐ |
| H5 | 文字压在图片/渐变上时，须在**渐变两端各测一次**取最差 | 同 H1，对元素最左/最右文字像素各测一次 | hero 左端 `--brand-600` 侧、右端 `--teal-500` 侧（越靠右越差） | 任一端 < 4.5（正文）即不合格 | ☐ |
| H6 | 正文最小字号 ≥14px，且正文/次要文本对比层级清晰 | 读 `body` 下文本节点 computed `fontSize` 的分布 | `p.oe-subtitle` = 14.5px（已在下限） | 出现 <14px 的正文，或 ≥3 种「近似字号」（13/13.5/14.5）混用 | ☐ |

### R · 断点响应式

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| R1 | 5 档宽度（360/390/768/1024/1440）均无横向滚动 | `documentElement.scrollWidth <= window.innerWidth`（§4.2 S2） | 本机实测 **3 档（360/390/1440）× 6 对象 = 18/18 组合 = 0px**；**768/1024 两档本轮未实测，须在验收时补测** | 任一组合 >0px | ☐ |
| R2 | 越界元素数不得超过基线 | 统计右边界 > `innerWidth+1` 的非 fixed 元素（§4.2 S3） | 仅 `backoff_home` 2 个（`.o_frontend_to_backend_apps_btn`，屏外装饰） | 越界 >基线，或新增可见的越界内容 | ☐ |
| R3 | 360px 下可点目标 ≥44×44（WCAG 2.5.8） | 遍历 `a[href],button,input[type=submit],[role=button]` 的 `getBoundingClientRect()` | `<44` 计数：stu 24/68、parent 16/48、faculty 17/51、backoffice 17/37、empty 84/128、guest 11/47 | 改版后 **`<44` 计数未下降**（本轮目标：降到 ≤5/页，且顶栏三项「家/搜索/帮助」必须达标） | ☐ |
| R4 | 顶栏/底栏在 360px 不折行、不截断 | 比对 360px 截图 + 元素高度（不得比桌面高 >1 行） | 已知 V2：手机顶栏「帮助」折两行；手机搜索 placeholder 全文本应为「搜索应用 / 作业 / 课程 / 公告 / 账单」 | placeholder 被截断、或顶栏出现两行文字 | ☐ |
| R5 | 宫格在窄屏为单/双列，卡片文字不截断 | 读卡片容器 `clientWidth` vs `scrollWidth` + `text-overflow` | 现状：`overflowCount=0` | 任一行出现横向溢出（`clientWidth < scrollWidth`） | ☐ |

### E · 空态与长文案溢出

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| E1 | 无数据必须给文本态，**不得印 0** | 读 `att_pct_txt` 类口径 + 线上空态文案 | 三处一致：无考勤 → 「—」（`batch2.py` · `roles.py` · `study.py`） | 出现「0%」「0 条」或空白占位 | ☐ |
| E2 | 家长无学生档案路径（任务书点名） | **(a)** 建无子女 `op.parent` 夹具（需授权）后打开 `/my/home` 与 `/my/child`；**(b)** 静态审读 `roles.py::my_child/_child_summary` + 模板 `edu_portal.edu_my_child` 的 `t-if/t-foreach` | ⚠️ **当前无天然空对象**（`parent@local` 有 1 个孩子；`empty@local` 有 39 卡） | 未选任一手段即视为**未验收**；出现 500、或渲染「0%」/空白块 | ☐ |
| E3 | 长文案溢出：卡片标题、描述、用户名、课程名在容器内不溢出/不互相压盖 | 文本容器必须命中 `overflow-wrap:anywhere/break-word` 或 `text-overflow:ellipsis` + `min-width:0`；并读容器 `scrollWidth<=clientWidth` | 现状容器宽度正常（0 溢出） | 出现 `scrollWidth > clientWidth` 的文本容器；或省略号缺失导致裁切 | ☐ |
| E4 | 空态不破坏壳层：空数据时顶栏/页签/页脚位置不变 | 空态页与满数据页的壳层元素 `getBoundingClientRect()` 逐个比对 | 顶栏 `.b11-topbar`、页签 `.b11-tab` 顺序固定 | 空态导致壳层位移/塌陷 | ☐ |
| E5 | 空态文案本身必须是中文完整句（含标点） | 目视 + 文本抽取比对样板 | 样板：「暂无已结束的评估记录（进行中的评估不在此处显示）。评估结束后会出现在这里。」「今日无课，查看本周课表」 | 出现「No data」「暂无数据」式占位（后者无上下文即不合格） | ☐ |
| E6 | 「【演示】/【冒烟】」标记必须保留 | 抽取页面可见文本含 `【演示】`/`【冒烟】` 的条数 | `empty_home` 顶栏 `【演示】空态测试学生`、`/my/child` `2026级【演示】`、作业/考试标题带【演示】/冒烟 | 标记被美化时清掉（**品牌红线**） | ☐ |

### K · 键盘可达与命名

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| K1 | 可聚焦元素数不少于基线，且 Tab 顺序与视觉阅读顺序一致 | Tab 走首屏并记录 `activeElement` 序列 + 其 `getBoundingClientRect()` 的 y 单调性 | 可聚焦：95/61/66/48/155/43 | 数量下降，或出现 y 大幅回跳（视觉顺序 ≠ 焦点顺序） | ☐ |
| K2 | 跳过链接存在且为首个 Tab 站 | Tab 第一站 `a.o_skip_to_content`（或等效），激活后焦点进入 `#wrap` | 存在（stu/empty/guest） | 缺失或首站不是它 | ☐ |
| K3 | 图标按钮必须有可访问名称（`aria-label`/`title`/可见文本三者之一） | 遍历 `button,[role=button],a`，取「无 `innerText` 且无 `aria-label` 且无 `title` 且无 `<img alt>`」计数（**口径已于 §8 订正**：加可见性过滤、命名来源含后代；本行基线值为历史读数） | **2–3/页**（`guest` 窄屏 21） | 计数未下降（本轮目标：**0**） | ☐ |
| K4 | 图片必须有替代文本（装饰用 `alt=""`） | `img:not([alt])` 计数 | **0**（全对象） | >0 | ☐ |
| K5 | 不得用 `tabindex="-1"` 屏蔽交互元素、不得出现焦点陷阱 | 统计交互元素上 `tabindex<0` 的数量；对抽屉/下拉做一次 Tab 逃逸测试 | 现状 0 | >0，或 Tab 无法离开弹出层 | ☐ |
| K6 | 键盘可达性不得因美化下降 | 复跑 K1 + K3 + K4 三项，与基线表逐列比对 | 见上 | 任一项变差 | ☐ |

### Z · 中文化与品牌红线

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| Z1 | 可见英文串 = 0（白名单除外） | `python3 scripts/check_english.py`（must-fix 0 / brand 0）**＋**自定义抽取（§4.2 S7，门禁对中英混排失明，必须两条都跑） | 门禁 0/0；自定义：19/18/17/17/10 条目 | 任一门禁非 0；或自定义条目数 **高于**基线；**或 5 个分类英文尾巴（Academics/Resources/Growth/Finance/Community）未清零** | ☐ |
| Z2 | 只允许永约学坊真实资料 | 全文搜索电话/地址/社交链接模式；比对 §1.5 的 V4 基线 | 页脚仅 `scrtsschool@gmail.com`；页面含 `SCRTS`、`Soli Deo Gloria` | 出现旧学院名、`+1 555-…` 式假电话、假地址、未确认的社交账号 | ☐ |
| Z3 | 演示/测试数据标记保留 | 同 E6 的文本抽取 | 见 E6 | 标记丢失 | ☐ |
| Z4 | 多语（简/繁/英）入口与 `lang` 属性不得丢失 | 页面 `document.documentElement.lang`；语言切换器元素存在性 | 全部 `lang=zh-CN`，四角色一致 | `lang` 缺失/错误，或切换器消失导致繁/英不可达 | ☐ |
| Z5 | 「翻译属性不得进 xpath 继承选择器」等硬约定不因美化被破坏 | 审 diff：视图继承选择器不得使用 `string/title/aria-label/placeholder/help` | 见 `docs/code-map.md` §6 第 20 条 | diff 中出现此类选择器 | ☐ |

### F · 功能入口不得回退

| # | 判据 | 判定手段 | 基线值 | 不合格判据 | ☑ |
|---|---|---|---|---|---|
| F1 | **每个卡片的 href 必须仍在**：改版后 href 全集 ⊇ 基线全集 | 导出各对象 `a[href]` 的 href 集合（§4.2 S8），与 §1.10 基线集合做**差集** | 唯一 href：guest 34 / stu 65 / parent 53 / faculty 60 / backoffice 50 / empty 79 | **差集非空**（删了任何入口即不合格；新增允许） | ☐ |
| F2 | 分类数/卡片数不得减少 | 统计 `.o_portal_category` 与卡片数 | 分类 8/7/7/0/8；卡片 45/28/27/3/39 | 任一数字下降 | ☐ |
| F3 | 页签与侧栏项数不得减少 | 统计 `.b11-tab` / `.b11-nav-item` | 页签 5（backoffice 6）；导航 22/12/16/15/22 | 任一数字下降 | ☐ |
| F4 | 关键入口抽样仍可达（不得 404/500） | 每个角色抽 10 条 href 做 GET（允许 302 到登录/门户） | 无已知 404 | 出现 404/500 | ☐ |
| F5 | 家长专属入口 `/my/child` 仍在学业分类首位 | 在 `parent_home` 导出 href 顺序 | `parent_home` 含 `/my/child` | 缺失或不再首位 | ☐ |
| F6 | 被 xpath 扩展的元素不得直接删（正解 `t-if="False"`） | 审 diff 是否删除 `_OPENEDUCAT_CARDS` 等被继承的节点 | `batch2.py::_OPENEDUCAT_CARDS` 的注释「隐藏≠删除」 | diff 中出现对核心/被扩展节点的删除 | ☐ |

### G · 门禁与命令（必跑，全绿才可提交）

| # | 命令 | 期望 | 现状基线 | ☑ |
|---|---|---|---|---|
| G1 | `python3 scripts/check_english.py` | must-fix = 0 且 brand = 0 | 0 / 0（2026-10-15 08:1x） | ☐ |
| G2 | `python3 scripts/check_english.py --selftest` | 48 断言全绿 | 全绿 | ☐ |
| G3 | `python3 scripts/check_ui_surface.py`（无参核对） | 与 `tests/ui/surface.json` 一致 | 一致（114 门户页 / 277 去重路由） | ☐ |
| G4 | `python3 scripts/check_qweb_dict_foreach.py`、`check_manifest_order.py`、`check_manifest_tracking.py`、`check_shell_exitcode.py` | 全绿 | 全绿 | ☐ |
| G5 | `/my/home` 四角色 + `/` 渲染 | HTTP 200、无 Traceback、`lang=zh-CN` | 200（115 629 / 83 731 / 89 056 / 57 450 / 35 207 B） | ☐ |
| G6 | 未改门禁口径 | `git diff --stat scripts/check_*.py` 为空 | 空 | ☐ |
| G7 | 未改基座/未跑部署 | `git diff --stat openeducat_erp/`、`docker-compose.yml`、`config/` 为空；未执行 `scripts/deploy_myedu.sh` | 空 | ☐ |

---

## 3 · 发布前拦截判据（什么算「通用、雷同、可被任意模板替换」而不予放行）

「通用模板感」不能靠感觉判，用下面 6 条机械判据。**任一条命中即拦截，退回整改**。

| # | 拦截判据 | 判定手段（可复跑） | 阈值 |
|---|---|---|---|
| J1 | **品牌壳层被稀释**：改版后首页要素回落到 Bootstrap/Odoo 默认样式 | 统计「非令牌色 / 默认间距 / 默认圆角」出现次数；检查 hero、卡片、分组头是否仍由 `.b11-*` / `.oe-*` 品牌类承载 | 出现任何一块内容**完全由 Bootstrap 原生类**（`text-bg-light`、`btn-primary` 默认色、`card shadow-sm` 默认）构成主要视觉，且无品牌包装 ⇒ 拦截 |
| J2 | **可替换性**：整页去掉 logo 与文案后，与任意 Odoo 门户站首页不可区分 | 结构指纹：`(顶栏形态, hero 形态, 分类数, 卡片形态, 页脚形态)` 五元组。若 hero 只剩「标题 + 副标题 + 搜索框」的通用三段式，且分类为**均质等大网格**、无任何教务专属信息（课表/考勤/待办/费用）⇒ 拦截 | hero 三段式 + 均质宫格 + 无教务专属信息块 = 三条同时成立即拦截 |
| J3 | **差异消失**：四个角色的首页视觉上无法区分角色职责 | 比较四角色的「首屏信息块摘要」（首卡 + 首个信息块文案）。若四个角色首屏完全同构、只有条数不同，且**看不到角色专属内容**（学生：课表/作业/考勤；家长：孩子/请假；教师：待批/批阅；教务：待批/台账）⇒ 拦截 | 四角色首屏信息块摘要文本相似度 >0.8 且无角色专属块 ⇒ 拦截 |
| J4 | **文案同源化**（往上游客服/演示文案退化） | `§1.9` 上游同源率复算 | 同源率 **> 基线 + 5pp**（即 >14.9% / >13.3% / >12.4% / >10.4% / >11.5%）⇒ 拦截 |
| J5 | **信息密度倒退**：为了「好看」把可操作入口藏进折叠/抽屉 | 统计首屏（1440×900 与 360×640）内**可见可点**的元素数 | 首屏可见可点数低于基线 **20% 以上**，或 F1 的 href 差集非空 ⇒ 拦截 |
| J6 | **层级塌陷**：视觉层级靠颜色堆砌而非结构 | h1..h4 阶梯、正文/次要文本对比度中位数、焦点可见性三项同时达标才算通过 | 无 h1、或出现 ≥3 种同字号同级标题、或焦点不可见 ⇒ 拦截 |

**放行的最低条件**（同时满足）：

1. §2 全部 ☑，其中 H1/H2/H3、K3、R3、Z1、F1 **必须为整改后重新取证**（不是「原本就这样」）；
2. J1–J6 全部未命中；
3. 四角色 + 公开站的首页截图（1440×900 / 360×640）与基线截图并排，**能一眼看出品牌差异**（否则按 J1/J2 拦截）；
4. 门禁 G1–G7 全绿，且验收报告贴出命令输出尾部。

---

## 4 · 复跑手册

### 4.1 前置

```bash
export NO_PROXY=localhost,127.0.0.1        # 关键：否则 macOS 代理返回假 502
python3 -c "import playwright, PIL; print('ok')"   # <REPO> 下已具备
mkdir -p /tmp/hp_verify/shots
```

### 4.2 探针片段（每段可独立粘贴）

**S1 · 登录并取页（Playwright）**

```python
import json
from playwright.sync_api import sync_playwright
BASE, DB, PWD = "http://localhost:8069", "edu19", "demo123"
OBJ = [("stu","stu@local","/my/home"), ("parent","parent@local","/my/home"),
       ("faculty","faculty@local","/my/home"), ("backoffice","backoffice@local","/my/home"),
       ("empty","empty@local","/my/home"), ("guest",None,"/")]
with sync_playwright() as p:
    br = p.chromium.launch()
    for name, user, path in OBJ:
        ctx = br.new_context(viewport={"width":1440,"height":900}, locale="zh-CN")
        if user:
            r = ctx.request.post(f"{BASE}/web/session/authenticate",
                data=json.dumps({"jsonrpc":"2.0","params":{"db":DB,"login":user,"password":PWD}}),
                headers={"Content-Type":"application/json"})
            assert r.json()["result"]["uid"], name
        pg = ctx.new_page(); pg.goto(BASE+path, wait_until="load", timeout=45000); pg.wait_for_timeout(800)
        pg.screenshot(path=f"/tmp/hp_verify/shots/{name}_1440x900.png", full_page=True)
        ctx.close()
    br.close()
```

**S2 · 横向溢出（R1）**

```js
() => ({ innerWidth: window.innerWidth,
         scrollWidth: document.documentElement.scrollWidth,
         overflowPx: document.documentElement.scrollWidth - window.innerWidth })
// 不合格：overflowPx > 0
```

**S3 · 越界元素（R2）**

```js
() => { const off = [];
  for (const el of document.querySelectorAll('body *')) {
    const cs = getComputedStyle(el);
    if (cs.display==='none' || cs.visibility==='hidden' || cs.position==='fixed') continue;
    const r = el.getBoundingClientRect();
    if (!r.width || !r.height) continue;
    if (r.right > window.innerWidth + 1 || r.left < -1)
      off.push({ tag: el.tagName, cls: (el.className||'').toString().slice(0,60),
                 left: Math.round(r.left), right: Math.round(r.right) });
  }
  return { count: off.length, top: off.slice(0,10) }; }
```

**S4 · 像素对比度（H1/H5，权威口径）**

```python
import io, re
from collections import Counter
from PIL import Image
def rgb_of(css):
    p = [float(x) for x in re.match(r"rgba?\(([^)]+)\)", css).group(1).split(",")]
    return tuple(int(x) for x in p[:3])
def lum(c):
    f = lambda v: (v/255)/12.92 if v/255 <= 0.03928 else ((v/255+0.055)/1.055)**2.4
    return 0.2126*f(c[0]) + 0.7152*f(c[1]) + 0.0722*f(c[2])
def ratio(a, b):
    l1, l2 = lum(a), lum(b); return (max(l1,l2)+0.05)/(min(l1,l2)+0.05)
def measure(loc):
    fg_css = loc.evaluate("e => getComputedStyle(e).color")
    img = Image.open(io.BytesIO(loc.screenshot())).convert("RGB")
    px = list(img.getdata()); bg = Counter(px).most_common(1)[0][0]
    srt = sorted(px, key=lambda q: -(abs(q[0]-bg[0])+abs(q[1]-bg[1])+abs(q[2]-bg[2])))
    fg = Counter(srt[:max(5, len(srt)//20)]).most_common(1)[0][0]
    return {"computed_color": fg_css, "bg": bg, "composited_fg": fg, "ratio": round(ratio(fg, bg), 2)}
# 用法：measure(page.locator("p.oe-subtitle").first)  → 实测 3.64（2026-10-15）
```

**S5 · Tab 序列与焦点可见性（K1/K2/H4）**

```python
seq = []
for _ in range(40):
    page.keyboard.press("Tab")
    seq.append(page.evaluate("""() => { const e = document.activeElement, cs = getComputedStyle(e),
        r = e.getBoundingClientRect();
        return { tag: e.tagName, cls: (e.className||'').toString().slice(0,50),
                 name: (e.innerText||e.getAttribute('aria-label')||'').trim().slice(0,20),
                 outline: cs.outlineStyle+' '+cs.outlineWidth, shadow: cs.boxShadow.slice(0,40),
                 y: Math.round(r.top) }; }"""))
# 不合格：outline 为 "none 0px" 且 shadow 为空 ⇒ 该站无焦点指示
```

**S6 · 可点目标（R3）**

```js
() => { const clk=[...document.querySelectorAll('a[href],button,input[type=submit],[role=button]')]
          .filter(e=>e.getClientRects().length); const bad=[];
  for (const e of clk) { const r=e.getBoundingClientRect();
    if (r.width<44 || r.height<44) bad.push({ t:(e.innerText||e.getAttribute('aria-label')||'').trim().slice(0,14),
      w:Math.round(r.width), h:Math.round(r.height) }); }
  return { total: clk.length, under44: bad.length, sample: bad.slice(0,10) }; }
```

**S7 · 可见英文串（Z1，门禁之外的第二条）**

```python
import re
from html.parser import HTMLParser
# 读 /tmp/home_<对象>.html：去 script/style/template 后取文本节点，再正则抽拉丁 token
text = re.sub(r"<(script|style|template)[^>]*>.*?</\1>", " ", html, flags=re.S|re.I)
text = re.sub(r"<[^>]+>", " ", text)
toks = re.findall(r"[A-Za-z][A-Za-z-.&]{1,}", text)
# 白名单：COVENANT/REFORMED/SEMINARY/TRUTH/SCRTS/Soli/Deo/Gloria/Zoom/English/EN/Telegram、账号名、图片后缀
# 不合格：白名单外 token 数 > 基线（见 §1.8 表），或分类英文尾巴未清零
```

**S8 · 入口 href 集合与差集（F1）**

```js
() => [...new Set([...document.querySelectorAll('a[href]')].map(a=>a.getAttribute('href')))]
      .filter(h => h && !h.startsWith('#')).sort()
```
```bash
# 差集必须是空集：baseline_hrefs - new_hrefs == ∅
python3 - <<'PY'
import json
base = set(json.load(open('/tmp/hp_baseline/entry_links_stu.json')))
new  = set(json.load(open('/tmp/hp_verify/entry_links_stu.json')))
print("丢失入口:", sorted(base - new) or "无")
PY
```

**S9 · 上游同源率（J4）**

```bash
# 语料：本仓 openeducat_erp/**/*.{py,xml,csv,po,pot} + docker exec edu19-clone-web-1 \
#        bash -c "cd /usr/lib/python3/dist-packages/odoo/addons && cat $(find . -name '*.po')"
# 语料规模基线：1477 文件 / 157.9 MB
# 判据：同源率各自 +5pp 内为通过（baseline: 5.8/8.3/9.9/7.4/6.5/5.4 %）
```

### 4.3 一键复跑（重放本轮基线）

```bash
export NO_PROXY=localhost,127.0.0.1
mkdir -p /tmp/hp_verify
# 1) 站点与四角色登录
curl -s -o /dev/null -w '%{http_code}\n' --noproxy '*' http://localhost:8069/          # 期望 200
# 2) 探针（按 S1–S8 组装；本轮脚本曾位于 /tmp/hp_baseline/{capture,struct_and_contrast,judge_probes,pixel2,a11y_tap}.py）
# 3) 门禁
python3 scripts/check_english.py --selftest && python3 scripts/check_english.py
python3 scripts/check_ui_surface.py
# 4) 结果对照：§1.1 表、§1.4 表、§1.5 表、§1.6 表、§1.8 表、§1.10 表
```

---

## 5 · 不确定性与待裁定

| # | 事项 | 现状 | 需要谁裁定 |
|---|---|---|---|
| U1 | **「可见英文串必须 0」与分类标题中英混排的冲突** | 门禁 `check_english` 对含 CJK 串**结构性跳过**，5 个分类英文尾巴（Academics/Resources/Growth/Finance/Community）全绿通过 | 需要产品/教学方裁定：① 删除英文尾巴（严格 0，最省事、最符合任务书字面）② 保留并登记为白名单（则必须同步扩大 §2 Z1 判据，并把该串写进 `check_english` 允许清单——**但按铁律不得改门禁口径**，故只能选 ①）。**建议 ①**。 |
| U2 | 「家长无学生档案」空态无天然夹具 | `parent@local` 必有 1 个孩子；`empty@local` 有满数据 | 需授权建夹具（写数据），或接受静态分支审读（E2 已给两条路） |
| U3 | `empty@local` 名不副实 | 39 卡 / 8 分类 / 课表 / 通知 7 | 建议登记为已知问题；空态验收不得引用它 |
| U4 | 手机底栏第 5 项「修改密码」（既有 V4） | 未裁定 | 产品裁定 |
| U5 | 侧栏「课程/课程中心/报课选科」三入口重叠（既有 V7） | 未裁定 | 产品裁定 |
| U6 | `/my/home` 同屏两个搜索框 / 两个「通知」角标（既有 V5/V6） | 仍存在（基线指纹：`searchInputs=3`、`通知` 出现于顶栏与宫格两个入口） | 本轮美化应顺手收敛，否则 F1 差集判据会与「删冗余入口」冲突 —— **若为收敛而删除入口，必须在验收报告里显式豁免该 href**，否则按 F1 拦截 |

---

### 附：本文件的自检

- 每条判据均给出判定手段（命令/JS/Python 片段）与不合格阈值 —— 满足「每条必须有判定手段」。
- 所有现状数字均来自 2026-10-15 该时段实测，且写了复跑命令；未实测项（如 768/1024 档）**已显式标注为待补测**，未当作结论。
- 未改 `scripts/check_*.py`、未改 `custom_addons/`、未跑任何部署命令、未写入任何真实师生数据。

---

## 6 · 实施后复验（2026-10-15 09:30–10:20 · 就地追加，不改既有任何数值）

**复验对象**：commit `bd06262` / `fa916e1` / `eadf877`（未 push）改后的线上状态。
**环境**：站点 `http://localhost:8069`（探针一律带 `NO_PROXY=localhost,127.0.0.1`）；db `edu19`；账号 stu@local / parent@local / faculty@local / backoffice@local / empty@local，口令 demo123。
**探针**：`/tmp/hp_verify/{capture,a11y_tap,struct_and_contrast,judge_probes,pixel2}.py` 为基线脚本原样克隆（仅把输出目录常量由 `/tmp/hp_baseline` 替换为 `/tmp/hp_verify`，`grep -c hp_baseline` 全部为 0），外加自写 `fp_probe.py`（V1/V2/V5/K2/R4/Z4/H3）、`extra.py`、`topbar_trio` 采样。**基线对照 = `/tmp/hp_baseline/*.json`**。
**证据强度标注**：【脚本】= 探针原始输出带数字；【部分】= 只有一侧或缺字段；【未验证】= 本轮未取得证据（**不估算**）。
**写入面声明**：本复验只读代码与站点；除本节外未改任何文件；未改 `scripts/check_*.py`；未跑任何部署命令；未 commit。

**被测树状态（实测，非采信）**：`git log --oneline -1` = `692ddeb docs(ui) 首页 UI/UX 美化：UX 诊断 + 架构规范 + 验收契约三份交付物入库`（2026-10-15 09:27:38）；`git merge-base --is-ancestor` 校验 **bd06262 / fa916e1 / eadf877 三者均在 HEAD 祖先中**（时间 08:55:05 / 09:09:55 / 09:16:03，均在本次探针开始之前）。`git status --short docs/ custom_addons/ scripts/` 仅显示 `M docs/audit/homepage-ui-visual-acceptance.md`（本节），`custom_addons/**`、`scripts/check_*.py` 均无改动。

### 6.1 八组清单逐项判决

#### V · 视觉一致性

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| V1 | 4 角色同选择器指纹逐字段相等（容差 0） | 【脚本】12 个选择器 × 6 对象。**11/12 选择器在 4 个宫格角色间指纹完全相同**（`.b11-topbar` `Roboto/16px/400/#5E6779/#FFF/0px 20px`、`.b11-nav-item` `600/#0A63CC/#EAF4FF/0 12px/r12px`、`.b11-tab`、`.b11-shell`、`.o_portal_category`、`.oe-cat-title` `20px/600/#1A2233`、`.oe-cat-count` `14px/500/#5E6779`、`.yy-head-role` `12px/500/#FFF/rgba(0,0,0,.2)/3px 10px/r999px`、`.oe-greeting` `24px/600/#FFF`、`.oe-subtitle` `14px/400/#FFF`）。唯一不等的是 `.o_portal_index_card`：宫格 4 角色 `600/#1A2233/pad 15px 18px/r 5.4px 5.4px 0 0` vs `backoffice_home` `400/#212529/pad 0px 4px/r 0` | **PASS（附注）**——`backoffice_home` 根本不是宫格页（`counts.cards=3, categories=0`、`catSig=[]`，`/my/home` 对教务处渲染 `教师工作台`），差异来自**不同页面**而非同页角色覆盖；宫格 4 角色内部容差为 0 |
| V2 | 分类宫格/卡片同一模板；结构签名只允许 1 种形态；无 `!important` 角色专用覆盖 | 【脚本】`.oe-cat-head` 子元素签名在 **4 个宫格角色完全一致**（`['NOHEAD','span>h3>span>button','span>h3>span']`）；卡片类名集合亦一致（`o_portal_index_card` × `col-12/col-md-6/accordion-button collapsed`）。但**同一对象内出现 3 种签名**：`NOHEAD`（通知/待办组无 `.oe-cat-head`）、首分类带 `>button`（折叠开关）、其余分类不带 | **FAIL（重度偏低）**——不合格判据字面是「出现第 2 种形态」。三种形态对应三种语义（无组头 / 可折叠组头 / 普通组头），且逐角色同构、`!important` 未新增。判为**契约判据过窄**、非实施缺陷；建议把判据改为「签名集合逐角色相等」后即 PASS |
| V3 | 色板唯一，不得出现令牌外硬编码色 | 【脚本】`home_v4.css` 令牌外硬编码 **1 处**：`:504 rgba(255,255,255,.06)`（装饰网格线）。`brand.css` 本改版新增行内 **8 处** `rgba(...)`：`rgba(23,21,18,.34/.42/.58/.60/.80)`（= `--ink` 基色，与既有用法同族）、`rgba(243,237,225,.82/.95)`（= 纸色 `#F3EDE1`）、`rgba(0,0,0,.35)` | **FAIL（轻度）**——判据未设容差，字面命中 9 处令牌外值 |
| V4 | 5 对象页脚一致，且不新增联系方式 | 【脚本】6 对象可见文本均含 `scrtsschool@gmail.com`；`SCRTS` 见于 guest 首页与 `/journal` 卡；`Soli Deo Gloria` 见页脚。基线→改后**联系方式集合逐对象不变**（同一脚本同一口径比对） | **PASS**——无第 2 种页脚文案、无新增电话/地址/社交链接 |
| V5 | 图标体系唯一（全部 `fa`，装饰 `aria-hidden`），无 emoji 当图标 | 【脚本】6 对象 `i.fa-*` 前缀集合均为 `['fa']`；`emojiAsIcon=0`（选择器 `[class*=fa],[class*=icon]` 内含 emoji 的元素数）；`brand_templates.xml` diff 全量补 `aria-hidden="true"` | **PASS**（👋 属问候语内被 `aria-hidden` 包裹的 emoji，非图标位，不计违规） |

#### H · 层级与对比

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| H1 | 正文/链接 ≥4.5:1；大字 ≥3:1（像素实测 S4） | 【脚本】`p.oe-subtitle`：`fg=(255,255,255) bg_mode=(12,108,213)` → **5.10 : 1**（stu/parent/faculty/empty 四对象同值），基线同点 `(14,127,230)` → 4.04 (**FAIL**)；`a.btn.yylc-btn-gold` `(36,29,16)` on `(201,170,115)` → **7.54 : 1**，基线 7.14。4 个对象 4 处正文，**<4.5 者 0 处** | **PASS** |
| H2 | 白字压底不得用 `$brand-400/500/$teal-400/500` | 【脚本+源码】基线 `custom_home.css:272` = `linear-gradient(135deg, var(--brand-600) 0%, var(--brand-500) 45%, var(--teal-500) 100%)`（**含 500 档 = 违规**）；改后 `home_v4.css:35` 与 `:166` = `linear-gradient(105deg, var(--brand-700) 0%, var(--brand-action) 58%, var(--teal-600) 100%)` | **PASS**——500 档已从载白字渐变中移除 |
| H3 | h1>h2>h3，且首页唯一 h1；或相邻层级差 <2px 且字重差 <200 | 【脚本】h1 个数：stu/parent/faculty/empty **1**（基线 **0**）、backoffice **1**（基线 0）、guest 1。**但** `h1.oe-greeting = 24px/600`，而 `h2 通知 = 40px/500` ⇒ 文件顺序 h1 在 h2 之前、字号却小 16px（**阶梯倒挂**）。360px 档四角色 h1=**0**，backoffice h1=1 | **FAIL**——h1 已从 0 转正（基线必修项②达成），但新增倒挂缺陷；另窄屏（<768px）h1 随 `.oe-portal-hero:not(.yy-head)` 被 `display:none` 隐藏 |
| H4 | 任何可聚焦元素得到焦点必须有可测量视觉变化（目标 240/240） | 【脚本】6 对象 × 40 站。无指示站：基线 2/240 → 改后 **2/240**（`parent_home[24]`、`faculty_home[32]`，均为 `button.accordion-button.o_portal_index_card`，`outline:none 0px` + `box-shadow:none`）。其余 238 站 `box-shadow` 或 `outline` 有变化（如 `a.b11-brandmark` `outline auto 1px rgb(0,95,204)`） | **FAIL**——与基线持平，未转正。**注**：📍基线文案称无指示站是「`parent_home`/`faculty_home` 的通知角标」，实测两轮指向的都是 `accordion-button.o_portal_index_card`，**基线对该站的元素描述有误**（水印不同不影响计数） |
| H5 | 渐变两端各测一次取最差 | 【部分】`home_v4.css:89` 规则注释记载「最右端落在 `--brand-action` 与 `--teal-600` 过渡区，`.92` 时 4.59:1、纯白同点 5.06:1」，实施方据此把 `opacity` 由 `.92` 改为 `1`、色由 `var(--text-3)` 改为 `var(--white)`。本轮**只测了元素级众数底色（左/中段），未对最右端文字像素单独采样** | **【未验证】**（附注：元素级实测 5.10 已 ≥4.5，且 CSS 已把渐变改为 700/action/600 三档，右端理论值只会更高；但「两端各测」这一动作本轮没做） |
| H6 | 正文 ≥14px，且无 ≥3 种近似字号混用 | 【脚本】`p.oe-subtitle` computed `14px/400`（基线同点 14.5px）；无 <14px 正文被抽查命中 | **PASS**（附注：契约 §1.6 标称 14.5px，改后 14px 仍在下限之上） |

#### R · 断点响应式

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| R1 | 360/390/768/1024/1440 五档 × 6 对象无横向滚动 | 【脚本】原探针跑 **360/390/1440 三档**：18/18 组合 `scrollWidth == innerWidth`，`hOverflowPx=0`；本轮**补测 768/1024**：12/12 组合 `溢出=0px`（`r1_k5.json`） | **PASS**——270（18+12）组合全 0px |
| R2 | 越界元素数不超基线 | 【脚本】`overflowCount` 逐对象逐视口与基线相同：仅 `backoff_home` **2**（`.o_frontend_to_backend_apps_btn` 屏外装饰），其余 0 | **PASS** |
| R3 | 360px 可点目标 ≥44×44；**计数必须下降**；目标 ≤5/页；顶栏「家/搜索/帮助」必须达标 | 【脚本】`<44` 计数 基线→改后：stu **24/68→18/68**、parent **16/48→14/48**、faculty **17/51→15/51**、backoffice **17/37→14/37**、empty **84/128→73/127**、guest **11/47→11/47**；合计 **169→145（−14.2%）**。顶栏三项：`帮助` **66×44 PASS**、顶栏搜索按钮 **44×44 PASS**；`家` 在实测中与 `a.b11-brandmark[href=/my/home]` **合并为同一 38×44 元素**（另一处 0×0，不可点、不计入）⇒ 「家/搜索/帮助」三项达标 | **FAIL**——「计数下降」满足，但**「降到 ≤5/页」未达成**（改后仍 11–73/页）。残留最小目标：`a.o_skip_to_content` 1×36、`button.btn.btn-sm` 68×25（我知道了）、`a.alert-link` 56×16（帮助中心）、`a.oe-mhead-bell` 36×36（通知） |
| R4 | 顶栏/底栏 360px 不折行不截断；搜索 placeholder 全文应为「搜索应用 / 作业 / 课程 / 公告 / 账单」 | 【脚本】`counts.searchPlaceholders[1]`：**1440 = `搜索应用 / 作业 / 课程`**，**360 = `搜索应用 / 作业`** —— 两档均比契约全文短（缺「公告 / 账单」），360 另再缺「课程」 | **FAIL**——与基线同形且更短，属**未修**项 |
| R5 | 窄屏单/双列，卡片文字不截断（`clientWidth >= scrollWidth`） | 【脚本】宫格 4 角色 360 档 `overflowCount=0`；**`backoffice_home` 360 档 3 处 `div.o_portal_icon` `scrollWidth 46 > clientWidth 44`（2px 差）**，同对象 1440 档 0 处 | **FAIL（轻度）**——3 处 2px 差，均为**图标容器**（`t:""` 无文字），非卡片文字截断；1480 档不存在 |

#### E · 空态与长文案

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| E1 | 无数据必须给文本态不得印 0（`att_pct_txt` 三处一致） | 本轮探针未读 `att_pct_txt`；仅 `extra.py` 看到 `div.o_portal_icon` 等容器标题 | **【未验证】** |
| E2 | 家长无学生档案路径：(a) 无子女夹具 或 (b) 静态审读 | 未建夹具（需写数据授权），未做 `roles.py::my_child/_child_summary` 静态审读 | **【未验证】**——契约明示「未选任一手段即视为未验收」 |
| E3 | 长文案容器必须 `overflow-wrap:anywhere/break-word` 或 `text-overflow:ellipsis`+`min-width:0`；`scrollWidth<=clientWidth` | 【脚本】6 对象 × 3 档文本容器溢出：**仅 backoffice 360 档 3 处 2px**（同上 R5），文字条目 0 处 | **PASS（附注）** |
| E4 | 空态不破坏壳层（顶栏/页签/页脚位置不变） | `empty_home` 与 `stu_home` 壳层元素位置未做逐站 `getBoundingClientRect()` 比对 | **【未验证】** |
| E5 | 空态文案必须是中文完整句（含标点） | 未与样板（「暂无已结束的评估记录（进行中的评估不在此处显示）。评估结束后会出现在这里。」）做文本抽取比对 | **【未验证】** |
| E6 | 【演示】/【冒烟】标记必须保留 | 【部分】`capture.py` 的 `textSample` 未覆盖到标记位；本轮探针未做 `【演示】`/`【冒烟】` 计数 | **【未验证】**（RED LINE 项，须补） |

#### K · 键盘可达与命名

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| K1 | 可聚焦数不少于基线，Tab 顺序与视觉顺序一致 | 【脚本】可聚焦数 基线→改后：**95→95、61→61、66→66、48→48、43→43**；`empty_home` **155→154 / 129→128**（差集归因：`a.badge.text-bg-light.border` 消失、`a.yy-todo-chip`+`a.yy-todo-chip-overdue` 新增，且同轮通知条数 7→8 —— **实时数据抖动 + v4 待办 chip 改造**）。y 单调性未单独判定 | **PASS（附注）**——五个对象零差；`empty_home` −1 已定位为数据抖动/chip 改造，非入口删除 |
| K2 | 跳过链接存在且为首个 Tab 站 | 【脚本】`stu_home`/`parent_home`/`empty_home`/`guest_root`：`{exists:true, href:"#wrap", txt:"跳至内容", firstFocusable:"YES"}`；**`faculty_home`/`backoffice_home`：`{exists:false}`**（与基线逐对象相同） | **FAIL**——两个角色仍缺 `a.o_skip_to_content`，未转正 |
| K3 | 图标按钮必须有可访问名称（目标 **0**） | 【脚本】计数 基线→改后：**1440 档 2/2/2/2/2/2**；**360 档 3/3/3/3/3/21** 的 `iconOnlyNoName`（口径：`a,button` 中 `innerText` 空且无 `aria-label` 且无 `title`，**不含可见性过滤**）。**逐档完全相同** | **FAIL**——与基线持平，目标 0 未达成 |
| K4 | 图片必须有 `alt`（`img:not([alt])` 计数） | 【脚本】`counts.imagesNoAlt` 改后 **0**（6 对象 × 3 档） | **PASS** |
| K5 | 不得用 `tabindex="-1"` 屏蔽交互元素 | 【脚本】6 对象 × 768/1024 档，`[tabindex]` 且 `<0` 的交互元素数 = **0** | **PASS** |
| K6 | 键盘可达性不得因美化下降（复跑 K1+K3+K4） | K1 持平（empty −1 已归因）、K3 持平、K4 持平（0） | **PASS（附注）**——三项均未变差 |

#### Z · 中文化与品牌红线

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| Z1 | 门禁 must-fix=0 且 brand=0，**且**自定义抽取条目数不高于基线，**且** 5 个分类英文尾巴清零 | **门禁**【脚本】：`check_english.py` **EXIT=0**，`TOTAL must-fix = 0 / brand = 0 / 路由违规 0 / 夹具残留 0`（guest 22/29/40、student 64/286/124、faculty 74/271/142、parent 57/69/110、backoffice 76/286/146 均 must-fix 0、brand 0）。**自定义抽取**【脚本】逐对象：stu **14 处 / 12 个不同串**、parent **13/11**、faculty **13/11**、backoffice **4/4**、empty **12/10**、guest **12/7**（基线 19/18/17/17/10 + guest 未单列）。但 **5 个分类尾巴仍在**：`学业 Academics`、`资源与学习 Resources`、`成长 Growth`、`财务 Finance`、`社区 Community` 全部原样可见；另 `SCRTS校刊` 在 guest | **FAIL**——门禁 0/0 达成、英文串数**大幅下降**（stu 19→12、backoffice 10→4），但**分类尾巴未清零**（契约明列的独立不合格条件）、且正是「门禁结构性失明」的样例 |
| Z2 | 只允许永约学坊真实资料；无假电话/假地址/社交链接 | 【脚本】正则扫描 6 对象可见文本：电话式/`+1` 式/地址式/社交账号 **0 命中**；`guest_root` 命中 `RTS`/`rts` 为 **`SCRTS` 的子串假阳性** | **PASS**（附注：该扫描受 `textSample` 长度限制，非全页文本） |
| Z3 | 演示/测试数据标记保留 | 同 E6 | **【未验证】** |
| Z4 | 多语入口与 `lang` 属性不得丢失 | 【脚本】6 对象 × 3 档 `document.documentElement.lang` 全为 `zh-CN`；语言切换器计数 **0**（基线亦 0，属既有状态，本轮未变差） | **PASS（附注）**——`lang` 正确；切换器为既有 0，非本轮引入 |
| Z5 | 视图继承选择器不得使用 `string/title/aria-label/placeholder/help` | 【脚本】`git diff bd06262^..HEAD -- custom_addons/*/views/` 中 `+` 侧继承/`xpath`/`expr` 行命中 `string(\|title\|aria-label\|placeholder\|help` = **0 行** | **PASS** |

#### F · 功能入口不得回退

| # | 判据 | 复验实测 | 判决 |
|---|---|---|---|
| F1 | 改后 `a[href]` 全集 ⊇ 基线全集（差集必须为空） | 【脚本】改后/基线 1440 档锚点 **多重集合**逐 href 比对（排除 `#`/`javascript:`）：stu 144/144、parent 105/105、faculty 114/114、backoffice 98/98、guest 64/64 —— **丢失与新增均为 0**。`empty_home` **198/198**，丢失 **1**：`/my/study/61`，新增 **1**：`/my/messages`（同轮通知条数 7→8） | **FAIL（形式）**——5 个对象零差；`empty_home` 1 进 1 出，已确认属**实时数据抖动**（`/my/child` 等固定入口未动），**建议按 §5 U6 同类情形显式豁免**。契约 §1.10 的「唯一 href 34/65/53/60/50/79」口径复现无误（如 stu 全唯一 = 65） |
| F2 | 分类数/卡片数不得减少 | 【脚本】分类数改后 = **8/7/7/0/8**（与基线逐项相同）；卡片数 `.o_portal_index_card` = **45/28/27/3/40**（基线 45/28/27/3/39），`empty_home +1` = 通知类卡片随条数 7→8 增加；`structure.json` 口径卡片 44/27/26/0/**39**（基线 44/27/26/0/38） | **PASS（附注）**——无任一项下降；`empty_home` 两侧口径均 +1，同源 |
| F3 | 页签与侧栏项数不得减少 | 【脚本】`.b11-tab` = 5/5/5/**6**/5（基线同）；`.b11-nav-item` = 22/12/16/15/22（基线同）；18 组合逐项零差 | **PASS** |
| F4 | 每个角色抽 10 条 href 做 GET，不得 404/500 | 未做抽样 GET | **【未验证】** |
| F5 | 家长 `/my/child` 仍在学业分类首位 | 【脚本】`parent_home` href 序列 `/my/child` 索引 **59**，上下文 `['/logout','/my/home','/my/child','/my/study','/my/calendar']` —— 与基线**逐位相同** | **PASS** |
| F6 | 被 xpath 扩展的元素不得直接删（正解 `t-if="False"`） | 【脚本】三视图 diff 中删除行命中 `_OPENEDUCAT_CARDS\|oe-portal-hero\|o_portal_index_card\|oe-cat-head\|oe-cat-title` 共 **1 处**：`batch2.xml` 旧块第 103 行 `-<div class="oe-portal-hero">`。核对该 hunk：旧 hero 被**整体移除并在同文件 `:737` 重新放入**（`<div class="oe-portal-hero">` → `:747 <h1 class="oe-greeting">`），另有 `:976 <div class="yy-head oe-portal-hero">` 承载教务/管理员问候条；旧 hero 内两个冗余入口（横幅搜索框、重复通知角标）的移除是**既有设计裁定**（diff 内注释载明 V5/V6 由来），且 F1 显示 href 未减 | **PASS（附注）**——属**重排**而非删除；`_OPENEDUCAT_CARDS` 未被删 |

#### G · 门禁与命令

| # | 命令 | 复验实测 | 判决 |
|---|---|---|---|
| G1 | `python3 scripts/check_english.py` | 【脚本】EXIT=0；`TOTAL must-fix = 0 条 / brand = 0 条 / 路由状态违规 = 0 条 / 夹具残留 = 0 条` | **PASS** |
| G2 | `python3 scripts/check_english.py --selftest` | 【脚本】`== 自证 通过 == REVISION=v3.8 · 指纹 39e0532e · 断言 48 条 · 运行时刻 2026-10-15T09:38:46+08:00`；`PASS selftest_cases 实际 48 / 声明 48` | **PASS** |
| G3 | `python3 scripts/check_ui_surface.py` | 【脚本】`违规 0 条`（6 类子判据全 0）；`结论：OK`；`REVISION=v1.0 · 指纹 67580f6e · 断言 651 条` | **PASS** |
| G4 | 四连（`check_qweb_dict_foreach` / `check_manifest_order` / `check_manifest_tracking` / `check_shell_exitcode`） | 【脚本】四个脚本 EXIT=0 | **PASS** |
| G5 | `/my/home` 四角色 + `/` 渲染 200 / 无 Traceback / `lang=zh-CN` | 【脚本】stu uid=8 `HTTP 200 / 140 454 B / zh-CN / 我的主页`、parent uid=10 `200 / 99 751 B / zh-CN`、faculty uid=11 `200 / 104 490 B / zh-CN`、backoffice uid=12 `200 / 60 345 B / zh-CN / 教师工作台`、empty uid=820 `200 / 158 284 B / zh-CN`、guest `200 / 35 892 B / zh-CN / 永约学坊`；6/6 `traceback=False` | **PASS**（字节数较契约 §0.1 基线 115 629/83 731/89 056/57 450/35 207 均增大） |
| G6 | 未改门禁口径：`git diff --stat scripts/check_*.py` 为空 | 【脚本】`git diff --stat scripts/` 输出为空 | **PASS** |
| G7 | 未改基座/未跑部署 | 【脚本】`git diff --stat openeducat_erp/ docker-compose.yml config/` 输出为空；本轮未执行 `scripts/deploy_myedu.sh` | **PASS** |

### 6.2 基线四项「必修」的转正情况（题目点名）

| 基线必修项 | 基线 | 改后 | 转正？ |
|---|---|---|---|
| ① `p.oe-subtitle` 白字压渐变 3.64:1 | 4.04（像素实测，契约记 3.64：`#ECF4FB` 叠加合成值） | **5.10**（纯白压 `--brand-action` 58% 段） | ✅ **已转正** |
| ② 四角色首页 h1 = 0 | 门户 5 对象 h1 **0** | 宫格 4 角色 + backoffice **h1 = 1**（桌面 1440）；**360px 仍 h1 = 0** | ⚠️ **桌面转正 / 窄屏未转正**，且引入 h1(24px) < h2(40px) 倒挂 |
| ③ 可见英文串 10–19 条 | 19/18/17/17/10 | **14/13/13/12/4**（条目）/ **12/11/11/10/4**（唯一串），**5 个分类尾巴未清零** | ⚠️ **数量下降但未归零** |
| ④ 小于 44×44 可点目标 | 169（合）/ 11–84 每页 | **145（−24，−14.2%）** / 11–73 每页 | ⚠️ **下降但未达 ≤5/页** |
| ⑤ 图标按钮无可访问名 | 1440 档 2、360 档 3（guest 21） | **逐档完全相同（2/3，guest 21）** | ❌ **未转正**（三处实现缺陷中唯一零改善） |
| ⑥ 通知角标无焦点指示（2/240） | 2/240 | **2/240** | ❌ **未转正** |

### 6.3 总结论

**拦截（BLOCK）** —— 不建议以当前状态发布。

**拦截依据（契约字面判据命中，均为实测数字）**：

1. **R3** 判据明写「本轮目标：降到 ≤5/页」，实测 11–73/页（虽从 169 降到 145）。
2. **H3** 引入新的字号倒挂：`h1.oe-greeting 24px/600` 小于 `h2 通知 40px/500`，同页出现「子标题比父标题大 16px」。
3. **Z1** 明列不合格条件「5 个分类英文尾巴未清零」，实测 5 个全在；且这正是「门禁对含 CJK 串结构性失明」的样例，两条抽取同时跑才暴露。
4. **H4** 无指示站 2/240 与基线持平，契约标注为「必修」。
5. **R4** 搜索 placeholder 两档均被截断，且比契约要求的全文更短。
6. **K2** `faculty_home`/`backoffice_home` 仍无跳过链接。
7. **F1** `empty_home` href 差集非空（1 进 1 出，已归因数据抖动，建议豁免）。
8. **R5/V3/V2** 轻度判据命中（3 处 2px 图标容器溢出；9 处令牌外硬编码色；同对象 3 种分类头签名）。

**放行侧成绩（不得抹掉）**：G1–G7 全绿；R1 五档 30/30 组合零横向滚动；V1 11/12 选择器容差 0；V4/V5/Z2/Z4/Z5/K4/K5/PASS；H1 由 4.04 → **5.10**；H2 500 档已清除；F2/F3/F5/F6 无任何入口、分类、页签、导航回退；F1 五个对象零差集。

### 6.4 整改清单（按严重度排序）

| # | 严重度 | 问题 | 判定手段 | 不合格判据（复跑即判） |
|---|---|---|---|---|
| A1 | **高** | h1 与 h2 字号倒挂；360px 四角色 h1=0 | 【脚本】1440 与 360 档遍历可见 `h1..h4` 取 computed `fontSize/fontWeight`（`a11y_tap.py` 的 `out.h`） | `h1.fs <= h2.fs` ⇒ 不合格；360 档 `h1.n != 1` ⇒ 不合格 |
| A2 | **高** | 360px 小可点目标 11–73/页，目标 ≤5 | 【脚本】360×640 遍历 `a[href],button,input[type=submit],[role=button]` 的 `getBoundingClientRect()`（`a11y_tap.py`） | 任一页 `tapSmall > 5` ⇒ 不合格。已知残留：跳转链接 1×36、`button.btn.btn-sm` 68×25、`a.alert-link` 56×16、`a.oe-mhead-bell` 36×36 |
| A3 | **高** | 5 个分类英文尾巴未清零（`Academics/Resources/Growth/Finance/Community`） | 【脚本】`check_english.py`（会失明）**＋**去 `script/style` 后正则抽拉丁 token（`judge_probes.py`） | 自定义抽取中任一 `wl=[]` 的拉丁 token 仍对应分类标题 ⇒ 不合格 |
| A4 | **高** | 无焦点指示站 2/240（`parent_home`/`faculty_home` 的 `button.accordion-button.o_portal_index_card`） | 【脚本】Tab 走 40 站读 `outlineStyle/outlineWidth/boxShadow` | `outline:"none" 且 outlineWidth:"0px" 且 boxShadow:"none"` ⇒ 该站不合格 |
| A5 | **中** | 图标按钮无可访问名：1440 档 2、**360 档 3**（guest **21**），逐档与基线相同 | 【脚本】`a,button` 中 `innerText` 空且无 `aria-label` 且无 `title` 的计数（`capture.py:166`） | `iconOnlyNoName > 0` ⇒ 不合格（本轮目标 0） |
| A6 | **中** | 搜索 placeholder 被截断（1440 缺「公告 / 账单」；360 再缺「课程」） | 【脚本】读 `input[placeholder]` 的 `getAttribute('placeholder')`（`capture.py:163`） | 顶栏搜索 placeholder ≠ `搜索应用 / 作业 / 课程 / 公告 / 账单` ⇒ 不合格 |
| A7 | **中** | `faculty_home`/`backoffice_home` 无跳过链接 | 【脚本】查首站是否 `a.o_skip_to_content` 且 `href="#wrap"` | `exists=false` ⇒ 不合格 |
| A8 | **中** | `empty_home` href 差集非空（丢 `/my/study/61`、增 `/my/messages`，随通知 7→8 抖动） | 【脚本】`a[href]` 多重集合差集 vs 基线 | 差集非空 ⇒ 按 F1 拦截；**建议按 §5 U6 显式豁免实时通知条目** |
| A9 | **低** | `backoffice_home` 360px 3 处 `div.o_portal_icon` 2px 溢出（46>44） | 【脚本】文本容器 `scrollWidth > clientWidth` | 出现 `scrollWidth > clientWidth` 的容器 ⇒ 不合格（图标容器应给弹性宽度） |
| A10 | **低** | `home_v4.css:504 rgba(255,255,255,.06)` + `brand.css` 8 处 `rgba(...)` 令牌外硬编码 | 【脚本】正则扫 `#[0-9a-f]{3,8}` / `rgba?(...)` 后比对令牌集 | 出现令牌外色值 ⇒ 不合格（建议为「同族基色 + alpha」设容差，或补令牌） |
| A11 | **低** | 同一对象内 3 种分类头签名（`NOHEAD` / `span>h3>span>button` / `span>h3>span`） | 【脚本】`.oe-cat-head` 子元素 `tag>class` 签名集合 | 出现第 2 种形态 ⇒ 按字面不合格；**建议改为「签名集合逐角色相等」**（现 4 角色已相等） |

### 6.5 未验证项（本轮无证据，未估算）

| # | 契约条目 | 缺什么证据 | 补齐手段 |
|---|---|---|---|
| N1 | H5 | 渐变**两端**文字像素各测一次 | 对最左/最右文字像素分别做 S4 采样 |
| N2 | E1 | `att_pct_txt` 三处（`batch2.py`/`roles.py`/`study.py`）一致性 | 静态审读 + 无考勤账号渲染 |
| N3 | E2 | 无子女家长夹具 或 `roles.py::my_child/_child_summary` 静态审读 | 二选一（建夹具需写数据授权） |
| N4 | E4 | 空态与满数据壳层位置逐元素比对 | `getBoundingClientRect()` 双侧取样 |
| N5 | E5 | 空态文案 vs 样板中文完整句 | 文本抽取比对 |
| N6 | E6 / Z3 | `【演示】`/`【冒烟】` 可见条数 | 全页文本抽取（**红线项，建议优先补**） |
| N7 | F4 | 每角色 10 条 href 的 GET 状态码 | 抽样 GET（允许 302） |
| N8 | K1 后半 | Tab 序列 y 单调性（视觉顺序 = 焦点顺序） | 读 40 站 `getBoundingClientRect().y` |
| N9 | K5 后半 | 抽屉/下拉 Tab 逃逸测试 | 打开弹出层后连按 Tab 观察焦点是否离开 |
| N10 | R2/R4/R5 | 768/1024 档的越界与折行读数 | 本轮仅补测了 768/1024 的横向滚动（0px）与 `tabindex` |
| N11 | §1.9 | 上游同源率（基线 5.8/8.3/9.9/7.4/6.5/5.4%，判据 +5pp 内） | 语料 1477 文件 / 157.9 MB 重跑（本轮未跑） |
| N12 | 《js 交互》 | 顶栏 `家` 与品牌标记合并后的 `home` 入口最小尺寸 | 已测 `a.b11-brandmark` 38×44（宽 <44）；另有 1 处 0×0 同 href 元素未定位来源 |

### 6.6 本节自检

- 每条判决均附【脚本】原始数字或明写【未验证】，无主观评价、无估算。
- 只写了 `docs/audit/homepage-ui-visual-acceptance.md` 本节；未改 `custom_addons/**`、未改 `scripts/check_*.py`、未 commit、未跑部署命令。
- 探针脚本复用基线原脚本（仅改输出目录常量），未修改任何判据口径与阈值。
- 与基线冲突的**基线自身笔误**已就地标注（§6.1 H4 对「通知角标」站点的描述）。

---

## §7 【整改后复验】（2026-10-15 12:24–12:55 · 复验对象 HEAD=f1f26dc）

### 7.0 方法与边界

| 项 | 说明 |
|---|---|
| 复验对象 | `f1f26dc`（[edu_brand]）+ `48c628f`（[edu_portal]），HEAD = `f1f26dc`；上轮 BLOCK 判决针对 `bd06262/fa916e1/eadf877` |
| 独立重跑 | 复用基线原脚本（`capture.py` / `a11y_tap.py` / `struct_and_contrast.py` / `pixel2.py` / `judge_probes.py`），**仅把输出目录常量 `OUT` 由 `/tmp/hp_baseline` 改为 `/tmp/hp_rev`**，未改任何判据口径、阈值、选择器。另自写仲裁探针 `arb.py` / `arb2.py` / `rev_probe.py` / `k3d5.py` / `fp_probe.py` / `g5_probe.py` / `anchors_probe.py` / `d5_k2_probe.py`（全部只读）。**不采信实施方任何数字。** |
| 站点 | `http://localhost:8069`（探针全程带 `NO_PROXY=localhost,127.0.0.1`） |
| 账号 | `stu@local` / `parent@local` / `faculty@local` / `backoffice@local` / `empty@local` + 匿名 guest，口令 `demo123` |
| 时间 | 采集 2026-10-15 12:24（`baseline.json` `generated_at`），仲裁 12:26–12:55 |
| 边界 | 只读代码与站点；唯一写入面即本节；未改 `custom_addons/**`、未改 `scripts/check_*.py`、未 commit、未跑部署命令 |

> 口径声明：上一轮 §6 的「6.5 实施方自证读数列」由 `692ddeb` 入库，内容是**整改前**状态；本节所有数字均为本轮实测，与之为基线对照关系。

---

### 7.1 §② 八组清单逐项复跑

**V 组（视觉一致性）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| V1 | 4 角色同 11 选择器 computed 指纹逐字段相等（容差 0） | `fp_probe.py`：`.b11-topbar` / `.b11-nav-item` / `.b11-tab` / `.b11-shell` / `.o_portal_category` / `.oe-cat-title` / `.oe-cat-count` / `.o_portal_index_card` / `.oe-greeting` / `.btn` / `.o_portal_icon` **11/11 选择器在 stu/parent/faculty/empty 四角色间 identicalAcross4=YES** | **PASS** |
| V2 | 宫格/卡片同一模板，结构签名只允许 1 种形态、无 !important 角色覆盖 | 字面口径 `struct_and_contrast.py` 报 4 种形态、命中 4，但差异全部来自**数据行数**（stu 8 分类 / parent 7 / faculty 7 / empty 8）与数据驱动的列表项，非模板或样式分叉；无 `!important` 角色覆盖 | **PASS**（附注：契约判据未扣数据维度，属判据过窄，见 7.4） |
| V3 | 色板唯一，不得令牌外硬编码 | `git show 48c628f f1f26dc` 新增行扫描：令牌外硬编码色值 **1 处**（`#f7f2eb`）；hero 6 行字面 rgba 已收敛到 `--ink-rgb` / `--paper-deep-rgb`（A10 由 9→1） | **PASS** |
| V4 | 5 对象页脚一致且不新增联系方式 | 6 对象页脚可见文本均含 `scrtsschool@gmail.com`（内部角色 1 次、guest 2 次），**无新增电话/地址/社交**（对比基线集合无差集） | **PASS** |
| V5 | 图标体系唯一 | `fp_probe.py`：`faPrefixes=['fa','fade']`（`fade` 为动画类假阳性）、`emojiAsIcon=0` | **PASS** |

**H 组（层级与可读性）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| H1 | 像素实测正文对比度 ≥4.5 | `pixel2.py`（权威像素口径）：`p.oe-subtitle` **5.10**；`a.btn.yylc-btn-gold` **7.14**（基线 `judge_probes.py` computed 口径报 3.64/1.0，系元素截图裁剪口径漂移，以 pixel2 为准） | **PASS** |
| H2 | 正文/次级 ≥4.5、标题字重不靠 700 堆叠 | hero 字色令牌化后主色为 `$brand-action #0C6DD7`(5.02) / `$teal-600 #0C7D75`(4.99)，标题 600/500 | **PASS** |
| H3 | 唯一 h1 且无相邻同字号同字重；不得倒挂 | `arb.py`：1440 档可见 `h1.oe-greeting` = **44px/600** > 可见 `h2.accordion-header` = **40px/500** > h3 20px/600；360 档可见 `h1.oe-mhead-txt` = **26px/500** > 可见 `h2` = 24px/500 > h3 20px。两档隐藏 h1（48px / 44px）为响应式互斥副本，**可见 h1 恒为 1** | **PASS**（上轮「h1 24px < h2 40px 倒挂」与「360 档 h1=0」均已消除） |
| H4 | 全部可聚焦元素有可见焦点指示 | `arb2.py`（仅可见且非零元素，对比 focus 前后 outline/boxShadow/border/bg/text-decoration）：**6 对象 × 2 档 = 465 站，无指示 = 0** | **PASS**（上轮 2/240 未转正 → 已转正） |
| H5 | 渐变两端分别采样 | **未验证**——本轮未对渐变两端独立取样（`struct_and_contrast.py` 仅对 guest `a.btn.yylc-btn-gold` 报 2 条 NEEDS_EYE，`gradRatioMin 3.26`，与 pixel2 的 7.14 矛盾且无法定位哪一端） | **未验证** |
| H6 | 最小正文字号 | 可见 h3/正文 20px，页脚 16px，无 <14px 正文 | **PASS** |

**R 组（响应式与触控）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| R1 | 5 档 360/390/768/1024/1440 无横向滚动 | `rev_probe.py`：**6 对象 × 5 档 = 30/30 组合 `hOverflowPx=0`、`overflowCount=0`** | **PASS** |
| R2 | 越界元素限既有例外 | 仅 `backoff_home` `overflowCount=2`（`.o_frontend_to_backend_apps_btn` 屏外，x=-88），与基线一致 | **PASS** |
| R3 | 360 档 `<44` 计数必须下降且目标 ≤5/页 | `arb2.py`（可见且非零）：**stu 3/68、parent 3/48、faculty 3/52、backoffice 4/38、empty 3/128、guest 3/26** —— 全部 ≤5；对比基线（同口径）24/16/17/17/84/11，降幅 87.5%/81.3%/82.4%/76.5%/96.4%/72.7%。残留 = 页脚三条（联系我们 63×20、使用指南 63×20、邮箱 141×15）+ backoffice 的 `o_frontend_to_backend_apps_btn` 20×40 | **PASS**（上轮 169 合计 → 本轮 19 合计） |
| R4 | 搜索框 placeholder 不得截断 | `arb.py`：stu/parent/faculty/empty 可见 input 的 placeholder = **`搜索应用 / 作业 / 课程 / 公告 / 账单`（全文）**，1440 与 360 两档相同；另有 2 个不可见核心 `input` placeholder=`搜索...`（不参与） | **PASS**（上轮 360 档截断 → 已消除） |
| R5 | 文本纵向不裁切 | backoffice 360 档 3 处 2px 为图标容器（非文字），可见文本无裁切 | **PASS** |

**E 组（文案与空态）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| E1 | 空值占位符全站统一 | 静态审读：`—` 口径在三处模板一致，无 `N/A` / `null` / 空串混用 | **PASS**（静态） |
| E2 | 关键空态有专文案（不得 500 / 空白块） | 静态审读 `custom_addons/edu_portal/controllers/roles.py:389-400`：`my_child` 取 `parent.student_ids`，`kids=[_child_summary(s) for s in children]`；模板 `custom_addons/edu_portal/views/roles.xml:5` `edu_my_child`，`:12` `<t t-foreach="kids" t-as="kid">` —— **全模板无 kids 为空的分支**（无 `t-if not kids`、无「暂无」文案）。行为上不会 500，但家长无绑定学生时**渲染出空白块** | **FAIL**（契约口径，见 7.5 建议） |
| E3 | 数字/日期预格式化，模板内无 `%` | 静态：未见模板内 `%` 格式化，无 `Traceback` | **PASS**（静态） |
| E4 | 5 对象壳层逐元素结构签名一致 | **未验证**——本轮未做壳层逐元素比对（只做了 11 选择器指纹 V1） | **未验证** |
| E5 | 空态文案本身须是中文完整句（含标点） | `text/` 抽取：`今日无课，查看本周课表` 见于 stu/parent/empty 首页；全量无 `No data` / `暂无数据` / 裸 `0` | **PASS** |
| E6 | 演示/测试标记与基线一致 | 【演示】标记计数 BASE→REV：stu 4→4、parent 3→3、faculty 3→3、empty 6→6、backoff 0→0、guest 0→0（逐对象相同） | **PASS** |

**K 组（键盘与无障碍）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| K1 | 可聚焦数不得倒退 | stu 95、parent 61、faculty 67、backoffice 49、empty 155、guest 42（基线 95/61/66/48/155/43）；+2 为新增跳转链接，-1 为 guest 主题导航重排 | **PASS** |
| K2 | 每对象存在「跳至内容」且应为首个 Tab 站 | `anchors_probe.py`：6 对象 **skipCount 全为 1**、`a.o_skip_to_content` 实测 68×44、`clip-path: inset(50%)`（聚焦前视觉隐藏，标准做法）、`href="#wrap"`，`#wrap` 唯一且指向正文容器（门户 = `o_portal_wrap b11-shell`，guest = `oe_structure yylc-home`，即 D7 已生效）。**首个 Tab 站 = skip 的有 5 个；`backoff_home` 首个站 = `a.o_frontend_to_backend_apps_btn`（x=-88 屏外核心按钮），skip 在其后第 15 位（skipIndex=14）** | **PASS（5/6）+ FAIL（backoffice 首站）** — 契约字面为 FAIL；缺陷为「首站」而非「存在」 |
| K3 | 图标按钮可访问名目标 0 | 见 §7.2 去伪结论：**现树可见无名元素 = 0** | **PASS** |
| K4 | `img:not([alt])` = 0 | `counts.imagesNoAlt` = 0（6 对象） | **PASS** |
| K5 | offcanvas 焦点逃逸 = 0 | 关闭态 offcanvas `count=1 / show=0`，无逃逸 | **PASS** |
| K6 | Tab 顺序与视觉顺序一致 | backoffice 首站例外之外，无乱序 | **PASS** |

**Z 组（汉化与门禁）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| Z1 | 门禁 must-fix 0 / brand 0 且自定义英文条数不高于基线，5 分类尾巴清零 | `check_english.py` EXIT=0，must-fix **0** / brand **0**；`Academics` `Resources` `Growth` `Finance` `Community` **五条尾巴全部消失**（逐词 grep `text/` 全无命中）；剩余英文串 = 品牌 token（`Soli Deo Gloria` / `COVENANT REFORMED SEMINARY` / `SCRTS` / `TRUTH` / `Zoom`）+ 邮箱域名，逐对象 12/12/12/10/11/0，与基线持平或下降 | **PASS** |
| Z2 | 页脚无新增联系方式 | 同 V4 | **PASS** |
| Z3 | 演示数据标记保留 | 同 E6 | **PASS** |
| Z4 | slug/lang 正确 | `lang=zh-CN`，6 对象一致 | **PASS** |
| Z5 | 品牌名一致（永约学坊 / SCRTS） | 6 对象 title/页脚一致，无双品牌 | **PASS** |

**F 组（入口完整性）**

| 项 | 判据 | 本轮实测 | 判决 |
|---|---|---|---|
| F1 | href 差集必须空（零丢失） | 见 §7.6 对账：**LOST = 0**（6 对象 × 3 视口逐位，无 href 消失） | **PASS** |
| F2 | 角色入口分区正确 | `rev_probe.py` 分区断言通过 | **PASS** |
| F3 | 门户页签/导航项不减少 | navItems 与基线持平；faculty +1、backoffice +1 为新增 skip 链接 | **PASS** |
| F4 | 菜单项目标可达（GET 抽样） | **未验证**——本轮未对全部菜单项做 GET 抽样；仅 D5 相关实测：`/apps` 对 faculty/backoffice = 200，对 stu/parent/empty = 200 但被重定向回 `/my/home` | **未验证** |
| F5 | 无 404/500 入口 | `g5_probe.py`：6 对象全 HTTP 200 | **PASS** |
| F6 | 页脚链接集合不变 | 同 V4/F1 | **PASS** |

**G 组（门禁）**

| 项 | 命令 | 结果 | 判决 |
|---|---|---|---|
| G1 | `check_english.py` | EXIT=0，must-fix 0 / brand 0 / 路由违规 0 / 夹具残留 0 | **PASS** |
| G2 | 各 `--selftest` | `check_english` 48/48、`check_odoo_trace` 53/53、`check_view_xpath` 26/26 | **PASS** |
| G3 | `gate_seam_check.py` | 六样本全绿 | **PASS** |
| G4 | `check_docs_index.py` / `check_manifest_*.py` | 全绿 | **PASS** |
| G5 | 站点冒烟 | 6 对象 HTTP 200、`lang=zh-CN`、无 `Traceback`；字节数 stu 136633 / parent 97440 / faculty 102044 / backoffice 59501 / empty 153067 / guest 35292 | **PASS** |
| G6 | `safe_upgrade edu_portal,edu_brand` | EXIT=0，`grep Traceback`=0（日志中的 ERROR 全为既有 `Error-prone use of @class` 警告，非本轮引入） | **PASS** |
| G7 | `check_view_xpath.py` | **rc=3 INCOMPLETE**（失败项 0 / 未覆盖 1）——见 §7.7 | **FAIL（口径边界漂移，非代码缺陷）** |

**八组统计**：PASS 43 项 · FAIL 2 项（E2、G7；另有 K2 局部 FAIL） · 未验证 3 项（H5、E4、F4）。

---

### 7.2 K3 去伪（重要）

**问题**：基线把 `iconOnlyNoName` 记为「桌面 2–3、窄屏 3（guest 21）」，判为「图标按钮无可见名」。本轮逐个判定这些命中的成因。

**实测（`k3d5.py`，逐个 injection 实验）**：

| 状态 | 无名 a/button 命中（现树内） | **其中可见的** |
|---|---|---|
| 现树（含页面自身 aria-label / 脚本注入） | **0 / 对象** | **0** |
| 剥掉页面上**全部** `aria-label` 后 | stu 6、parent 6、faculty 6、backoffice 4、empty 6、guest 6 | **1** |

**判据**：原始检测器口径是「`innerText` 空 且 无 `aria-label` 且 无 `title`」，**不含可见性过滤**。

**逐个归因**：

| 命中元素 | 所在位置 | 隐藏原因 | 性质 |
|---|---|---|---|
| `a.nav-link.btn.p-2.o_not_editable` | 关闭态 offcanvas 内 | `.offcanvas`（`count=1`、`show=0`） | **检测器假象**——隐藏元素本就应被无障碍树排除 |
| `button.nav-link.btn-close` | `.offcanvas-end` 内（关闭态抽屉） | 同上 | **检测器假象** |
| `button.btn-close` | 隐藏抽屉副本 | 同上 | **检测器假象** |
| `button.oe-mhead-av` | 窄屏响应式副本 | 零尺寸 / 响应式互斥 | **检测器假象** |
| `button.oe-mhead-bell` | 窄屏响应式副本 | 零尺寸 / 响应式互斥 | **检测器假象** |
| `button.btn.btn-sm.btn-outline-secondary[type=submit]`（顶栏搜索按钮，内含 `<span class="oi oi-search"/>`） | 可见 | — | **真实「可见」但现行树已带 `aria-label="搜索"`**——脚本按其自身逻辑（`textContent` 为空）无法为它命名；它不是缺陷 |

**结论**：

1. **基线 K3 的命中绝大多数是检测器假象**——元素位于关闭态 offcanvas 或零尺寸响应式副本内，`innerText` 读成空纯属隐藏所致，本应被无障碍树排除。检测器口径**缺可见性过滤**是根因。
2. **当前树里真实无名可见元素 = 0 处**。剥掉全部 `aria-label` 后剩下的唯一可见命中（顶栏搜索按钮）在现树里有 `aria-label="搜索"`，属**已命名**。
3. 因此 **K3 应判 PASS**；同时建议在契约里把 `iconOnlyNoName` 口径改为「可见（`getBoundingClientRect` 非零且非 `display:none`/`visibility:hidden`）且无名」——否则该判据会永久指着假象不转正。

---

### 7.3 D5 裁决：教务侧到底有没有侧栏

**争议**：研究测 `.oe-sidebar = 0` 断言「教务无侧栏」；实施方主张 `aside#b11-side = 1` 且含应用面板链接。

**按角色 × 视口实测（`k3d5.py` + `d5_k2_probe.py`）**：

| 角色 | `aside#b11-side` 1440 档 | `aside#b11-side` 390 档 | `GET /apps` | `/apps` 链接在 aside 内？ |
|---|---|---|---|---|
| stu | **存在**，`display:block` 宽 232px，可见 | **存在**，`display:none` 宽 0，不可见 | 200 → 被弹回 `/my/home` | 无 `/apps` 链接 |
| parent | 同上 | 同上 | 200 → 被弹回 `/my/home` | 无 |
| faculty | 同上 | 同上 | **200，停在 `/apps`** | **3 条全在 OTHER**（`dropdown-item`×2 + 卡片），**aside 内无** |
| backoffice | 同上 | 同上 | **200，停在 `/apps`** | **1 条在 `ASIDE`（`cls=b11-nav-item`）**＋ 4 条 OTHER |
| empty | 同上 | 同上 | 200 → 被弹回 `/my/home` | 无 |

**裁决**：

1. **「教务无侧栏」的原始断言是错的**——口径错误：研究只探了 `.oe-sidebar` 这个**主题遗留 class**，而本仓自研壳层的侧栏是 `aside#b11-side`。**5 个内部角色在该选择器下都命中 1 个 `aside`，1440 档可见（232px）、390 档折叠（`display:none`，宽度 0）**，响应式行为正确。
2. **但实施方「含应用面板链接」的说法只对 backoffice 成立**：backoffice 左侧导航里确有 `b11-nav-item → /apps`；**faculty 的 `/apps` 入口不在侧栏，在顶栏下拉与卡片里**（3 条全 OTHER）。
3. **应用面板对 faculty/backoffice 可达**（GET 200，未被弹回）；对 stu/parent/empty 虽返回 200，但控制器把请求重定向回 `/my/home`，即**学生/家长/未绑定账号无应用面板权限**——这是**设计意图**（越权按「不存在」处理），非缺陷。
4. `390` 档侧栏 `display:none` 不等于「无侧栏入口」——移动档由 offcanvas / 顶栏承接，同页 offcanvas 存在（`count=1`），属预期响应式设计。

**结论**：**D5 判「实施方成立、研究测的 0 是选择器口径错误」**；细化为「侧栏存在且响应式正确；应用面板链接位置随角色而异（backoffice 在侧栏、faculty 在顶栏），权限分层正确」。

---

### 7.4 本任务新增 3 条跨模块继承的必要性与副作用

| # | 继承 | 必要性 | 副作用判定 |
|---|---|---|---|
| 1 | `edu_portal` · `skip_to_content_internal`（`inherit_id=web.frontend_layout`，xpath `//div[@id='wrapwrap']/header` position=before，`t-if request.env.user.has_group('base.group_user')`） | **必要**：核心 `portal/views/portal_templates.xml:12` 的「跳至内容」带 `groups="!base.group_user"`，内部用户（stu/parent/faculty/backoffice）天然拿不到。实测三档：**faculty 桌面 122→123、backoffice 104→105，增量恰为 1 条 `href="#wrap"`** | **无副作用**：① 与核心那条靠 `groups` 互斥，实证 **6 对象 skipCount 全为 1，无角色出现两条跳转链接**；② 只作用于内部用户，guest 不受影响（guest 51→71 的增量来自主题导航，非本继承）；③ **backoffice 首站例外**——skip 位于 `o_frontend_to_backend_apps_btn`（x=-88 屏外）之后第 15 位（K2 局部 FAIL 的成因） |
| 2 | `edu_portal` · `a11y_names_offcanvas`（`inherit_id=web.frontend_layout`，xpath `//div[@id='wrapwrap']` position=inside，内嵌纯浏览器 `<script>`） | **不需要**（见 §7.5） | **三个副作用**：① 遍历整棵 `a,button`，**作用面是全部前端页**（含公开站与门户，不区分角色）；② 实测真实贡献：**1440 档可见贡献 0；360 档可见贡献 1**（`button.b11-user-btn.dropdown-toggle`，aria-label = 用户名），其余全落在关闭态 offcanvas / 零尺寸副本上；③ 它按 `textContent` 取名，**对「有标签、只是 aria-label 因脚本逻辑取不到」的元素是护身符**——去掉脚本后顶栏搜索按钮等会退化（脚本注入 aria-label 数：stu 171 / parent 123 / faculty 119 / backoffice 26 / empty 170，含核心自带） |
| 3 | `edu_brand` · `homepage_drop_empty_wrap`（`inherit_id=website.homepage`，xpath `//div[@id='wrap'][hasclass('oe_empty')]` position=replace，删空壳） | **必要**：`website.homepage` 的 arch 带 `<div id="wrap" class="oe_structure oe_empty"/>`，与正文（`brand_templates.xml:9` 的 `oe_structure yylc-home`，无 `oe_empty`）是**兄弟**⇒ 页面出现两个 `id="wrap"`，`href="#wrap"` 落到靠前的空壳 | **无副作用，但有两个脆弱点须记**：① **内部用户不会出现两条跳转链接**（实测 6 对象 skipCount=1，与继承 1 的 `t-if` 互斥叠加后仍为 1）；② 实测 guest 页 `#wrap` 唯一 = `oe_structure yylc-home` ⇒ 生效；③ **脆弱点 a**：脚本/继承**只作用于公开站首页**（`website.homepage` 是站点专属视图，非 `website.layout`），门户页的 `#wrap` 是 `o_portal_wrap b11-shell` 本身就唯一，故「脚本是否作用于全部前端页」= **否，也不需要有**；④ **脆弱点 b**：`website.homepage` 已被 COW（copy-on-write 成站点专属记录，原 xmlid 不存在），本继承靠 `setup_brand_yongyue.py` 按 key 接线注入到该链——**若将来主题升级把 arch 里 `oe_empty` 空壳改名/删掉，`position="replace"` 会因 xpath 未命中而静默失效**，届时需重新核对（本轮实测命中正常） |

---

### 7.5 对 `a11y_names_offcanvas` 的明确建议

**建议：删掉这个脚本继承，改为在那处 markup 就地补名。**

理由（全部有本轮实测支撑）：

1. **它主要在修第 3 项的检测器假象**——脚本命名对象集中在关闭态 offcanvas 与零尺寸响应式副本内；这些元素**本应被无障碍树排除**，加 `aria-label` 并不带来任何真实的无障碍收益，只是把「检测器假象」刷成绿。
2. **它的真实收益极小且可被就地修取代**——真正可见且被命名的只有 1 个（360 档 `button.b11-user-btn.dropdown-toggle`）。该按钮模板在 `custom_addons/edu_portal/views/edu_portal_templates.xml:93-105`，内含 `img alt="头像"` 与 `<span class="b11-user-name d-none d-md-inline">用户名</span>`；窄屏 span 是 `display:none`，脚本才把它的 `textContent` 提成 `aria-label`。**正确做法是在 `button` 上直接写静态 `aria-label="用户菜单"`（或给窄屏做个 `visually-hidden` 的用户名）**，一处 5 个字符的 markup 改动即可替代整个脚本。
3. **脚本作用面过宽、成本不成比例**——它遍历全部前端页的全部 `a,button`，注入量级 119–171 条/对象，却换来 1 条可见贡献；且其 `textContent` 取值对「有标签但 `innerText` 空」的元素是隐性补丁，会让 K3 类检测永久失去发现真缺陷的能力（检测器与修补共用同一判据）。
4. **风险**：内嵌无 `t-` 前缀的 `<script>` 走浏览器执行，绕过 QWeb 的 `%%` 折叠规则，属可维护性债务。

**保留它也不会带来功能性损害**（无 500、无布局影响），因此这是一条**建议**而非拦截项；但若采纳，须同步在契约里把 `iconOnlyNoName` 口径改为可见性过滤——否则删了脚本后那些假象又会把 K3 打回 FAIL。

---

### 7.6 入口零丢失复核（与基线逐位对账）

**方法**：同一 `capture.py`、同一 `entryLinks`（`#wrapwrap a[href]` 带文本）口径，BASE `generated_at=2026-10-15T08:13:58` ↔ REV `2026-10-15T12:24:36`，逐对象 × 逐视口做 href 集合对账。

| 对象 | 视口 | BASE | REV | LOST | NEW |
|---|---|---|---|---|---|
| guest_root | desktop / phone / narrow | 71 / 51 / 51 | 72 / 71 / 71 | **0** | +1 / **+20** / **+20** |
| stu_home | 三档 | 62 / 62 / 62 | 62 / 62 / 62 | **0** | 0 |
| parent_home | 三档 | 50 / 50 / 50 | 50 / 50 / 50 | **0** | 0 |
| faculty_home | 三档 | 122 / 121 / 121 | 123 / 122 / 122 | **0** | +1（`#wrap`） |
| backoff_home | 三档 | 105 / 104 / 104 | 106 / 105 / 105 | **0** | +1（`#wrap`） |
| empty_home | 三档 | 76 / 76 / 76 | 76 / 76 / 76 | **0** | 0 |

**LOST 恒为 0** ⇒ 入口零丢失成立（F1 PASS）。

**裁决实施方自标的可疑点「guest 360 档链接 51→72」**：

- **实测为 51→71（phone/narrow 两档），不是 72**——72 是 **desktop** 档（71→72）。实施方把两档数字串了，量级判断正确。
- **+20 的来源已定位**：新增 class 组合 **`a.nav-link.p-3.text-wrap` ×17**（及其它 3 条），**不在本仓源码**（`grep -rn "p-3 text-wrap" custom_addons/` 无命中），来自主题视图 `openeducat` 的公开站手机抽屉导航。
- **不是入口丢失，也不是本提交引入**：`f1f26dc` 对 `brand_templates.xml` 的改动**仅**新增 `homepage_drop_empty_wrap` 一条 xpath（已 `git show` 全文核对），不含任何 nav markup。
- **性质**：guest 手机档主题导航出现多副本（实测重复 href：`/` 4 次、`/about` 4 次、`/admissions` 4 次、`/journal` 4 次），属**主题上游的移动抽屉重复渲染**，对内部角色无影响（stu/parent/empty 三档 0 增）、对公开站为导航冗余展示而非入口缺陷。
- **判定**：**不构成放行障碍**；若要与基线逐位对齐，可在后续主题导航治理里单独处理（超出本任务写入面）。

---

### 7.7 `check_view_xpath.py` rc=3 INCOMPLETE 的边界判断

**复跑实测**：

```
$ python3 scripts/check_view_xpath.py
未覆盖（跳过）跨模块继承 = 28 处
明细: auth_signup x1, auth_totp x1, auth_totp_portal x1, digest x2,
      mail x2, portal x5, web x11, website x5
规则 7 跳过外部模块模型 = 36 个  （与 EXPECTED_EXTERNAL_MODELS=36 一致）
BOUNDARY-DRIFT  跨模块继承跳过 28 ≠ 常量 25
RESULT=INCOMPLETE  （失败项 0 / 未覆盖 1）
REVISION=r16 · 指纹 6d67f32a · 断言 26 条       rc=3
```

**漂移是否就这 3 条 —— 是，且逐位可核**：

| 模块 | 本仓 `inherit_id` 到该模块的继承者 | 计数 |
|---|---|---|
| `web` | `edu_portal_templates.xml:696`（`web.frontend_layout` = 继承 1）、`:714`（`web.frontend_layout` = 继承 2） | **11**（本任务 +2，原 9） |
| `website` | `brand_templates.xml:217`（`website.layout`）、`odoo_debrand.xml:96 / 211 / 237`（`website.layout`）、`brand_templates.xml:283`（`website.homepage` = 继承 3） | **5**（本任务 +1，原 4） |
| `portal` | 5（未变） | 5 |
| `mail` / `digest` | 2 / 2（未变） | 2 / 2 |
| `auth_signup` / `auth_totp` / `auth_totp_portal` | 各 1（未变） | 1 / 1 / 1 |
| **合计** | | **28**（原 25，+3） |

⇒ **漂移恰为 25 + 3 = 28，增量逐位等于本任务新增的 3 条继承**（`web` +2、`website` +1）；`EXPECTED_EXTERNAL_MODELS=36` 未漂移，失败项 0。

**判断：应声明边界（改 `EXPECTED_SKIPPED_INHERIT` 25 → 28），不应重构掉。**

依据：

1. **拒态语义不是「代码错」**——`:996` / `:999` 的判定逻辑与注释明确写「声明过的边界（与 `EXPECTED_*` 常量一致）算已接受，不构成 INCOMPLETE」。也就是说这个 rc=3 **设计上就是用来提醒「边界常量该更新了」的闹钟**，而不是缺陷报告。本次失败项 = 0、未覆盖 = 1（纯边界漂移），红灯完全由常量滞后触发。
2. **「重构掉」不是本任务权限，也非正确方向**——① 边界不成立的继承本就不可能被仓内规则校验（跨模块 xpath 目标不在本仓），重构既消不掉这 28 处，也得不到额外验证；② 按铁律，**为让门禁变绿而改判定口径/阈值本身是禁区**——但这里恰好相反：常量滞后于事实，**把常量对齐到事实**是「声明边界」不是「放水」；③ 若把该继承从 3 条压回 0 来换绿灯，等于为了门禁数字砍掉真实无障碍/锚点修复，本末倒置。
3. **可核查性**：+3 已在 §7.4 逐条给出源码行号与作用面，任何人可复算 `grep -rn 'inherit_id="web\.\|inherit_id="website\.'` 得到 11 / 5。

**建议**：在 `scripts/check_view_xpath.py:152` 把 `EXPECTED_SKIPPED_INHERIT = 25` 改为 `28`，并将该行注释追加本次理由（`r20 首页视觉整改：web.frontend_layout ×2（跳至内容/offcanvas 命名）+ website.homepage ×1（删空 #wrap）`）。**本任务只读，不实施该改动**。

---

### 7.8 最终裁决

**判决：放行。**

**放行理由（§3 放行最低条件逐条核对）**：

| 最低条件 | 状态 |
|---|---|
| §2「必须整改后重取证」五项：H1 / H2+H3 / K3 / R3 / Z1 | **全部转正**：H1 像素 5.10 / 7.14；H3 唯一可见 h1 且 44>40>20（360 档 26>24>20），倒挂消除；K3 现树可见无名 = 0；R3 169→19（≤5/页）；Z1 五分类英文尾巴清零且门禁 0/0 |
| J1–J6 全未命中 | **未命中**：J1 品牌壳层完整（V1 11 选择器四角色一致、V5 图标体系唯一）；J3 角色差异保留（分类/卡片数按角色分化，D5 应用面板权限分层）；J4 同源率未上升（英文串数量持平/下降、文案已汉化）；J5 信息密度未倒退（K1 可聚焦 95/61/67/49/155/42 持平基线、F1 零丢失）；J6 层级不塌陷（可见 h1 恒为 1、H4 无指示 465/465=0） |
| 截图能看出品牌差异 | V1 / V5 / Z5 全绿，hero 令牌化落地 |
| G1–G7 全绿 | G1–G6 绿；**G7 rc=3** 经 §7.7 判定为**边界常量滞后**（失败项 0），非代码缺陷 |

**随行挂账（不构成拦截，须随下一次提交关闭）**：

| # | 项 | 证据 | 归属 |
|---|---|---|---|
| C1 | `backoff_home` 首个 Tab 站是 `o_frontend_to_backend_apps_btn`（x=-88 屏外）而非「跳至内容」（skipIndex=14） | §7.1 K2、§7.4 继承 1 | 轻缺陷：键盘用户需多走 14 次才到正文，但 skip 链接**存在且可用**；建议把该核心按钮移出首站位置或在 skip 链接上补 `autofocus` 语义 |
| C2 | 家长无绑定学生时 `/my/child` **无空态分支**，渲染空白块（不 500） | §7.1 E2，`roles.py:389-400` + `roles.xml:5/:12` | 轻缺陷：`roles.xml` 补 `t-if="not kids"` 中文空态一句 |
| C3 | `check_view_xpath.py` rc=3：`EXPECTED_SKIPPED_INHERIT` 25 → 28 | §7.7 | 门禁常量对齐事实，非放水 |
| C4 | 契约 `iconOnlyNoName` 口径缺可见性过滤，会永久照着 offcanvas 假象报 FAIL | §7.2、§7.5 | 判据修订（若同时采纳 7.5 删脚本建议，此项为必做） |

**未验证清单（不掩盖，明写）**：H5（渐变两端分别采样）、E4（5 对象壳层逐元素结构签名）、F4（菜单项 GET 抽样）。三项均**未取得证据**，不作估算、不计入 PASS。其中 E4/F4 与上一轮 §6.5 N1–N12 同类；H5 因 `struct_and_contrast.py` 的 `NEEDS_EYE` 与 `pixel2.py` 结论冲突（3.26 vs 7.14）而无法收敛，须以「对渐变起止做双点像素采样」的专用探针补证。

**明确不放行的若改判条件**：若验收人坚持 §3「§2 全 ☑」的字面口径，则本轮的 C1（K2 首站）与 C2（E2 空态）两项即为未 ☑ ⇒ 应判**拦截**，差异点仅此两处、且均为轻缺陷；**其余全部转正**。

---

### 7.9 本节自证

- 所有数字来自本轮独立重跑（`/tmp/hp_rev/` 探针），**未采信实施方自证数字**；每个 PASS/FAIL 附脚本原始读数或明写【未验证】，无估算。
- 只写了 `docs/audit/homepage-ui-visual-acceptance.md` 本节；未改 `custom_addons/**`、未改 `scripts/check_*.py`、未 commit、未跑部署命令。
- 唯一写入路径：本文件追加；探针工作区在 `/tmp/hp_rev/`（仓外），仅克隆基线脚本并改 `OUT` 常量。
- 未删除任何既有结论；与基线冲突处（如 D5 的研究原始断言「教务无侧栏」）就地给出选择器口径反证。

---

## §8 【挂账 C1–C4 清除】判据口径订正与边界常量回收（2026-10-15 16:2x · Lead 就地追加，不改既有任何数值）

本节只做三件事：① 落实 §7.5 建议被采纳后**必须**完成的 `iconOnlyNoName` 判据修订（挂账 C4）；② 记录 C3 边界常量的回收；③ 给 C1 / C2 的关闭留下取证。数字来源：**§7.2 表逐条重判 + 挂账清除轮的探针实测**；Lead 本轮未新增像素/探针读数，故不写「本轮实测」。

### 8.1 为什么必须改口径（C4）
§7.2 / §7.5 已证明：基线 `iconOnlyNoName` 的命中绝大多数是**检测器假象**——元素位于关闭态 offcanvas 或零尺寸响应式副本内，`innerText` 读成空纯属隐藏所致，本应被无障碍树排除。原口径「`innerText` 空 且 无 `aria-label` 且 无 `title` 且 无 `<img alt>`」有两个缺口：
1. **无可见性过滤** ⇒ 隐藏元素的空 `innerText` 被算作「无名」；
2. **命名来源只看元素自身** ⇒ 后代已提供可访问名（`<span role="img" aria-label>` / `<img alt>` / `<svg><title>`）也判为无名。
两处叠加会让 K3 **永久指着假象、无法转正**。

### 8.2 新口径（自本节起生效）
- **可见性过滤**：只统计 `getBoundingClientRect()` 宽高均 > 0、且计算样式非 `display:none` / `visibility:hidden` 的元素（与 §7.2 的可见性判定同口径）。
- **命名来源**：元素自身或**任一后代**具备下列之一即算已命名 ⇒ `aria-label`（任意元素）、`title`、`role="img"` 且带 `aria-label`、`img[alt]`（非空）、`svg > title`、非空可见文本。
- **计数对象**不变：`button,[role=button],a`。

### 8.3 按新口径复算（`c74d9bc` 之后的业主代码）
| 对象 | 新口径命中 | 逐条 | 判定 |
|---|---|---|---|
| `stu_home` / `parent_home` / `faculty_home` / `backoff_home` / `empty_home` | **0 / 0 / 0 / 0 / 0** | — | PASS |
| `guest_root`（公开站首页） | **1** | `a.navbar-brand.logo` —— 其后代 `<span role="img" aria-label="…">` 与 `<img alt=…>` 已提供可访问名 | 假阳性，实际 **0** ⇒ PASS |

### 8.4 K3 最终判定
**PASS**。原判 FAIL 系口径缺口所致，不是代码缺陷。§2 K3 行与 §6.4 A5 行的历史读数**保持原样不改**，以本节口径为生效判据。

### 8.5 C3 边界常量回收
按 §7.5 建议删除 `a11y_names_offcanvas`（提交 `c74d9bc`；改在 `custom_addons/edu_portal/views/edu_portal_templates.xml:93-105` 的 `button.b11-user-btn` 上写静态 `aria-label`）后，跨模块继承跳过数 **28 → 27**；`scripts/check_view_xpath.py` 的 `EXPECTED_SKIPPED_INHERIT` 相应由 28 收回 **27**，并在该行上方 r19 注记里写明「净 +2」与订正理由（提交 `59ee46b`）。`python3 scripts/check_view_xpath.py` 由 rc=3 INCOMPLETE 回到 **rc=0 OK**（失败项 0 / 未覆盖 0）。

### 8.6 C1 / C2 关闭取证（挂账清除轮）
- **C1 关闭**：`custom_addons/edu_portal/views/edu_portal_templates.xml` 新增 `skip_to_content_internal`（`inherit_id=web.frontend_layout`，锚 `//body/*[1]` position=before，产出 `a#yy-skip-to-content[href="#wrap"]`）；实测 `backoff_home` 在 1440 与 360 两档的**首个 Tab 站**均为该链接（rect 90×38，可见），6 个验收对象 `skipIndex` = **0**。原首站 `o_frontend_to_backend_apps_btn` 仍在树上（rect 左 -88，核心按钮未动、未改权限）。
- **C2 关闭**：`custom_addons/edu_portal/views/roles.xml` 补 `t-else` 空态块（中文一句），`custom_addons/edu_portal/controllers/roles.py` **未改**（路由与安全判定零改动）；实测「解绑 / 绑回」两态（含一次绑定行 `2|5` 存在的断言）分别渲染空态与列表，不 500。

### 8.7 挂账状态
C1 **已关闭**（`c74d9bc`）· C2 **已关闭**（`9e59261`）· C3 **已关闭**（`59ee46b`）· C4 **已关闭**（本节 8.2/8.3）。§7.8「随行挂账」四项至此清空；§7.8 的放行结论与 §7.8 的未验证清单（H5 / E4 / F4）不受影响，仍然有效。

### 8.8 本节自证
- 只写了 `docs/audit/homepage-ui-visual-acceptance.md`（§8 追加 + §2 K3 行加一行口径指针）；未改任何历史数值、未删任何既有结论。
- 未改 `scripts/check_*.py` 的判定口径与阈值；`check_view_xpath.py` 的常量变更属「声明既有边界」，有 r19 注记与本节 8.5 双重记录，且该文件变更的唯一行是常量与其注记。
- 数字全部来自 §7.2 与挂账清除轮的实测读数；Lead 未新增读数，也**未采信实施方自述**。
