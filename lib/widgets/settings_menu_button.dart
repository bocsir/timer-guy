// widgets/settings_menu_button.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/settings.dart';
import 'package:timer_guy/theme/theme.dart';

/// A small settings popover for display preferences.
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FPopover(
      popoverAnchor: Alignment.topRight,
      childAnchor: Alignment.bottomRight,
      popoverBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeMode,
                builder: (context, mode, _) => FSwitch(
                  label: const Text('Dark mode'),
                  description: const Text('Switch between light and dark.'),
                  value: mode == ThemeMode.dark,
                  onChange: (enabled) => appThemeMode.value = enabled
                      ? ThemeMode.dark
                      : ThemeMode.light,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: animatedBackgroundEnabled,
                builder: (context, enabled, _) => FSwitch(
                  label: const Text('Animated background'),
                  description: const Text(
                    'Random blurred colors that react to working and resting.',
                  ),
                  value: enabled,
                  onChange: (value) => animatedBackgroundEnabled.value = value,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (_, controller, _) => FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: controller.toggle,
        child: Icon(FIcons.settings, color: colors.mutedForeground, size: 24),
      ),
    );
  }
}
