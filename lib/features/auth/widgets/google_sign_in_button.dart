import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/feedback.dart';
import '../../../data/repositories/auth_repository.dart';
import '../session_cubit.dart';

/// "Continue with Google". Android's Credential Manager returns an ID token
/// whose audience is the *web* OAuth client (serverClientId); the backend
/// verifies it against GOOGLE_CLIENT_IDS like the web app's token.
///
/// Hidden unless GOOGLE_SERVER_CLIENT_ID is supplied at build time, because
/// it also needs an Android OAuth client (package + signing SHA-1) registered
/// in the same Google Cloud project — without that it can only fail.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  static bool get isEnabled => AppConfig.googleServerClientId.isNotEmpty;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  static Future<void>? _init;
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      _init ??= GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleServerClientId,
      );
      await _init;
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google returned no ID token');
      final user = await sl<AuthRepository>().signInWithGoogle(idToken);
      if (mounted) await context.read<SessionCubit>().signedIn(user);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        Toast.show(context, 'Google sign-in failed. Please try again.', error: true);
      }
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _busy ? null : _signIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                  const SizedBox(width: 10),
                  Text('Continue with Google', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
