import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    await FirebaseService.initialize();
  } catch (e) {
    // No bloquear la app si Firebase falla (ej. en web sin configuración)
  }

  runApp(
    const ProviderScope(
      child: CondosApp(),
    ),
  );
}
