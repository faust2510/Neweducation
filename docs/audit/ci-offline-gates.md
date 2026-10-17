# CI 离线门禁接入报告（2026-10-17）

外部评审 P1：「无 CI、无 lint、`scripts/check_all.sh` 依赖活站点且硬编码 macOS 路径」。
本报告是这一轮的取证与交付记录：把 `AGENTS.md` §4 的 16 条离线命令接进 GitHub Actions，
并逐条给出**本机实测 rc**。执行环境：macOS，`<REPO> = CPython 3.13.13。

> 采纳说明：`.github/workflows/static-gates.yml` 在本轮开工前**已存在于工作区但未入库**
> （`git status --porcelain .github/` 输出 `?? .github/`，文件 mtime 2026-10-14 17:17，来自别的窗口的在途工作）。
> 本轮的处置是：**复核 + 最小修正后入库**，未推倒重来、未另建重叠工作流。修正点见 §1。

## 1. 变更文件清单

| 文件 | 状态 | 用途（一句话） |
| --- | --- | --- |
| `.github/workflows/static-gates.yml` | 修改（既有未入库工作，复核后入库） | 三个 job：`offline-gates`（阻塞）/ `site-gates`（不阻塞）/ `known-red`（不阻塞），第二层 Odoo 容器 job 留注释 |
| `scripts/check_all.sh` | 修改 | 去掉「默认位写死 `/opt/homebrew/bin/python3`」的可移植性缺陷 |
| `docs/audit/ci-offline-gates.md` | 新增 | 本报告 |

对既有工作流做的**最小修正**（其余原样复用）：

1. **把 2 条必然假红的命令移出阻塞 job** —— 原文件把 `check_english`（全模式）与
   `check_nav_reachable` 放在阻塞循环里，而这两条**实测**要活站点（§2.3）。托管 runner 上
   每次 push 都会红 ⇒ 拆到 `site-gates`（`continue-on-error: true`）。
2. **补 `requests` 依赖** —— 原文件只装 `lxml`，而 `requests` 是 `check_english.py` /
   `check_odoo_trace.py` / `tests/smoke/gate_seam_check.py` 的**模块级** import（§3），缺了必红。
3. **补 `tests/unit/` 全量单测步骤**（任务书要求的第一层内容，原文件没有）。
4. 补 `check_english.py --list`（离线子模式，名单对账）作为汉化门禁的离线部分。
5. 补 `permissions: contents: read`（最小权限）。
6. `python-version` 由 `'3.12'` 改为 `'3.13'`：与本机实测解释器同版，减少一处未验证变量。
7. 第二层 Odoo 容器 job 写成注释块并标注 `【未验证】`（理由见 §7.2）。

## 2. 逐条本地实测 rc：AGENTS.md §4 的 16 条

### 2.1 站点在跑（本机 `edu19-clone-web-1` 可达，`curl http://127.0.0.1:8069/web/login` → 302）

全部 16 条 rc=0。改动后**重跑一次仍然全绿**（§6）。

| # | 命令 | rc |
| --- | --- | --- |
| 1 | `python3 scripts/check_english.py --selftest` | 0 |
| 2 | `python3 scripts/check_english.py` | 0 |
| 3 | `python3 scripts/check_odoo_trace.py --selftest` | 0 |
| 4 | `python3 scripts/check_view_xpath.py --selftest` | 0 |
| 5 | `python3 scripts/check_view_xpath.py` | 0 |
| 6 | `python3 tests/smoke/gate_seam_check.py` | 0 |
| 7 | `python3 scripts/check_docs_index.py` | 0 |
| 8 | `python3 scripts/check_manifest_order.py` | 0 |
| 9 | `python3 scripts/check_manifest_tracking.py` | 0 |
| 10 | `python3 scripts/check_qweb_dict_foreach.py` | 0 |
| 11 | `python3 scripts/check_recordset_none.py` | 0 |
| 12 | `python3 scripts/check_shell_exitcode.py` | 0 |
| 13 | `python3 scripts/check_ui_surface.py` | 0 |
| 14 | `python3 scripts/check_po_sanity.py` | 0 |
| 15 | `python3 scripts/check_alias_not_extended.py` | 0 |
| 16 | `python3 scripts/check_nav_reachable.py` | 0 |

### 2.2 站点不可达（模拟方法见下）

