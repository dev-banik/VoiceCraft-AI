import 'package:logger/logger.dart';

/// App-wide logger instance. Wrapped so the concrete logging package can be
/// swapped (e.g. for Crashlytics reporting) without touching call sites.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
