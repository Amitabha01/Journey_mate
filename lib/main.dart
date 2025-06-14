import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:journey_mate_app_v1/models/ride_model.dart';
import 'package:journey_mate_app_v1/screens/auth/signin_page.dart';
import 'package:journey_mate_app_v1/screens/auth/signup_page.dart';
import 'package:journey_mate_app_v1/screens/home/home_screen.dart';
import 'package:journey_mate_app_v1/screens/rides/create_ride_screen.dart';
import 'package:journey_mate_app_v1/screens/rides/ride_details_screen.dart';
import 'package:journey_mate_app_v1/screens/profile/profile_screen.dart';
import 'package:journey_mate_app_v1/screens/rides/confirm_booking_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journey_mate_app_v1/screens/wrapper.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:journey_mate_app_v1/screens/rides/your_rides_screen.dart';
import 'firebase_options.dart';
import 'package:journey_mate_app_v1/screens/chat/inbox_screen.dart';
import '../../screens/admin/rides/chat_screen.dart' as AdminChat;


void main() async{

  WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file

    await dotenv.load(fileName: ".env");

    
    await Firebase.initializeApp(

      options: DefaultFirebaseOptions.currentPlatform,
    
    );


  await setup();  //?!??

  final User? currentUser = FirebaseAuth.instance.currentUser;


  runApp(MainApp(initialRoute: currentUser == null ? '/signin' : '/homescreen'));
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
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      home: const Wrapper(),  // Useing the Wrapper widget as the home
      
        //initialRoute: '/signin',
          routes: {
          '/signin': (context) => const SigninPage(),
          '/signup': (context) => const SignupPage(),
          '/homescreen': (context) => const HomeScreen(),
          '/createride': (context) => const CreateRideScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/ridedetails': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return RideDetailsScreen(ride: args['ride']);
          },

          '/confirmBooking': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ConfirmBookingScreen(
              ride: args['ride'],
              currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
            );
          },

          '/yourrides': (context) => YourRidesScreen(), // Pass actual rides dynamically

          
          '/inbox': (context) => const InboxScreen(), 
          '/chatscreen': (context) {
            final rideId = ModalRoute.of(context)!.settings.arguments as String;
            return AdminChat.ChatScreen(rideId: rideId);
          },
          // Add other routes here
          }, 

          onGenerateRoute: (settings) {
          if (settings.name == '/ridedetails') {
            final ride = settings.arguments as RideModel;
            return MaterialPageRoute(
            builder: (context) => RideDetailsScreen(ride: ride),
          );
        }
        return null;
      },
          
    );
  }
}