模拟方法：`/tmp/nosite/run_offline.py` 把 `requests.adapters.HTTPAdapter.send` 打桩，
凡 URL 含 `8069` 一律抛 `ConnectionError`，再 `runpy.run_path` 跑目标脚本。
（不用 `HTTP_PROXY` 那套：`scripts/check_english.py:773` 明确 `s.trust_env = False`，
代理环境变量对它无效 —— 这一点是用实测反证出来的。）

| # | 命令 | 站点不可达 rc | 判定 |
| --- | --- | --- | --- |
| 1 | `check_english.py --selftest` | 0 | 真离线 |
| 2 | `check_english.py` | **1** | **要站点** |
| 3 | `check_odoo_trace.py --selftest` | 0 | 真离线 |
| 4 | `check_view_xpath.py --selftest` | 0 | 真离线 |
| 5 | `check_view_xpath.py` | 0 | 真离线 |
| 6 | `tests/smoke/gate_seam_check.py` | 0 | 真离线 |
| 7 | `check_docs_index.py` | 0 | 真离线 |
| 8 | `check_manifest_order.py` | 0 | 真离线 |
| 9 | `check_manifest_tracking.py` | 0 | 真离线（但需 `git`，见 §2.4） |
| 10 | `check_qweb_dict_foreach.py` | 0 | 真离线 |
| 11 | `check_recordset_none.py` | 0 | 真离线 |
| 12 | `check_shell_exitcode.py` | 0 | 真离线 |
| 13 | `check_ui_surface.py` | 0 | 真离线 |
| 14 | `check_po_sanity.py` | 0 | 真离线 |
| 15 | `check_alias_not_extended.py` | 0 | 真离线 |
| 16 | `check_nav_reachable.py` | **2** | **要站点** |

于是第一层离线阻塞面 = **14 条**（加上 §4 之外的单测 15 份），不是 16 条。

### 2.3 两条「要站点」的机制（不是环境噪声，是设计如此）

- `scripts/check_english.py`：全模式对五个角色逐个 `login()`（`scripts/check_english.py:777`），
  登录失败进 `bad_login`，而 `scripts/check_english.py:1203` 是 `if bad_login: return 1`。
  站点不可达时输出尾部为 `== 角色 guest（匿名）登录 OK` 之后各角色 `登录 FAIL`。**rc=1 = 判失败**，
  不是「环境未就绪」—— 所以它不能留在阻塞 job 里。
- `scripts/check_nav_reachable.py`：输入源是**活表** `website.menu`
  （`scripts/check_nav_reachable.py:106` 的 `A.kw(sess, 'website.menu', 'search_read', ...)`），
  读不到时按自己的契约输出 `UNVERIFIED` 并 **exit 2**。它**不是**「靠参数就能离线」：
  `EDU_NAV_TREE` 注入夹具（`scripts/check_nav_reachable.py:130-143`）脚本自述「只为正反双向自证」，
  用它当 CI 输入等于换判据口径 ⇒ 不做（铁律：不许为让门禁变绿改判定口径）。

结论：这两条在托管 runner 上没有可用形态，只能 `continue-on-error`（已如此处理），
或者等**自建 runner**（有 edu19 站点）时把 `continue-on-error` 去掉。

### 2.4 额外实测：一条隐性环境依赖

`scripts/check_manifest_tracking.py` 调 `git ls-files`（`scripts/check_manifest_tracking.py:133`）。
把 PATH 清空后实测 **rc=2**（输出 `ENV：git 不可用或当前不是 git 仓库`）。
`actions/checkout@v4` 提供 git ⇒ CI 上成立；但它是**非离线无关的硬前提**，写在此处备查。

## 3. CI 必须装的依赖（实测：缺了就红）

把 `requests` 从 import 体系里屏蔽（ImportError 打桩）后实测：

| 命令 | 缺 requests 时 rc | 失败文案 |
| --- | --- | --- |
| `check_english.py --selftest` | 1 | `ModuleNotFoundError: No module named 'requests'` |
| `check_odoo_trace.py --selftest` | 1 | 同上 |
| `tests/smoke/gate_seam_check.py` | 2 | `环境错误：无法导入门禁模块` |
| `check_view_xpath.py --selftest` | 0 | 不依赖 requests |
| `check_view_xpath.py` | 0 | 不依赖 requests |

`lxml` 只被 `scripts/check_view_xpath.py:93`（`from lxml import etree`）模块级 import，
`tests/smoke/gate_seam_check.py` 传递依赖它。

⇒ CI 装 `lxml requests`。这**不是**新增仓内第三方依赖：脚本本来就这么 import，
只是托管 runner 缺这两个包；仓里没有 `requirements.txt`，故不新增文件、不锁版本。

