// Constantes globales de Evio Club

abstract class AppConstants {
  // App
  static const String appName = 'Evio Club';

  // Límites
  static const int maxTicketsPerUser = 10;
  static const int maxTransfersPerTicket = 3;
  static const int minPasswordLength = 8;
  static const int dniLength = 8;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration paymentTimeout = Duration(seconds: 30);

  // Paginación
  static const int defaultPageSize = 20;

  // Moneda
  static const String defaultCurrency = 'ARS';

  // Storage keys
  static const String authTokenKey = 'evio_auth_token';
  static const String onboardingCompleteKey = 'evio_onboarding_complete';
}

abstract class ValidationPatterns {
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp dniArgentina = RegExp(r'^\d{7,8}$');

  static final RegExp phoneArgentina = RegExp(
    r'^(\+54|0)?[\s-]?(9)?[\s-]?(\d{2,4})[\s-]?(\d{4})[\s-]?(\d{4})$',
  );
}
