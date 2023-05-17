
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'scheduled.dart';

// Taken from https://pub.dev/packages/mobile_scanner examples

class JoinCamera extends StatefulWidget {
  const JoinCamera ({super.key, required this.userID});
  final String userID;
  @override
  State<JoinCamera> createState() => _JoinCamera();

}

class _JoinCamera extends State<JoinCamera> {

  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose(); // You need to do this.

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mobile Scanner'),
          actions: [
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.torchState,
                builder: (context, state, child) {
                  switch (state) {
                    case TorchState.off:
                      return const Icon(Icons.flash_off, color: Colors.grey);
                    case TorchState.on:
                      return const Icon(Icons.flash_on, color: Colors.yellow);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              color: Colors.white,
              icon: ValueListenableBuilder(
                valueListenable: cameraController.cameraFacingState,
                builder: (context, state, child) {
                  switch (state) {
                    case CameraFacing.front:
                      return const Icon(Icons.camera_front);
                    case CameraFacing.back:
                      return const Icon(Icons.camera_rear);
                  }
                },
              ),
              iconSize: 32.0,
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: MobileScanner(
          // fit: BoxFit.contain,
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              
              testBarcode(context, barcode.rawValue);
              debugPrint('Barcode found! ${barcode.rawValue}');
              
            }
          },
        ),
    );
  }
  Future<void> testBarcode(BuildContext context, String? rawValue) async {
    
    // DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dates').doc(rawValue).get();
    // Test Barcode US9Bx29JA52Alfrl691Z
    // START TEST
    // if (context.mounted) {
    //   cameraController.stop();
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJoin(dateID: "US9Bx29JA52Alfrl691Z", userID: widget.userID)));
    // }

    // END TEST
    try { 
      if (rawValue != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dates').doc(rawValue).get();
        if (doc.exists && context.mounted) {
          cameraController.stop();
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateJoin(dateID: rawValue, userID: widget.userID)));
        }
      }
    } catch (e) {
      // debugPrint(e.toString());
      return;
    }
  }
}

class Joined extends StatefulWidget {
  const Joined({super.key, required this.dateID, required this.userID});
  final String userID, dateID;

  
  @override
  State<Joined> createState() => _Joined();

}

class _Joined extends State<Joined> {

  @override initState() {
    super.initState();
    FirebaseFirestore.instance.collection('dates').doc(widget.dateID).snapshots().listen((event) => setState(() => {}));
  }

  Future<List<String>> getDateAttendees(BuildContext context) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dates').doc(widget.dateID).get();
    List<String> result = [];
    if (doc['ready'] && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Scheduled(dateID: widget.dateID)));
    }
    for (Map<String, dynamic> d in doc['attendees']) {
      // result.add(d['id']); // Make it name
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('schedule').doc(d['id']).get();
      result.add(userDoc['name']);
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
            FutureBuilder<List<String>>(
              future: getDateAttendees(context), // a previously-obtained Future<String> or null
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
            )
          ],)
        ),
      )));
  }

}


class CreateJoin extends StatefulWidget {
  const CreateJoin({super.key, required this.dateID, required this.userID});
  final String userID, dateID;

  
  @override
  State<CreateJoin> createState() => _CreateJoin();

}

class _CreateJoin extends State<CreateJoin> {
  bool flexable = true;
  
  Future<void> addInvite() async {
    dynamic doc = await FirebaseFirestore.instance.collection('dates').doc(widget.dateID).get();//.get();
    List<dynamic> attendees = doc['attendees'];
    attendees.add({"id": widget.userID, 'flexable': flexable});
    await FirebaseFirestore.instance.collection('dates').doc(widget.dateID).update({'attendees': attendees});
    if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => Joined(userID: widget.userID, dateID: widget.dateID)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Event"),
      ),
      body: Center(
        child: Column(children: [
          const Text("Are you OK with this event possibly overlapping with your flexible parts of your schedule?"),
          Checkbox(value: flexable, onChanged: (change) => setState(() => flexable = change ?? false)),
            ElevatedButton(
              onPressed: addInvite,
              child: const Text("Join Event"),
            ),
        ],)
      ),
    );
  }

}