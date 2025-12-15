import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  Future<void> _cadastrar() async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos.')));
      return;
    }

    setState(() => _carregando = true);

    try {
      String role = 'client'; 

      final emailNormalizado = _emailController.text.trim().toLowerCase();

      final queryBarbeiro = await FirebaseFirestore.instance
          .collection('barbeiros')
          .where('email', isEqualTo: emailNormalizado)
          .limit(1)
          .get();

      if (queryBarbeiro.docs.isNotEmpty) {
        role = 'barber';
      }

      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailNormalizado,
        password: _senhaController.text.trim(),
      );

      if (credencial.user != null && !credencial.user!.emailVerified) {
        await credencial.user!.sendEmailVerification();
      }

      await credencial.user?.updateDisplayName(_nomeController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(credencial.user!.uid).set({
        'name': _nomeController.text.trim(),
        'email': emailNormalizado,
        'createdAt': FieldValue.serverTimestamp(),
        'role': role, 
      });

      if (mounted) {
        await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Cadastro Realizado!'),
                  content: Text(
                    role == 'barber'
                      ? 'Bem-vindo, Barbeiro! Sua conta profissional foi ativada. Verifique seu email antes de logar.'
                      : 'Enviamos um link de verificação para o seu email. Por favor, confirme para poder fazer o login.'
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ok')),
                  ],
                ));
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Ocorreu um erro no cadastro.';
      if (e.code == 'weak-password') {
        mensagem = 'A senha é muito fraca (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        mensagem = 'Este email já está em uso por outra conta.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'O email digitado não é válido.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.redAccent));
      }
    }

    if (mounted) {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.black87)),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.white],
            stops: const [0.2, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Criar Conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                const SizedBox(height: 48),
                TextField(controller: _nomeController, decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: 'Nome Completo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 16),
                TextField(controller: _emailController, decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: 'Email Válido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                TextField(controller: _senhaController, decoration: InputDecoration(filled: true, fillColor: Colors.white, labelText: 'Senha (mínimo 6 caracteres)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), obscureText: true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _carregando ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: _carregando ? const CircularProgressIndicator() : const Text('Cadastrar', style: TextStyle(fontSize: 18, color: Colors.black87)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
