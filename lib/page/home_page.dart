import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raw_gnss/gnss_measurement_model.dart';
import 'package:raw_gnss/raw_gnss.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  final String title = "TimeIs Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platformBattery = MethodChannel('com.coooolfan.timeis/battery');
  static const platformTime = MethodChannel('com.coooolfan.timeis/time');
  String _timeString = "00:00:00";
  late Timer _timer;

  String _batteryLevel = 'Unknown battery level.';
  String _platformTimeString = 'Unknown time';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await platformBattery.invokeMethod<int>('getBatteryLevel');
      batteryLevel = 'Battery level at $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    } on MissingPluginException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Future<void> _getTime() async {
    String platformTimeString;
    try {
      final result = await platformTime.invokeMethod<String>('getPlatformTime');
      platformTimeString = 'Time is $result.';
    } on PlatformException catch (e) {
      platformTimeString = "Failed to get time : '${e.message}'.";
    } on MissingPluginException catch (e) {
      platformTimeString = "Failed to get time : '${e.message}'.";
    }

    setState(() {
      _platformTimeString = platformTimeString;
    });
  }

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
              _batteryLevel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
            ),
            ElevatedButton(
              onPressed: _getBatteryLevel,
              child: const Text('Get Battery Level'),
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _refreshLocation,
      //   tooltip: 'RefreshLocation',
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}
