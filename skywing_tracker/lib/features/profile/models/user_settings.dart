class UserSettings {
  final String userId;
  final bool useKilometers;
  final bool notifyFlightStart;
  final bool notifyOverdue;
  final bool notifyReturnReminder;
  final bool notifyInactive;
  final bool notifyDeclinePerformance;

  const UserSettings({
    required this.userId,
    this.useKilometers = true,
    this.notifyFlightStart = true,
    this.notifyOverdue = true,
    this.notifyReturnReminder = true,
    this.notifyInactive = false,
    this.notifyDeclinePerformance = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      useKilometers: json['use_kilometers'] as bool? ?? true,
      notifyFlightStart: json['notify_flight_start'] as bool? ?? true,
      notifyOverdue: json['notify_overdue'] as bool? ?? true,
      notifyReturnReminder: json['notify_return_reminder'] as bool? ?? true,
      notifyInactive: json['notify_inactive'] as bool? ?? false,
      notifyDeclinePerformance:
          json['notify_decline_performance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'use_kilometers': useKilometers,
    'notify_flight_start': notifyFlightStart,
    'notify_overdue': notifyOverdue,
    'notify_return_reminder': notifyReturnReminder,
    'notify_inactive': notifyInactive,
    'notify_decline_performance': notifyDeclinePerformance,
  };

  UserSettings copyWith({
    String? userId,
    bool? useKilometers,
    bool? notifyFlightStart,
    bool? notifyOverdue,
    bool? notifyReturnReminder,
    bool? notifyInactive,
    bool? notifyDeclinePerformance,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      useKilometers: useKilometers ?? this.useKilometers,
      notifyFlightStart: notifyFlightStart ?? this.notifyFlightStart,
      notifyOverdue: notifyOverdue ?? this.notifyOverdue,
      notifyReturnReminder: notifyReturnReminder ?? this.notifyReturnReminder,
      notifyInactive: notifyInactive ?? this.notifyInactive,
      notifyDeclinePerformance:
          notifyDeclinePerformance ?? this.notifyDeclinePerformance,
    );
  }
}
