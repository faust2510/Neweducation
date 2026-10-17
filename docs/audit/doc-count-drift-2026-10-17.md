# 入口文档计数与行数漂移修复（2026-10-17）

**范围**：只改 `README.md` 与 `docs/code-map.md` 的**数字、模块表行与明显错误条目**；不重写结构、不重排、不新增章节。
**依据**：`AGENTS.md` §4 把 `scripts/check_doc_module_count.py` 列为长期红项 + `README.md` 模块表与 `ls -d custom_addons/edu_*` 实测不符。
**未使用的手段**：没有改任何 `scripts/check_*.py` 的判定口径 / 白名单 / 阈值（该文件只读）；`openeducat_erp/`、`docker-compose.yml`、`config/` 一字未动；`docs/plans/` 未动（索引有逐字一致性门禁）；`docs/audit/README.md` 未动。

## 1. 改动清单（原值 → 实测值 → 命令）

| 文件:行号 | 原值 | 实测值 | 实测命令 |
|---|---|---|---|
| README.md:3 | 「14 个模块」 | 15 | `ls -d custom_addons/edu_* \| wc -l` |
| README.md:51-68（模块地图表） | 10 行 `edu_*` + 1 行基座；缺 6 个模块，且仍列已删除的 `edu_eval` | 15 行 `edu_*` + 1 行基座（补 6 行、退 1 行） | `ls -d custom_addons/edu_*`；`docs/audit/edu-eval-removal.md` |
| docs/code-map.md:47 | 「（14 个 edu_*）」 | 15 | 同上 |
| docs/code-map.md:74 | `batch1.py`(935行) | 998 | `wc -l custom_addons/edu_portal/controllers/batch1.py` |
| docs/code-map.md:75 | `batch2.py`(1548行，最大文件) | 2217 | `wc -l custom_addons/edu_portal/controllers/batch2.py` |
| docs/code-map.md:76 | `batch3.py`(900行) | 1352 | `wc -l custom_addons/edu_portal/controllers/batch3.py` |
| docs/code-map.md:77 | `roles.py`(585行) | 3497 | `wc -l custom_addons/edu_portal/controllers/roles.py` |
| docs/code-map.md:78 | `calendar.py`(854行) | 869 | `wc -l custom_addons/edu_portal/controllers/calendar.py` |
| docs/code-map.md:106 | `models/`（25 个模型） | 41 个文件 / 47 个模型 | `ls custom_addons/edu_portal/models/*.py \| wc -l`；`grep -h "^\s*_name\s*=" custom_addons/edu_portal/models/*.py \| sed "s/.*= *['\"]//;s/['\"].*//" \| sort -u \| wc -l` |
| docs/code-map.md:110 | `pages.xml`(418行)+`brand_templates.xml`(239行) | 423 / 286 | `wc -l custom_addons/edu_brand/views/pages.xml custom_addons/edu_brand/views/brand_templates.xml` |

> `batch2.py` 仍是最大文件（2217 > `roles.py` 3497？否——**实测 roles.py 3497 行已超过 batch2 2217 行**，但本次只改数字、不重排、不改「最大文件」这类判定语，故保留原措辞并在 §4 记为待裁定。）

## 2. README 模块表补的 6 行（依据）

| 模块 | 补入依据 |
|---|---|
| `edu_assess` | 盘上存在且是**唯一**评估引擎（`edu.assess.*` 模板/任务/答卷三件套，门户 `/assess`、`/assess/my`、`/assess/review`）；原 `edu_eval` 于 2026-09-29 卸载删除，先例 `docs/audit/edu-eval-removal.md` |
| `edu_admit_invite` | 盘上 6 个文件（含 2 个 `__init__.py`）：给 `edu.invite.code` 加 `application_id`、给 `edu.application` 加发放入学码按钮；零新增路由/模型/表/ACL |
| `edu_nav` | 菜单收口模块（`data/menu_consolidation_data.xml` + `models/menu_consolidation.py`），由 code-map.md:7 的 2026-09-17 条目点名 |
| `edu_tg_bind` | 由 code-map.md:7 的 2026-09-17 条目点名，设计 `docs/plans/tg-invite-bot-design.md` |
| `edu_tg_gate` | 盘上存在（`routing.py` + `controllers/gate.py`）；Telegram 前门分发，无模型/表/ACL |
| `edu_tg_assist` | 盘上存在（班务机器人，Mini App 面板）；同族设计 `docs/plans/tg-assist-bot-design.md` |

**`edu_eval` 行的处置（不删历史）**：原 README.md:59 是删除线行「~~`edu_eval`~~ … 2026-09-29 已卸载并删除模块」。本次把该行**改成 `edu_assess` 行**，并把「原 `edu_eval` 已于 2026-09-29 卸载并删除模块（证据 `docs/audit/edu-eval-removal.md`）」并入同一行文本。**那份审计文件本身（历史结论）一字未改**，删除事实仍在 README 与审计档案中可查。

