import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static String normalizeToDigits(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static String ensureBrazilCountryCode(String digits) {
    if (digits.startsWith('55')) return digits;
    return '55$digits';
  }

  static Uri _nativeUri({
    required String phoneDigits,
    required String message,
  }) {
    final encoded = Uri.encodeComponent(message);
    return Uri.parse('whatsapp://send?phone=$phoneDigits&text=$encoded');
  }

  static Uri _webUri({
    required String phoneDigits,
    required String message,
  }) {
    final encoded = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$phoneDigits?text=$encoded');
  }

  static Future<void> openWhatsApp({
    required String phoneE164OrAny,
    required String message,
  }) async {
    final digits = ensureBrazilCountryCode(normalizeToDigits(phoneE164OrAny));

    final native = _nativeUri(phoneDigits: digits, message: message);
    final web = _webUri(phoneDigits: digits, message: message);

    // 1) tenta abrir pelo app (mais rápido e direto)
    final openedNative = await launchUrl(
      native,
      mode: LaunchMode.externalApplication,
    );

    if (openedNative) return;

    // 2) fallback web (muito mais compatível em Android 11+)
    final openedWeb = await launchUrl(
      web,
      mode: LaunchMode.externalApplication,
    );

    if (!openedWeb) {
      throw Exception('Não foi possível abrir o WhatsApp.');
    }
  }
}