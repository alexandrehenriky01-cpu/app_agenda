class WhatsAppMessages {
  static String confirm({
    required String clientName,
    required String dateTime,
    required String services,
    required int duration,
    required double total,
    String studioName = 'Studio Pro',
  }) {
    return 'Olá $clientName 👋\n\n'
        'Seu agendamento está *confirmado* ✅\n'
        '📅 $dateTime\n'
        '💄 $services\n'
        '⏱ $duration min\n'
        '💰 R\$ ${total.toStringAsFixed(2)}\n\n'
        'Qualquer dúvida é só responder esta mensagem.\n'
        '$studioName 💖';
  }

  static String reminder({
    required String clientName,
    required String dateTime,
    required String services,
    String studioName = 'Studio Pro',
  }) {
    return 'Olá $clientName 😊\n\n'
        'Passando para lembrar do seu agendamento ⏰\n'
        '📅 $dateTime\n'
        '💄 $services\n\n'
        'Se precisar reagendar, é só me avisar.\n'
        '$studioName 💖';
  }

  static String cancel({
    required String clientName,
    required String dateTime,
    String? reason,
    String studioName = 'Studio Pro',
  }) {
    final reasonText = (reason == null || reason.trim().isEmpty)
        ? ''
        : '\n📝 Motivo: $reason';

    return 'Olá $clientName 👋\n\n'
        'Seu agendamento foi *cancelado* ❌\n'
        '📅 $dateTime'
        '$reasonText\n\n'
        'Se quiser, posso te ajudar a remarcar em outro horário.\n'
        '$studioName 💖';
  }
}