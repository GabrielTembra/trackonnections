import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackonnections/telaBase.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaReconhecimento.dart';
import 'package:trackonnections/telaSpotify.dart';
import 'firebase_options.dart'; // Importe as credenciais geradas pela FlutterFire CLI
import 'telaLogin.dart'; // Certifique-se de que o caminho da telaLogin.dart está correto

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/telabase': (context) => HomeScreen(),
        '/spotify':(context) => SpotifyAuthScreen(), 
        '/mapa':(context) => MusicMapScreen(),
        'gravacao':(context) => AudioRecorder(onStop: (String path) {},),// Defina sua tela de login aqui
        // Adicione outras rotas aqui conforme necessário
      },
    );
  }
}
