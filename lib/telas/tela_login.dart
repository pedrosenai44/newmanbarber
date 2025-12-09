import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:newmanbarber/telas/tela_principal.dart';
import 'package:newmanbarber/telas/admin/tela_principal_admin.dart';
import 'package:newmanbarber/telas/barbeiro/tela_principal_barbeiro.dart';
import 'package:newmanbarber/telas/tela_cadastro.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  Future<void> _entrar() async {
    setState(() => _carregando = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (!mounted || userCredential.user == null) return;
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      final userData = userDoc.data();
      final String role = userData?['role'] ?? 'client';

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomePage()));
        return;
      }
      
      if (role == 'barber') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BarberHomePage()));
      } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
      }

    } on FirebaseAuthException catch (e) {
      String mensagem = (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential')
        ? 'Email ou senha incorretos.'
        : 'Ocorreu um erro. Tente novamente.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _resetarSenha() async {
    final emailParaReset = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redefinir Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu email e enviaremos um link para você criar uma nova senha.'),
            const SizedBox(height: 16),
            TextField(controller: emailParaReset, decoration: const InputDecoration(labelText: 'Email de cadastro', prefixIcon: Icon(Icons.email_outlined))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (emailParaReset.text.isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailParaReset.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link enviado! Verifique sua caixa de entrada.'), backgroundColor: Colors.green));
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Usuário não encontrado.'), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.white],
            stops: const [0.4, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const CircleAvatar(radius: 40, backgroundColor: Colors.black, child: Icon(Icons.content_cut, size: 40, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('NewManBarber', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                const SizedBox(height: 48),
                TextField(controller: _emailController, decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: 'seu@email.com', labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                TextField(controller: _senhaController, decoration: InputDecoration(filled: true, fillColor: Colors.white, hintText: '*******', labelText: 'Senha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), obscureText: true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _carregando ? null : _entrar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: _carregando ? const CircularProgressIndicator() : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.black87)),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _resetarSenha, child: const Text('Esqueceu a senha?', style: TextStyle(color: Colors.black54))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                      child: const Text('Cadastre-se', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
