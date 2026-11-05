import 'package:flutter/material.dart';

void main() {
  runApp(const DnbPlantAiApp());
}

class DnbPlantAiApp extends StatelessWidget {
  const DnbPlantAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DNB Plant AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF168B70),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F5),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const sections = <_Section>[
    _Section('ثبت جدید', 'ثبت گیاه و وضعیت اولیه', Icons.add_a_photo_outlined),
    _Section('گیاهان من', 'شناسنامه و تاریخچه هر گیاه', Icons.local_florist_outlined),
    _Section('اطلاعات ذخیره', 'موارد شناسایی‌شده و ذخیره‌شده', Icons.bookmark_border),
    _Section('تکثیر', 'راهنمای قلمه، بذر و تقسیم', Icons.content_cut),
    _Section('گفت‌وگو با دانا', 'دستیار هوشمند گیاهان', Icons.chat_bubble_outline),
    _Section('نمودار وضعیت', 'روند سلامت گیاهان تا سه ماه', Icons.show_chart),
    _Section('تنظیمات', 'زبان، اعلان‌ها و حریم خصوصی', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DNB Plant AI'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تنظیمات',
              onPressed: () => _openSection(context, sections.last),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF126B59), Color(0xFF23A783)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_outlined, color: Colors.white, size: 38),
                  SizedBox(height: 14),
                  Text(
                    'دانا زبان گیاه شما',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'همراه هوشمند برای شناخت، ثبت و مراقبت از گیاهان',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'بخش‌های اصلی',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (final section in sections)
              Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE5F3ED),
                    child: Icon(section.icon, color: const Color(0xFF168B70)),
                  ),
                  title: Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(section.subtitle),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openSection(context, section),
                ),
              ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'نسخه آزمایشی اولیه • DNB Plant AI',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSection(BuildContext context, _Section section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SectionPage(section: section),
      ),
    );
  }
}

class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(section.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(section.icon, size: 58, color: const Color(0xFF168B70)),
                const SizedBox(height: 18),
                Text(
                  section.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'این بخش در نسخه‌های بعدی تکمیل می‌شود. اطلاعات و شناسنامه گیاهان در مراحل بعدی به‌صورت واقعی ذخیره خواهند شد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section {
  const _Section(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
