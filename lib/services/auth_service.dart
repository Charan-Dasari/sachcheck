import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email/Password Sign-Up ───────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Set display name
    await credential.user?.updateDisplayName(displayName);
    await credential.user?.reload();

    // Create Firestore user profile
    await _createUserProfile(
      uid: credential.user!.uid,
      displayName: displayName,
      email: email,
    );

    return credential;
  }

  // ── Email/Password Sign-In ───────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Create Firestore profile if first time
    final doc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (!doc.exists) {
      await _createUserProfile(
        uid: userCredential.user!.uid,
        displayName: userCredential.user?.displayName ?? 'User',
        email: userCredential.user?.email ?? '',
      );
    }

    return userCredential;
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Password Reset ───────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Firestore User Profile ───────────────────────────────────────────────
  Future<void> _createUserProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'totalVerifications': 0,
      'verifiedCount': 0,
      'cautionCount': 0,
      'notVerifiedCount': 0,
    });
  }

  /// Increments the user's verification stats in Firestore.
  Future<void> updateVerificationStats(String verdict) async {
    final user = currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {
      'totalVerifications': FieldValue.increment(1),
    };

    switch (verdict) {
      case 'verified':
        updates['verifiedCount'] = FieldValue.increment(1);
        break;
      case 'needs_caution':
        updates['cautionCount'] = FieldValue.increment(1);
        break;
      case 'not_verified':
        updates['notVerifiedCount'] = FieldValue.increment(1);
        break;
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  /// Returns the user's profile data from Firestore.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Streams the user's profile data for real-time updates.
  Stream<Map<String, dynamic>?> userProfileStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.data());
  }
}
