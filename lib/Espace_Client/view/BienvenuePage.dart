import 'package:flutter/material.dart';
import 'Login.dart';
import 'Registration.dart';
import 'dart:async';


class BienvenuePage extends StatefulWidget {
  @override
  _BienvenuePageState createState() => _BienvenuePageState();
}

class _BienvenuePageState extends State<BienvenuePage>{


  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false,child: Scaffold(
      backgroundColor: const Color.fromARGB(1000, 60, 70, 120),
      body: ListView(

        children: [

          Padding(padding: const EdgeInsets.only(top: 10,bottom: 20),child: Center(child: Container(
            width: 220,
            height: 220,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: Image.asset("assets/images/logo1.png",fit: BoxFit.cover,width: 150,) ,
            ),
          ),
          ),
          ),

          const Padding(padding: EdgeInsets.only(bottom: 100,right: 20,left: 20),child: Center(
            child: Text(textAlign: TextAlign.center,style:TextStyle(letterSpacing: 1.5,color: Colors.white),'Planifiez vos rendez-vous médicaux rapidement et sans tracas grâce à notre interface conviviale, evitant ainsi les appels téléphoniques et les attentes en personne.'),
          ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: (){

                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login()));
                },
                child:  Container(
                  width: MediaQuery.of(context).size.width/2.3,
                  height: 60,

                  child: const Card(

                    color:  Color.fromARGB(990, 238, 80, 103),
                    elevation: 0,
                    child: Center(
                      child: Text('Se connecter',textAlign: TextAlign.center,style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ),
              ),


              GestureDetector(
                onTap: (){

                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Registration()));

                },
                child:  Container(
                  width: MediaQuery.of(context).size.width/2.3,
                  height: 60,
                  decoration: BoxDecoration(

                    borderRadius: BorderRadius.circular(15),


                  ),
                  child: const Card(

                    child: Center(
                      child: Text('S\'inscrire',textAlign: TextAlign.center,style: TextStyle(color:  Color.fromARGB(990, 238, 80, 103)),),
                    ),
                  ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 250,),
        ],
      ),
    ),);
  }
}
