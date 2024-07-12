import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

final logging = Logger('swifty_companion');

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 61, 94, 150)),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class UserInfo extends StatefulWidget {
  UserInfo({super.key, required this.user});

  String user;

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  String login = "";
  String email = "";
  String phone = "";
  String wallets = ""; 
  String pp = "";
  List cursus_users = [];
  List<Map<String, dynamic>> structuredSkills = [];
  List<Map<String, dynamic>> structuredPU = [];
  bool userExists = false;

  dynamic getU(String user) async{
    final result = ApiService().getUser('users/$user');
    return (result);
  }

  dynamic getPU(String user) async{
    final result = ApiService().getProjectsUser(user);
    return (result);
  }

  Future<List<Map<String, dynamic>>> fetchUserDataAndSkills() async {
    try {
      dynamic result = await getU(widget.user);
      late Map jsonResult;
      if (result != 1) {
        userExists = true;
        jsonResult = jsonDecode(result);
        login = widget.user;
        jsonResult.forEach((key, value) {
          if (key == 'email') {
            email = value.toString();
          }
          if (key == 'wallet') {
            wallets = value.toString();
          }
          if (key == 'phone') {
            phone = value.toString();
          }
          if (key == "image") {
            pp = value['link'].toString();
          }
          if (key == "cursus_users") {
            value.forEach((cu) {
              String cuId = cu['cursus']['slug'];
              Map cuName = {};
              cuName['cursus_name'] = cuId;
              cursus_users.add(cuName);
              cursus_users.add(cu['skills']);
            });
          }
        });
        for (int i = 0; i < cursus_users.length; i += 2) {
        String cursusName = cursus_users[i]['cursus_name'];
          List<dynamic> skills = cursus_users[i + 1];
          structuredSkills.add({
            'cursus_name': cursusName,
            'skills': skills,
          });
        }
      }
    } catch(e) {
      logging.info('Exception caught: $e');
    }
    return structuredSkills;
  }

  Future<List<Map<String, dynamic>>> fetchProjectsUser() async {

      try {
        dynamic res = await getPU(widget.user);
        if (res != 1) {
          List jsonResult = json.decode(res);
          for (var item in jsonResult) {
            if (item['final_mark'].toString() == "null") {
              structuredPU.add({
                item['project']['name']: "in progress"
              });
            }
            else {
              structuredPU.add({
                item['project']['name']: item['final_mark'].toString()
              });
            }
          }
        }
      }
      catch(e) {
        logging.info('Exception caught: $e');
      }
      logging.info(structuredPU);
      return structuredPU;
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchAllData() async {
    final results = await Future.wait([fetchUserDataAndSkills(), fetchProjectsUser()]);

    return {
      'skills': results[0],
      'projects_user': results[1],
    };
  }

  Column printUserInfo() {
    if (userExists){
      return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image(
            fit: BoxFit.fitHeight,
            height: 150,
            width: 150,
            image: NetworkImage(pp),
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 11, top: 10),
            child: Text(
            "login: $login\nemail: $email\nphone number: $phone\nwallets: $wallets",
            style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        ExpansionTile(
          title: const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold),),
            children: [
            ...structuredSkills.map<Widget>((item) {
            return Padding(
              padding: const EdgeInsets.only(left: 25,),
              child: ExpansionTile(
              title: Text(item['cursus_name']),
              children: item['skills'].map<Widget>((skill) {
                return Padding(
                  padding: const EdgeInsets.only(left: 45,),
                  child:ListTile(
                  title: Text(skill['name']),
                  subtitle: Text('Level: ${skill['level']}'),
                ));
              }).toList(),
              )
            );
            })
       ]),
       ExpansionTile(
            title: const Text("Projects", style: TextStyle(fontWeight: FontWeight.bold),),
            children: structuredPU.map<Widget>((item) {
              return ListTile(
                title: Text(item.keys.first),
                subtitle: Text('${item.values.first}'),
              );
            }).toList(),
          ),
       ]);
    }
    else {
       return const Column(
      children: [
        Text(
        "User not found"
      )
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    var vue = Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>> (
        future: fetchAllData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('User not found'));
          } 
          else {
            return SingleChildScrollView(
              child: printUserInfo(),
            );
          }

        },
      ),
    );
    return vue;
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  var user = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center (child: SingleChildScrollView(
        child: Column( 
          children: [
            Padding(
            padding: const EdgeInsets.only(left: 50, right: 50, bottom: 15),
            child: TextFormField(
              controller: user,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'user',
            ),
            ),
          ),
          ElevatedButton(
            child: const Text('Search'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserInfo(user: user.value.text)))
          )
        ]
       )
      )
      ));
  }
}