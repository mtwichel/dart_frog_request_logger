/// A logging severity reported in Cloud Logging
enum Severity {
  /// The log entry has no assigned severity level.
  normal,

  /// Debug or trace information.
  debug,

  /// Routine information, such as ongoing status or performance.
  info,

  /// Normal but significant events, such as start up, shut down, or
  /// a configuration change.
  notice,

  /// Warning events might cause problems.
  warning,

  /// Error events are likely to cause problems.
  error,

  /// Critical events cause more severe problems or outages.
  critical,

  /// A person must take an action immediately.
  alert,

  /// One or more systems are unusable.
  emergency;

  @override
  String toString() {
    switch (this) {
      case Severity.normal:
        return 'DEFAULT';
      case Severity.debug:
        return 'DEBUG';
      case Severity.info:
        return 'INFO';
      case Severity.notice:
        return 'NOTICE';
      case Severity.warning:
        return 'WARNING';
      case Severity.error:
        return 'ERROR';
      case Severity.critical:
        return 'CRITICAL';
      case Severity.alert:
        return 'ALERT';
      case Severity.emergency:
        return 'EMERGENCY';
    }
  }
}
