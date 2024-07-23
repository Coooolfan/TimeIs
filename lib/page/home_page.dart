import 'dart:async';

import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = "TimeIs Demo";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _timeString = "00:00:00";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      _refreshTime();
    });
  }

  void _refreshTime() {
    var now = DateTime.now().add(const Duration(hours: 8)).toString();
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshTime,
        tooltip: 'RefreshTime',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
