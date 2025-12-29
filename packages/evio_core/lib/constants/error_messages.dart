// Mensajes de error centralizados

abstract class ErrorMessages {
  // Auth
  static const String invalidCredentials = 'Email o contraseña incorrectos';
  static const String emailAlreadyInUse = 'Este email ya está registrado';
  static const String userNotFound = 'Usuario no encontrado';
  static const String sessionExpired = 'Tu sesión expiró';

  // Validación
  static const String requiredField = 'Este campo es requerido';
  static const String invalidEmail = 'El email no es válido';
  static const String invalidDni = 'El DNI no es válido';
  static const String passwordTooShort = 'Mínimo 8 caracteres';

  // Tickets
  static const String ticketNotFound = 'Ticket no encontrado';
  static const String ticketAlreadyUsed = 'Este ticket ya fue utilizado';
  static const String ticketExpired = 'Este ticket expiró';
  static const String invalidQrCode = 'Código QR inválido';

  // Compras
  static const String paymentFailed = 'El pago falló';
  static const String insufficientStock = 'No hay stock disponible';
  static const String maxTicketsExceeded = 'Superaste el máximo de tickets';

  // Red
  static const String noInternet = 'Sin conexión a internet';
  static const String serverError = 'Error del servidor';
  static const String timeout = 'La operación tardó demasiado';
}

abstract class SuccessMessages {
  static const String loginSuccess = '¡Bienvenido!';
  static const String ticketPurchased = '¡Compra exitosa!';
  static const String ticketValidated = '✓ Entrada válida';
}
