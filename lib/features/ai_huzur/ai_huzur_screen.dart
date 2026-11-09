import "package:flutter/material.dart";
import "package:firebase_ai/firebase_ai.dart";
import "../../core/theme/glass_container.dart";

const _systemPrompt =
    "Sen Huzur uygulamasının dini konulara odaklanan yapay zeka rehberisin. "
    "Yalnızca din, inanç, ibadet, kutsal metinler, dinler tarihi, dini ahlak "
    "ve karşılaştırmalı din konularında yardımcı ol. Konu dışı sorulara "
    "nazikçe Huzur AI uygulamasının yalnızca dini sorular için olduğunu söyle. "
    "Türkçe, anlaşılır, saygılı ve tarafsız cevap ver. Ayet veya hadis "
    "kaynağı uydurma. Emin olmadığın bilgiyi açıkça belirt. Kesin fetva "
    "verme; gerektiğinde yetkin bir din uzmanına danışılmasını öner.";

class AiHuzurScreen extends StatefulWidget {
  const AiHuzurScreen({super.key});

  @override
  State<AiHuzurScreen> createState() => _AiHuzurScreenState();
}

class _AiHuzurScreenState extends State<AiHuzurScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: "Selam. Ben Huzur AI. Din, inanç, ibadet ve kutsal metinler "
          "hakkındaki sorularını birlikte inceleyebiliriz. Sana nasıl "
          "yardımcı olabilirim?",
      isUser: false,
    ),
  ];

  ChatSession? _chat;
  bool _sending = false;

  ChatSession get _session {
    if (_chat != null) return _chat!;
    final model = FirebaseAI.googleAI().generativeModel(
      model: "gemini-3.5-flash-lite",
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 900,
      ),
    );
    _chat = model.startChat();
    return _chat!;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;

    _input.clear();
    final answerIndex = _messages.length + 1;

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _messages.add(_ChatMessage(
        text: "",
        isUser: false,
        isTyping: true,
      ));
      _sending = true;
    });
    _scrollToBottom();

    try {
      await for (final chunk
          in _session.sendMessageStream(Content.text(question))) {
        if (!mounted) return;
        final part = chunk.text ?? "";
        if (part.isEmpty) continue;

        setState(() {
          _messages[answerIndex].text += part;
          _messages[answerIndex].isTyping = false;
        });
        _scrollToBottom();
      }

      if (mounted && _messages[answerIndex].text.isEmpty) {
        setState(() {
          _messages[answerIndex].isTyping = false;
          _messages[answerIndex].text =
              "Bu soruya şu anda yanıt oluşturamadım. Tekrar deneyebilirsin.";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages[answerIndex].isTyping = false;
          _messages[answerIndex].text =
              "Şu anda bağlantı kuramadım. Lütfen tekrar dene.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 18, 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFE082),
                    size: 23,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Huzur",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Dini sorular için akıllı rehber",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.circle,
                    color: Color(0xFF64FFDA),
                    size: 8,
                  ),
                  const SizedBox(width: 5),
                  const Text("Çevrimiçi", style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: GlassContainer(
                borderRadius: 24,
                emeraldGlow: true,
                enableBlur: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF64FFDA),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Dini bir soru sor...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        color:
                            _sending ? Colors.white30 : const Color(0xFFFFE082),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  bool isTyping;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: GlassContainer(
            borderRadius: 20,
            emeraldGlow: !user,
            goldAccentBorder: user,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!user)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Color(0xFF64FFDA),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "HUZUR AI",
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64FFDA),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (message.isTyping)
                  const _TypingIndicator()
                else
                  SelectableText(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _dots;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dots = List.generate(3, (index) {
      final start = index * 0.18;
      return Tween<double>(begin: 0.2, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, start + 0.55, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Yanıt hazırlanıyor ",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        ..._dots.map(
          (animation) => FadeTransition(
            opacity: animation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF64FFDA),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
