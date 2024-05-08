import 'package:abondon_vehicle/Mongodb/MongoProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:abondon_vehicle/Helpers/NavBar.dart';

void main() async{

  // Connect to MongoDB
  await MongoProvider().connectToMongo();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MongoProvider(),
      child: MaterialApp(
        title: 'Abondoned Vehicle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        ),
        home: const NavBar(idx: 0,)
      ),
    );
  }

}
