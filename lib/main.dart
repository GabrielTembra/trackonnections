import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackonnections/telaBase.dart';
import 'package:trackonnections/telaMapa.dart';
import 'package:trackonnections/telaSpotify.dart';
import 'package:trackonnections/telaReconhecimento.dart';
import 'package:trackonnections/telaLogin.dart';
import 'package:provider/provider.dart'; // Para o Provider
import 'package:trackonnections/profile_provider.dart'; // Importe o seu ProfileProvider
import 'package:trackonnections/telaRecorder.dart'; // Importe o RecorderState
import 'firebase_options.dart'; // Importe as credenciais geradas pela FlutterFire CLI
import 'package:shared_preferences/shared_preferences.dart'; // Para SharedPreferences

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
        home: FutureBuilder<String>(
          future: _getInitialRoute(), // Chama a função assíncrona que retorna a tela inicial
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator()); // Aguarda a resposta
            } else if (snapshot.hasData) {
              return Navigator(
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case '/login':
                      return MaterialPageRoute(builder: (_) => const LoginScreen());
                    case '/telabase':
                      return MaterialPageRoute(builder: (_) => const HomeScreen());
                    case '/spotify':
                      return MaterialPageRoute(builder: (_) => const SpotifyAuthScreen());
                    case '/mapa':
                      return MaterialPageRoute(builder: (_) => const MusicMapScreen());
                    case '/gravacao':
                      return MaterialPageRoute(builder: (_) => AudioRecorder(onStop: (String path) {}));
                    default:
                      return null;
                  }
                },
                initialRoute: snapshot.data, // Define a rota inicial com base no snapshot
              );
            } else {
              return const Center(child: Text('Erro ao verificar o login'));
            }
          },
        ),
      ),
    );
  }

  // Função para verificar se o login está salvo nos SharedPreferences
  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    if (email != null && password != null) {
      return '/telabase'; // Redireciona para a tela principal se o login estiver salvo
    } else {
      return '/login'; // Redireciona para a tela de login se não houver login salvo
    }
  }
}
