import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  bool _isInitialized = false;

  FirebaseService._init();

  bool get isConfigured => _isInitialized;

  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        return;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('Firebase successfully initialized for project: studymate-e8da6');
    } catch (e) {
      debugPrint('Firebase is not yet configured with native credentials: $e');
      _isInitialized = false;
    }
  }

  FirebaseAuth? get auth {
    if (!_isInitialized) return null;
    return FirebaseAuth.instance;
  }

  FirebaseFirestore? get firestore {
    if (!_isInitialized) return null;
    return FirebaseFirestore.instance;
  }

  // --- Collection references for current user ---
  CollectionReference<Map<String, dynamic>>? getUserCollection(
    String userId,
    String collection,
  ) {
    if (!_isInitialized || firestore == null) return null;
    return firestore!.collection('users').doc(userId).collection(collection);
  }
}
