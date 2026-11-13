import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/huzur_api_service.dart';

class DuaCommunityPanel extends StatefulWidget {
  const DuaCommunityPanel({super.key});

  @override
  State<DuaCommunityPanel> createState() => _DuaCommunityPanelState();
}

class _DuaCommunityPanelState extends State<DuaCommunityPanel> {
  static const _gold = Color(0xFFFFCE78);
  static const _turquoise = Color(0xFF75DCCF);
  static const _panel = Color(0xFF121F20);

  final HuzurApiService _api = HuzurApiService();
  final TextEditingController _bodyController = TextEditingController();

  List<Map<String, dynamic>> _posts = [];
  final Set<String> _busyPosts = {};

  bool _loading = true;
  bool _sending = false;
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
        _posts = raw
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
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

  Future<void> _createPost() async {
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
      final countryCode =
          prefs.getString('huzur_world_country_code') ?? 'TR';

      await _api.createDuaPost(
        body: body,
        countryCode: countryCode,
      );

      if (!mounted) return;
      _bodyController.clear();
      _message('Duan paylaşıldı.');
      await _loadPosts();
    } catch (error) {
      _message(
        error is HuzurApiException && error.statusCode == 429
            ? 'Saatlik paylaşım sınırına ulaştın.'
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
      final count = (result['amin_count'] as num?)?.toInt() ?? 0;

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
        result['duplicate'] == true
            ? 'Bu duaya daha önce Âmin demiştin.'
            : 'Âmin. Allah kabul etsin.',
      );
    } catch (error) {
      _message('Âmin işlemi gerçekleştirilemedi.');
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
          const SizedBox(height: 13),
          TextField(
            controller: _bodyController,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Duanı buraya yaz...',
              hintStyle: const TextStyle(color: Colors.white38),
              counterStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.045),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _sending ? null : _createPost,
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
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
          if (!_signedIn) ...[
            const SizedBox(height: 9),
            const Text(
              'Dua paylaşmak, Âmin demek ve şikâyet etmek için '
              'mevcut Apple hesabınla giriş yapmalısın.',
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
            'Uygunsuz içerikleri şikâyet edebilirsin.',
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
                tooltip: 'Şikâyet et',
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white54,
                ),
                color: const Color(0xFF1B2B2C),
                onSelected: (reason) => _report(id, reason),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'spam',
                    child: Text('Spam'),
                  ),
                  PopupMenuItem(
                    value: 'inappropriate',
                    child: Text('Uygunsuz içerik'),
                  ),
                  PopupMenuItem(
                    value: 'other',
                    child: Text('Diğer'),
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
