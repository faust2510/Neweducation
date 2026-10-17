# 旧评估 A 套（`edu.eval.*`）退役 —— ④ 备份台账 + ⑤ 删除闸门

> **状态**：`④ 备份` **已完成**（2026-10-14，本地栈）｜`⑤ 删除` **未执行 —— 等人工拍板**
> 对应待办：`docs/plans/README.md` 队列 ④；设计依据：`docs/plans/evaluation-rebuild-design.md` §7.1/§7.2/§7.4
> 事实底座：`docs/audit/review-pack-eval-retirement.md`（含两次勘误）；B 套先例：`docs/audit/edu-eval-removal.md`
> 本页只记**证据与读数**，每条都能原样复跑；**⑤ 的结论不在这里，在拍板之后**。

---

## 1. 产物（路径 / 字节 / sha256）

| 产物 | 字节 | sha256 | 采集时刻 | 行数（template/line/task/score） |
|---|---|---|---|---|
| `docs/audit/eval-rebuild/a-suite-eval-definitions.json` | 3675 | `8f3885a2cd424c380f7101bc9220371cd56f3430b7d5130793b9c2c655aa6b63` | 2026-10-14T17:51:16+08:00 | 3 / 12 / 1 / 5 |
| `docs/audit/eval-rebuild/a-suite-eval-definitions.2026-09-29-with-b-suite.json` | 3851 | `3041d56aed823ebc3b792aa1c4d74940440c77a5a990eb7f537bbde1cc977c6f` | 2026-09-29T12:20:55+08:00 | 3 / 12 / 1 / 5（**另含** `b_suite` 0/0/0 留档） |
| `docs/audit/eval-rebuild/a-suite-pg-dump-20261014.sql` | 22888 | `aede8ee669112a65d8c4e29d7aa7d9b7b513f2c3e24ae78e149f30e71209b0cf` | 2026-10-14 17:51 | 3 / 12 / 1 / 5（21 行数据） |

复跑命令：

```bash
# 定义留档（只读 SELECT；产物含 b_suite 时会被互锁拒绝，见 §3）
python3 scripts/backup_a_eval_json.py

# 表级 pg_dump（本地库 edu19，4 张表 21 行）
docker compose exec -T db pg_dump -U odoo -d edu19 -t 'edu_eval_*' \
  > docs/audit/eval-rebuild/a-suite-pg-dump-20261014.sql

# 核对
shasum -a 256 docs/audit/eval-rebuild/*
```

第 2 行的产物是从 `2026-09-29` 的留档**原样保留**的副本（`cp -p`，sha256 与原件逐字相同），
因为新脚本会覆盖同名产物，而那份留档里存着**删除 B 套之前**的 `b_suite` = 0/0/0 取证材料（脚本文件头第 12–16 行明说了这个风险）。

---

## 2. 本次实测读数 —— 推翻 review-pack 的一条事实

`docs/audit/review-pack-eval-retirement.md:29` 写「本地 A 套数据：四张表**全 0 行**」。**这条不成立**，
2026-10-14 本地库 `edu19` 实测（只读）：

```bash
docker exec edu19-clone-db-1 psql -U odoo -d edu19 -tAc "
select 'edu_eval_template', count(*) from edu_eval_template
union all select 'edu_eval_template_line', count(*) from edu_eval_template_line
union all select 'edu_eval_task', count(*) from edu_eval_task
union all select 'edu_eval_score', count(*) from edu_eval_score;"
# edu_eval_template|3
# edu_eval_template_line|12
# edu_eval_task|1
# edu_eval_score|5
```

明细（同样只读）：

- 模板 3 行：`1 学生综合评估记分表【演示】/student`、`2 实习同工评估表【演示】/intern`、`3 新生综合测评表【演示】/freshman`（**没有**生产那第 4 行「学生表现分」）。
- 任务 1 行：`id=1 template_id=1 student_id=5 evaluator_type=teacher period=2026秋 state=done total_score=90`。
- 打分 5 行：`task_id=1`、`template_line_id=1..5`、每条 `score=18`。

⇒ 本地这 5 条打分是**演示数据的残留**（模板全带【演示】、分数整齐），与 `2026-09-29` 留档完全一致
（⇒ 本地自那次采集以来**没有变过**）。**这不改变「A 套从未被真实使用过」的结论，但它确实推翻了
「本地四张表全 0」这句**——按 `docs/code-map.md` §6 第 23 条的立场，读数只能以现测为准。

设计稿 §7.2 的「生产 4 模板 / 13 评分项 / 1 空任务 / 0 打分」是**生产**读数：
本仓不含生产凭据（`AGENTS.md` §6），**本轮无法复核，也未复核**；此处只记录它的来源是 `docs/plans/evaluation-rebuild-design.md` §2.5/§7.2。

---

## 3. 防覆盖互锁：实测（不是读代码猜的）

```bash
python3 scripts/backup_a_eval_json.py
# REFUSED: a-suite-eval-definitions.json 含有 b_suite 留档（删除行政评估前的取证材料），重跑会覆盖它。确需覆盖请显式 EDU_ALLOW_OVERWRITE_EVIDENCE=1。
# rc=3
EDU_ALLOW_OVERWRITE_EVIDENCE=1 python3 scripts/backup_a_eval_json.py
# BACKUP file=a-suite-eval-definitions.json templates=3 lines=12 tasks=1 scores=5
# rc=0
```

