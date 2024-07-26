import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raw_gnss/gnss_status_model.dart';
import 'package:raw_gnss/raw_gnss.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  final String title = "TimeIs Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _hasPermissions = false;
  late RawGnss _gnss;
  @override
  void initState() {
    super.initState();
    _gnss = RawGnss();
    if (!Platform.isAndroid) {
      setState(() => _hasPermissions = false);
      return;
    }
    Permission.location
        .request()
        .then((value) => setState(() => _hasPermissions = value.isGranted));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: !_hasPermissions
            ? Text(Platform.isAndroid ? '无权限' : '平台不支持')
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder(
                      stream: _gnss.gnssMeasurementEvents,
                      builder: (context, snapshot) {
                        var reportTime = DateTime.now();
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        var clock = snapshot.data!.clock!;
                        return Column(
                          children: [
                            const Text('协调世界时:'),
                            Text(
                              _getGPSTime(
                                  clock.timeNanos!,
                                  clock.fullBiasNanos!,
                                  clock.biasNanos!,
                                  reportTime),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                          ],
                        );
                        // return Text(' ${snapshot.data!.string}');
                      }),
                  StreamBuilder(
                    stream: _gnss.gnssStatusEvents,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      var gnssStatus = snapshot.data!;
                      var constellationTypes =
                          _getConstellationTypes(gnssStatus);
                      return Column(
                        children: [
                          Text('更新于: ${DateTime.now()}'),
                          Text('可见的卫星数量: ${gnssStatus.satelliteCount}'),
                          Text('参与定位的卫星数量: ${_getFixedSatellites(gnssStatus)}'),
                          Text('🇺🇸GPS: ${constellationTypes[1]}'),
                          Text('🇺🇳SBAS: ${constellationTypes[2]}'),
                          Text('🇷🇺GLONASS: ${constellationTypes[3]}'),
                          Text('🇯🇵QZSS: ${constellationTypes[4]}'),
                          Text('🇨🇳北斗: ${constellationTypes[5]}'),
                          Text('🇪🇺Galileo: ${constellationTypes[6]}'),
                          Text("🇮🇳IRNSS: ${constellationTypes[7]}"),
                          Text('其他: ${constellationTypes[0]}'),
                        ],
                      );
                    },
                  )
                ],
              ),
      ),
    );
  }

  String _getGPSTime(
      int timeNanos, int fullBiasNanos, double biasNanos, DateTime reportTime) {
    var offset = DateTime.utc(1980, 1, 6);
    var timeStampGPS = timeNanos - (fullBiasNanos + biasNanos);
    var dateTimeGPS = offset.add(Duration(microseconds: timeStampGPS ~/ 1000));
    dateTimeGPS = dateTimeGPS.subtract(const Duration(seconds: 18));
    dateTimeGPS = dateTimeGPS.add(DateTime.now().difference(reportTime));
    return dateTimeGPS.toString();
  }

  int _getFixedSatellites(GnssStatusModel gnssStatusModel) {
    var fixedSatellites = 0;
    for (var i = 0; i < gnssStatusModel.satelliteCount!; i++) {
      if (gnssStatusModel.status![i].usedInFix!) {
        fixedSatellites++;
      }
    }
    return fixedSatellites;
  }

  Map _getConstellationTypes(GnssStatusModel gnssStatusModel) {
    var constellationTypesMap = {
      0: 0,
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0
    };
    for (var i = 0; i < gnssStatusModel.satelliteCount!; i++) {
      constellationTypesMap[gnssStatusModel.status![i].constellationType!] =
          constellationTypesMap[
                  gnssStatusModel.status![i].constellationType!]! +
              1;
    }
    return constellationTypesMap;
  }
}
