import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lee y mantiene en memoria el rol del usuario actual desde /users/{uid}.
/// Acepta los campos `rol` o `role` y los normaliza a: 'client' | 'admin' | 'courier'.
class RoleProvider extends ChangeNotifier {
  String? _role; // null mientras carga
  String? get role => _role;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  RoleProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      // Reset al cambiar auth
      _userDocSub?.cancel();
      _role = null;
      notifyListeners();

      if (user == null) return;

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      _userDocSub = docRef.snapshots().listen((snap) {
        final data = snap.data();
        String normalized = 'client'; // default
        if (data != null) {
          final raw = (data['rol'] ?? data['role']) as String?;
          if (raw != null) {
            normalized = _normalizeRole(raw);
          }
        }
        _role = normalized;
        notifyListeners();
      });
    });
  }

  String _normalizeRole(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('admin')) return 'admin';
    if (v.contains('courier') || v.contains('domicili')) return 'courier';
    if (v.contains('client') || v.contains('cliente')) return 'client';
    return 'client';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
