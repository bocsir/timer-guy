// hive/hive_adapters.dart
import 'package:hive_ce/hive.dart';
import 'package:proj/models/workout.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Workout>()])
class HiveAdapters {}
