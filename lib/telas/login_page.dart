import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newmanbarber/telas/home_page.dart';
import 'package:newmanbarber/telas/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to capture user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If successful, navigate to HomePage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle login errors
      String message;
      if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido.';
      } else if (e.code == 'invalid-credential') {
        message = 'Credenciais inválidas. Verifique seu email e senha.';
      } else {
        message = 'Erro ao fazer login. Tente novamente.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocorreu um erro inesperado.'), backgroundColor: Colors.redAccent),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
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
            colors: [
              Colors.blue.shade300,
              Colors.white,
            ],
            stops: const [0.4, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Placeholder for Logo
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.content_cut, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'NewManBarber',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'seu@email.com',
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '*******',
                    labelText: 'Senha',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
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
