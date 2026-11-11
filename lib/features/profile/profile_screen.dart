import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ai_huzur/ai_privacy_consent.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;
  String? _consentUid;
  Future<bool>? _consentFuture;

  UserInfo? _appleInfo(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'apple.com') return info;
    }
    return null;
  }

  String _displayName(User user) {
    final apple = _appleInfo(user);
    final value = (user.displayName ?? apple?.displayName ?? '').trim();
    return value.isEmpty ? 'Ad bilgisi Apple tarafından paylaşılmadı' : value;
  }

  String _email(User user) {
    final apple = _appleInfo(user);
    final value = (user.email ?? apple?.email ?? '').trim();
    return value.isEmpty ? 'E-posta bilgisi bulunamadı' : value;
  }

  Future<bool> _consentFor(String uid) {
    if (_consentUid != uid || _consentFuture == null) {
      _consentUid = uid;
      _consentFuture = AiPrivacyConsent.hasConsent(uid);
    }
    return _consentFuture!;
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _signInWithApple() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      await FirebaseAuth.instance.signInWithProvider(provider);
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'canceled'
          ? 'Giriş işlemi iptal edildi.'
          : 'Apple ile giriş tamamlanamadı. Lütfen tekrar dene.';
      _message(message);
    } catch (_) {
      _message('Giriş sırasında beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeConsent(User user, bool enabled) async {
    if (_busy) return;

    try {
      if (enabled) {
        final accepted = await AiPrivacyConsent.ensureConsent(
          context,
          user.uid,
        );
        if (!mounted) return;

        setState(() {
          _consentFuture = Future<bool>.value(accepted);
        });

        _message(
          accepted
              ? 'AI veri aktarım iznin kaydedildi.'
              : 'AI veri aktarım izni verilmedi.',
        );
      } else {
        await AiPrivacyConsent.setConsent(user.uid, false);
        if (!mounted) return;

        setState(() {
          _consentFuture = Future<bool>.value(false);
        });

        _message(
          'İzin geri çekildi. Yeni AI istekleri gönderilmeyecek.',
        );
      }
    } catch (_) {
      _message('Gizlilik tercihin kaydedilemedi. Tekrar dene.');
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _message('Oturum kapatılamadı. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(User user) async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF211B14),
          title: const Text(
            'Hesabın silinsin mi?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Huzur hesabın ve geliştiricinin kontrolündeki '
            'hesap verilerin silinecek. Apple ile giriş yetkin de '
            'iptal edilecek. Bu işlem Huzur Özel aboneliğini iptal etmez. '
            'Otomatik yenilenen aboneliğin varsa Apple hesabının '
            'Ayarlar > Abonelikler bölümünden ayrıca iptal et. '
            'Bu işlem geri alınamaz. Cihazdaki diğer Huzur kayıtların '
            'ayrıca etkilenmez.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB64235),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hesabı sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      // Apple'dan yeni bir yetkilendirme kodu al.
      final reauthenticated = await user.reauthenticateWithProvider(provider);

      final authorizationCode =
          reauthenticated.additionalUserInfo?.authorizationCode?.trim();

      if (authorizationCode == null || authorizationCode.isEmpty) {
        throw StateError(
          'Apple yetkilendirme kodu alınamadı. Hesap silinmedi.',
        );
      }

      // Önce Sign in with Apple yetkisini iptal et.
      await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
        authorizationCode,
      );

      // Ardından Firebase Authentication hesabını sil.
      await user.delete();

      // Bu hesaba ait yerel AI iznini ve AI kullanım sayacını temizle.
      await AiPrivacyConsent.clearForAccount(user.uid);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'requires-recent-login'
          ? 'Güvenlik doğrulaması gerekli. Yeniden deneyebilirsin.'
          : 'Hesap silme tamamlanamadı (${error.code}). Tekrar dene.';
      _message(message);
    } catch (error) {
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSignedOut() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 45),
        _card(
          Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFA21A).withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFFFC15A),
                  size: 39,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Huzur Profilim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Profil bilgilerini ve AI gizlilik tercihlerini '
                'görüntülemek için Apple hesabınla giriş yap. '
                'Huzur’un diğer bölümlerini giriş yapmadan '
                'kullanmaya devam edebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: Text(
                    _busy ? 'Bağlanıyor...' : 'Apple ile devam et',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignedIn(User user) {
    final name = _displayName(user);
    final email = _email(user);
    final consentFuture = _consentFor(user.uid);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFD27A),
                          Color(0xFFFFA21A),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF20170D),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'E-POSTA ADRESİ',
                style: TextStyle(
                  color: Color(0xFFFFC15A),
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              SelectableText(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apple e-posta adresini gizlemeyi seçtiyse, '
                'Apple tarafından sağlanan yönlendirme adresi burada '
                'aynen gösterilir.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFFC15A),
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'AI gizlilik tercihleri',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Soru metninin, seçtiğin görsellerin ve gerekli sohbet '
                'bağlamının Google tarafından sunulan yapay zekâ hizmetine aktarılmasına '
                'verdiğin izni buradan yönetebilirsin.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<bool>(
                future: consentFuture,
                builder: (context, snapshot) {
                  final ready =
                      snapshot.connectionState == ConnectionState.done;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: snapshot.data ?? false,
                    onChanged: ready && !_busy
                        ? (value) => _changeConsent(user, value)
                        : null,
                    activeThumbColor: const Color(0xFFFFA21A),
                    title: Text(
                      snapshot.data == true ? 'İzin açık' : 'İzin kapalı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: const Text(
                      'İzni kapatırsan yeni AI isteği gönderilmez.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Oturumu kapat',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: _busy ? null : _signOut,
              ),
              Divider(color: Colors.white.withValues(alpha: 0.12)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFFF8175),
                ),
                title: const Text(
                  'Hesabımı sil',
                  style: TextStyle(
                    color: Color(0xFFFF8175),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Huzur hesabını ve ilişkili giriş bilgilerini kalıcı olarak siler.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                onTap: _busy ? null : () => _deleteAccount(user),
              ),
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 18),
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFA21A),
              strokeWidth: 2,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100D09),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profilim',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFA21A),
                ),
              );
            }

            final user = snapshot.data;
            final hasAppleSignIn = user?.providerData.any(
                  (info) => info.providerId == 'apple.com',
                ) ??
                false;

            if (user == null || !hasAppleSignIn) {
              return _buildSignedOut();
            }

            return _buildSignedIn(user);
          },
        ),
      ),
    );
  }
}
