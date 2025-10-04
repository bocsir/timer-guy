// header.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/theme/button_style.dart';
import 'package:proj/theme/theme.dart';

class Header extends StatelessWidget {
  final String? backBtnText;
  final String titleText;
  //maybe add settings stuff too

  const Header({super.key, this.backBtnText, required this.titleText});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: backBtnText == null
                    ? FButton.icon(
                        style: transparentButtonStyle,
                        onPress: () => Navigator.pop(context),
                        child: Icon(
                          FIcons.chevronLeft,
                          color: colors.accent,
                          size: 24,
                        ),
                      )
                    : FButton(
                        onPress: () => Navigator.pop(context),
                        style: transparentButtonStyle,
                        prefix: Icon(
                          FIcons.chevronLeft,
                          color: colors.accent,
                          size: 24,
                        ),
                        child: Text(
                          backBtnText!,
                          style: TextStyle(color: colors.accent),
                        ),
                      ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                titleText,
                style: context.theme.typography.lgSemibold,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FButton.icon(
                onPress: () {},
                style: transparentButtonStyle,
                child: Icon(FIcons.settings, color: colors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
