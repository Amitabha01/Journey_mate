//import 'dart:math';

import 'package:flutter/material.dart';


class LoadingDialouge extends StatelessWidget {

  final String messageText;

   const LoadingDialouge({super.key, required this.messageText});


  @override
  Widget build(BuildContext context) {

    return Dialog(

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      backgroundColor: Colors.black54,

      child: Container(

        margin: const EdgeInsets.all(14),
        width: double.infinity,

        decoration: BoxDecoration(

          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),

        ),

        child: Padding(padding: EdgeInsets.all(15),

          child: Row(children: [

            const SizedBox(width: 6,),
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation <Color>(Colors.white),),
            const SizedBox(width: 9,),

            Text(messageText,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: "Brand-Bold",
              ),
              
            ),
            
          ],)

        )
      ),

    );
      
      

  }
}