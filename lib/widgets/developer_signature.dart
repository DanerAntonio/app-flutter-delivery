import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperSignature extends StatelessWidget {
  const DeveloperSignature({super.key});

  // 📧 Abrir correo
  void _openEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'danerantonio@gmail.com',
      query: 'subject=Consulta%20sobre%20tu%20app%20Flutter',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  // 💬 Abrir WhatsApp
  void _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/573112762618?text=Hola%20Daner,%20vi%20tu%20app%20y%20me%20gustaría%20contactarte');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

   

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(thickness: 1.2),
          const SizedBox(height: 8),
          Text(
            '👨‍💻 DANER ANTONIO MOSQUERA BEDOYA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TECNÓLOGO EN ANÁLISIS Y DESARROLLO DE SOFTWARE',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            'INSTITUCIÓN: SENA',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            '📧 danerantonio@gmail.com',
            style: TextStyle(color: Colors.blueGrey),
          ),
          Text(
            '📱 311 276 2618',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _openEmail,
                icon: const Icon(Icons.email, size: 18),
                label: const Text('Correo'),
              ),
              ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
