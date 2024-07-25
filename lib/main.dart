// import 'package:flutter/material.dart';
// import 'package:time_is/page/home_page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'TimeIs Demo',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raw_gnss/gnss_measurement_model.dart';
import 'package:raw_gnss/gnss_status_model.dart';
import 'package:raw_gnss/raw_gnss.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Eddy's GNSS logs"),
        ),
        body: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _hasPermissions = false;
  late RawGnss _gnss;

  @override
  void initState() {
    super.initState();

    _gnss = RawGnss();

    Permission.location
        .request()
        .then((value) => setState(() => _hasPermissions = value.isGranted));
  }

// Measurment Model

  @override
  Widget build(BuildContext context) => _hasPermissions
      ? StreamBuilder<GnssMeasurementModel>(
          builder: (context, snapshot) {
            return ListView.builder(
              itemBuilder: (context, position) {
                if (snapshot.data != null &&
                    snapshot.data!.measurements != null &&
                    position < snapshot.data!.measurements!.length) {
                  if (position == 0) {
                    return Text(
                      _getGPSTime(snapshot.data!.clock),
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold),
                    );
                  }

                  var measurement = snapshot.data!.measurements![position];
                  return Column(
                    // 左对齐
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Satellite: ${measurement.svid}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        "Time: ${measurement.receivedSvTimeNanos} PRN: ${measurement.svid}, C_N0: ${measurement.cn0DbHz}, Constellation type: ${measurement.constellationType} ",
                      ),
                    ],
                  );
                }
                return null; // 或者返回一个占位符Widget
              },
              itemCount: snapshot.data?.measurements?.length ?? 0,

              //itemCount: snapshot.data!.satelliteCount ?? 0,
            );
          },
          stream: _gnss.gnssMeasurementEvents,
        )
      : _loadingSpinner();

  Widget _loadingSpinner() => const Center(child: CircularProgressIndicator());
}

String _getGPSTime(Clock? gnssClock) {
  if (gnssClock == null) {
    return "No clock data";
  }
  var GPSTIME = (gnssClock.timeNanos ?? 0).toDouble() -
      ((gnssClock.fullBiasNanos ?? 0).toDouble() +
          (gnssClock.biasNanos ?? 0.0));
  // 从纳秒转换为可读的时间
  GPSTIME = GPSTIME / 1000000000;
  // 从时间戳转换为UTC时间
  var date = DateTime.fromMillisecondsSinceEpoch(GPSTIME.toInt() * 1000);
  return "GPSTIME:\n $date";
}
