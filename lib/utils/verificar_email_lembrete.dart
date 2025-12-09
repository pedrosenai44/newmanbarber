import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerificarEmailLembrete extends StatelessWidget {
  const VerificarEmailLembrete({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Se o usuário não existe ou já verificou, não mostra nada
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink(); 
    }

    // Widget do Lembrete
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      color: Colors.amber.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Seu email ainda não foi verificado.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await user.sendEmailVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link de verificação reenviado!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao reenviar: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Reenviar', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline, decorationColor: Colors.white)),
          )
        ],
      ),
    );
  }
}
