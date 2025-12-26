// header.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/theme/button_style.dart';
import 'package:proj/theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Header extends StatelessWidget {
  final bool? hideBackBtn;
  final String? backBtnText;
  final String? titleText;

  // settings stuff
  final FPopoverController? popoverController;
  final List<FItemGroup>? settingsStuff;

  const Header({
    super.key,
    this.hideBackBtn,
    this.backBtnText,
    this.titleText,
    this.popoverController,
    this.settingsStuff,
  });

  @override
  Widget build(BuildContext context) {
    final title = titleText;

    final colors = context.theme.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          // make stack a fixed height
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hideBackBtn != true)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IntrinsicWidth(
                    child: backBtnText == null
                        ? FButton.icon(
                            style: transparentButtonStyle,
                            onPress: () => Navigator.pop(context),
                            child: Icon(FIcons.chevronLeft, color: colors.accent, size: 28),
                          )
                        : FButton(
                            onPress: () => Navigator.pop(context),
                            style: transparentButtonStyle,
                            child: Text(backBtnText!, style: TextStyle(color: colors.accent)),
                          ),
                  ),
                ),
              if (title != null && title.isNotEmpty)
                Align(
                  alignment: Alignment.center,
                  child: Text(title, style: context.theme.typography.lgSemibold),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: FPopoverMenu(
                  popoverController: popoverController,
                  menuAnchor: Alignment.topRight,
                  childAnchor: Alignment.bottomRight,
                  menu: [
                    if (settingsStuff != null)
                      ...settingsStuff!
                    else
                      FItemGroup(children: [FItem(title: Text('No settings available'))]),
                  ],
                  builder: (context, controller, child) => FButton.icon(
                    onPress: controller.toggle,
                    style: transparentButtonStyle,
                    child: SvgPicture.asset(
                      'lib/assets/circle-ellipsis.svg',
                      width: 24,
                      height: 24,
                      theme: SvgTheme(currentColor: colors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
