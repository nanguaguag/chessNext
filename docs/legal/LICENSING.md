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

file_selector1.1.0及实际解析的平台/传递依赖见[文件选择登记](FILE_SELECTOR_DEPENDENCIES.md)，包含归档与本机LICENSE摘要。官方平台能力表为文档证据；实际使用能力与未验项见RECORD_FILE_IMPORT_SLICE/TRACEABILITY。

2026-11-02 E34研究PNG：Agent自制棋步，通过公开保存图片/复制图片得出；图片含参考站木纹/棋子外观，只在docs/research/samples留证据，不作为产品素材或引擎测试资源。产品PNG仅用项目原创Flutter绘制；SHA/来源见samples/E34-manifest.json，许可决定仍按用户要求暂缓。

2026-11-02 E35研究GIF：Agent自制棋树/标题，通过公开动态图预览与下载取得；GIF及截图含参考站木纹、棋子和排版，只在docs/research留作功能范围证据，不作为产品素材、编码fixture或视觉基线。产品动态图必须由项目原创棋盘绘制，SHA/帧数据/来源见samples/E35-manifest.json；许可决定仍按用户要求暂缓。

2026-11-03 显式登记动态图编码依赖：[`image` 4.12.0](https://pub.dev/packages/image/versions/4.12.0)，MIT，pubspec.lock归档SHA256 `89ed75b2f8231fe676808c5564f9590d728024ded7ac782a7ed8474f1c95b72a`，本机LICENSE SHA256 `f3c17da84e0780e1c334325c73098257c32221d62498ed55ef3c1361904925aa`；传递依赖`archive` 4.6.0 MIT，归档SHA `de5ac590b8155e4e676088d714bd41ea620449a6adc0f7950c5073874b287ddb`、LICENSE SHA `32f97d332eae7453ec4079858e6f1d74be85beeb6d3881068b47d02a379cccea`；`posix` 6.5.4 MIT，归档SHA `613646d076944f3acc125830af935b48d4b8a57a388691547bbfd25b434f4d63`、LICENSE SHA `aaf6271abd048deb3125828613f1797b7556472de6c7acd7103bd43e9cb6a84b`。完整传递依赖许可/SBOM仍属发行前工作。

## 2026-11-03 M4-06 本机音效

本项目原创WAV由 tool/generate_sound_assets.dart 经 lib/adapters/audio/tone_wave.dart 可重复生成，非参考站素材。select.wav SHA256 9d88d1cd189f795fba055aa3456d5ae4995cb3995d533db5fc9a385d0956ccbe；move.wav SHA256 4f4b1aab580d79ea0929e2b677eebe4fc03e8653a7d8d73c3f9ccbd33e41938e；capture.wav SHA256 0ce428bbe41b57c4c829a7d092f3caef17250c8062d5006ced20b43e0b5009a4；check.wav SHA256 eb59c23c531d319b090949c9c17b82a77b90f4d3e49a72679cac2a40782d7373；mate.wav SHA256 d720793b24428b809ea6ec1e965eac8fceafeacaeaea34ace315c61aedfa1a3b。均为短PCM合成提示音。

新增 audioplayers 6.8.1（https://pub.dev/packages/audioplayers/versions/6.8.1），pub.dev标注MIT，直接归档SHA256 2ba4bb2944baacbdd5372ff8254a8e7feb8c10d7739545e392f5605a8f618745；解析 audioplayers_android 5.3.0、audioplayers_darwin 6.5.0、audioplayers_linux 4.3.0、audioplayers_web 5.3.0、audioplayers_windows 4.4.1 和 platform interface，确切锁定版本/归档摘要见pubspec.lock。macOS构建出现插件Swift 6隔离警告（当前是warning），需要未来升级/发行复核；本片只在macOS实际集成验证。此登记不等于全部传递依赖SBOM完成。

2026-11-03新增[flutter_tts 4.2.5](https://pub.dev/packages/flutter_tts/versions/4.2.5)，官方pub.dev发布页标注MIT，pub归档SHA256 ce5eb209b40e95f2f4a1397116c87ab2fcdff32257d04ed7a764e75894c03775。插件声明平台为Android/iOS/macOS/Web/Windows，没有Linux实现；本项目为离线边界在Web也不自动朗读，防止依赖浏览器未知在线voice。macOS插件编译给AVSpeechSynth枚举future-case warning，构建成功；Flutter还提示该插件暂不支持Swift Package Manager，将来Flutter可能提高要求。须在升级/发行前复核。
