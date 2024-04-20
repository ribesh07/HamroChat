import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hamrochat/firebase/firebaseservices.dart';
import 'package:hamrochat/home.dart';

class readData extends StatelessWidget {
  readData({super.key});
  final textController = TextEditingController();
  final textController1 = TextEditingController();
  final Firebaseservice _firebaseservice = Firebaseservice();
  bool isdeleted = false;
  // @override
  void Dispose() {
    textController.dispose();
    textController1.dispose();
  }

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
      body: Container(
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
                        DocumentSnapshot document = snapshot.data!.docs[index];
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
                                        builder: (context) => Homepage(
                                            id: document.id, s: 'update'),
                                      ));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _firebaseservice
                                      .deleteNote(document.id)
                                      .then((value) {
                                    setState() {
                                      isdeleted = true;
                                    }
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
            if(isdeleted)
              const Text('Deleted Successfully !!!',style: TextStyle(fontSize: 15,),),
          ],
        ),
      ),
    );
  }
}
