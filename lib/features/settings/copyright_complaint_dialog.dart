import 'package:flutter/material.dart';

import '../../ports/copyright_complaint_service.dart';
import '../../ports/feedback_service.dart';

class CopyrightComplaintDialog extends StatefulWidget {
  const CopyrightComplaintDialog({
    super.key,
    required this.endpoint,
    required this.service,
    this.attachmentPicker,
  });

  final String endpoint;
  final CopyrightComplaintService service;
  final FeedbackAttachmentPicker? attachmentPicker;

  @override
  State<CopyrightComplaintDialog> createState() =>
      _CopyrightComplaintDialogState();
}

class _CopyrightComplaintDialogState extends State<CopyrightComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fields = List.generate(6, (_) => TextEditingController());
  bool _truthConfirmed = false;
  bool _sending = false;
  bool _sent = false;
  String? _status;
  final List<FeedbackAttachment> _attachments = [];

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_truthConfirmed) {
      setState(() => _status = '请先确认声明真实、准确。');
      return;
    }
    final complaint = CopyrightComplaintSubmission(
      complainant: _fields[0].text,
      email: _fields[1].text,
      work: _fields[2].text,
      ownership: _fields[3].text,
      content: _fields[4].text,
      details: _fields[5].text,
      attachments: _attachments,
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认提交版权投诉'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('接收地址：${widget.endpoint.trim()}'),
                for (final pair in <(String, String)>[
                  ('投诉人', complaint.complainant),
                  ('联系邮箱', complaint.email),
                  ('作品', complaint.work),
                  ('权属说明', complaint.ownership),
                  ('涉及内容', complaint.content),
                  (
                    '补充说明',
                    complaint.details.isEmpty ? '未提供' : complaint.details,
                  ),
                ]) ...[
                  Text(pair.$1),
                  SelectableText(pair.$2),
                  const SizedBox(height: 6),
                ],
                Text('附件（${complaint.attachments.length}）'),
                if (complaint.attachments.isEmpty)
                  const Text('未选择附件')
                else
                  for (final attachment in complaint.attachments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.memory(
                        attachment.bytes,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_outlined),
                      ),
                      title: Text(attachment.name),
                      subtitle: Text(
                        '${attachment.mimeType} · ${attachment.bytes.length} B',
                      ),
                    ),
                const Text(
                  '只发送以上填写内容和明确选择的附件。连接会向服务及托管层暴露来源IP等网络信息；数据保存在运营者私有目录，保留期限由运营者设置。',
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
            key: const ValueKey('confirm-send-complaint'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认提交'),
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
      await widget.service.submitCopyrightComplaint(
        endpoint: Uri.parse(widget.endpoint.trim()),
        complaint: complaint,
      );
      if (mounted) {
        setState(() {
          _sending = false;
          _sent = true;
          _status = '已提交至配置的自建投诉服务。';
        });
      }
    } on FeedbackServiceUnavailable {
      _finish('暂时无法连接服务；请确认是否收到后再重试。');
    } on FeedbackServiceRejected catch (error) {
      _finish('服务拒绝请求（HTTP ${error.statusCode}）。');
    } on FeedbackServiceInvalidResponse {
      _finish('服务返回无效响应；请联系运营者确认是否收到。');
    } catch (_) {
      _finish('提交失败；请联系运营者确认是否收到。');
    }
  }

  void _finish(String message) {
    if (mounted) {
      setState(() {
        _sending = false;
        _status = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('版权投诉'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(0, '投诉人', required: true, max: 160),
              _field(1, '联系邮箱', required: true, max: 254),
              _field(2, '作品名称及权利类型', required: true, max: 500),
              _field(3, '权属/授权证明说明', required: true, max: 2000, lines: 3),
              _field(4, '涉及内容及可定位链接', required: true, max: 2000, lines: 3),
              _field(5, '补充说明（可选）', required: false, max: 2000, lines: 3),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('pick-complaint-attachments'),
                  onPressed:
                      _sending ||
                          widget.attachmentPicker == null ||
                          _attachments.length >=
                              FeedbackAttachment.maxAttachments
                      ? null
                      : _pickAttachments,
                  icon: const Icon(Icons.attach_file),
                  label: Text('添加证明图片（${_attachments.length}/3）'),
                ),
              ),
              for (var index = 0; index < _attachments.length; index++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Image.memory(
                    _attachments[index].bytes,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
                  ),
                  title: Text(_attachments[index].name),
                  subtitle: Text(
                    '${(_attachments[index].bytes.length / 1024).ceil()} KiB',
                  ),
                  trailing: IconButton(
                    tooltip: '移除${_attachments[index].name}',
                    onPressed: _sending
                        ? null
                        : () => setState(() => _attachments.removeAt(index)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              CheckboxListTile(
                key: const ValueKey('complaint-truth'),
                contentPadding: EdgeInsets.zero,
                value: _truthConfirmed,
                onChanged: _sending
                    ? null
                    : (value) =>
                          setState(() => _truthConfirmed = value ?? false),
                title: const Text('我确认以上投诉真实、准确，并愿承担相应责任。'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const Text(
                '可选添加最多3张PNG/JPEG图片，每张不超过256KiB、合计不超过512KiB。仅在完整预览并确认后发送；服务运营者负责私有保存和保留期限。',
              ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
        key: const ValueKey('preview-complaint'),
        onPressed: _sending || _sent ? null : _preview,
        child: Text(
          _sending
              ? '正在提交…'
              : _sent
              ? '已提交'
              : '预览并提交',
        ),
      ),
    ],
  );

  Widget _field(
    int index,
    String label, {
    required bool required,
    required int max,
    int lines = 1,
  }) => TextFormField(
    key: ValueKey('complaint-field-$index'),
    controller: _fields[index],
    maxLines: lines,
    maxLength: max,
    decoration: InputDecoration(labelText: label),
    validator: (value) => required && (value == null || value.trim().isEmpty)
        ? '请填写$label'
        : null,
  );

  Future<void> _pickAttachments() async {
    final picker = widget.attachmentPicker;
    if (picker == null) return;
    try {
      final selected = await picker.pickAttachments(
        remaining: FeedbackAttachment.maxAttachments - _attachments.length,
      );
      if (selected == null || !mounted) return;
      final combined = [..._attachments, ...selected];
      if (combined.fold<int>(0, (sum, item) => sum + item.bytes.length) >
          FeedbackAttachment.maxTotalBytes) {
        setState(() => _status = '附件合计不能超过512KiB，请移除部分图片后重试。');
        return;
      }
      setState(() {
        _attachments
          ..clear()
          ..addAll(combined);
        _status = null;
      });
    } on FeedbackAttachmentPickerException catch (error) {
      final message = switch (error.reason) {
        FeedbackAttachmentPickerFailure.limit => '最多选择3张图片。',
        FeedbackAttachmentPickerFailure.size => '单张不能超过256KiB，附件合计不能超过512KiB。',
        FeedbackAttachmentPickerFailure.format => '仅支持有效的PNG或JPEG图片。',
        FeedbackAttachmentPickerFailure.unavailable => '此平台当前无法打开图片选择器。',
        FeedbackAttachmentPickerFailure.read => '无法读取所选图片。',
      };
      if (mounted) setState(() => _status = message);
    }
  }
}
