import 'package:flutter/material.dart';

import '../../application/app_metadata.dart';
import '../../ports/release_service.dart';
import '../../ports/feedback_service.dart';
import '../../ports/copyright_complaint_service.dart';
import 'feedback_dialog.dart';
import 'copyright_complaint_dialog.dart';

class AboutSupportDialog extends StatefulWidget {
  const AboutSupportDialog({
    super.key,
    required this.releaseEndpoint,
    required this.releaseService,
    required this.feedbackService,
    required this.copyrightComplaintService,
  });

  final String releaseEndpoint;
  final ReleaseService releaseService;
  final FeedbackService feedbackService;
  final CopyrightComplaintService copyrightComplaintService;

  @override
  State<AboutSupportDialog> createState() => _AboutSupportDialogState();
}

class _AboutSupportDialogState extends State<AboutSupportDialog> {
  ReleaseMetadata? metadata;
  String? status;
  bool checking = false;

  Future<void> _check() async {
    final endpoint = Uri.tryParse(widget.releaseEndpoint.trim());
    if (endpoint == null || widget.releaseEndpoint.trim().isEmpty) return;
    setState(() {
      checking = true;
      status = null;
      metadata = null;
    });
    try {
      final result = await widget.releaseService.fetchLatest(
        endpoint: endpoint,
      );
      if (!mounted) return;
      setState(() {
        metadata = result;
        checking = false;
      });
    } on ReleaseServiceUnavailable {
      _finishWith('无法连接更新服务，请检查地址与网络后重试。');
    } on ReleaseServiceInvalidResponse {
      _finishWith('更新服务返回的数据无效，未采用该内容。');
    } on ReleaseServiceRejected catch (error) {
      _finishWith('更新服务拒绝请求（HTTP ${error.statusCode}）。');
    } catch (_) {
      _finishWith('检查更新失败，请稍后重试。');
    }
  }

  void _finishWith(String message) {
    if (!mounted) return;
    setState(() {
      checking = false;
      status = message;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('关于 chessNext'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前版本 ${AppMetadata.displayVersion}'),
            const SizedBox(height: 8),
            const Text('离线优先的中国象棋分析应用。检查仅读取用户配置的自建发布信息，不下载或安装程序。'),
            const SizedBox(height: 16),
            if (widget.releaseEndpoint.isEmpty)
              const Text('未配置更新/反馈服务；应用保持离线，不会后台检查或发送信息。')
            else
              const Text('更新仅在手动检查时读取服务清单；反馈只在预览内容与地址后由你明确确认发送。'),
            const SizedBox(height: 12),
            if (checking)
              const LinearProgressIndicator()
            else if (metadata case final value?) ...[
              Text(
                _releaseStatus(value.current),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '服务端版本 ${value.current.version}+${value.current.build} · '
                '${_date(value.current.publishedAt)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(value.current.notes),
              for (final release in value.history.skip(1))
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '${release.version}+${release.build} · ${_date(release.publishedAt)}',
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(release.notes),
                      ),
                    ),
                  ],
                ),
            ] else if (status case final message?)
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: AppMetadata.name,
          applicationVersion: AppMetadata.displayVersion,
        ),
        child: const Text('开源许可'),
      ),
      TextButton(
        key: const ValueKey('open-feedback'),
        onPressed: widget.releaseEndpoint.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => FeedbackDialog(
                  endpoint: widget.releaseEndpoint,
                  service: widget.feedbackService,
                ),
              ),
        child: const Text('问题反馈与建议'),
      ),
      TextButton(
        key: const ValueKey('open-copyright-complaint'),
        onPressed: widget.releaseEndpoint.isEmpty
            ? null
            : () => showDialog<void>(
                context: context,
                builder: (_) => CopyrightComplaintDialog(
                  endpoint: widget.releaseEndpoint,
                  service: widget.copyrightComplaintService,
                ),
              ),
        child: const Text('版权投诉'),
      ),
      OutlinedButton.icon(
        key: const ValueKey('check-release-updates'),
        onPressed: checking || widget.releaseEndpoint.isEmpty ? null : _check,
        icon: const Icon(Icons.refresh),
        label: const Text('检查更新'),
      ),
      TextButton(
        onPressed: checking ? null : () => Navigator.pop(context),
        child: const Text('关闭'),
      ),
    ],
  );

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _releaseStatus(ReleaseEntry latest) {
    final remote = _versionParts(latest.version);
    final local = _versionParts(AppMetadata.version);
    for (var i = 0; i < 3; i++) {
      if (remote[i] != local[i]) {
        return remote[i] > local[i] ? '发现新版本' : '当前版本高于服务端清单';
      }
    }
    if (latest.version != AppMetadata.version) {
      final remotePre = latest.version.contains('-');
      final localPre = AppMetadata.version.contains('-');
      if (remotePre != localPre) return remotePre ? '当前版本高于预发布版本' : '发现新版本';
    }
    if (latest.build > AppMetadata.build) return '发现新版本';
    if (latest.build < AppMetadata.build) return '当前版本高于服务端清单';
    return '当前已是最新版本';
  }

  List<int> _versionParts(String value) => value
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}
