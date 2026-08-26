/// Feature Configuration
/// Toggle features on/off for development, testing, or production.
class FeatureConfig {
  FeatureConfig._();

  /// Enable/disable push notification feature.
  /// Set to true for production with Firebase configured.
  static const bool _enablePushNotificationDefault = true;

  /// Override value for testing purposes.
  /// Set to null to use default value.
  static bool? pushNotificationOverride;

  /// Returns whether push notifications are enabled.
  /// Can be overridden for testing by setting [pushNotificationOverride].
  static bool get enablePushNotification =>
      pushNotificationOverride ?? _enablePushNotificationDefault;

  /// Enable/disable face recognition feature.
  static const bool enableFaceRecognition = true;

  /// Enable/disable overtime feature.
  static const bool enableOvertime = true;

  /// Enable/disable reimbursement feature.
  static const bool enableReimbursement = true;

  /// Reset all overrides to default values.
  /// Call this in test tearDown.
  static void resetOverrides() {
    pushNotificationOverride = null;
  }
}