## 4. 第一层单测：`tests/unit/` 清单与依据

清单 = `tests/unit/*.py` **全部 15 份**（目录下无其它 `.py`）。

依据（三条，逐条实测）：
1. 全目录 `grep -nE "import odoo|from odoo" tests/unit/*.py` **零命中**
   （唯一含 "odoo" 字样的 `tests/unit/tg_assist_reminder_panel_test.py:81` 是**字符串断言**：
   `'from odoo.exceptions import UserError' in rem`，不导入）。
2. 每份都用 `importlib.util.spec_from_file_location` 直接加载源文件后测纯函数，不发 HTTP。
3. **站点不可达打桩下逐个跑，15/15 rc=0**。
   文件名：`check_nav_jobs_entries_test.py`、`edu_portal_login_alias_test.py`、
   `tg_assist_bindcode_test.py`、`tg_assist_bridge_test.py`、`tg_assist_file_test.py`、
   `tg_assist_forward_test.py`、`tg_assist_material_test.py`、`tg_assist_menu_test.py`、
   `tg_assist_miniapp_test.py`、`tg_assist_notice_test.py`、`tg_assist_poll_test.py`、
   `tg_assist_reminder_panel_test.py`、`tg_assist_security_test.py`、`tg_assist_text_test.py`、
   `tg_gate_router_test.py`。

CI 里用 `for t in tests/unit/*.py; do python3 "$t"; done` 跑，**不引 pytest**
（仓里没有 pytest 依赖，也不为此新增）。

> 注：`tests/unit/check_nav_jobs_entries_test.py` 与已知红灯 `scripts/check_nav_jobs_entries.py`
> 不是同一个东西 —— 前者是后者的**自证单测**，它本身 rc=0。

## 5. 已知红灯四条的排除理由与建议

### 5.1 理由（2026-10-17 实测，全部非环境问题）

| 命令 | 实测 rc | 实测原因 | 能否当失败条件 |
| --- | --- | --- | --- |
| `check_doc_module_count` | **0** | 已修绿：`docs/code-map.md:47` 与 `README.md:3` 都写 15，实测 `custom_addons/` 下 edu_* 15 个 | 见 5.2 |
| `check_md_tables` | 1 | `docs/plans/gradebook-center-design.md:182` 表头 2 格 / 本行 5 格（历史遗留 1 条） | 不能 |
| `check_menu_data_sync` | 1 | `FAIL \| 菜单 547 的 active 应为 False（档1 彻底隐藏），但 XML 未声明且原值…` | 不能 |
| `check_nav_jobs_entries` | 1 | `FAIL \| 导航出现 2 条指向空页 /jobs 的入口` | 不能 |

`AGENTS.md` §4 把四条都列成「已知红」。**实测有出入**：`check_doc_module_count` 现在 rc=0
（另一窗口把 `docs/code-map.md:47` 的 14 改成了 15，实测 15=15，输出 `结论：OK`）。
另三条确为红，而且都不是环境型 —— 放进阻塞 job 就是「每次 push 必然红」，
红成常态后真回归也被淹没。

### 5.2 建议（按代价从低到高）

1. **立刻可做（0 风险）**：把已修绿的 `check_doc_module_count` 从 `known-red` 移进
   `offline-gates` 阻塞循环，并同步 `AGENTS.md` §4 的红灯名单（该文件当前 untracked，
   不在本轮边界内，故本轮只报告不改）。
2. **保持现状**：另三条留在 `known-red`（`continue-on-error: true` + `|| echo "::warning"`）。
   这个形态比「纯注释掉」好：真回归会在 PR 上以 `warning` 注解浮现，而不会假红。
3. **不建议**：给这三条单独建 job 加 `if: github.event_name == 'schedule'` 之类 ——
   三条 defect 各自都能一条 commit 修掉（`docs/plans/gradebook-center-design.md:182` 补 3 格、
   菜单 547 补 `active="False"` 声明、两条 `/jobs` 导航入口删掉），届时修完直接进阻塞 job。
   为三条可修缺陷建调度 job 是过度设计。

## 6. 本地自证

- **YAML 可解析**：`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/static-gates.yml'))"` → `YAML PARSE OK`；
  结构读回：`triggers = [push, pull_request, workflow_dispatch]`、`permissions = {contents: read}`、
  `jobs = [offline-gates, site-gates, known-red]`，各 job 的 `runs-on` / `continue-on-error` / 步骤数均符合预期。
  （注：pyyaml 是 YAML 1.1，`on:` 会被解析成布尔键 `True` —— 这是 pyyaml 的已知行为，GitHub 侧解析正确。）
