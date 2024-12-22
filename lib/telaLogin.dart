import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'telaBase.dart'; // Certifique-se de que a tela base está implementada corretamente
import 'telaPerfil.dart'; // Tela de personalização de perfil

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Método para salvar login e senha no Firestore
  Future<void> saveLoginToFirestore(String email, String password) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').add({
        'email': email,
        'password': password,
        'timestamp': FieldValue.serverTimestamp(), // Adiciona um timestamp
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para salvar login e senha no SharedPreferences
  Future<void> saveLoginToSharedPreferences(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);  // Salva o email
    await prefs.setString('password', password);  // Salva a senha
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A), // Fundo roxo alterado
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A), // Cor da appBar alterada
        elevation: 0,
        automaticallyImplyLeading: false, // Removendo o ícone de volta
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Deseja personalizar seu perfil?'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Personalizar',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomizeProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TrackConnections',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  'Bem-vindo ao TrackConnections',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conecte-se e descubra músicas ao seu redor!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu Email',
                      hintStyle: TextStyle(color: Color(0xFF6A1B9A)), // Cor do hintText alterada
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.mail, color: Color(0xFF6A1B9A)), // Cor do ícone alterada
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua Senha',
                      hintStyle: TextStyle(color: Color(0xFF6A1B9A)), // Cor do hintText alterada
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF6A1B9A)), // Cor do ícone alterada
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isNotEmpty && password.isNotEmpty) {
                      // Salva login e senha no Firestore
                      await saveLoginToFirestore(email, password);

                      // Salva login e senha no SharedPreferences
                      await saveLoginToSharedPreferences(email, password);

                      // Navega para a tela principal
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, preencha todos os campos.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A1B9A), // Cor do botão alterada
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    print('Botão Esqueceu a Senha pressionado');
                  },
                  child: const Text(
                    'Esqueceu a senha?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
