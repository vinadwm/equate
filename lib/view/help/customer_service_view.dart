import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

import 'help_widgets.dart';

// ================================================================
// GANTI DENGAN NOMOR CS KAMU
// WhatsApp: format internasional tanpa "+" atau "0" di depan
// ================================================================
const String kCsWhatsApp = '6281234567890';
const String kCsPhone = '+6281234567890';

const Color _kWaGreen = Color(0xFF25D366);

// ================================================================
// DATA TOPIK BOT (dua bahasa)
// ================================================================
class _BotTopic {
  final String id;
  final String labelId;
  final String labelEn;
  final IconData icon;
  final String answerId;
  final String answerEn;
  final List<String> followUps;
  final List<String> keywords;
  final bool showWhatsApp;
  final bool hidden; // tidak tampil sebagai chip

  const _BotTopic({
    required this.id,
    required this.labelId,
    required this.labelEn,
    required this.icon,
    required this.answerId,
    required this.answerEn,
    this.followUps = const [],
    this.keywords = const [],
    this.showWhatsApp = false,
    this.hidden = false,
  });

  String get label => tr(labelId, labelEn);
}

const List<_BotTopic> _topics = [
  _BotTopic(
    id: 'about',
    labelId: 'Apa itu Equate?',
    labelEn: 'What is Equate?',
    icon: Icons.info_outline_rounded,
    answerId:
        'Equate adalah aplikasi kalkulator dan pemantau pasar untuk emas dan Hang Seng. Kamu bisa menghitung profit/loss, pivot point, dan sinyal NEST, sekaligus melihat data historis.',
    answerEn:
        'Equate is a calculator and market tracker app for gold and Hang Seng. You can calculate profit/loss, pivot points, and NEST signals, and browse historical data.',
    followUps: ['calc', 'markets', 'guide'],
    keywords: ['equate', 'aplikasi', 'apa itu', 'fungsi', 'kegunaan', 'app', 'what is'],
  ),
  _BotTopic(
    id: 'calc',
    labelId: 'Cara memakai kalkulator',
    labelEn: 'How to use the calculator',
    icon: Icons.calculate_outlined,
    answerId:
        'Buka tab Kalkulator, pilih instrumen (Emas Digital, Emas Fisik, Pivot Point, atau NEST), isi data yang diminta, lalu tekan hitung. Hasilnya tersimpan otomatis di akunmu.',
    answerEn:
        'Open the Calculator tab, choose an instrument (Digital Gold, Physical Gold, Pivot Point, or NEST), fill in the required data, then tap calculate. Results are saved to your account automatically.',
    followUps: ['digital_physical', 'pivot_nest', 'history'],
    keywords: ['kalkulator', 'hitung', 'menghitung', 'kalkulasi', 'calculator', 'calculate'],
  ),
  _BotTopic(
    id: 'digital_physical',
    labelId: 'Emas Digital vs Emas Fisik',
    labelEn: 'Digital vs Physical Gold',
    icon: Icons.currency_exchange_rounded,
    answerId:
        'Emas Digital menghitung profit/loss dari posisi Buy/Sell dalam satuan lot. Emas Fisik menghitung hasil transaksi berdasarkan berat (gram), modal, dan harga posisi.',
    answerEn:
        'Digital Gold calculates profit/loss from Buy/Sell positions in lots. Physical Gold calculates results based on weight (grams), capital, and position price.',
    followUps: ['pivot_nest', 'disclaimer'],
    keywords: ['digital', 'fisik', 'lot', 'gram', 'beda', 'physical', 'difference'],
  ),
  _BotTopic(
    id: 'pivot_nest',
    labelId: 'Apa itu Pivot Point & NEST?',
    labelEn: 'What are Pivot Point & NEST?',
    icon: Icons.candlestick_chart_rounded,
    answerId:
        'Pivot Point menentukan acuan harga (support dan resistance) dari harga pembukaan. NEST membantu membaca tren dan sinyal berdasarkan harga penutupan.',
    answerEn:
        'Pivot Point sets price references (support and resistance) from the opening price. NEST helps read trends and signals based on the closing price.',
    followUps: ['source', 'disclaimer', 'calc'],
    keywords: ['pivot', 'nest', 'support', 'resistance', 'sinyal', 'tren', 'signal', 'trend'],
  ),
  _BotTopic(
    id: 'markets',
    labelId: 'Pasar apa saja yang tersedia?',
    labelEn: 'Which markets are available?',
    icon: Icons.public_rounded,
    answerId:
        'Di Beranda tersedia Emas Global (LGD), Hang Seng/HKK (HSI), dan Nikkei/JPK (SNI). Kalkulator mendukung instrumen Emas dan Hang Seng.',
    answerEn:
        'The Home tab offers Global Gold (LGD), Hang Seng/HKK (HSI), and Nikkei/JPK (SNI). The calculator supports Gold and Hang Seng instruments.',
    followUps: ['home', 'source'],
    keywords: ['pasar', 'market', 'nikkei', 'hang seng', 'hangseng', 'lgd', 'hsi', 'sni', 'indeks', 'index'],
  ),
  _BotTopic(
    id: 'source',
    labelId: 'Sumber data harga',
    labelEn: 'Price data source',
    icon: Icons.storage_rounded,
    answerId:
        'Data historis bersumber dari Newsmaker.id, meliputi Open, High, Low, dan Close berdasarkan tanggal yang dipilih di Beranda.',
    answerEn:
        'Historical data comes from Newsmaker.id, covering Open, High, Low, and Close for the date you pick on the Home tab.',
    followUps: ['home', 'disclaimer'],
    keywords: ['sumber', 'data', 'newsmaker', 'harga', 'historis', 'historical', 'source', 'price'],
  ),
  _BotTopic(
    id: 'home',
    labelId: 'Cara membaca Beranda',
    labelEn: 'How to read the Home tab',
    icon: Icons.home_rounded,
    answerId:
        'Di Beranda, pilih pasar dan tanggal data. Kamu akan melihat Open, High, Low, Close, grafik pergerakan, dan tabel data historis. Tarik layar ke bawah untuk memuat ulang.',
    answerEn:
        'On the Home tab, pick a market and a date. You will see Open, High, Low, Close, the price chart, and the historical table. Pull down to refresh.',
    followUps: ['chart', 'source'],
    keywords: ['beranda', 'home', 'tabel', 'tanggal', 'table', 'date'],
  ),
  _BotTopic(
    id: 'chart',
    labelId: 'Mengatur rentang grafik',
    labelEn: 'Changing the chart range',
    icon: Icons.show_chart_rounded,
    answerId:
        'Di kartu Pergerakan Harga ada pilihan rentang: 7H, 30H, 90H, 1Y, dan Semua. Tabel data historis di bawahnya ikut menyesuaikan, dan bisa dibuka lebih panjang lewat "Lihat Selengkapnya".',
    answerEn:
        'The Price Movement card has range options: 7D, 30D, 90D, 1Y, and All. The historical table below follows it, and can be expanded with "Show more".',
    followUps: ['home', 'markets'],
    keywords: ['grafik', 'chart', 'rentang', 'range', 'pergerakan', 'movement'],
  ),
  _BotTopic(
    id: 'history',
    labelId: 'Di mana riwayat perhitungan?',
    labelEn: 'Where is my calculation history?',
    icon: Icons.history_rounded,
    answerId:
        'Hasil perhitungan tersimpan otomatis di akunmu. Buka tab Kalkulator, lihat bagian Riwayat, lalu ketuk "Lihat Semua" untuk detail lengkap.',
    answerEn:
        'Your results are saved to your account automatically. Open the Calculator tab, find the History section, then tap "See all" for full details.',
    followUps: ['calc', 'account'],
    keywords: ['riwayat', 'history', 'tersimpan', 'simpan', 'saved'],
  ),
  _BotTopic(
    id: 'register',
    labelId: 'Cara membuat akun',
    labelEn: 'How to create an account',
    icon: Icons.person_add_alt_1_rounded,
    answerId:
        'Di halaman Masuk, ketuk "Daftar" di bawah kartu, isi nama, e-mail, dan kata sandi (minimal 8 karakter, 1 huruf kapital, dan 1 angka), lalu ketuk Daftar.',
    answerEn:
        'On the Sign In page, tap "Sign up" below the card, fill in your name, e-mail, and password (at least 8 characters, 1 capital letter, and 1 number), then tap Sign up.',
    followUps: ['google', 'forgot'],
    keywords: ['daftar', 'buat akun', 'register', 'sign up', 'signup', 'create account'],
  ),
  _BotTopic(
    id: 'google',
    labelId: 'Masuk dengan Google',
    labelEn: 'Sign in with Google',
    icon: Icons.login_rounded,
    answerId:
        'Ketuk tombol "Google" di pojok kanan atas judul pada halaman Masuk atau Daftar, lalu pilih akun Google kamu.',
    answerEn:
        'Tap the "Google" button next to the title on the Sign in or Sign up page, then pick your Google account.',
    followUps: ['register', 'forgot'],
    keywords: ['google', 'gmail'],
  ),
  _BotTopic(
    id: 'forgot',
    labelId: 'Lupa kata sandi',
    labelEn: 'Forgot my password',
    icon: Icons.lock_reset_rounded,
    answerId:
        'Di halaman Masuk, ketuk "Lupa?" pada kolom kata sandi, masukkan e-mail akunmu, lalu cek inbox atau folder spam untuk link membuat kata sandi baru.',
    answerEn:
        'On the Sign in page, tap "Forgot?" in the password field, enter your account e-mail, then check your inbox or spam folder for the reset link.',
    followUps: ['account', 'cs_hours'],
    keywords: ['lupa', 'sandi', 'password', 'reset', 'login', 'forgot', 'masuk'],
  ),
  _BotTopic(
    id: 'account',
    labelId: 'Ubah nama atau kata sandi',
    labelEn: 'Change name or password',
    icon: Icons.manage_accounts_rounded,
    answerId:
        'Buka tab Profil. Ketuk "Edit Profil" untuk mengubah nama dan foto, atau "Ubah Kata Sandi" untuk memperbarui keamanan akunmu.',
    answerEn:
        'Open the Profile tab. Tap "Edit Profile" to change your name and photo, or "Change Password" to update your account security.',
    followUps: ['photo', 'theme'],
    keywords: ['profil', 'nama', 'edit', 'akun', 'ganti sandi', 'profile', 'name', 'account'],
  ),
  _BotTopic(
    id: 'photo',
    labelId: 'Mengganti foto profil',
    labelEn: 'Changing profile photo',
    icon: Icons.photo_camera_outlined,
    answerId:
        'Buka Profil > Edit Profil, lalu pilih foto baru dari galeri atau kamera. Izinkan akses kamera atau galeri saat diminta oleh ponselmu.',
    answerEn:
        'Go to Profile > Edit Profile, then choose a new photo from the gallery or camera. Allow camera or gallery access when your phone asks.',
    followUps: ['account', 'bug'],
    keywords: ['foto', 'gambar', 'kamera', 'galeri', 'photo', 'picture', 'camera', 'gallery'],
  ),
  _BotTopic(
    id: 'theme',
    labelId: 'Mode gelap & terang',
    labelEn: 'Dark & light mode',
    icon: Icons.dark_mode_outlined,
    answerId:
        'Di tab Profil, aktifkan atau matikan "Mode Gelap" sesuai seleranmu. Pilihan ini berlaku di seluruh aplikasi.',
    answerEn:
        'On the Profile tab, switch "Dark Mode" on or off as you like. It applies across the whole app.',
    followUps: ['language', 'account'],
    keywords: ['gelap', 'terang', 'dark', 'light', 'tema', 'theme', 'mode'],
  ),
  _BotTopic(
    id: 'language',
    labelId: 'Mengganti bahasa',
    labelEn: 'Changing the language',
    icon: Icons.translate_rounded,
    answerId:
        'Di tab Profil, pada baris "Bahasa", pilih ID untuk Bahasa Indonesia atau EN untuk English.',
    answerEn:
        'On the Profile tab, in the "Language" row, choose ID for Indonesian or EN for English.',
    followUps: ['theme', 'account'],
    keywords: ['bahasa', 'language', 'inggris', 'english', 'indonesia', 'translate'],
  ),
  _BotTopic(
    id: 'internet',
    labelId: 'Data tidak muncul / loading terus',
    labelEn: 'Data not showing / loading forever',
    icon: Icons.wifi_off_rounded,
    answerId:
        'Pastikan ponselmu terhubung ke internet, lalu tarik layar Beranda ke bawah untuk memuat ulang. Data harga membutuhkan koneksi aktif.',
    answerEn:
        'Make sure your phone is online, then pull down on the Home tab to refresh. Price data needs an active connection.',
    followUps: ['bug', 'source'],
    keywords: ['internet', 'koneksi', 'loading', 'lambat', 'offline', 'connection', 'slow', 'tidak muncul', 'not showing'],
  ),
  _BotTopic(
    id: 'disclaimer',
    labelId: 'Apakah ini saran investasi?',
    labelEn: 'Is this investment advice?',
    icon: Icons.gavel_rounded,
    answerId:
        'Bukan. Hasil di aplikasi hanya estimasi untuk membantu analisis. Keputusan investasi tetap menjadi tanggung jawab masing-masing pengguna.',
    answerEn:
        'No. Results in the app are only estimates to help your analysis. Investment decisions remain your own responsibility.',
    followUps: ['calc', 'source'],
    keywords: ['saran', 'investasi', 'rekomendasi', 'untung', 'rugi', 'jamin', 'advice', 'investment', 'guarantee'],
  ),
  _BotTopic(
    id: 'guide',
    labelId: 'Panduan penggunaan lengkap',
    labelEn: 'Full user guide',
    icon: Icons.menu_book_rounded,
    answerId:
        'Panduan langkah demi langkah ada di Pusat Bantuan > Panduan Penggunaan, berisi 6 langkah mudah memakai Equate dari awal.',
    answerEn:
        'The step-by-step guide is in Help Center > User Guide, with 6 easy steps to start using Equate.',
    followUps: ['calc', 'home'],
    keywords: ['panduan', 'tutorial', 'petunjuk', 'langkah', 'guide', 'steps'],
  ),
  _BotTopic(
    id: 'cs_hours',
    labelId: 'Jam operasional CS',
    labelEn: 'Support hours',
    icon: Icons.schedule_rounded,
    answerId:
        'Tim CS tersedia Senin–Jumat 09.00–17.00 WIB dan Sabtu 09.00–13.00 WIB. Minggu dan hari libur tutup. Kamu bisa menghubungi lewat WhatsApp atau telepon.',
    answerEn:
        'Our support team is available Monday–Friday 09:00–17:00 WIB and Saturday 09:00–13:00 WIB. Closed on Sundays and holidays. Reach us via WhatsApp or phone.',
    followUps: ['about'],
    keywords: ['jam', 'operasional', 'buka', 'tutup', 'kapan', 'cs', 'telepon', 'hours', 'open', 'when', 'phone'],
    showWhatsApp: true,
  ),
  _BotTopic(
    id: 'bug',
    labelId: 'Aplikasi error atau data salah',
    labelEn: 'App error or wrong data',
    icon: Icons.bug_report_outlined,
    answerId:
        'Coba tarik layar ke bawah untuk memuat ulang, atau tutup lalu buka lagi aplikasinya. Kalau masih bermasalah, hubungi tim CS lewat WhatsApp dan sertakan penjelasan atau tangkapan layar.',
    answerEn:
        'Try pulling down to refresh, or close and reopen the app. If it still fails, contact our team on WhatsApp with a description or screenshot.',
    followUps: ['internet', 'cs_hours'],
    keywords: ['error', 'bug', 'salah', 'rusak', 'gagal', 'masalah', 'macet', 'crash', 'wrong', 'broken', 'problem', 'issue', 'fail'],
    showWhatsApp: true,
  ),
  _BotTopic(
    id: 'greet',
    labelId: 'Halo',
    labelEn: 'Hello',
    icon: Icons.waving_hand_rounded,
    answerId:
        'Halo! Senang bertemu kamu 👋 Mau tanya soal apa? Pilih salah satu pertanyaan di bawah ya.',
    answerEn:
        'Hello! Nice to meet you 👋 What would you like to know? Pick one of the questions below.',
    followUps: ['about', 'calc', 'forgot'],
    keywords: ['halo', 'hai', 'hi', 'hello', 'hey', 'selamat', 'pagi', 'siang', 'malam'],
    hidden: true,
  ),
  _BotTopic(
    id: 'thanks',
    labelId: 'Terima kasih',
    labelEn: 'Thank you',
    icon: Icons.favorite_border_rounded,
    answerId:
        'Sama-sama! Kalau masih ada yang ingin ditanyakan, aku di sini. 😊',
    answerEn:
        'You are welcome! If you have more questions, I am right here. 😊',
    followUps: ['about'],
    keywords: ['terima kasih', 'makasih', 'thanks', 'thank you', 'thx', 'trims'],
    hidden: true,
  ),
];

