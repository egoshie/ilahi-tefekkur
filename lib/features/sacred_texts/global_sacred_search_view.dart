import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/global_sacred_search_service.dart';

class GlobalSacredSearchView extends StatefulWidget {
  final String query;
  final bool includeBible;
  final ValueChanged<GlobalSacredSearchResult> onOpen;

  const GlobalSacredSearchView({
    super.key,
    required this.query,
    required this.includeBible,
    required this.onOpen,
  });

  @override
  State<GlobalSacredSearchView> createState() => _GlobalSacredSearchViewState();
}

class _GlobalSacredSearchViewState extends State<GlobalSacredSearchView> {
  Timer? _debounce;
  late Future<List<GlobalSacredSearchResult>> _future;

  Future<List<GlobalSacredSearchResult>> _search() {
    if (widget.query.trim().length < 2) {
      return Future.value(const []);
    }
    return GlobalSacredSearchService().search(
      widget.query,
      includeBible: widget.includeBible,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = _search();
  }

  @override
  void didUpdateWidget(covariant GlobalSacredSearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.includeBible != widget.includeBible) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _future = _search());
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.trim().length < 2) {
      return const Center(
        child: Text(
          'Kur’an, sure adı ve kayıtlı kitap metinlerinde aramak için en az 2 harf yazın.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }

    return FutureBuilder<List<GlobalSacredSearchResult>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Arama sırasında bir sorun oluştu.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'Kayıtlı metinlerde eşleşme bulunamadı.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => widget.onOpen(item),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.tradition,
                            style: const TextStyle(
                              color: Color(0xFF64FFDA),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.originalText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.originalText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.7,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        item.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
