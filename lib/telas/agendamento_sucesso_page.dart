import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/tela_principal.dart'; // Importação correta da Home

class AgendamentoSucessoPage extends StatefulWidget {
  const AgendamentoSucessoPage({super.key});

  @override
  State<AgendamentoSucessoPage> createState() => _PaginaSucessoAgendamentoState();
}

class _PaginaSucessoAgendamentoState extends State<AgendamentoSucessoPage> with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacaoEscala;

  @override
  void initState() {
    super.initState();
    // animacao config
    _controlador = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // efeito
    _animacaoEscala = CurvedAnimation(
      parent: _controlador,
      curve: Curves.elasticOut,
    );

    // animaçao
    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cores
    const Color corFundo = Color(0xFF1E1E2C); // azul escuro
    const Color corSucesso = Color(0xFF4CAF50); // verde

    return Scaffold(
      backgroundColor: corFundo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // card branco
              Container(
                margin: const EdgeInsets.only(top: 50), // espaco topo
                padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // tamanho
                  children: [
                    const Text(
                      'SUCESSO!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Seu agendamento foi confirmado.\nEstamos esperando por você!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // voltar ao inicio
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // para a principal
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corSucesso,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'VOLTAR AO INÍCIO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. icone com animacao
              Positioned(
                top: 0,
                child: ScaleTransition(
                  scale: _animacaoEscala,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: corSucesso,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4), // bordinha branca
                      boxShadow: [
                        BoxShadow(
                          color: corSucesso.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
