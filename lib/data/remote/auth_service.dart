import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';
import 'firebase_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthService(firebaseService);
});

class AuthService {
  final FirebaseService _firebaseService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keySessionUser = 'session_user_profile';
  static const String _keyMockUsers = 'mock_registered_users';

  AuthService(this._firebaseService);

  bool get isFirebaseActive => _firebaseService.isConfigured;

  // Stream current user or null
  Stream<UserProfileModel?> authStateChanges() async* {
    if (isFirebaseActive) {
      await for (final user in FirebaseAuth.instance.authStateChanges()) {
        if (user == null) {
          yield null;
        } else {
          yield UserProfileModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Student',
            photoUrl: user.photoURL,
            createdAt: user.metadata.creationTime ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
    } else {
      // Local session persistence
      final storedUserJson = await _secureStorage.read(key: _keySessionUser);
      if (storedUserJson != null) {
        try {
          final map = jsonDecode(storedUserJson) as Map<String, dynamic>;
          yield UserProfileModel.fromMap(map);
        } catch (_) {
          yield null;
        }
      } else {
        yield null;
      }
    }
  }

  Future<UserProfileModel?> getCurrentUser() async {
    if (isFirebaseActive) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String displayName = user.displayName ?? '';
        String? photoUrl = user.photoURL;
        int dailyGoal = 120;

        if (_firebaseService.firestore != null) {
          try {
            final doc = await _firebaseService.firestore!
                .collection('users')
                .doc(user.uid)
                .get();
            if (doc.exists && doc.data() != null) {
              final d = doc.data()!;
              if ((d['displayName'] as String?)?.isNotEmpty == true) {
                displayName = d['displayName'] as String;
              }
              if ((d['photoUrl'] as String?)?.isNotEmpty == true) {
                photoUrl = d['photoUrl'] as String;
              }
              if (d['dailyGoalMinutes'] != null) {
                dailyGoal = (d['dailyGoalMinutes'] as num).toInt();
              }
            }
          } catch (_) {}
        }

        if (displayName.isEmpty) {
          displayName = (user.email?.split('@').first) ?? 'Student';
        }

        final profile = UserProfileModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          photoUrl: photoUrl,
          dailyGoalMinutes: dailyGoal,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(profile.toMap()),
        );

        return profile;
      }
      return null;
    } else {
      final storedUserJson = await _secureStorage.read(key: _keySessionUser);
      if (storedUserJson != null) {
        try {
          final map = jsonDecode(storedUserJson) as Map<String, dynamic>;
          return UserProfileModel.fromMap(map);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<UserProfileModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (isFirebaseActive) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
        final user = credential.user;
        if (user == null) {
          throw const AuthException('Registration failed. Please try again.');
        }

        await user.updateDisplayName(name.trim());
        await user.sendEmailVerification();

        final profile = UserProfileModel(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: name.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (_firebaseService.firestore != null) {
          try {
            await _firebaseService.firestore!
                .collection('users')
                .doc(user.uid)
                .set(profile.toMap(), SetOptions(merge: true));
          } catch (e) {
            debugPrint('Error syncing profile to Firestore: $e');
          }
        }

        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(profile.toMap()),
        );

        return profile;
      } else {
        // Secure local account registration
        final users = await _getStoredUsers();
        final cleanEmail = email.trim().toLowerCase();
        if (users.containsKey(cleanEmail)) {
          throw const AuthException(
            'An account already exists with this email address.',
          );
        }

        final uid = 'local_user_${DateTime.now().millisecondsSinceEpoch}';
        final profile = UserProfileModel(
          uid: uid,
          email: email.trim(),
          displayName: name.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        users[cleanEmail] = {'password': password, 'profile': profile.toMap()};

        await _secureStorage.write(
          key: _keyMockUsers,
          value: jsonEncode(users),
        );
        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(profile.toMap()),
        );

        return profile;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'An unexpected error occurred during registration: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _getStoredUsers() async {
    final mockUsersJson = await _secureStorage.read(key: _keyMockUsers);
    Map<String, dynamic> users = {};
    if (mockUsersJson != null) {
      try {
        users = jsonDecode(mockUsersJson) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (users.isEmpty) {
      final userAman = UserProfileModel(
        uid: 'user_aman_default',
        email: 'aman@studymate.app',
        displayName: 'Aman',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final userRahul = UserProfileModel(
        uid: 'user_rahul_default',
        email: 'rahul@studymate.app',
        displayName: 'Rahul',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      users['aman@studymate.app'] = {
        'password': '123',
        'profile': userAman.toMap(),
      };
      users['rahul@studymate.app'] = {
        'password': '123',
        'profile': userRahul.toMap(),
      };
      await _secureStorage.write(key: _keyMockUsers, value: jsonEncode(users));
    }
    return users;
  }

  Future<UserProfileModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (isFirebaseActive) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
        final user = credential.user;
        if (user == null) throw const AuthException('Sign in failed.');

        String displayName = user.displayName ?? '';
        String? photoUrl = user.photoURL;
        int dailyGoal = 120;

        if (_firebaseService.firestore != null) {
          try {
            final doc = await _firebaseService.firestore!
                .collection('users')
                .doc(user.uid)
                .get();
            if (doc.exists && doc.data() != null) {
              final d = doc.data()!;
              if ((d['displayName'] as String?)?.isNotEmpty == true) {
                displayName = d['displayName'] as String;
              }
              if ((d['photoUrl'] as String?)?.isNotEmpty == true) {
                photoUrl = d['photoUrl'] as String;
              }
              if (d['dailyGoalMinutes'] != null) {
                dailyGoal = (d['dailyGoalMinutes'] as num).toInt();
              }
            }
          } catch (_) {}
        }
        if (displayName.isEmpty) {
          displayName = email.split('@').first;
        }

        final profile = UserProfileModel(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: displayName,
          photoUrl: photoUrl,
          dailyGoalMinutes: dailyGoal,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(profile.toMap()),
        );

        return profile;
      } else {
        // Secure local login validation
        final users = await _getStoredUsers();
        final cleanEmail = email.trim().toLowerCase();

        if (!users.containsKey(cleanEmail)) {
          throw const AuthException(
            'No registered account found with this email. Please sign up first.',
          );
        }

        final userData = users[cleanEmail] as Map<String, dynamic>;
        if (userData['password'] != password) {
          throw const AuthException('Invalid password. Please try again.');
        }

        final profile = UserProfileModel.fromMap(
          userData['profile'] as Map<String, dynamic>,
        );
        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(profile.toMap()),
        );
        return profile;
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (isFirebaseActive) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      } else {
        // Check if user exists
        final mockUsersJson = await _secureStorage.read(key: _keyMockUsers);
        if (mockUsersJson != null) {
          final users = jsonDecode(mockUsersJson) as Map<String, dynamic>;
          if (!users.containsKey(email.trim().toLowerCase())) {
            throw const AuthException(
              'No account found with this email address.',
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to send reset email: $e');
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account registered with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few moments.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      if (isFirebaseActive) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
        }
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
    int? dailyGoalMinutes,
  }) async {
    try {
      if (isFirebaseActive) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(displayName);
          if (photoUrl != null) await user.updatePhotoURL(photoUrl);

          if (_firebaseService.firestore != null) {
            try {
              await _firebaseService.firestore!
                  .collection('users')
                  .doc(user.uid)
                  .set({
                    'uid': user.uid,
                    'email': user.email ?? '',
                    'displayName': displayName,
                    'photoUrl': ?photoUrl,
                    'dailyGoalMinutes': ?dailyGoalMinutes,
                    'updatedAt': DateTime.now().toIso8601String(),
                  }, SetOptions(merge: true));
            } catch (e) {
              debugPrint('Warning: Cloud profile sync: $e');
            }
          }
        }
      }

      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updated = currentUser.copyWith(
          displayName: displayName,
          photoUrl: photoUrl,
          dailyGoalMinutes: dailyGoalMinutes,
          updatedAt: DateTime.now(),
        );
        await _secureStorage.write(
          key: _keySessionUser,
          value: jsonEncode(updated.toMap()),
        );
      }
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (isFirebaseActive) {
        await FirebaseAuth.instance.signOut();
      }
      await _secureStorage.delete(key: _keySessionUser);
    } catch (e) {
      throw AuthException('Failed to log out: $e');
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      if (isFirebaseActive) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);
          await user.delete();
        }
      } else {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final mockUsersJson = await _secureStorage.read(key: _keyMockUsers);
          if (mockUsersJson != null) {
            final users = jsonDecode(mockUsersJson) as Map<String, dynamic>;
            final cleanEmail = currentUser.email.toLowerCase();
            if (users.containsKey(cleanEmail)) {
              final userData = users[cleanEmail] as Map<String, dynamic>;
              if (userData['password'] != password) {
                throw const AuthException(
                  'Incorrect password for account deletion.',
                );
              }
              users.remove(cleanEmail);
              await _secureStorage.write(
                key: _keyMockUsers,
                value: jsonEncode(users),
              );
            }
          }
        }
      }
      await _secureStorage.delete(key: _keySessionUser);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ?? 'Account deletion failed.',
        code: e.code,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to delete account: $e');
    }
  }
}
