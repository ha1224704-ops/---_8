import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const MainPage(),
    );
  }
}

// الصفحة الرئيسية بيها تبويبين
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: current == 0? const QuranListPage() : const AzkarPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        onTap: (i) => setState(() => current = i),
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "القرآن"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "أذكاري"),
        ],
      ),
    );
  }
}

// قائمة السور
class QuranListPage extends StatelessWidget {
  const QuranListPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("القرآن الكريم - 114 سورة"), centerTitle: true),
      body: ListView.builder(
        itemCount: 114,
        itemBuilder: (context, i) {
          int num = i + 1;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.green.shade900, child: Text("$num", style: const TextStyle(color: Colors.white))),
              title: Text(quran.getSurahNameArabic(num), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: Text("${quran.getPlaceOfRevelation(num) == "Makkah"? "مكية" : "مدنية"} - ${quran.getVerseCount(num)} آية"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahPage(surahNumber: num))),
            ),
          );
        },
      ),
    );
  }
}

// صفحة السورة - قراءة
class SurahPage extends StatelessWidget {
  final int surahNumber;
  const SurahPage({super.key, required this.surahNumber});
  @override
  Widget build(BuildContext context) {
    int count = quran.getVerseCount(surahNumber);
    return Scaffold(
      appBar: AppBar(title: Text(quran.getSurahNameArabic(surahNumber)), centerTitle: true),
      body: Column(
        children: [
          if (surahNumber!= 1 && surahNumber!= 9)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.withOpacity(0.15),
              child: const Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: count,
              itemBuilder: (context, i) {
                int verseNum = i + 1;
                String verse = quran.getVerse(surahNumber, verseNum);
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VerseDetailPage(surahNumber: surahNumber, verseNumber: verseNum))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                    child: Row(
                      children: [
                        Expanded(child: Text(verse, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 23, height: 1.8), textAlign: TextAlign.right)),
                        const SizedBox(width: 8),
                        Text("﴿$verseNum﴾", style: TextStyle(color: Colors.amber.shade300, fontSize: 18)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// صفحة الآية + الصوت - من تدوس على الآية
class VerseDetailPage extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  const VerseDetailPage({super.key, required this.surahNumber, required this.verseNumber});
  @override
  State<VerseDetailPage> createState() => _VerseDetailPageState();
}

class _VerseDetailPageState extends State<VerseDetailPage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  bool loading = false;

  Future<void> playAudio() async {
    if (isPlaying) {
      await player.pause();
      setState(() => isPlaying = false);
      return;
    }
    setState(() => loading = true);
    try {
      String surahId = widget.surahNumber.toString().padLeft(3, '0');
      String verseId = widget.verseNumber.toString().padLeft(3, '0');
      // صوت كل آية على حدة - عبد الباسط
      String url = "https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/${surahId}${verseId}.mp3";
      await player.setUrl(url);
      await player.play();
      setState(() { isPlaying = true; loading = false; });
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => isPlaying = false);
        }
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الصوت يحتاج انترنت")));
    }
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    String verseText = quran.getVerse(widget.surahNumber, widget.verseNumber);
    return Scaffold(
      appBar: AppBar(title: Text("${quran.getSurahNameArabic(widget.surahNumber)} - آية ${widget.verseNumber}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Text(verseText, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 32, height: 1.9, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            Text("﴿${widget.verseNumber}﴾ - ${quran.getSurahNameArabic(widget.surahNumber)}", style: TextStyle(color: Colors.amber.shade300, fontSize: 18)),
            const Spacer(),
            loading? const CircularProgressIndicator() : IconButton(icon: Icon(isPlaying? Icons.pause_circle_filled : Icons.play_circle_filled, size: 90, color: Colors.green), onPressed: playAudio),
            const SizedBox(height: 10),
            Text(isPlaying? "يتم التشغيل..." : "اضغط للاستماع للآية", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// صفحة الأذكار - 3 اذكار فقط للمبتدئ
class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

  final List<Map<String, String>> azkar = const [
    {"title": "أذكار الصباح", "text": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ\n\nاللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ"},
    {"title": "أذكار المساء", "text": "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ\n\nاللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ\n\nاللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ"},
    {"title": "أذكار النوم", "text": "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا\n\nاللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ\n\nاللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ\n\nسُبْحَانَ اللَّهِ (33) - الْحَمْدُ لِلَّهِ (33) - اللَّهُ أَكْبَرُ (34)"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("أذكاري"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: azkar.length,
        itemBuilder: (context, i) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.favorite, color: Colors.green.shade300, size: 20), const SizedBox(width: 8), Text(azkar[i]["title"]!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade300))]),
                  const Divider(height: 20),
                  Text(azkar[i]["text"]!, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 18, height: 1.8), textAlign: TextAlign.right),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}