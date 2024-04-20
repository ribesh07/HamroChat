// import 'dart:math';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hamrochat/firebase/firebaseservices.dart';
// import 'package:hamrochat/readdata.dart';

class Homepage extends StatefulWidget {
  String? id;
  String? s;
  // Homepage({super.key,this.id,this.s});
  // ignore: use_super_parameters
  Homepage({Key? key, this.id, this.s}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final textController = TextEditingController();

  final textController1 = TextEditingController();

  final Firebaseservice _firebaseservice = Firebaseservice();
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
      body: Center(
        child: Container(
          color: Colors.blueGrey[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(widget.s =='update')
                Text(widget.s.toString().toUpperCase(),style:const TextStyle(fontSize: 15,)),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Name',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 15
                ),
                child: TextField(
                  controller: textController1,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'descriptions',
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    debugPrint(textController.text);
                    debugPrint(textController1.text);
                    if (widget.id == null) {
                      _firebaseservice
                          .addnote(textController.text, textController1.text)
                          .then((value) {
                        textController.clear();
                        textController1.clear();
                      });
                      debugPrint(widget.id);
                      debugPrint(widget.s);
                    } else {
                     _firebaseservice
                          .updateNote(widget.id!, textController.text,
                              textController1.text)
                          .then((value) {
                        textController.clear();
                        textController1.clear();
                      });
                      debugPrint(widget.id);
                      debugPrint(widget.s);

                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
