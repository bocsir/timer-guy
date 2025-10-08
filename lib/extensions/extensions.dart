// extensions/extensions.dart
import 'package:forui/forui.dart';

extension FPickerControllerExtension on FPickerController {
  int get totalSeconds {
    return (value[0] * 3600 + value[1] * 60 + value[2]);
  }
}
