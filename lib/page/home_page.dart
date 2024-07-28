import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raw_gnss/raw_gnss.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  final String title = "TimeIs Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _offset = 0;
  var _registerredListener = false;
  var _currentTime = DateTime.now();
  var _lastReportTime = DateTime.now();
  var _lastGPSFixTime = DateTime.now();
  var _hasPermissions = false;
  var _satelliteCount = 0;
  var _unavailable = true;
  var _constellationTypesMap = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) {
      setState(() => _hasPermissions = false);
      return;
    }
    Permission.location
        .request()
        .then((value) => setState(() => _hasPermissions = value.isGranted));
    _updateCurrentTimeString();
  }

  void _registerListener() {
    RawGnss().gnssMeasurementEvents.listen((e) {
      var reportTime = DateTime.now();
      var clock = e.clock!;
      var offsetGPS = DateTime.utc(1980, 1, 6);
      var timeStampGPS =
          clock.timeNanos! - (clock.fullBiasNanos! + clock.biasNanos!);
      var dateTimeGPS = offsetGPS
          .add(Duration(
              microseconds: timeStampGPS ~/ 1000)) // 除以1000转换为毫秒, 加上偏移量
          .subtract(
              const Duration(seconds: 18)); // 同步闰秒 减去18秒，GPS时间比UTC时间慢18秒 -2024-7-27
      setState(() {
        _lastReportTime = reportTime;
        _lastGPSFixTime = dateTimeGPS;
        _offset = reportTime.difference(dateTimeGPS).inMilliseconds;
      });
    });

    RawGnss().gnssStatusEvents.listen((e) {
      setState(() {
        _satelliteCount = e.satelliteCount!;
        _constellationTypesMap = {
          0: 0,
          1: 0,
          2: 0,
          3: 0,
          4: 0,
          5: 0,
          6: 0,
          7: 0
        };
        for (var i = 0; i < e.satelliteCount!; i++) {
          _constellationTypesMap[e.status![i].constellationType!] =
              _constellationTypesMap[e.status![i].constellationType!]! + 1;
        }
      });
    });
  }

  // 创建一个计时器，以尽可能短的时间间隔更新UI
  void _updateCurrentTimeString() {
    Future.delayed(const Duration(), () {
      if (mounted) {
        if (_hasPermissions && !_registerredListener) {
          _registerListener();
          _registerredListener = true;
        }
        if (_offset != 0) {
          setState(() {
            _unavailable = _lastGPSFixTime.year != _lastReportTime.year;
            _currentTime = DateTime.now().add(Duration(
                milliseconds: _lastGPSFixTime
                    .difference(_lastReportTime)
                    .inMilliseconds));
          });
        }
        _updateCurrentTimeString();
      }
    });
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
                  _unavailable
                      ? const Text(
                          "卫星信号不可用，尝试移动到开阔地带",
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        )
                      : const SizedBox(),
                  const Text("当前时间:"),
                  Text(_currentTime.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  Text("设备时间的偏移值：$_offset 毫秒"),
                  const Text("上次获取到的世界协调时: "),
                  Text(_lastGPSFixTime.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  const Divider(),
                  Text("可见卫星数量: $_satelliteCount"),
                  Text('🇺🇸GPS: ${_constellationTypesMap[1]}'),
                  Text('🇺🇳SBAS: ${_constellationTypesMap[2]}'),
                  Text('🇷🇺GLONASS: ${_constellationTypesMap[3]}'),
                  Text('🇯🇵QZSS: ${_constellationTypesMap[4]}'),
                  Text('🇨🇳北斗: ${_constellationTypesMap[5]}'),
                  Text('🇪🇺Galileo: ${_constellationTypesMap[6]}'),
                  Text("🇮🇳IRNSS: ${_constellationTypesMap[7]}"),
                  Text('其他: ${_constellationTypesMap[0]}'),
                ],
              ),
      ),
    );
  }
}
