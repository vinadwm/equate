import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/model/news_model.dart';
import 'package:equate/service/news_service.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/view/help/help_widgets.dart';
import 'package:equate/view/news/news_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

class NewsDetailView extends StatefulWidget {
  final NewsItem item;

  const NewsDetailView({super.key, required this.item});

  @override
  State<NewsDetailView> createState() => _NewsDetailViewState();
}

class _NewsDetailViewState extends State<NewsDetailView> {
  List<String> _paragraphs = [];
  bool _loading = true;
  bool _fullText = false;

  @override
  void initState() {
    super.initState();
    _paragraphs = _fallback();
    _load();
  }

  // Isi cadangan dari RSS (konten atau ringkasan).
  List<String> _fallback() {
    final src = widget.item.content.isNotEmpty
        ? widget.item.content
        : widget.item.summary;

    return src
        .split(RegExp(r'\n{2,}'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _load() async {
    final result = await NewsService.fetchArticle(widget.item.link);
    if (!mounted) return;

    setState(() {
      if (result.length >= 3) {
        _paragraphs = result;
        _fullText = true;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AppThemeLang(
      builder: (context, isDark, t) {
        final bg = isDark ? const Color(0xFF0D0E12) : Colors.white;

        return Scaffold(
          backgroundColor: bg,
          body: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              // ---------------- GAMBAR ----------------
              SizedBox(
                height: 290,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NewsImage(url: item.imageUrl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.45, 1.0],
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            bg,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 14,
                      child: Material(
                        color: Colors.black.withOpacity(0.35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------- ISI ----------------
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [kAuthOrangeSoft, kAuthOrangeDeep],
                            ),
                          ),
                          child: Text(
                            item.source,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          newsTimeAgo(item.publishedAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: t.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_paragraphs.isEmpty && !_loading)
                      Text(
                        tr(
                          'Isi artikel tidak tersedia di aplikasi. Buka artikel asli di web untuk membacanya.',
                          'The article body is not available in the app. Open the original article on the web to read it.',
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.7,
                          color: t.textSecondary,
                        ),
                      )
                    else
                      ..._paragraphs.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            p,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 1.75,
                              color: t.textPrimary.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ),

                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kAuthOrange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              tr(
                                'Memuat isi artikel...',
                                'Loading article...',
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_loading && !_fullText && _paragraphs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          tr(
                            'Ini hanya ringkasan. Baca selengkapnya di artikel asli.',
                            'This is only a summary. Read more in the original article.',
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: t.textSecondary,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ---------------- TOMBOL KE WEB ----------------
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: kAuthOrange.withOpacity(0.40),
                            blurRadius: 20,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kAuthOrangeSoft,
                                kAuthOrange,
                                kAuthOrangeDeep,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            splashColor: Colors.white.withOpacity(0.25),
                            onTap: () => openNewsInBrowser(context, item),
                            child: SizedBox(
                              height: 52,
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    tr(
                                      'Lihat artikel langsung di web',
                                      'View the original article on the web',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: Text(
                        tr(
                          'Sumber: ${item.source}',
                          'Source: ${item.source}',
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}