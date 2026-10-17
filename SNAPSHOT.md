# 快照说明（公开镜像，只读，纯代码评审用）

「永约学坊教务系统」（Odoo 19 + OpenEduCat 19.0 社区快照 + `custom_addons/edu_*` 15 个自研模块）的**只读代码快照**。

**刻意不含**：基座 `openeducat_erp/`（不能直接安装运行，仅供阅读）；生产运维档案（`docs/ops|research|plans`、`docs/audit/migration`、`docs/audit/security-audit-*`）；部署件（`deploy/`、`scripts/deploy_*|backup_*|ops/`）；面向生产的冒烟脚本（`tests/smoke/`）；`config/`；导入原始数据；评估表格；dev-tool 元数据（`.serena/`）；**所有二进制资产**（png/webp/woff/pdf/xlsx/docx——评审只读文本，剔除它们既减体积也避免上传时被图片截断）；以及本身逐条写着真实值的脱敏规则表（`scripts/hallucinate.py`）。

**已脱敏**：生产主机/IP/目录/容器名/域名/机器人标识/个人邮箱、真实师生姓名与学号、本机绝对路径。

先读 `CLAUDE.md`（铁律）、`AGENTS.md`（代理入职说明）、`docs/code-map.md`（一页图谱）。
