// widgets/settings_menu_button.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/settings.dart';
import 'package:timer_guy/theme/theme.dart';

/// A small settings popover for display preferences and workout file actions.
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key, this.onImport, this.onExport});

  /// Called when the user chooses to import workouts.
  final VoidCallback? onImport;

  /// Called when the user chooses to export workouts.
  ///
  /// The item is omitted when this is null.
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return FPopover(
      popoverAnchor: Alignment.topRight,
      childAnchor: Alignment.bottomRight,
      popoverBuilder: (context, controller) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              if (onImport != null || onExport != null)
                FItemGroup(
                  divider: FItemDivider.full,
                  children: [
                    if (onImport case final onImport?)
                      FItem(
                        prefix: const Icon(FIcons.upload),
                        title: const Text('Import workouts'),
                        subtitle: const Text('Load workouts from a YAML file'),
                        onPress: () async {
                          await controller.hide();
                          onImport();
                        },
                      ),
                    if (onExport case final onExport?)
                      FItem(
                        prefix: const Icon(FIcons.download),
                        title: const Text('Export workouts'),
                        subtitle: const Text('Save workouts as a YAML file'),
                        onPress: () async {
                          await controller.hide();
                          onExport();
                        },
                      ),
                  ],
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
