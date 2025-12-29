class OrderException implements Exception {
  final String message;
  final String? code;

  OrderException(this.message, {this.code});

  @override
  String toString() => message;

  // Factory constructors para errores comunes
  factory OrderException.soldOut(String ticketName, int available) {
    return OrderException(
      'El ticket "$ticketName" está agotado. Solo quedan $available disponibles.',
      code: 'SOLD_OUT',
    );
  }

  factory OrderException.maxExceeded(String ticketName, int max) {
    return OrderException(
      'Máximo $max tickets de "$ticketName" por compra.',
      code: 'MAX_EXCEEDED',
    );
  }

  factory OrderException.unauthorized() {
    return OrderException(
      'Debes estar autenticado para comprar tickets.',
      code: 'UNAUTHORIZED',
    );
  }

  factory OrderException.serverError(String details) {
    return OrderException(
      'Error creando orden: $details',
      code: 'SERVER_ERROR',
    );
  }
}
