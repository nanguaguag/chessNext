# 当前状态

日期：2026-11-01，Asia/Shanghai。当前 M2-02 / B15 编辑局面校验切片已完成，完整 M2 尚未完成。

## 授权与范围

用户已明确授权按计划开始实现离线业务。登录后和在线服务延期；许可事项按要求暂不处理、不阻挡本地开发，既有记录保留。此前“仅调查/仅通信诊断”限制已被本次授权取代。每轮仍交付小而可验证的增量。

## 已有产物

- M0：32项功能矩阵、访客证据、架构/设计/规划、六个Agent Skills。
- M1：research/spikes/flutter_engine_probe，Flutter测试2/2、macOS沙箱App通信成功。固定Pikafish2026-09-06及NNUE位于.local（Git忽略），来源/hash见engine/pikafish.lock.json。移动FFI和其他桌面未测。
- M2-01：packages/xiangqi_core独立纯Dart包。不可变坐标/棋子/走法/局面、FEN、七类棋子走法、自陷将军过滤、将帅照面、合法落子与perft，无Flutter/IO依赖。

## 本轮验证

dart analyze无问题；dart test 11/11通过；python3 tools/verify_xiangqi_perft.py 对4组局面逐分支与官方Pikafish完全一致（79666/1564/1100/46642节点）。原始证据docs/engine/evidence/xiangqi-perft.json。未重跑无变更的Flutter通信测试。

## 未完成与下一步

FEN解析只做结构验证；新增validateForPlay静态语义校验，但不证明历史可达；长将长捉、重复、自然限着和完整终局裁决未实现。没有业务棋盘UI、棋谱存储或完整App。下一步：B15局面语义校验/终局/历史接口→B16棋树与会话→棋盘垂直切片；B14移动桥接仍待做。

环境：Flutter3.44.6/Dart3.12.2，macOS14.4 arm64/Xcode15.0。基线已提交b3b423a；功能增量按中文Conventional Commits单独提交；无后台进程。许可原文已归档，后续是否处理以用户任务范围为准，不重复阻挡本地工作。

M2-02：新增棋子数量/将士象位置/兵卒位置与未过河同路重复/将帅照面/非行棋方被将军校验，返回错误类型、方色和坐标。根Flutter测试5/5、纯Dart20/20、引擎2/2，三处analyze全部通过。根目录Flutter包为测试/应用边界，尚无业务UI；tools/check.sh执行全套门槛。下一步实现将死/困毙终局（历史裁决仍独立）。
