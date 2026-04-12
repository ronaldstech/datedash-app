import 'package:datedash/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_service.dart';
import '../models/user_profile_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProfileService _profileService = ProfileService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '409694106333-8703fkvopn9me0nauro1ki5frbbmamld.apps.googleusercontent.com',
  );

  // Get user state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email & password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email & password
  Future<UserCredential?> signUpWithEmail(
      String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // Initialize user document in Firestore with name and 50 signup credits
        await _profileService.saveUserProfile(
            cred.user!.uid, UserProfile(firstName: name, credits: 50));

        // Log the signup reward
        await NotificationService().sendNotification(
          recipientId: cred.user!.uid,
          senderId: 'system',
          senderName: 'Datedash',
          type: 'reward',
          message: '🎁 Welcome bonus: 50 free credits added!',
        );
      }

      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      if (cred.user != null) {
        // Check if profile exists, if not initialize it
        final profile = await _profileService.getUserProfile(cred.user!.uid);
        if (profile == null) {
          await _profileService.saveUserProfile(cred.user!.uid,
              UserProfile(firstName: cred.user?.displayName, credits: 50));

          // Log the signup reward
          await NotificationService().sendNotification(
            recipientId: cred.user!.uid,
            senderId: 'system',
            senderName: 'Datedash',
            type: 'reward',
            message: '🎁 Welcome bonus: 50 free credits added!',
          );
        }
      }

      return cred;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
