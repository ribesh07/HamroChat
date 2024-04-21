import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hamrochat/firebaseCRUD/firebaseservices.dart';
import 'package:hamrochat/firebaseCRUD/home.dart';

// ignore: camel_case_types
class readData extends StatefulWidget {
  const readData({super.key});

  @override
  State<readData> createState() => _readDataState();
}

// ignore: camel_case_types
class _readDataState extends State<readData> {
  final textController = TextEditingController();

  final textController1 = TextEditingController();

  final Firebaseservice _firebaseservice = Firebaseservice();

  bool isdeleted = false;

  // @override
  // ignore: non_constant_identifier_names
  void Dispose() {
    textController.dispose();
    textController1.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // _firebaseservice.getNotesStream();
  //   if(isdeleted){
  //     Future.delayed(const Duration(seconds: 3), () {
  //         setState(() {
  //         isdeleted = false;
  //         });
  //      });
  //   }
  // }
  // int count = 0;

  // TextStyle? fontControl() {
  //   if (count == 1) {

  //     return const TextStyle(fontSize: 15,color: Colors.red,
  //                       fontWeight: FontWeight.bold,);
  //   }
  //   return TextStyle(fontSize: 10 + count.toDouble()); //default
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent[100],
          title: Expanded(
            child: Container(
                alignment: Alignment.center,
                // color: Colors.deepPurpleAccent[100],
                // height: 200,
                // width: double.infinity,
                child: const Text(
                  'CRUD',
                  style: TextStyle(fontSize: 24),
                )),
          )),
      body: InkWell(
        onTap: () {
          setState(() {
          isdeleted = false;
          });
        },
        child: Container(
          alignment: Alignment.topRight,
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseservice.getNotesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document =
                              snapshot.data!.docs[index];
                          // String Docid = document.id;
                          return ListTile(
                            title: Text(document['title']),
                            subtitle: Text(document['description']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: () {
                                    // debugPrint(document.id);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Homepage(s: 'update'),
                                        ));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _firebaseservice
                                        .deleteNote(document.id)
                                        .then((value) {
                                      debugPrint('Deleted');
                                    });
                                    isdeleted = true;
                                    setState(() {
                                      // Future.delayed(const Duration(seconds: 3), () {
                                      //     isdeleted = false;
                                      // });
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text('No data found'),
                    );
                  }
                },
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Homepage(s: 'create')));
                  },
                  child: const Text('Create Data')),
              if (isdeleted)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                      alignment: Alignment.bottomCenter,
                      child: const Text(
                        'Deleted Successfully !!!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
      
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),label: 'home',),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart_rounded),label: 'create')
      ],
      ),
    );
  }
}
