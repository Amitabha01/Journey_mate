import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:journey_mate_app_v1/screens/auth/signin_page.dart';
import 'package:journey_mate_app_v1/screens/auth/signup_page.dart';
import 'package:journey_mate_app_v1/screens/home/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'firebase_options.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file

    await dotenv.load(fileName: ".env");

    
    await Firebase.initializeApp(

      options: DefaultFirebaseOptions.currentPlatform,
    
    );


  await setup();  //?!??

  runApp(const MainApp());
}

Future<void> setup() async {

 final token = dotenv.env["MAPBOX_ACCESS_TOKEN_KEY"];
  print("Mapbox Access Token Is Here: $token"); // Debug print

  if (token == null || token.isEmpty) {
    throw Exception("Mapbox Access Token is missing or invalid.");
  }

  MapboxOptions.setAccessToken(token);

}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journey mate',
      
      home: const HomeScreen(),
        //SigninPage(),
      
        initialRoute: '/homescreen',
          routes: {
          '/signin': (context) => const SigninPage(),
          '/signup': (context) => const SignupPage(),
          '/homescreen': (context) => const HomeScreen(),
          // Add other routes here
          }, 
          
    );
  }
}