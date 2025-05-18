
//import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:journey_mate_app_v1/methods/common_connection_methods.dart';
import 'package:journey_mate_app_v1/screens/home/home_screen.dart';
import 'package:journey_mate_app_v1/widgets/loading_dialouge.dart';



class SignupPage extends StatefulWidget {
  const SignupPage ({super.key});

  @override
  State <SignupPage> createState() =>  SignupPageState();
}

class  SignupPageState extends State <SignupPage> {

  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userphoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  CommonMethods cMethods = CommonMethods();

  checkIfnetworkIsAvailable() async {

    cMethods.checkConnectivity(context);

    signupFormvalidation();

  }


  signupFormvalidation() {

    if (userNameController.text.trim().length < 3) {

      cMethods.displaySnackBar(context, 'Please enter a valid name, Your name should be minimum 4 caracters');

      return;
    }

    else if (emailController.text.contains('@') == false && emailController.text.contains('.com') == false) {
      
      cMethods.displaySnackBar(context, 'Please enter a valid email address');

      return;
    }

    else if (userphoneController.text.length <= 7) {

      cMethods.displaySnackBar(context, 'Please enter a valid phone number, Your phone number should be minimum 8 caracters');
      
      return;
    }

    else if (passwordController.text.length < 8) {
      
      cMethods.displaySnackBar(context, 'Please enter a valid password, Your password should be minimum 8 caracters');

      return;
    }

    else if (confirmPasswordController.text != passwordController.text) {

      cMethods.displaySnackBar(context, 'Password does not match');

      return;
    }

    else {

      //cMethods.displaySnackBar(context, 'Well done, Please wait');

      registerNewuser();

    }

  }

  registerNewuser() async {


    showDialog(

      context: context, 
      barrierDismissible: false, 
      builder: (BuildContext context) => LoadingDialouge(messageText: 'Please wait.Creating...')
      
    );

    //await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text.trim());

    final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(

      email: emailController.text.trim(), 
      password: passwordController.text.trim()
      
    );
    
    final User? userfirebase = userCredential.user;

    if (!context.mounted) {
      
      Navigator.pop(context); //closing loading dialouge

      return;
    }


    if (userfirebase != null) {

      //cMethods.displaySnackBar(context, 'Account created successfully!');
      
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users').child(userfirebase.uid);

      Map userDataMap = {

        'userName': userNameController.text.trim(),
        'userEmail': emailController.text.trim(),
        'userPhone': userphoneController.text.trim(),
        'userPassword': passwordController.text.trim(),
        'userId': userfirebase.uid,
        'blockStatus': false,
        'userProfilePic': '',
        'userCoverPic': '',
        'userBio': '',
        'userGender': '',
        'userCountry': '',
        'userState': '',
        'userCity': '',
        'userAddress': '',
        'userDateOfBirth': '',
        'userRole': 'passenger',
        'userDateOfJoin': DateTime.now().toString(),
        'userDateOfLastSeen': DateTime.now().toString()
        

      };

      //print('Database Reference Path: ${usersRef.path}');

      usersRef.set(userDataMap);

      //print('Successfully user Data Map: $userDataMap');

      cMethods.displaySnackBar(context, 'Account created successfully!');

      //pushing after registered to homepage

      Navigator.push(context, MaterialPageRoute (builder:(e) => const HomeScreen()));

    } else {

      cMethods.displaySnackBar(context, 'Something is wrong..!!!');

    }
      

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [

              const SizedBox(height: 110,),

              Image.asset('assets/images/1000521834.jpg',
                width: MediaQuery.of(context).size.width * .5,
              ),

              const SizedBox(height: 10,),

              const Text('Create an Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 60,),

              TextField(
                controller: userNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Enter your Full Name',
                  labelStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20,),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Enter your Email',
                  labelStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

              TextField(

                controller: userphoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Enter your Phone Number',
                  labelStyle: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),

              ),

              const SizedBox(height: 20,),

              TextField(
                controller: passwordController,
                obscureText: true,
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
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20,),

              TextField(
                controller: confirmPasswordController,
                obscureText:true ,
                decoration :const InputDecoration (
                  labelText : 'Confirm Password' ,
                  labelStyle :TextStyle (
                    color :Colors.blueAccent ,
                    fontSize :16 ,
                  ) ,
                  focusedBorder :OutlineInputBorder (

                    borderSide :BorderSide (color :Colors.blueAccent) ,

                  ) ,
                ) ,
              ),

              const SizedBox(height: 20,),

              ElevatedButton(onPressed: (){

                checkIfnetworkIsAvailable();
               
                // and navigate to the next screen upon success.

                // print('Sign Up button clicked');
                // print('Full Name: ${userNameController.text}');
                // print('Email: ${emailController.text}');
                // print('Phone Number: ${userphoneController.text}');
                // print('Password: ${passwordController.text}');
                // print('Confirm Password: ${confirmPasswordController.text}');
                // // You can also add validation for the input fields here

               },

               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color.fromARGB(255, 54, 63, 78),
                 padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(30),
                 ),
               ),
              
               child: const Text('Sign Up',
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                 ),
               ),

              ),

              const SizedBox(height: 20,),

              //const Text('By signing up, you agree to our'),
              //const Text('Terms of Service and Privacy Policy'),

              const Text('Already have an account?'),

              TextButton(onPressed: () {
                // Navigate to the Sign In page
                Navigator.pushReplacementNamed(context, '/signin');

              }, child: const Text('Sign In')),
              
              const SizedBox(height: 20,),

            ],
          ),
        ),
      ),
    );
  }
}