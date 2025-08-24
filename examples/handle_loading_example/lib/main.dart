import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handle_loading_example/app.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