## 3. 门禁证据（2026-10-17 本机实测）

```
$ python3 scripts/check_doc_module_count.py
实测：custom_addons/ 下 edu_* 目录 15 个
  [OK] README.md:3 写的是 15（实测 15）
  [OK] docs/code-map.md:47 写的是 15（实测 15）
结论：OK
rc=0

$ python3 scripts/check_docs_index.py
未登记 0｜重复登记 0｜状态行缺失 0｜状态行非法 0｜状态行重复 0｜双状态行 0｜索引不一致 0｜取代悬空 0｜取代成环 0｜缺横幅 0
结论：OK
rc=0

$ python3 scripts/check_md_tables.py
畸形行 1 条（多格 1 / 少格 0）｜涉及文件 1 份｜规则 3 登记豁免 1 条
  FAIL docs/plans/gradebook-center-design.md:182 表头 2 格 / 本行 5 格
结论：FAIL   （= 唯一那条历史 FAIL，本次未新增）
rc=1

$ python3 scripts/check_english.py
TOTAL must-fix = 0 条 / brand = 0 条 / **路由状态违规 = 0 条** / **夹具残留 = 0 条**
rc=0
```

AGENTS.md §4 其余离线门禁（`check_english.py --selftest` 48 断言、`check_odoo_trace.py --selftest` 53、`check_view_xpath.py --selftest` 26、`check_view_xpath.py`、`tests/smoke/gate_seam_check.py`、`check_manifest_order.py`、`check_manifest_tracking.py`、`check_qweb_dict_foreach.py`、`check_recordset_none.py`、`check_shell_exitcode.py`、`check_ui_surface.py`、`check_po_sanity.py`、`check_alias_not_extended.py`、`check_nav_reachable.py`）**逐条 rc=0**。

## 4. 口径不明 / 需裁定，故**未改**（附实测）

| 位置 | 文档值 | 实测 | 为何未改 |
|---|---|---|---|
| docs/code-map.md:71 | edu_portal「~1.5 万行」 | `*.py` 27,719 行 / 全部文件 52,901 行 | 原文用「~」且未写口径（只算 .py？含 xml/js？），差一个口径就无法判定对错 ⇒ 留待台账维护者定口径 |
| docs/code-map.md:75 | batch2「最大文件」 | `roles.py` 3497 行 > `batch2.py` 2217 行 | 属判定语而非数字，改它要动措辞 ⇒ 未改，此处点明 |
| docs/code-map.md:117 | edu_public「等 13 路由」 | `@http.route` 装饰器 14 个 / 路径 15 条 | 若口径为「页面级路由（排除内部片段 `/alumni/job/card`）」恰得 13 ⇒ 两可，未改 |
| docs/code-map.md:140 | edu_admit_invite「4 个文件」 | 6 个文件（含 2 个 `__init__.py`） | 按「非 `__init__` 的实质文件」口径恰为 4 ⇒ 仍成立，不动 |
| docs/code-map.md:107 | 图标「24+ 彩色 SVG」 | `find custom_addons/edu_portal/static -name "*.svg" \| wc -l` = 49 | 「24+」仍成立，不动 |
| docs/code-map.md:7 | 「最后更新：2026-09-17」 | 文件内已有 2026-10-12 / 2026-10-14 内容 | 该段是**变更摘要**（改它等于新写一段摘要）⇒ 属改写，未动，标记滞后 |
| README.md:9 / README.md:38 | 「52 静态路由」/「100 路由 × 5 角色」 | — | 两者口径不同（静态路由清单 vs 路由矩阵行数），非同一数字，不动 |
| README.md:93 | 「edu_portal 26 路由复刻」 | — | 历史沿革段，记的是 2026-08-22 当时状态，非漂移 |

## 5. 未验证

- **【未验证】** docker 相关 41 个脚本（含 `safe_upgrade.sh` 真跑升级）未执行。**订正（Lead 复核，2026-10-17）**：原因**不是**「本机无 Docker」—— 本机 docker 可用且容器在跑（`docker compose ps` 显示 `edu19-clone-web-1` / `edu19-clone-db-1` 均 running）；真实原因是本次为纯文档改动、未触及任何模块代码，无需跑升级。
- **【未验证】** `README.md:12` 的「首页从 3744px 降到 1366–1469px」需浏览器实测，离线不可复现，未核。
- **【未验证】** `docs/code-map.md` §5 的门禁表历史结论（如「52 静态路由 + 动态发现」）未逐条复核，本轮只核了被点名的计数项。
- **【未验证】** 本次未跑 `check_menu_data_sync.py`、`check_nav_jobs_entries.py`（AGENTS.md §4 已登记的其余红项，与本次改动无关）。
