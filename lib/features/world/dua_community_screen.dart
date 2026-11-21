import 'package:material_ui/material_ui.dart';

import 'dua_community_panel.dart';

class DuaCommunityScreen extends StatelessWidget {
  const DuaCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080F12),
        foregroundColor: const Color(0xFFFFCE78),
        elevation: 0,
        title: const Text(
          'Dua Bırak',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: const [DuaCommunityPanel()],
        ),
      ),
    );
  }
}
