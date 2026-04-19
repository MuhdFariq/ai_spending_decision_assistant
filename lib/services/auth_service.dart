import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get current user ID (Member C will need this)
  String? get currentUserId => _auth.currentUser?.uid;

  // 2. Stream to listen to login/logout (Main.dart will need this)
  Stream<User?> get userState => _auth.authStateChanges();

  // 3. Login Method (Stub)
  Future<void> login(String email, String password) async {
    // Member B/C can fill this in later
  }

  // 4. Logout
  Future<void> logout() async => await _auth.signOut();
}
