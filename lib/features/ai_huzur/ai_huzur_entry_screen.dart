import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ai_huzur_screen.dart';

class AiHuzurEntryScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const AiHuzurEntryScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<AiHuzurEntryScreen> createState() => _AiHuzurEntryScreenState();
}

class _AiHuzurEntryScreenState extends State<AiHuzurEntryScreen> {
  bool _signingIn = false;
  String? _errorMessage;

  Future<void> _signInWithApple() async {
    if (_signingIn) return;

    setState(() {
      _signingIn = true;
      _errorMessage = null;
    });

    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      await FirebaseAuth.instance.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        switch (error.code) {
          case 'canceled':
            _errorMessage = 'Giriş isteği iptal edildi.';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Apple girişi Firebase ayarlarında etkin değil.';
            break;
          case 'network-request-failed':
            _errorMessage =
                'Bağlantı kurulamadı. İnternet bağlantını kontrol et.';
            break;
          default:
            _errorMessage =
                'Apple ile giriş tamamlanamadı. Tekrar deneyebilirsin.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Beklenmeyen bir giriş hatası oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
    }
  }

  Widget _buildPanel({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
    Widget? footnote,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF100D09),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF100D09),
              Color(0xFF21170C),
              Color(0xFF100D09),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211B14),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFFFA21A).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFFFFA21A).withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFFFFC15A),
                          size: 39,
                        ),
                      ),
                      const SizedBox(height: 23),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 25),
                        action,
                      ],
                      if (footnote != null) ...[
                        const SizedBox(height: 18),
                        footnote,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPage() {
    return _buildPanel(
      icon: Icons.auto_awesome_rounded,
      title: 'Huzur Dini Asistan',
      message: 'Dini asistanı kullanmak için Apple hesabınla giriş yap. '
          'Huzur uygulamasının diğer bölümlerini hesabın olmadan '
          'kullanmaya devam edebilirsin.',
      action: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _signingIn ? null : _signInWithApple,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _signingIn
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Apple ile devam et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      footnote: _errorMessage == null
          ? const Text(
              'Giriş işlemi Apple tarafından yürütülür. '
              'Hesap oturumu Firebase Authentication ile yönetilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.45,
              ),
            )
          : Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF9B85),
                fontSize: 12,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF100D09),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFA21A),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildPanel(
            icon: Icons.error_outline_rounded,
            title: 'Oturum kontrol edilemedi',
            message: 'Firebase oturumu kontrol edilirken bir hata oluştu. '
                'Lütfen tekrar dene.',
          );
        }

        final currentUser = snapshot.data;
        final hasAppleSignIn = currentUser?.providerData.any(
              (info) => info.providerId == 'apple.com',
            ) ??
            false;

        if (!hasAppleSignIn) {
          return _buildSignInPage();
        }

        // Yaş aralığı kontrolü tamamlanmadan AI sohbeti açılmaz.
        return AiHuzurScreen(
          onNavigateToTab: widget.onNavigateToTab,
        );
      },
    );
  }
}