---

## 4. 可恢复性演练（本地临时库，已销毁）

`-t 'edu_eval_*'` 是**过滤导出**，因此先验证它真的能装回去（`⑤ DROP TABLE` 不可逆）：

```bash
docker exec edu19-clone-db-1 createdb -U odoo edu_restore_rehearsal_NNN
docker exec -i edu19-clone-db-1 psql -U odoo -d edu_restore_rehearsal_NNN -q -v ON_ERROR_STOP=1 \
  -f - < docs/audit/eval-rebuild/a-suite-pg-dump-20261014.sql
docker exec edu19-clone-db-1 psql -U odoo -d edu_restore_rehearsal_NNN -tAc "…count…"
docker exec edu19-clone-db-1 dropdb -U odoo edu_restore_rehearsal_NNN
```

结果：4 张表建成、**21 行数据全部装入**（3 / 12 / 1 / 5，与源库逐表相等）；
唯一报错是 `psql:<stdin>:707: ERROR: relation "public.res_users" does not exist` ——
那是 `edu_eval_score.create_uid → public.res_users` 的外键，而 `-t 'edu_eval_*'` **不含基表**，属**预期内**，
不影响表与数据的可恢复性。演练库已 `dropdb`，容器内无残留。

---

## 5. 这一轮**没有**做的（Step A 的缺口，别当成已完成）

| 缺口 | 原因 |
|---|---|
| 4 个模板的 xlsx 导出（设计稿 §7.1 原话） | 本地只有 3 条【演示】模板，第 4 条「学生表现分」只存在于生产；本仓不含生产凭据 ⇒ 无法导出 |
| 生产库表级 `pg_dump` | 同上（`AGENTS.md` §6：任何部署命令都不要跑） |
| `edu_eval_*` 之外的隐式耦合清点（`ir_model_data` / `ir_model_fields` / 外键反查…） | 属 **⑤ 删前**动作（`review-pack` Q4/Q5 清单），未拍板前不动 |

---

## 6. ⑤ 删除的闸门（未动，等拍板）

> **拍板结果（2026-10-14，用户）**：走**冻结期**路线 —— **先冻结 2 周（至 2026-10-28）**，
> 期间观察有没有人报「找不到评估」，期满再执行 ⑤（依据 = `review-pack` Q1 的倾向：生产无 staging、删除不可逆）。
> 同一轮拍板：设计稿 §7.1 的「4 个模板 xlsx 导出」由**用户在生产后台自行导出**后留档，本仓不代为执行（见 §5）。

- **未执行任何删除动作**：4 个模型类、8 条 ACL（`custom_addons/edu_portal/security/ir.model.access.csv:60-67`）、
  7 条 303 路由与 `custom_addons/edu_portal/controllers/eval_compat.py`、
  `custom_addons/edu_portal/views/evaluation.xml` 的 A 套 action/view/menuitem、migration 里的 `DROP TABLE` —— **全部原样**。
- 删前必查（`review-pack` Q4 易误删清单）：① 活子菜单（`parent_id` 反查 + `active`）
  ② `inherit_id` 反查 ③ `ir_model_data` ④ `ir_model_fields` ⑤ 指向被删表的外键。
- **红线**：根菜单 `588`（`edu_portal.menu_edu_eval_root`）**不得停用/删除** —— 新引擎 `edu_assess` 的 4 条菜单
  以它为 `parent`（`custom_addons/edu_assess/views/assess_views.xml:262/266/270/274`），停用等于关掉新引擎后台入口
  （详见 `docs/code-map.md` §6 第 23 条与 `review-pack` 文首勘误第二次）。

**期满后 ⑤ 的执行顺序**（设计稿 §7.1「每步独立 commit、可独立回滚」；本轮**未开始**）：

1. 只读清单：按上面 5 项逐条查现态（活子菜单 / `inherit_id` 反查 / `ir_model_data` / `ir_model_fields` / 外键），
   把读数写进本页，**再**动代码。判据见 `docs/code-map.md` §6 第 23 条。
2. commit A（可独立回滚）：`custom_addons/edu_portal/` 内删 4 个模型类、8 条 ACL、7 条路由与 `eval_compat.py`、
   `views/evaluation.xml` 的 A 套 action/view/menuitem ⇒ `bash scripts/safe_upgrade.sh edu_portal`（无 Traceback）。
3. commit B：幂等 migration `DROP TABLE`（savepoint + `information_schema` 列/表检查，禁裸 `except`）+ 本页登记
   ⇒ 再跑一次升级；回滚 = revert commit B（表已删，数据靠 §1 三份产物重灌）。

---

## 7. 顺带观测（**未修**，与本任务无关）

`docs/audit/README.md:6` 写「份数 `65`（`docs/audit/**/*.md`，不含本页）」，2026-10-14 实测
`find docs/audit -name '*.md' -not -name README.md | wc -l` = **67** ⇒ 索引已有 2 份的历史漂移。
本轮**不改它**（不在本任务边界内）；本页是目录 `README.md`，按该页口径**不计入份数**，因此本轮不制造新的计数漂移。
