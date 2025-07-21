import 'package:intl/intl.dart';

/// Formats a DateTime object to a string with both date and time in the local timezone.
///
/// @param dateTime The DateTime object to format (typically in UTC)
/// @param format Optional DateFormat to use for formatting
/// @return A formatted string representing the date and time in local time
String formatDateTime(DateTime dateTime, {DateFormat? format}) {
  final localDateTime = dateTime.toLocal();
  return (format ?? DateFormat.yMMMMd().add_Hm()).format(localDateTime);
}

/// Formats just the date part of a DateTime object in the local timezone.
/// 
/// @param dateTime The DateTime object to format (typically in UTC)
/// @param format Optional DateFormat to use for formatting
/// @return A formatted string representing just the date in local time
String formatDate(DateTime dateTime, {DateFormat? format}) {
  final localDateTime = dateTime.toLocal();
  return (format ?? DateFormat.yMMMd()).format(localDateTime);
}

/// Formats just the time part of a DateTime object in the local timezone.
/// 
/// @param dateTime The DateTime object to format (typically in UTC)
/// @param format Optional DateFormat to use for formatting
/// @return A formatted string representing just the time in local time
String formatTime(DateTime dateTime, {DateFormat? format}) {
  final localDateTime = dateTime.toLocal();
  return (format ?? DateFormat.Hm()).format(localDateTime);
}
