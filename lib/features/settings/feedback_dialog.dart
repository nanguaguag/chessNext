import 'package:flutter/material.dart';

import '../../ports/feedback_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({
    super.key,
    required this.endpoint,
    required this.service,
  });

  final String endpoint;
  final FeedbackService service;

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _contact = TextEditingController();
  FeedbackKind _kind = FeedbackKind.problem;
  String? _status;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    final feedback = FeedbackSubmission(
      kind: _kind,
      message: _message.text,
      contact: _contact.text,
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认发送反馈'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('接收地址：${widget.endpoint.trim()}'),
                Text('类型：${_kind == FeedbackKind.problem ? '问题反馈' : '功能建议'}'),
                const SizedBox(height: 8),
                const Text('描述'),
                SelectableText(feedback.message),
                const SizedBox(height: 8),
                Text(
                  '联系方式：${feedback.contact.trim().isEmpty ? '未提供' : feedback.contact.trim()}',
                ),
                const SizedBox(height: 12),
                const Text(
                  '只发送以上内容，不附加设备、浏览器、系统、棋谱或诊断信息。连接本身会让服务及托管层看到来源IP等网络信息。收件内容保存在目标服务私有目录，保留期限由运营者设置。',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回修改'),
          ),
          FilledButton(
            key: const ValueKey('confirm-send-feedback'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认发送'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _sending = true;
      _status = null;
    });
    try {
      final endpoint = Uri.parse(widget.endpoint.trim());
      await widget.service.submit(endpoint: endpoint, feedback: feedback);
      if (mounted) {
        setState(() {
          _sending = false;
          _sent = true;
          _status = '已发送至配置的自建反馈服务。';
        });
      }
    } on FeedbackServiceUnavailable {
      _finish('暂时无法连接反馈服务。内容未确认送达，可检查网络后重试。');
    } on FeedbackServiceInvalidResponse {
      _finish('反馈服务返回无效响应；请联系服务运营者确认是否收到。');
    } on FeedbackServiceRejected catch (error) {
      _finish('反馈服务拒绝请求（HTTP ${error.statusCode}）。');
    } catch (_) {
      _finish('发送失败；请联系服务运营者确认是否收到。');
    }
  }

  void _finish(String value) {
    if (mounted) {
      setState(() {
        _sending = false;
        _status = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('问题反馈与建议'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FeedbackKind>(
                key: const ValueKey('feedback-kind'),
                initialValue: _kind,
                decoration: const InputDecoration(labelText: '类型'),
                items: const [
                  DropdownMenuItem(
                    value: FeedbackKind.problem,
                    child: Text('问题反馈'),
                  ),
                  DropdownMenuItem(
                    value: FeedbackKind.suggestion,
                    child: Text('功能建议'),
                  ),
                ],
                onChanged: _sending
                    ? null
                    : (value) {
                        if (value != null) setState(() => _kind = value);
                      },
              ),
              TextFormField(
                key: const ValueKey('feedback-message'),
                controller: _message,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '请描述遇到的问题或建议',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '请填写描述' : null,
              ),
              TextFormField(
                key: const ValueKey('feedback-contact'),
                controller: _contact,
                maxLength: 200,
                decoration: const InputDecoration(labelText: '联系方式（可选）'),
              ),
              const SizedBox(height: 8),
              Text('反馈服务：${widget.endpoint.trim()}'),
              const Text(
                '内容会保存到自建服务的私有收件目录；保留期限由服务运营者设置。请勿填写敏感信息。连接会让服务/托管层看到来源IP等网络信息。不会自动收集设备或棋谱信息；附件暂不可用。',
              ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_status!),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _sending ? null : () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
      FilledButton(
        key: const ValueKey('preview-feedback'),
        onPressed: _sending || _sent ? null : _preview,
        child: Text(
          _sending
              ? '正在发送…'
              : _sent
              ? '已发送'
              : '预览并发送',
        ),
      ),
    ],
  );
}
