# 许可调查与发布门槛

这是工程许可清单，未完成法律审查，未选定项目 LICENSE。[Pikafish 官方 README](https://github.com/official-pikafish/Pikafish/blob/master/README.md) 标明 GPL v3，并要求分发时提供与二进制对应源码及修改；固定 tag 源文件头采用 v3 或以后版本措辞，须逐文件核对以决定项目 SPDX。不要仅凭进程隔离判断不存在派生或组合义务。

| 对象 | 当前状态 | 发布前动作 |
|---|---|---|
| 项目自有代码与文档 | 已有自有Flutter/Dart业务、测试和文档 | 明确版权归属、选择 GPL 兼容许可、加完整 LICENSE |
| Pikafish 与桥接补丁 | .local固定官方制品及开发沙箱helper；未修改上游源码 | 固定SHA、COPYING/AUTHORS、对应源码归档、构建说明、修改声明 |
| NNUE | .local已下载并校验，不入Git | 独立核实制品许可/来源/匹配版本，SHA256；训练数据许可不自动等于权重许可 |
| Flutter/Dart 与插件 | 已使用SDK/path_provider/crypto等，清单仍需持续补全 | 逐依赖含传递依赖登记许可证与NOTICE，生成SBOM |
| 棋子/棋盘/字体/声音 | 未复制 | 原创或明确可再分发许可，保留署名与来源 |
| 棋谱/精选/云库/识别 | 未复制或接入 | 取得数据/API服务许可，核对缓存/批量限制与隐私；公开可浏览不代表允许搬运 |

[Apple 审核指南](https://developer.apple.com/app-store/review/guidelines/) 是平台规则依据，但不证明 GPL 与商店条款兼容。iOS 必须在分发方案确定后复核签名、用户权利与商店条款；未解决不得发布。GPL 正文官网本轮抓取超时，后续必须取得权威完整文本核查。

制品清单字段：名称、版本、来源URL、完整SHA、许可证、版权、修改、对应源码路径、构建工具与脚本、架构、网络校验、分发渠道。每个发布包内附第三方许可和可获取的对应源码，不只链接不断变化的 master。

## 发行包实证修订 / 2026-11-01

已从官方2026-09-06发行包取得 NNUE-License.md，明确禁止未经许可商用。原始文本保留于 [NNUE许可](pikafish-2026-09-06/NNUE-License.md)，GPL正文和AUTHORS一并留存以供核查。这是权重独立限制，不能用源码GPL覆盖。

本轮仅本地技术验证；引擎与权重放在被Git忽略的.local/pikafish，不纳入发布。不可声称当前全部运行资源符合自由开源许可。发行选项：取得明确授权；或研究与该引擎真实兼容且授权开放的权重。文中提及的其他引擎CC0权重不能未经兼容性验证直接替换。该问题阻断发行，不阻断合法本地研究。

来源与校验见 engine/COMMUNICATION_VALIDATION.md；这些hash是此次下载实测值，不是已验证的上游签名。第三方许可原文复制仅用于归档与合规研究，不作为本项目许可。

## 2026-11-02 显式依赖登记

crypto 3.0.8：[官方发布页](https://pub.dev/packages/crypto)，Dart项目作者，BSD-3-Clause；本次由原有传递依赖改为直接依赖，版本未变。包归档SHA256为e3626ae6270383c9e3a549f34c9e4cd26c09ae6a9adaab2bf4737a00340efdc4（pubspec.lock）。本机包LICENSE SHA256为ad6a71997da90924b2cfb1fb47ec46537f70faf469efe016168794ae45ed6888；用于制品与后续缓存摘要。SDK和其他依赖完整SBOM仍待发布阶段，不将此一项登记视为全部许可已处理。遵用户指示许可决策暂缓，不阻挡功能开发。
