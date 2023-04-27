//https://pub.dev/packages/syncfusion_flutter_calendar
// import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_date/join.dart';
import 'package:flutter/material.dart';
import 'invite.dart';

class ExampleForm extends StatefulWidget {
  const ExampleForm({super.key, required this.userID});
  final String userID;
  @override
  State<ExampleForm> createState() => _ExampleForm();
}

class _ExampleForm extends State<ExampleForm> {

  // TextEditingController nameController = TextEditingController();
  // late Future<List<Widget>> _children;
  List<Widget> children = [];

  Future<String> getName() async{
    DocumentSnapshot schedule = await FirebaseFirestore.instance.collection('schedule').doc(widget.userID).get();
    if (schedule.exists) {
      try {
        return schedule['name']; 

      }
      catch (e) {
        return "";
      }
    }
    return "";
  }

  Future<void> setName(result) async {
    FirebaseFirestore.instance.collection('schedule').doc(widget.userID).set({'name': result});
  }

  // Adapted from https://stackoverflow.com/questions/46611369/get-all-from-a-firestore-collection-in-flutter
  Future<List<QueryDocumentSnapshot<Object?>>> getObligations() async {
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').get();
    // Get data from docs and convert map to List
    return querySnapshot.docs;
 }

  List<Widget>buildChildren() {
    List<Widget> result = [];
    result.add(
      FutureBuilder<String>(
        future: getName(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          Widget nameResult;
          if (snapshot.hasData) {
            nameResult = SizedBox(
            width: 300.0,
            child: TextFormField(
                  // controller: nameController,
                  decoration: const InputDecoration( // adapted from this example https://api.flutter.dev/flutter/material/TextFormField-class.html
                      icon: Icon(Icons.person),
                      hintText: 'What do people call you?',
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    ),
                  onFieldSubmitted: setName,
                  initialValue: snapshot.data ?? "",
                ),
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
    );

    result.add(
      FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
        future: getObligations(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<List<QueryDocumentSnapshot<Object?>>> snapshot) {
          Widget nameResult;
          if (snapshot.hasData) {
            return SizedBox( 
              height: 540,
              width: 550,
              child: ListView.builder(
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: 
                    (BuildContext context, index) {
                      // return Text();
                      return WeekForm(userID: widget.userID, doc: snapshot.data?[index]);
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
    );
    return result;
  }

  Future<void> addObligation() async {
    List<bool> week = [false,false,false,false,false,false,false];
    TimeOfDay start = const TimeOfDay(hour: 0, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 0, minute: 0);
    bool vital = false;
    FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').add(
      {
        "week": week,
        "start_hour": start.hour,
        "start_minute": start.minute,
        "end_hour": end.hour,
        "end_minute": end.minute,
        "vital": vital
      }
    );
  }

  // // Testing to see if I can just push an entire list of widgets into firebase.
  // // Future<List<Widget>> getChildren() async {
  // Future<void> getChildren() async {
  //   DocumentSnapshot schedule = await FirebaseFirestore.instance.collection('schedule').doc(widget.userID).get();
  //   if (schedule.exists && schedule['children'] != null) {
  //     setState(() {
  //       children = schedule['children'];
  //     });

  //   } else {
  //     setState(() {
  //       children = [
  //         SizedBox(
  //           width: 300.0,
  //           child: TextFormField(
  //             // controller: nameController,
  //             decoration: const InputDecoration( // adapted from this example https://api.flutter.dev/flutter/material/TextFormField-class.html
  //                 icon: Icon(Icons.person),
  //                 hintText: 'What do people call you?',
  //                 labelText: 'Name',
  //                 border: OutlineInputBorder(),
  //                 contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
  //               ),
  //             onFieldSubmitted: (value) {
  //               // Send changes to firebase
  //               debugPrint("CHANGE to $value");
  //             },
  //           ),
  //         ),
  //       ];
        
  //       addObligation()
  //       updateChildren();

  //     });
  //   }
  // }

  // Future<void> updateChildren() async {
  //   FirebaseFirestore.instance.collection('schedule').doc(widget.userID).set({"children": children});
  // }

  @override
  void initState() {
    super.initState();
    
    FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').snapshots().listen((event) => setState(() => {}));
    // addObligation();
    // getChildren();

    // children = [
    //     SizedBox(
    //       width: 300.0,
    //       child: TextFormField(
    //         // controller: nameController,
    //         decoration: const InputDecoration( // adapted from this example https://api.flutter.dev/flutter/material/TextFormField-class.html
    //             icon: Icon(Icons.person),
    //             hintText: 'What do people call you?',
    //             labelText: 'Name',
    //             border: OutlineInputBorder(),
    //             contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    //           ),
    //         onFieldSubmitted: (value) {
    //           // Send changes to firebase
    //           debugPrint("CHANGE to $value");
    //         },
    //       ),
    //     ),
    //     const WeekForm()
    //   ];

  }

  // @override
  // void dispose() {
  //   nameController.dispose();
  //   super.dispose();
  // }

  Widget buildBody() {
    return SingleChildScrollView(child: Align(alignment: Alignment.topCenter, child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: buildChildren(),
      )));
    // return FutureBuilder<List<Widget>>(
    //     future: getChildren(), // a previously-obtained Future<String> or null
    //     builder: (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
    //       Widget result;
    //       if (snapshot.hasData) {
    //         if (snapshot.data != null) {
    //           result = SingleChildScrollView(child: Align(alignment: Alignment.topCenter, child: Column(
    //             mainAxisAlignment: MainAxisAlignment.start,
    //             children: snapshot.data,
    //             )));
    //         } else {
    //           // result = SingleChildScrollView(child: Align(alignment: Alignment.topCenter, child: Column(
    //           //   mainAxisAlignment: MainAxisAlignment.start,
    //           //   children: snapshot.data,
    //           //   )));
    //         }
    //       } else if (snapshot.hasError) {
    //         nameResult = Padding(
    //             padding: const EdgeInsets.only(top: 16),
    //             child: Text('Error: ${snapshot.error}'),
    //           );
    //       } else {
    //         nameResult = const SizedBox(
    //             width: 16,
    //             height: 16,
    //             child: CircularProgressIndicator(),
    //           );
    //       }
    //       return nameResult;
    //     },
    //   );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Welcome to Double Date!"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: buildBody()
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: addObligation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
              )
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => JoinCamera(userID: widget.userID)));
              },
              backgroundColor: Colors.pink,
              child: const Icon(Icons.qr_code),
              ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CreateInvite(userID: widget.userID)));
              },
              backgroundColor: Colors.pink,
              child: const Icon(Icons.favorite),
              ),
          )

      ],)
    );
  }
}

