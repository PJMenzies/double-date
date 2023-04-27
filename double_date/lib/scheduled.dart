import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Scheduled extends StatefulWidget {
  const Scheduled({super.key, required this.dateID});
  final String dateID;

  @override
  State<Scheduled> createState() => _Scheduled();

}


const List<String> weeklabel = ["SUN","MON","TUE","WED","THU","FRI","SAT"];

class _Scheduled extends State<Scheduled> {
  
  Future<List<String>> getTimesThatWork() async {
    Map<String, List<List<bool>>> schedules = {};
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dates').doc(widget.dateID).get();
    schedules['times'] = [];
    schedules['flex_times'] = [];

    for (int i = 0; i < 7; i++) {
      schedules['times']!.add(List<bool>.filled(1440, true));
      schedules['flex_times']!.add(List<bool>.filled(1440, true));
    } 
    List<String> result = [];
    for (Map<String, dynamic> d in doc['attendees']) {

      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance.collection('schedule').doc(d['id']).collection('obligation').get();
      List<QueryDocumentSnapshot<Map<String, dynamic>>> obligations = snapshot.docs;

      for (QueryDocumentSnapshot<Map<String, dynamic>> obligation in obligations) {
        Map<String, dynamic> data = obligation.data();
        int startTime = data['start_minute'] + data['start_hour']*60;
        int endTime = data['end_minute'] + data['end_hour']*60;
        bool vital = data['vital'];
        List<bool> week = data['week'].cast<bool>();
        for (int day = 0; day < 7; day++) {
          if (week[day] == true) {
            for (int min = startTime; min <= endTime; min++) {
              schedules['times']![day][min] = false;
              if (vital || d['flexable'] == false) {
                schedules['flex_times']![day][min] = false;
              }
            }
          }
        }
      }
    }

    // Find the times that work
    List<Map<String, int>> workingTimes = [];
    int timeRequired = doc['time_required'];
    if (doc['time_scale'] == 'Hour') timeRequired *= 60;
    String group = 'times';
    while(group != 'done') {
      int tempStart = 0;
      int startDay = 0;
      bool working = false;
      for (int day = 0; day < 7; day++) {
        for (int min = 0; min < 1440; min++) {
          if(schedules[group]![day][min] == true) {
            if (working == false) {
              working = true;
              tempStart = min;
              startDay = day;
            }
          } else {
            if (working == true) {
              working = false;
              int totalMin = min+(day-startDay)*1440;
              if (totalMin - tempStart > timeRequired) {
                workingTimes.add({'start_min': tempStart, 'start_day': startDay, 'end_min': min, 'end_day': day});
              }
            }
          }
        }
      }
      if (working) {
        if (1440 - tempStart > timeRequired) {
          workingTimes.add({'start_min': tempStart, 'start_day': startDay, 'end_min': 1440, 'end_day': 6});
        }
      }

      if (workingTimes.isEmpty && group != 'flex_times') {
        group = 'flex_times';
      } else {
        if (workingTimes.isEmpty) result.add("No valid times found");
        group = 'done';
      }
    }

    // Fix up the strings
    for (Map<String, int> time in workingTimes) {
      result.add("${weeklabel[time['start_day'] ?? 0]} ${(time['start_min']!/60).floor()}:${time['start_min']!%60} -> ${weeklabel[time['end_day'] ?? 0]} ${(time['end_min']!/60).floor()}:${time['end_min']!%60}");
    }
    return result;
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Times that work"),
            ),
            body: Center(
              child: Column(children: [
                      const Text("Schedule"),
                      FutureBuilder(
                        future: getTimesThatWork(),
                        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                        Widget nameResult;
                        if (snapshot.hasData) {
                          return SizedBox(
                            height: 400,
                            width: 600,
                            child: ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (BuildContext context, int index) {
                                  return Text(snapshot.data?[index] ?? "");
                                }));
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
                      }),
                      // navigator section of line below adapted from https://stackoverflow.com/questions/51071933/navigator-routes-clear-the-stack-of-flutter
                      ElevatedButton(onPressed: () => {Navigator.pushNamedAndRemoveUntil(context, "/profile", (r) => false)}, child: const Text("Return"))
                    ],)
                  ),
          ));
  }

}