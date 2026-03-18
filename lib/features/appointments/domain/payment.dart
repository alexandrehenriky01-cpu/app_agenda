enum PaymentMethod {
  pix,
  cash,
  creditCard,
  debitCard,
  transfer,
  other,
}

enum PaymentStatus {
  pending,
  paid,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.pix:
        return 'PIX';
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.creditCard:
        return 'Cartão de crédito';
      case PaymentMethod.debitCard:
        return 'Cartão de débito';
      case PaymentMethod.transfer:
        return 'Transferência';
      case PaymentMethod.other:
        return 'Outro';
    }
  }
}