- **job 内每条命令都在本机真跑过**：§2.1 / §2.2 / §4 三张表即逐条 rc。
  CI 的 `offline-gates` 只包含 §2.2 里 rc=0 的 14 条 + §4 的 15 份单测。
- **改动后重跑 16 条**：15 条 rc=0，`check_nav_reachable.py` 一次 rc=2、重跑 rc=0
  （那次是活表瞬时读不到，与本次改动无关：我的改动只碰 `.github/workflows/static-gates.yml`
  与 `scripts/check_all.sh`，而 `check_nav_reachable` 不读这两者；重跑输出尾部为
  `PASS | 20 条导航目标全部 200（游客态 + 登录态，两列均已验证）`）。
- **`scripts/check_all.sh` 修改后自证**：`bash -n` 通过；`bash scripts/check_all.sh --list` rc=0（40 行清单）；
  两个分支都实测过 —— 正常 PATH 下 `PY=<REPO> -v` 分支），
  `PATH=/tmp/emptybin` 下 `PY=/opt/homebrew/bin/python3`（兜底分支）。
- **`scripts/check_shell_exitcode.py`**（改动后）：`RESULT=OK（命中 0 / 跳过 0）` rc=0
  —— 新增的 `${EDU_PYTHON:-}` 式写法没触发「`$VAR` 后紧跟非 ASCII」那条约定。

## 7. 【未验证】清单

1. **CI runner 上的实际执行结果**：本机是 macOS + CPython 3.13.13，CI 是 ubuntu-latest + 3.13。
   我逐条跑的是**命令**，不是**runner 环境**；`ubuntu-latest` 上的 pip wheel、路径大小写敏感性等
   未在本机验证。风险点集中在 `check_view_xpath.py` 全模式对 `${TMPDIR:-/tmp}` 与文件系统大小写的假设。
2. **第二层 Odoo 容器 job ——【未验证】且判定为「当前形态不成立」，故整块留作注释、未启用**：
   - 本机没有 GitHub Actions 环境，我证明不了 `services: postgres:16` + `odoo:19` 那段 YAML 起得来，
     按纪律标【未验证】而不是写成「看起来能跑」的活 job；
   - 更硬的一条（有本机证据）：**基座不在仓里**。`openeducat_erp/` 在 `.gitignore:20` 被排除，
     `git ls-files openeducat_erp` 输出为空；而 `custom_addons/edu_portal/__manifest__.py:28` 起
     依赖 `openeducat_core` / `openeducat_timetable` / `openeducat_attendance` / `openeducat_assignment` 等
     ⇒ **干净检出里任何 `edu_*` 模块都装不起来**，`--test-enable` 无从谈起。
     要跑通须在 CI 联网拉 OpenEduCat 19.0 快照 —— 那是新增外部依赖，且与「基座快照逐字一致」冲突 ⇒ 不做；
   - 真要做，正确形态是**自建 runner** 上用现成 edu19-clone 栈跑
     `bash scripts/safe_upgrade.sh <模块>`（内含串行锁），而非在托管 runner 上重建基座。
3. **`site-gates` job 在 GitHub 上的表现**：预期两个步骤都非零退出（exit 1 / exit 2）、
   被 `continue-on-error` 兜住。本机只验证了「有站点时 rc=0」，没验证「托管 runner 无站点时的具体文案」。

## 8. 不做的与原因

- **没动 `AGENTS.md`**（虽然 §4 的「16 条全离线」与「四条第 1 条仍红」两处与实测不符）：
  该文件当前 untracked（`?? AGENTS.md`）且不在本轮边界内 ⇒ 只在 §2.3 / §5.1 报告，交调度方决定。
- **没碰任何 `scripts/check_*.py` 的判定口径/白名单/阈值**；没碰 `docker-compose.yml`、`config/`、
  `openeducat_erp/`、`custom_addons/`。
- **没改 `docs/audit/README.md`**（登记由调度方做）。
- **没让 `check_all.sh` 进 CI**：它按设计要活站点，且已正确区分
  「站点没起 ⇒ `INCOMPLETE` exit 2」（`scripts/check_all.sh:79-81`）——
  这是**诚实**的行为，不是缺陷；缺陷只是那条硬编码路径（已修）。
- **没修 §5.1 的三条红灯**：属别的主题（文档表格 / 菜单数据 / 导航数据），
  按「一次只动一个主题」不混进本轮 commit。
- **没执行 `git push`**；commit 全部路径范围限定。
