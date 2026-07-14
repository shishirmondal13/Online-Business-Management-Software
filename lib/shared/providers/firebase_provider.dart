import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set in [main] when Firebase.initializeApp fails; null means OK.
final firebaseInitErrorProvider = Provider<String?>((ref) => null);