_BotTopic _topicById(String id) => _topics.firstWhere((t) => t.id == id);

class _Msg {
  final String textId;
  final String textEn;
  final bool isUser;
  final DateTime time;
  final bool showWhatsApp;

  _Msg({
    required this.textId,
    required this.textEn,
    required this.isUser,
    this.showWhatsApp = false,
  }) : time = DateTime.now();

  String get text => tr(textId, textEn);
}

// ================================================================
// HALAMAN CHAT BOT
// ================================================================
class CustomerServiceView extends StatefulWidget {
  const CustomerServiceView({super.key});

  @override
  State<CustomerServiceView> createState() => _CustomerServiceViewState();
}

class _CustomerServiceViewState extends State<CustomerServiceView> {
  final TextEditingController _controller = TextEditingController();
  final List<_Msg> _messages = [];
  final Set<String> _asked = {};

  List<String> _suggestions = [];
  bool _typing = false;
  int _failCount = 0;
  String _lastUserText = '';

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Msg(
        textId:
            'Halo! Aku asisten Equate 👋\nPilih pertanyaan yang berjalan di bawah, atau ketik sendiri pertanyaanmu.',
        textEn:
            'Hi! I am the Equate assistant 👋\nPick one of the moving questions below, or type your own.',
        isUser: false,
      ),
    );
    _suggestions = _buildSuggestions(const []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // SUSUN DAFTAR SARAN: lanjutan topik + topik yang belum ditanya
  // ============================================================
  List<String> _buildSuggestions(List<String> followUps) {
    final visible = _topics.where((t) => !t.hidden).toList();
    final result = <String>[];

    for (final id in followUps) {
      if (!_topicById(id).hidden && !result.contains(id)) result.add(id);
    }
    for (final topic in visible) {
      if (result.length >= 10) break;
      if (!_asked.contains(topic.id) && !result.contains(topic.id)) {
        result.add(topic.id);
      }
    }
    for (final topic in visible) {
      if (result.length >= 6) break;
      if (!result.contains(topic.id)) result.add(topic.id);
    }
    return result;
  }

  // ============================================================
  // PROSES PERTANYAAN
  // ============================================================
  Future<void> _ask(String text, {String? topicId}) async {
    final clean = text.trim();
    if (clean.isEmpty || _typing) return;

    _lastUserText = clean;

    setState(() {
      _messages.add(_Msg(textId: clean, textEn: clean, isUser: true));
      _typing = true;
    });

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final topic = topicId != null ? _topicById(topicId) : _match(clean);

    if (topic == null) {
      _failCount++;
      final giveUp = _failCount >= 2;
      setState(() {
        _typing = false;
        _messages.add(
          _Msg(
            textId: giveUp
                ? 'Maaf, aku masih belum paham maksudmu. Biar lebih jelas, langsung chat tim CS lewat WhatsApp ya.'
                : 'Maaf, aku belum paham pertanyaan itu. Coba pilih salah satu pertanyaan di bawah, atau tulis dengan kata lain.',
            textEn: giveUp
                ? 'Sorry, I still do not get it. To make it clearer, chat with our team on WhatsApp.'
                : 'Sorry, I did not understand that. Try picking one of the questions below, or rephrase it.',
            isUser: false,
            showWhatsApp: giveUp,
          ),
        );
        _suggestions = _buildSuggestions(const []);
      });
      return;
    }

    _failCount = 0;
    _asked.add(topic.id);

    setState(() {
      _typing = false;
      _messages.add(
        _Msg(
          textId: topic.answerId,
          textEn: topic.answerEn,
          isUser: false,
          showWhatsApp: topic.showWhatsApp,
        ),
      );
      _suggestions = _buildSuggestions(topic.followUps);
    });
  }

  // Cocokkan teks bebas dengan kata kunci (kata pendek dicocokkan utuh)
  _BotTopic? _match(String input) {
    final text = input.toLowerCase();
    final tokens = text.split(RegExp(r'[^a-z0-9]+'));
    _BotTopic? best;
    int bestScore = 0;

    for (final topic in _topics) {
      int score = 0;
      for (final kw in topic.keywords) {
        final hit = kw.length <= 3 ? tokens.contains(kw) : text.contains(kw);
        if (hit) score += kw.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = topic;
      }
    }
    return bestScore > 0 ? best : null;
  }

  void _sendTyped() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    _ask(text);
  }

  // ============================================================
  // AKSI: WHATSAPP & TELEPON
  // ============================================================
  Future<void> _openWhatsApp() async {
    final message = _lastUserText.isEmpty
        ? tr(
            'Halo Equate, saya butuh bantuan terkait aplikasi.',
            'Hello Equate, I need help with the app.',
          )
        : tr(
            'Halo Equate, saya butuh bantuan. Pertanyaan saya: "$_lastUserText"',
            'Hello Equate, I need help. My question: "$_lastUserText"',
          );

    await _launch(
      Uri.parse(
        'https://wa.me/$kCsWhatsApp?text=${Uri.encodeComponent(message)}',
      ),
    );
  }

  Future<void> _call() async {
    await _launch(Uri(scheme: 'tel', path: kCsPhone));
  }

  Future<void> _launch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showError();
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Tidak dapat membuka aplikasi tujuan.',
            'Unable to open the target app.',
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // POP UP CARA PAKAI
  // ============================================================
  void _showInfo(AuthTokens t) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        Widget step(IconData icon, String title, String desc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAuthOrange.withOpacity(0.14),
                  ),
                  child: Icon(icon, size: 18, color: kAuthOrange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          height: 1.5,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AuthGlassCard(
              t: t,
              radius: 30,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Cara pakai chat CS', 'How to use CS chat'),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  step(
                    Icons.touch_app_rounded,
                    tr('Pilih pertanyaan', 'Pick a question'),
                    tr(
                      'Ketuk salah satu pertanyaan yang berjalan di bawah chat. Asisten akan menjawab otomatis.',
                      'Tap one of the moving questions below the chat. The assistant answers automatically.',
                    ),
                  ),
                  step(
                    Icons.edit_rounded,
                    tr('Atau ketik sendiri', 'Or type your own'),
                    tr(
                      'Tulis pertanyaanmu di kolom pesan, asisten akan mencari jawaban yang paling cocok.',
                      'Write your question in the message box and the assistant finds the best match.',
                    ),
                  ),
                  step(
                    Icons.chat_rounded,
                    tr('Masih bingung?', 'Still confused?'),
                    tr(
                      'Ketuk tombol hijau WhatsApp kapan saja untuk ngobrol langsung dengan tim kami.',
                      'Tap the green WhatsApp button any time to chat with our team directly.',
                    ),
                  ),
                  step(
                    Icons.call_rounded,
                    tr('Butuh cepat?', 'Need it fast?'),
                    tr(
                      'Ketuk ikon telepon di atas. Jam operasional: Senin–Jumat 09.00–17.00 WIB, Sabtu 09.00–13.00 WIB.',
                      'Tap the phone icon at the top. Hours: Mon–Fri 09:00–17:00 WIB, Sat 09:00–13:00 WIB.',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AuthActionButton(
                      t: t,
                      label: tr('Mengerti', 'Got it'),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          resizeToAvoidBottomInset: true,
          body: AppPlainBackground(
            isDark: isDark,
            child: Column(
              children: [
                _buildHeader(t),
                Expanded(child: _buildMessages(t, isDark)),
                _buildWhatsAppBar(t, isDark),
                _buildSuggestionTicker(t, isDark),
                _buildInputBar(t),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- HEADER (ikon polos, tanpa bulatan) ----------------
  Widget _buildHeader(AuthTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: t.textPrimary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Service',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: t.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF34C759),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr('Asisten Equate • Online', 'Equate Assistant • Online'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showInfo(t),
            icon: Icon(
              Icons.info_outline_rounded,
              size: 24,
              color: t.textPrimary,
            ),
          ),
          IconButton(
            onPressed: _call,
            icon: const Icon(Icons.call_rounded, size: 23, color: kAuthOrange),
          ),
        ],
      ),
    );
  }

  // ---------------- DAFTAR PESAN ----------------
  Widget _buildMessages(AuthTokens t, bool isDark) {
    final reversed = _messages.reversed.toList();
    final itemCount = reversed.length + (_typing ? 1 : 0);

    return ListView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_typing && index == 0) {
          return _TypingBubble(isDark: isDark);
        }

        final msg = reversed[_typing ? index - 1 : index];

        return _ChatBubble(
          msg: msg,
          isDark: isDark,
          t: t,
          onWhatsApp: _openWhatsApp,
        );
      },
    );
  }

  // ---------------- BAR WHATSAPP (selalu tampil) ----------------
  Widget _buildWhatsAppBar(AuthTokens t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr(
                'Butuh bantuan langsung dari tim kami?',
                'Need direct help from our team?',
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: t.textSecondary,
              ),
            ),
          ),
          Material(
            color: _kWaGreen,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              splashColor: Colors.white.withOpacity(0.25),
              onTap: _openWhatsApp,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PERTANYAAN BERJALAN ----------------
  Widget _buildSuggestionTicker(AuthTokens t, bool isDark) {
    final chips = _suggestions;
    final half = (chips.length / 2).ceil();
    final row1 = chips.sublist(0, half);
    final row2 = chips.sublist(half);
    final signature = chips.join('|');

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChipTicker(
            key: ValueKey('r1-$signature'),
            ids: row1,
            reverse: false,
            speed: 0.55,
            isDark: isDark,
            t: t,
            enabled: !_typing,
            onTap: _onChipTap,
          ),
          if (row2.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ChipTicker(
              key: ValueKey('r2-$signature'),
              ids: row2,
              reverse: true,
              speed: 0.4,
              isDark: isDark,
              t: t,
              enabled: !_typing,
              onTap: _onChipTap,
            ),
          ],
        ],
      ),
    );
  }

  void _onChipTap(String id) {
    _ask(_topicById(id).label, topicId: id);
  }

  // ---------------- KOLOM INPUT ----------------
  Widget _buildInputBar(AuthTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: t.fieldFill,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: t.fieldBorder),
              ),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendTyped(),
                cursorColor: kAuthOrange,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: t.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: tr('Ketik pertanyaanmu...', 'Type your question...'),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: kAuthOrange.withOpacity(0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendTyped,
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BARIS CHIP BERJALAN (auto-scroll, pause saat disentuh)
// ================================================================
class _ChipTicker extends StatefulWidget {
  final List<String> ids;
  final bool reverse;
  final double speed;
  final bool isDark;
  final AuthTokens t;
  final bool enabled;
  final ValueChanged<String> onTap;

  const _ChipTicker({
    super.key,
    required this.ids,
    required this.reverse,
    required this.speed,
    required this.isDark,
    required this.t,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ChipTicker> createState() => _ChipTickerState();
}

class _ChipTickerState extends State<_ChipTicker> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_paused || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.offset + widget.speed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.ids;
    if (ids.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: Listener(
        onPointerDown: (_) => _paused = true,
        onPointerUp: (_) => _paused = false,
        onPointerCancel: (_) => _paused = false,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          reverse: widget.reverse,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final id = ids[index % ids.length];
            final topic = _topicById(id);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SuggestionChip(
                label: topic.label,
                icon: topic.icon,
                isDark: widget.isDark,
                t: widget.t,
                onTap: widget.enabled ? () => widget.onTap(id) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final AuthTokens t;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.white.withOpacity(0.9),
        shape: StadiumBorder(side: BorderSide(color: t.fieldBorder)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          splashColor: kAuthOrange.withOpacity(0.15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: kAuthOrange),
                const SizedBox(width: 7),
                Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
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

// ================================================================
// GELEMBUNG CHAT
// ================================================================
class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  final bool isDark;
  final AuthTokens t;
  final VoidCallback onWhatsApp;

  const _ChatBubble({
    required this.msg,
    required this.isDark,
    required this.t,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.76;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 5),
      bottomRight: Radius.circular(isUser ? 5 : 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: isUser
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kAuthOrangeSoft,
                            kAuthOrange,
                            kAuthOrangeDeep,
                          ],
                        )
                      : null,
                  color: isUser
                      ? null
                      : (isDark
                            ? const Color(0xFF1E1F24).withOpacity(0.85)
                            : Colors.white.withOpacity(0.92)),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? kAuthOrange.withOpacity(0.25)
                          : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: isUser ? Colors.white : t.textPrimary,
                      ),
                    ),
                    if (msg.showWhatsApp) ...[
                      const SizedBox(height: 12),
                      _WhatsAppButton(onTap: onWhatsApp),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
                child: Text(
                  DateFormat('HH:mm').format(msg.time),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: t.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WhatsAppButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kWaGreen,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashColor: Colors.white.withOpacity(0.25),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_rounded, size: 17, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                tr('Chat CS via WhatsApp', 'Chat CS on WhatsApp'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// INDIKATOR "SEDANG MENGETIK"
// ================================================================
class _TypingBubble extends StatefulWidget {
  final bool isDark;

  const _TypingBubble({required this.isDark});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(20),
            ),
            color: isDark
                ? const Color(0xFF1E1F24).withOpacity(0.85)
                : Colors.white.withOpacity(0.92),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (_anim.value - i * 0.18) % 1.0;
                  final scale =
                      0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                  return Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAuthOrange.withOpacity(scale.clamp(0.3, 1.0)),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}