import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/huzur_api_service.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../paywall/liquid_glass_paywall.dart';

class DuaCommunityPanel extends ConsumerStatefulWidget {
  const DuaCommunityPanel({super.key});

  @override
  ConsumerState<DuaCommunityPanel> createState() => _DuaCommunityPanelState();
}

class _DuaCommunityPanelState extends ConsumerState<DuaCommunityPanel> {
  static const _gold = Color(0xFFFFCE78);
  static const _turquoise = Color(0xFF75DCCF);
  static const _panel = Color(0xFF121F20);

  final HuzurApiService _api = HuzurApiService();
  final TextEditingController _bodyController = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  final Set<String> _busyPosts = {};

  bool _loading = true;
  bool _sending = false;
  bool _checkingPremium = false;
  String? _error;

  bool get _signedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _api.getDuaPosts();
      final raw = response['posts'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        _posts =
            raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Dualar şu anda yüklenemedi.';
      });
      debugPrint('Huzur dua akışı: $error');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDuaComposer() async {
    if (_checkingPremium) return;

    if (!_signedIn) {
      _message('Dua bırakmak için önce Apple hesabınla giriş yapmalısın.');
      return;
    }

    setState(() => _checkingPremium = true);

    try {
      final premium = ref.read(premiumServiceProvider.notifier);

      // First check the locally verified StoreKit 2 entitlement.
      final hasAppleEntitlement = await premium.ensureStoreKitPremiumAccess();
      if (!mounted) return;

      if (!hasAppleEntitlement) {
        await LiquidGlassPaywallSheet.show(context);
        return;
      }

      // Premium yetkisi Apple StoreKit 2 tarafından cihazda
      // doğrulandı. Burada ikinci bir Firebase Premium kontrolü yok.
      // Dua API'si Firebase Auth ve App Check ile korunmaya devam eder.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.68),
        builder: (sheetContext) => _buildComposerSheet(sheetContext),
      );
    } catch (error) {
      _message('Premium kontrolü tamamlanamadı. Tekrar deneyebilirsin.');
      debugPrint('Huzur Dua Premium kontrolü: $error');
    } finally {
      if (mounted) setState(() => _checkingPremium = false);
    }
  }

  Widget _buildComposerSheet(BuildContext sheetContext) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF101A1D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: _gold.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: _gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dua bırak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gönlünden geçen duayı dünyayla paylaş.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold.withValues(alpha: 0.25)),
                    ),
                    child: const Text(
                      'HUZUR ÖZEL',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bodyController,
                autofocus: true,
                minLines: 5,
                maxLines: 8,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Duanı buraya yaz...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  counterStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.045),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _gold),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Paylaşmadan önce kişisel bilgilerini ve başkalarını tanımlayan '
                'ayrıntıları eklemediğinden emin ol.',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, height: 1.45),
              ),
              const SizedBox(height: 17),
              FilledButton.icon(
                onPressed: _sending ? null : () => _createPost(sheetContext),
                icon: _sending
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF17120A),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 17),
                label: Text(_sending ? 'Paylaşılıyor...' : 'Duanı paylaş'),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF17120A),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPost(BuildContext sheetContext) async {
    final body = _bodyController.text.trim();

    if (!_signedIn) {
      _message('Dua paylaşmak için Apple hesabınla giriş yapmalısın.');
      return;
    }

    if (body.isEmpty) {
      _message('Önce dua metnini yazmalısın.');
      return;
    }

    if (body.length > 500) {
      _message('Dua metni en fazla 500 karakter olabilir.');
      return;
    }

    setState(() => _sending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final countryCode = prefs.getString('huzur_world_country_code') ?? 'TR';

      await _api.createDuaPost(
        body: body,
        countryCode: countryCode,
      );

      if (!mounted) return;
      _bodyController.clear();
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      _message('Duan paylaşıldı.');
      await _loadPosts();
    } catch (error) {
      _message(
        error is HuzurApiException && error.statusCode == 429
            ? 'Saatlik paylaşım sınırına ulaştın.'
            : error is HuzurApiException && error.statusCode == 403
                ? 'Dua paylaşımı için sunucu Premium erişimini doğrulamalı.'
                : 'Dua paylaşılamadı. Tekrar deneyebilirsin.',
      );
      debugPrint('Huzur dua paylaşımı: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _amen(String postId) async {
    if (!_signedIn) {
      _message('Âmin demek için Apple hesabınla giriş yapmalısın.');
      return;
    }

    if (_busyPosts.contains(postId)) return;
    setState(() => _busyPosts.add(postId));

    try {
      final result = await _api.amenDuaPost(postId);
      // Older API builds returned aminCount; current builds return amin_count.
      final count = ((result['amin_count'] ?? result['aminCount']) as num?)
              ?.toInt() ??
          0;

      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere(
          (post) => post['id']?.toString() == postId,
        );
        if (index >= 0) {
          _posts[index] = {
            ..._posts[index],
            'amin_count': count,
          };
        }
      });

      _message(
        result['duplicate'] == true || result['added'] == false
            ? 'Bu duaya daha önce Âmin demiştin.'
            : 'Âmin. Allah kabul etsin.',
      );
    } catch (error) {
      if (error is HuzurApiException &&
          error.apiCode == 'cannot_amin_own_dua') {
        _message('Kendi duana Âmin yerine başka dualara destek olabilirsin.');
      } else if (error is HuzurApiException && error.statusCode == 429) {
        _message('Çok sık Âmin işlemi yaptın. Biraz sonra tekrar dene.');
      } else if (error is HuzurApiException && error.statusCode == 404) {
        _message('Bu dua artık yayında değil. Duaları yenile.');
      } else {
        _message('Âmin işlemi gerçekleştirilemedi. Lütfen tekrar dene.');
      }
      debugPrint('Huzur Âmin işlemi: $error');
    } finally {
      if (mounted) setState(() => _busyPosts.remove(postId));
    }
  }

  Future<void> _report(String postId, String reason) async {
    if (!_signedIn) {
      _message('Şikâyet için Apple hesabınla giriş yapmalısın.');
      return;
    }

    if (_busyPosts.contains(postId)) return;
    setState(() => _busyPosts.add(postId));

    try {
      final result = await _api.reportDuaPost(
        postId: postId,
        reason: reason,
      );

      if (!mounted) return;

      if (result['duplicate'] == true) {
        _message('Bu duayı daha önce şikâyet etmişsin.');
      } else {
        _message('Bildirimin alındı. Teşekkür ederiz.');
      }

      if (result['hidden'] == true) {
        await _loadPosts();
      }
    } catch (error) {
      _message('Şikâyet gönderilemedi.');
      debugPrint('Huzur dua şikâyeti: $error');
    } finally {
      if (mounted) setState(() => _busyPosts.remove(postId));
    }
  }

  Future<void> _blockUser(String publicId) async {
    if (!_signedIn) {
      _message('Kullanıcı engellemek için Apple hesabınla giriş yapmalısın.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kullanıcıyı engelle?'),
        content: const Text(
          'Bu kullanıcının duaları senin topluluk akışında gösterilmeyecek. '
          'Engeli daha sonra kaldırabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.blockDuaUser(publicId);
      _message('Kullanıcı engellendi.');
      await _loadPosts();
    } catch (error) {
      _message('Kullanıcı engellenemedi. Tekrar deneyebilirsin.');
      debugPrint('Huzur kullanıcı engelleme: $error');
    }
  }

  Future<void> _deleteOwnPost(String postId) async {
    if (!_signedIn) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Duan silinsin mi?'),
        content: const Text(
          'Bu dua topluluk akışından ve Huzur sunucusundaki ilişkili '
          'Âmin ve şikâyet kayıtlarıyla birlikte kalıcı olarak silinir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Duanı sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.deleteDuaPost(postId);
      _message('Duan silindi.');
      await _loadPosts();
    } catch (error) {
      _message('Dua silinemedi. Tekrar deneyebilirsin.');
      debugPrint('Huzur dua silme: $error');
    }
  }

  Future<void> _manageBlockedUsers() async {
    if (!_signedIn) return;

    try {
      final response = await _api.getBlockedDuaUsers();
      final blocked = (response['blocked_users'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      if (blocked.isEmpty) {
        _message('Engellediğin kullanıcı bulunmuyor.');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFF101A1D),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Engellenen kullanıcılar',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: blocked.length,
                    itemBuilder: (context, index) {
                      final publicId =
                          blocked[index]['public_id']?.toString() ?? '';
                      final shortId = publicId.length > 8
                          ? publicId.substring(0, 8)
                          : publicId;
                      return ListTile(
                        title: const Text(
                          'Huzur kullanıcısı',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Kullanıcı kodu: $shortId',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: TextButton(
                          onPressed: publicId.isEmpty
                              ? null
                              : () async {
                                  try {
                                    await _api.unblockDuaUser(publicId);
                                    setSheetState(
                                        () => blocked.removeAt(index));
                                    if (mounted) await _loadPosts();
                                    if (blocked.isEmpty &&
                                        sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                    _message('Kullanıcı engeli kaldırıldı.');
                                  } catch (error) {
                                    _message('Engel kaldırılamadı.');
                                    debugPrint('Huzur engel kaldırma: $error');
                                  }
                                },
                          child: const Text('Engeli kaldır'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      _message('Engellenen kullanıcılar yüklenemedi.');
      debugPrint('Huzur engellenen kullanıcılar: $error');
    }
  }

  String _timeLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month $hour:$minute';
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DUA BIRAK',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              if (_signedIn)
                IconButton(
                  onPressed: _manageBlockedUsers,
                  tooltip: 'Engellenen kullanıcıları yönet',
                  icon: const Icon(
                    Icons.block_rounded,
                    color: Colors.white54,
                  ),
                ),
              IconButton(
                onPressed: _loading ? null : _loadPosts,
                tooltip: 'Duaları yenile',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: _turquoise,
                ),
              ),
            ],
          ),
          const Text(
            'Bir dua paylaş, güzel bir duaya Âmin de.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _gold.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: _gold),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duanı dünyayla paylaş',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Huzur Özel üyelerine açık',
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_rounded, color: _gold, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _checkingPremium ? null : _openDuaComposer,
            icon: _checkingPremium
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF17120A),
                    ),
                  )
                : const Icon(Icons.volunteer_activism_rounded, size: 17),
            label:
                Text(_checkingPremium ? 'Erişim doğrulanıyor...' : 'Dua bırak'),
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF17120A),
              minimumSize: const Size(double.infinity, 47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (!_signedIn) ...[
            const SizedBox(height: 9),
            const Text(
              'Dua paylaşmak için Apple hesabınla giriş ve Huzur Özel '
              'üyeliği gerekir. Topluluk dualarını okuyabilir, Âmin diyebilir '
              've uygunsuz içerikleri bildirebilirsin.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const Divider(color: Colors.white12, height: 29),
          const Text(
            'TOPLULUK DUALARI',
            style: TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(color: _gold),
              ),
            )
          else if (_error != null)
            Column(
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: _loadPosts,
                  child: const Text(
                    'Tekrar dene',
                    style: TextStyle(color: _gold),
                  ),
                ),
              ],
            )
          else if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Henüz dua paylaşılmamış. İlk duayı sen bırakabilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            )
          else
            ..._posts.map(_buildPostCard),
          const SizedBox(height: 10),
          const Text(
            'Paylaşımlar herkese açıktır ve 24 saat sonra yayından kalkar. '
            'Kişisel bilgi, bağlantı, hakaret, taciz ve nefret söylemi yasaktır. '
            'Uygunsuz içeriği şikâyet edebilir, kullanıcıları engelleyebilirsin.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final id = post['id']?.toString() ?? '';
    final country = post['country_name']?.toString() ?? 'Dünya';
    final code = post['country_code']?.toString() ?? '';
    final body = post['body']?.toString() ?? '';
    final count = (post['amin_count'] as num?)?.toInt() ?? 0;
    final time = _timeLabel(post['created_at']);

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                color: _turquoise,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  code.isEmpty ? country : '$country ($code)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Şikâyet et veya engelle',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white54,
                ),
                color: const Color(0xFF1B2B2C),
                onSelected: (action) {
                  if (action == 'block') {
                    final publicId = post['author_public_id']?.toString();
                    if (publicId != null && publicId.isNotEmpty) {
                      _blockUser(publicId);
                    }
                  } else if (action == 'delete') {
                    _deleteOwnPost(id);
                  } else {
                    _report(id, action);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'spam',
                    child: Text('Spam'),
                  ),
                  const PopupMenuItem(
                    value: 'inappropriate',
                    child: Text('Uygunsuz içerik'),
                  ),
                  const PopupMenuItem(
                    value: 'personal_information',
                    child: Text('Kişisel bilgi'),
                  ),
                  const PopupMenuItem(
                    value: 'harassment',
                    child: Text('Taciz veya hedef gösterme'),
                  ),
                  const PopupMenuItem(
                    value: 'other',
                    child: Text('Diğer'),
                  ),
                  if (_signedIn && post['is_mine'] != true)
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Kullanıcıyı engelle'),
                    ),
                  if (_signedIn && post['is_mine'] == true)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Kendi duanı sil'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          if (post['is_mine'] == true)
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(
                Icons.favorite_rounded,
                color: _gold,
                size: 17,
              ),
              label: Text('Kendi duan  ·  $count'),
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: _gold,
                side: BorderSide(color: _gold.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _busyPosts.contains(id) ? null : () => _amen(id),
              icon: const Icon(
                Icons.favorite_rounded,
                color: _gold,
                size: 17,
              ),
              label: Text('Âmin  ·  $count'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: BorderSide(color: _gold.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
