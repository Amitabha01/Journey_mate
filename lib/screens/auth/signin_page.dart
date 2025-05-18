import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:journey_mate_app_v1/global/global_var.dart';
import 'package:journey_mate_app_v1/methods/common_connection_methods.dart';
import 'package:journey_mate_app_v1/screens/home/home_screen.dart';
import 'package:journey_mate_app_v1/widgets/loading_dialouge.dart';



class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {

       TextEditingController emailController = TextEditingController();
       TextEditingController passwordController = TextEditingController();

       CommonMethods cMethods = CommonMethods();

       checkIfnetworkIsAvailable() async {
        
          cMethods.checkConnectivity(context);

          signinFormvalidation();

       }

       signinFormvalidation() {

          if (!emailController.text.contains('@') && !emailController.text.contains('.com')) {
            
             cMethods.displaySnackBar(context, 'Please enter a valid email address');

             return;
          }

          else if (passwordController.text.length < 8) {
            
             cMethods.displaySnackBar(context, 'Please enter a valid password, Your password should be minimum 8 caracters');

             return;
          }

          else {
            
             //cMethods.displaySnackBar(context, 'Logging in...');

             signinUser();

          }
       }

        signinUser() async{
  
            showDialog(

              context: context,
              barrierDismissible: false,
              builder: (context) => const LoadingDialouge(messageText: 'Logging in...'),
              

            );


            final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
              
              email: emailController.text.trim(),
              password: passwordController.text.trim(),

            );

            final User? user = userCredential.user;

            if (!context.mounted) {
      
              Navigator.pop(context); //closing loading dialouge
      
              return;
            }

            if (user != null) {

              DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users').child(user.uid);

              final DataSnapshot snapshot = await usersRef.get();

                
                if (snapshot.exists) {
                  
                  // User data exists, you can access it here
                  Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
                  
                  

                  bool isBlocked = userData['blockStatus'] ?? true; // Default to true if null


                  if (!isBlocked) {

                    userFullName = userData['userName'];
                    var data = userData['userEmail'];
                    var phone = userData['userPhone'];
                    print(data);
                    print(phone);
                    print(userFullName);

                    Navigator.pop(context); //close loading dialouge

                    Navigator.push(context, MaterialPageRoute (builder:(e) => const HomeScreen()));

                    print('User is not blocked, proceed with login');
                    
                  } else {
                    
                    // User is blocked, sign out and show message
                    FirebaseAuth.instance.signOut();

                    Navigator.pop(context); //closing loading dialouge
                    
                    cMethods.displaySnackBar(context, 'Your account has been blocked. Please contact support.');
                    
                    return;
                    
                  }

                } else {

                  FirebaseAuth.instance.signOut();
                  
                  // User data does not exist
                  print('No user data found for this user.');

                  cMethods.displaySnackBar(context, 'User does not exists, Register First.');
                  
                }

              
              // User is logged in successfully
              cMethods.displaySnackBar(context, 'Login successful');
              
             
            } else {
              
              // Login failed
              cMethods.displaySnackBar(context, 'Login failed. Please try again.');
            }
  
            // Perform login action here
  
            // After successful login, navigate to home page
            Navigator.pushNamed(context, '/homepage');
        }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 

      body: 
       SingleChildScrollView(
              
              child: Padding(padding: const EdgeInsets.all(30),
              
                     child: Column(children: [

                            const SizedBox(height: 110,),

                            Image.asset('assets/images/1000521837.png', 
                            
                              width: MediaQuery.of(context).size.width * .5,

                            ),

                            const SizedBox(height: 10,),

                            const Text('Login to your Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 50,),
                            

                            TextField(

                                   controller: emailController,

                                   keyboardType: TextInputType.emailAddress,

                                   decoration: const InputDecoration(

                                          labelText: ' Enter your Email',

                                          labelStyle: TextStyle(

                                                 color: Colors.blueAccent,

                                                 fontSize: 16,

                                          ),
                                          focusedBorder: OutlineInputBorder(

                                                 borderSide: BorderSide(color: Colors.blueAccent),

                                          ),

                     

                                   ),
                                   style: const TextStyle(

                                          color: Color.fromARGB(255, 8, 202, 34),

                                          fontSize: 16,

                                   ),
                            ),

                            const SizedBox(height: 20,),
                            
                            TextField(

                                   controller: passwordController,

                                   obscureText: true,

                                   keyboardType: TextInputType.visiblePassword,

                                   decoration: const InputDecoration(

                                          labelText: 'Enter your Password',

                                          labelStyle: TextStyle(

                                                 color: Colors.blueAccent,

                                                 fontSize: 16,

                                          ),
                                          focusedBorder: OutlineInputBorder(

                                                 borderSide: BorderSide(color: Colors.blueAccent),

                                          ),

                     

                                   ),
                                   style: const TextStyle(

                                          color: Color.fromARGB(255, 8, 202, 34),

                                          fontSize: 16,

                                   ),
                            ),

                            const SizedBox(height: 25,),

                            ElevatedButton(

                                   onPressed: (){

                                          // Perform sign in action

                                          checkIfnetworkIsAvailable();

                                          print('Sign in button clicked');
                                          //print('Email: ${emailController.text}');

                                          //print('Password: ${passwordController.text}');

                                   },

                                   style: ElevatedButton.styleFrom(

                                          backgroundColor: const Color.fromARGB(255, 67, 192, 165),

                                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),

                                   ),

                                   child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                                 color: Colors.white,
                                                 fontSize: 16,
                                          ),
                                   ),

                            ),

                            const SizedBox(height: 14,),

                            const Text("Don't have an account?", style: TextStyle(color: Color.fromARGB(255, 42, 101, 204), fontSize: 16, )),

                            TextButton(onPressed: (){

                                   // Navigate to sign up page

                                   Navigator.pushNamed(context, '/signup');
                                   

                            }, child: const Text(" SignUp ", style: TextStyle(color: Color.fromARGB(255, 0, 55, 151), fontSize: 16, ),)),

                            const SizedBox(height: 14,),

                     ],)
              
              )

       ),

    );
  }
}