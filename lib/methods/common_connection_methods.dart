import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CommonMethods {

  checkConnectivity(BuildContext context) async {
    
    var connectionResult = await (Connectivity().checkConnectivity());
    print('Connection Result: $connectionResult');
    
    if (connectionResult.contains( ConnectivityResult.none)) {

      print('No valid internet connection detected.');

      if (!context.mounted) return;

      displaySnackBar(context, 'Kindly check your internet connection, Internet is not available');
      return;

    } else {

      print('Internet connection is available.');
      
    }

  }

  displaySnackBar(BuildContext context, String message) {
    print('Displaying SnackBar: $message');
    var snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
}