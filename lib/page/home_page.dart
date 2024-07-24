import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raw_gnss/gnss_measurement_model.dart';
import 'package:raw_gnss/raw_gnss.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = "TimeIs Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _timeString = "00:00:00";
  String _locationMsg = "Location is: ";
  late Timer _timer;
  Position _position = Position(
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: DateTime.now(),
      floor: 0,
      isMocked: false,
      altitudeAccuracy: 0,
      headingAccuracy: 0);
  @override
  void initState() {
    super.initState();
    _startTimer();
    //申请权限
    checkPermission();
  }

  void checkPermission() async {
    Permission permission = Permission.locationAlways;
    PermissionStatus status = await permission.status;
    print('检测权限$status');
    if (status.isGranted) {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setState(() {
          _locationMsg = "Last Location is: ";
          _position = position;
        });
      }

      //权限通过
    } else if (status.isDenied) {
      //权限拒绝， 需要区分IOS和Android，二者不一样
      requestPermission(permission);
    } else if (status.isPermanentlyDenied) {
      //权限永久拒绝，且不在提示，需要进入设置界面
      openAppSettings();
    } else if (status.isRestricted) {
      //活动限制（例如，设置了家长///控件，仅在iOS以上受支持。
      openAppSettings();
    } else {
      //第一次申请
      requestPermission(permission);
    }
  }

  void requestPermission(Permission permission) async {
    PermissionStatus status = await permission.request();
    print('权限状态$status');
    if (!status.isGranted) {
      openAppSettings();
    }
  }

  void _refreshLocation() async {
    setState(() {
      _locationMsg = "Location is loding: ";
    });
    Position position = await _determinePosition();
    print('Location: ${position.latitude}, ${position.longitude}');
    setState(() {
      _position = position;
      _locationMsg = "Location is: ";
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      _refreshTime();
    });
  }

  void _refreshTime() {
    var now = DateTime.now().toString();
    var newTime = now.substring(11, 19);
    if (newTime != _timeString) {
      setState(() {
        _timeString = newTime;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Time is:',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              _timeString,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _locationMsg,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              _position.toString(),
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
              StreamBuilder<GnssMeasurementModel>(
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return const CircularProgressIndicator();
                }

                return ListView.builder(
                  itemBuilder: (context, position) {
                    return ListTile(
                      title: Text(
                          "Satellite: ${snapshot.data!.measurements![position].svid}"),
                    );
                  },
                  itemCount: snapshot.data!.measurements?.length ?? 0,
                );
              },
              stream: RawGnss().gnssMeasurementEvents,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshLocation,
        tooltip: 'RefreshLocation',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
