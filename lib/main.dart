import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackonnections/telaBase.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaSpotify.dart';
import 'package:trackonnections/telaReconhecimento.dart';
import 'package:trackonnections/telaLogin.dart'; // Certifique-se de que o caminho da telaLogin.dart está correto
import 'package:provider/provider.dart'; // Para o Provider
import 'package:trackonnections/profile_provider.dart'; // Importe o seu ProfileProvider
import 'package:trackonnections/telaRecorder.dart'; // Importe o RecorderState
import 'firebase_options.dart'; // Importe as credenciais geradas pela FlutterFire CLI
import 'package:trackonnections/telaRecorder.dart'; // Importando a tela de gravação de áudio, se necessário

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()), // Provider para gerenciar o estado do perfil
        ChangeNotifierProvider(create: (_) => RecorderState()), // Provider para gerenciar o estado do gravador
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TrackConnections',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/login', // Defina a rota inicial
        routes: {
          '/login': (context) => const LoginScreen(),
          '/telabase': (context) => const HomeScreen(),
          '/spotify': (context) => const SpotifyAuthScreen(), 
          '/mapa': (context) => const MusicMapScreen(),
          '/gravacao': (context) => AudioRecorder(onStop: (String path) {}),
        },
      ),
    );
  }
}
