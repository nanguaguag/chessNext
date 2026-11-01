import 'package:flutter/material.dart';
import '../../application/app_preferences.dart';

/// Composition boundary above Navigator. Preserve the OS scaler as an object,
/// including its nonlinear behavior, and override only on explicit manual mode.
class AppTextScaling extends StatelessWidget {
  const AppTextScaling({
    super.key,
    required this.preference,
    required this.child,
  });
  final TextSizePreference preference;
  final Widget child;
  static TextScaler systemOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_SystemTextScaling>()
          ?.scaler ??
      MediaQuery.textScalerOf(context);
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final factor = preference.manualScale;
    return _SystemTextScaling(
      scaler: media.textScaler,
      child: MediaQuery(
        data: media.copyWith(
          textScaler: factor == null
              ? media.textScaler
              : TextScaler.linear(factor),
        ),
        child: child,
      ),
    );
  }
}

class _SystemTextScaling extends InheritedWidget {
  const _SystemTextScaling({required this.scaler, required super.child});
  final TextScaler scaler;
  @override
  bool updateShouldNotify(_SystemTextScaling oldWidget) =>
      scaler != oldWidget.scaler;
}
