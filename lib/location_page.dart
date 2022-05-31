import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loc/location.dart';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionStream;
  Position? _position;

  @override
  void initState() {
    LocationService().getCurrentPosition().then((value) {
      setState(() {
        _position = value;
      });
      print("init state positon $value");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Pge"),
      ),
      body: Center(
        child: Column(
          children: [
            _position != null
                ? Text("${_position.toString()}")
                : Text("No position"),
            // FutureBuilder(
            //     future: LocationService().getCurrentPosition(),
            //     builder: (context, snapshot) {
            //       if (snapshot.hasData) {
            //         return Text(snapshot.data.toString());
            //       } else {
            //         return Text("NO LOCATION");
            //       }
            //     }),
            TextButton(
              onPressed: () {
                LocationService().getCurrentPosition().then((value) {
                  setState(() {
                    _position = value;
                  });

                  print("Pos $value");
                });
              },
              child: Text("Fetch Latest Location"),
            ),
          ],
        ),
      ),
    );
  }
}
