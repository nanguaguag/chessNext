# ADR-092：自建只读版本与更新日志清单

- 状态：已采纳（M4-60服务端首片；客户端/检查动作待后续）
- 日期：2026-11-05
- 关联：F31、E70、E74

## 背景

参考站可见构建号、检查更新和更新日志入口（E70/E74），但点击后无可见反馈，真实响应、网络目的地及包下载流程均未知。项目不能冒充其协议或行为。

## 决策

- 扩展现有自建只读服务，使用可选`CHESSNEXT_RELEASE_ROOT`中的operator-authored `releases.json`，暴露`GET /v1/releases/latest`。
- 固定schema1：newest-first release列表，包含SemVer形式version、正整数build、UTC publishedAt、最多4000字符纯文本notes；最多100项；拒绝未知字段、重复版本+build、未降序日期、控制字符和超限文件（1MiB）。
- endpoint默认禁用；服务不提供程序包、不执行安装、不接受任何写入请求、不接收设备/用户标识、不持久化查询。部署沿用HTTPS反代、systemd loopback与原有安全边界。
- Flutter客户端只在用户明确执行“检查更新”时请求；零配置离线。该客户端和设置UI是后续独立增量，不能将本服务片称为F31对齐。

## 验收

manifest边界、排序、duplicate、可选禁用与只读路由测试；server analyze、根Flutter test/analyze；server二进制可编译；部署样例给出manifest根配置且不开放8087公网。

## 未解决

真实版本比较策略、渠道/平台过滤、真实日志、URL、重载生效、更新下载/签名/安装不在本片；站点实际行为均U。客户端需另定义版本比较、失败状态与TLS/timeout处理。