class WeekForm extends StatefulWidget {
  const WeekForm({super.key, this.doc, required this.userID});
  final QueryDocumentSnapshot<Object?>? doc;
  final String userID;

  @override
  State<WeekForm> createState() => _WeekForm();
}

class _WeekForm extends State<WeekForm> {
  late List<bool> week;
  List<String> weeklabel = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
  late TimeOfDay start = const TimeOfDay(hour: 0, minute: 0);
  late TimeOfDay end = const TimeOfDay(hour: 0, minute: 0);
  late bool vital = false;
  String name = "";

  @override
  void initState() {
    super.initState();
    try {
      week = widget.doc?['week'].cast<bool>()?? [false,false,false,false,false,false,false];
      start = TimeOfDay(hour: widget.doc?['start_hour'] ?? 0, minute: widget.doc?['start_minute'] ?? 0);
      end = TimeOfDay(hour: widget.doc?['end_hour'] ?? 0, minute: widget.doc?['end_minute'] ?? 0);
      vital = widget.doc?['vital'] ?? false;
    }
    catch (e) {
      week = [false,false,false,false,false,false,false];
      start = const TimeOfDay(hour: 0, minute: 0);
      end = const TimeOfDay(hour: 0, minute: 0);
      vital = false;
    }
  }

  Future<void> setObligation() async {
    // List<bool> week = [false,false,false,false,false,false,false];
    // TimeOfDay start = const TimeOfDay(hour: 0, minute: 0);
    // TimeOfDay end = const TimeOfDay(hour: 0, minute: 0);
    // bool vital = false;
    try {
      FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').doc(widget.doc?.id).set(
        {
          "week": week,
          "start_hour": start.hour,
          "start_minute": start.minute,
          "end_hour": end.hour,
          "end_minute": end.minute,
          "vital": vital
        }
      );
    } catch (e) {
      FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').add(
        {
          "week": week,
          "start_hour": start.hour,
          "start_minute": start.minute,
          "end_hour": end.hour,
          "end_minute": end.minute,
          "vital": vital
        }
      );
    }
    
  }

  List<Widget> buildWeek() {
    List<Widget> result = [];
    for (int i = 0; i < 7; i++) {
      result.add(
        Column(
          children: [
            Text(weeklabel[i]),
            Checkbox(value: week[i], onChanged: (change) => setState(() {
              week[i] = change ?? false;
              setObligation();
              }))
          ],
        )
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: buildWeek(),
        ),
        Row(
          children: [
            Column(
              children: [
                const Text("Starting Time"),
                ElevatedButton(
                  onPressed: () {
                    showTimePicker(context: context, initialTime: start)
                      .then((value) => setState(() {
                        start = value ?? start;
                        setObligation();
                      }));
                    },
                  child: Text("${start.hour}:${start.minute}")
                ),
              ]
            ),
            Column(
              children: [
                const Text("Ending Time"),
                ElevatedButton(
                  onPressed: () {
                    showTimePicker(context: context, initialTime: end)
                      .then((value) => setState(() {
                        end = value ?? end;
                        setObligation();
                      }));
                    },
                  child: Text("${end.hour}:${end.minute}")
                )
              ]
            ),
            Column(
              children: [
                const Text("Delete"),
                ElevatedButton(
                  onPressed: () async {
                      FirebaseFirestore.instance.collection('schedule').doc(widget.userID).collection('obligation').doc(widget.doc?.id).delete();
                    },
                  child: const Text("Delete")
                )
              ]
            )
          ]
        ),
        Row(
          children: [
            const Text("Can't Miss? "),
            Checkbox(value: vital, onChanged: (change) => setState((){
              vital = change ?? false;
              setObligation();
            }))
          ],
        )
      ],
    );
  }
}