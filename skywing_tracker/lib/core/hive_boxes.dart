import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  // Open all boxes
  await Future.wait([
    Hive.openBox(AppConstants.pigeonsBox),
    Hive.openBox(AppConstants.flightsBox),
    Hive.openBox(AppConstants.participantsBox),
    Hive.openBox(AppConstants.analyticsBox),
    Hive.openBox(AppConstants.pendingActionsBox),
  ]);
}

Box get pigeonsBox => Hive.box(AppConstants.pigeonsBox);
Box get flightsBox => Hive.box(AppConstants.flightsBox);
Box get participantsBox => Hive.box(AppConstants.participantsBox);
Box get analyticsBox => Hive.box(AppConstants.analyticsBox);
Box get pendingActionsBox => Hive.box(AppConstants.pendingActionsBox);
