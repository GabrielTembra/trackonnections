import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importe as credenciais geradas pela FlutterFire CLI
import 'telaLogin.dart';
import 'package:trackonnections/telaSpotify.dart';

void main() async {
  // Garantir que os widgets estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Inicialização correta com as opções do Firebase
  );
  
  // Iniciar o app
  runApp(const TrackConnectionsApp());
}

class TrackConnectionsApp extends StatelessWidget {
  const TrackConnectionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackConnections',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',  // Rota inicial para login
      routes: {
        '/login': (context) => const LoginScreen(),  // Defina sua tela de login aqui
        '/#/spotify': (context) => const SpotifyAuthScreen(), // Rota para autenticação com Spotify
        // Adicione outras rotas aqui conforme necessário
      },
    );
  }
}
