# ADR-088 云库客户端传输端口

- 日期：2026-11-05
- 状态：接受（M4-56传输层首片）
- 关联：F15、F22、F23、ADR-087、E71

## 决策

定义平台无关`BookService`及受限HTTP适配器。调用方显式提供服务根地址和精确`kind + FEN + history`；默认不配置服务、不发网络请求。公网仅允许HTTPS；HTTP只允许localhost/loopback，便于本机开发。连接/响应超时5秒、请求及响应体最多32KiB、历史最多512着、返回候选最多32项。

适配器核对响应schema、请求键回显、候选UCI格式/权重唯一性和数据集license/attribution；不负责领域合法性，不落子、不缓存、不重试。网络不可达返回Unavailable，非成功状态返回Rejected，协议不合法返回InvalidResponse；应用层之后负责合法着法复核、用户可见降级/本机引擎回退和隐私说明。

## 验证边界

本片提供可替换端口和真实HTTP协议客户端，但尚未注入应用composition root，也没有偏好UI、缓存或AI走棋集成；因此不会发出线上请求。服务端数据仍由运营者提供。HTTPS证书/超时验证通过本机HTTP fixture/类型测试，不代表部署TLS或端到端远端数据已验证。
