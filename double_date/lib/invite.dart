import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scheduled.dart';

class Invite extends StatefulWidget {
  const Invite({super.key, required this.dateID, required this.userID});
  final String userID, dateID;

  
  @override
  State<Invite> createState() => _Invite();

}

class _Invite extends State<Invite> {

  @override initState() {
    super.initState();
    FirebaseFirestore.instance.collection('dates').doc(widget.dateID).snapshots().listen((event) => setState(() => {}));
  }

  Future<List<String>> getDateAttendees() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dates').doc(widget.dateID).get();
    List<String> result = [];
    // if (doc['ready'] && context.mounted) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => Scheduled(dateID: widget.dateID)));
    // }
    for (Map<String, dynamic> d in doc['attendees']) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('schedule').doc(d['id']).get();
      result.add(userDoc['name']);
      // result.add(d['id']); // Make it name
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
        appBar: AppBar(
          title: const Text("Invite Friends"),
        ),
        body: Center(
          child: SizedBox(
            height: 550,
            width: 600,
            child: Column(children: [
            QrImage(
              data: widget.dateID,
              version: QrVersions.auto,
              size: 200.0
            ),
            FutureBuilder<List<String>>(
              future: getDateAttendees(), // a previously-obtained Future<String> or null
              builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                Widget nameResult;
                if (snapshot.hasData) {
                  return SizedBox( 
                    height: 300,
                    width: 550,
                    child: ListView.builder(
                        itemCount: snapshot.data?.length ?? 0,
                        itemBuilder: 
                          (BuildContext context, index) {
                              return Text(snapshot.data?[index] ?? "");
                          }
                      )
                  );
                } else if (snapshot.hasError) {
                  nameResult = Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text('Error: ${snapshot.error}'),
                    );
                } else {
                  nameResult = const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(),
                    );
                }
                return nameResult;
              },
            ),
            ElevatedButton(
                child: const Text("All users joined"),
                onPressed: () {
                  FirebaseFirestore.instance.collection('dates').doc(widget.dateID).update({'ready': true});
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Scheduled(dateID: widget.dateID)));
                }),
              
          ],)
        ),
      )));
  }

}

const List<String> list = <String>['Min', 'Hour'];

class CreateInvite extends StatefulWidget {
  const CreateInvite({super.key, required this.userID});
  final String userID;

  
  @override
  State<CreateInvite> createState() => _CreateInvite();

}

class _CreateInvite extends State<CreateInvite> {
  int time = 0;
  String timeScale = "Min";
  bool flexable = true;
  
  Future<void> addInvite() async {
    DocumentReference document = await FirebaseFirestore.instance.collection('dates').add(
      {
        "attendees": [{"id": widget.userID, 'flexable': flexable}],
        "time_required": time,
        "time_scale": timeScale,
        "ready": false,
      }
    );
    if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => Invite(userID: widget.userID, dateID: document.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invite"),
      ),
      body: Center(
        child: Column(children: [
          const Text("Are you OK with this event possibly overlapping with your flexible parts of your schedule?"),
          Checkbox(value: flexable, onChanged: (change) => setState(() => flexable = change ?? false)),
          const Text("How long would you like this event to be?"),
          SizedBox(
            width: 300.0,
            child: TextFormField(
              keyboardType: TextInputType.number,
              // controller: nameController,
              decoration: const InputDecoration( // adapted from this example https://api.flutter.dev/flutter/material/TextFormField-class.html
                  icon: Icon(Icons.person),
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                ),
              onFieldSubmitted: (change) => setState(() => time = int.tryParse(change) ?? 0),
            ),
          ),
          DropdownButton<String>(
              value: timeScale,
              onChanged: (String? value) {
                // This is called when the user selects an item.
                setState(() {
                  timeScale = value ?? "Min";
                });
              },
              items: list.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: addInvite,
              child: const Text("Create Invite"),
            ),
        ],)
      ),
    );
  }

}