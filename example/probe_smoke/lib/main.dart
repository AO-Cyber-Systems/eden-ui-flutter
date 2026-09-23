// The probe smoke app.
//
// One keyed widget and one identified nav item, so a driver has something to
// find and tool/probe_guard.sh has a real bundle to grep. Deliberately tiny:
// anything else here would be surface the guard has to reason about.
import 'package:eden_ui_flutter/probe.dart';
import 'package:flutter/material.dart';

void main() {
  // No-op without --dart-define=EDEN_PROBE=true. That is the whole point:
  // this line ships in production and costs nothing there.
  EdenProbe.install();
  runApp(const ProbeSmokeApp());
}

class ProbeSmokeApp extends StatelessWidget {
  const ProbeSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Probe Smoke',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                key: ValueKey<String>('probe-target'),
                width: 120,
                height: 40,
                child: ColoredBox(color: Color(0xFF2266CC)),
              ),
              Semantics(
                identifier: 'eden-nav-home',
                container: true,
                label: 'Home',
                child: SizedBox(width: 100, height: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
