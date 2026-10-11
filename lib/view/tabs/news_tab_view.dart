import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/model/news_model.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/view/help/help_widgets.dart';
import 'package:equate/view/news/news_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';
import 'package:equate/viewmodel/news_viewmodel.dart';

class NewsTabView extends StatefulWidget {
  const NewsTabView({super.key});

  @override
  State<NewsTabView> createState() => _NewsTabViewState();
}

class _NewsTabViewState extends State<NewsTabView> {
  final NewsViewModel _vm = NewsViewModel.instance;

  @override
  void initState() {
    super.initState();
    _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          body: AppPlainBackground(
            isDark: isDark,
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) {
                return RefreshIndicator(
                  color: kAuthOrange,
                  backgroundColor: isDark
                      ? const Color(0xFF1E1F24)
                      : Colors.white,
                  onRefresh: () => _vm.load(force: true),
                  child: _buildBody(context, isDark, t),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, AuthTokens t) {
    final list = _vm.filtered;
    final featured = list.isNotEmpty ? list.first : null;
    final rest = list.length > 1 ? list.sublist(1) : <NewsItem>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 140),
      children: [
        // ---------------- JUDUL ----------------
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: -0.8,
              color: t.textPrimary,
            ),
            children: [
              TextSpan(text: tr('Kabar ', 'Market ')),
              TextSpan(
                text: tr('pasar', 'news'),
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.8,
                  color: kAuthOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr(
            'Berita emas dan pasar keuangan dari berbagai sumber.',
            'Gold and financial market news from various sources.',
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: t.textSecondary,
          ),
        ),

        const SizedBox(height: 18),

        // ---------------- FILTER SUMBER ----------------
        if (_vm.items.isNotEmpty)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _chip(t, tr('Semua', 'All'), _vm.selectedSource == null, () {
                  _vm.selectSource(null);
                }),
                ..._vm.sources.map(
                  (s) => _chip(t, s, _vm.selectedSource == s, () {
                    _vm.selectSource(s);
                  }),
                ),
              ],
            ),
          ),

        const SizedBox(height: 18),

        // ---------------- ISI ----------------
        if (_vm.isLoading && _vm.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: CircularProgressIndicator(color: kAuthOrange),
            ),
          )
        else if (_vm.hasError && _vm.items.isEmpty)
          _buildError(t)
        else ...[
          if (featured != null) _FeaturedCard(item: featured),
          const SizedBox(height: 8),
          ...List.generate(rest.length, (i) {
            return Column(
              children: [
                _NewsRow(item: rest[i], t: t),
                if (i != rest.length - 1)
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.06),
                  ),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _chip(AuthTokens t, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
                  )
                : null,
            color: selected ? null : t.fieldFill,
            border: Border.all(
              color: selected ? Colors.white.withOpacity(0.45) : t.fieldBorder,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kAuthOrange.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AuthTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: t.textSecondary),
          const SizedBox(height: 12),
          Text(
            tr('Berita tidak dapat dimuat', 'News could not be loaded'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Periksa koneksi internetmu, lalu coba lagi.',
              'Check your internet connection and try again.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _vm.load(force: true),
            child: Text(
              tr('Coba Lagi', 'Try Again'),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: kAuthOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// BERITA UTAMA (kartu besar bergambar)
// ================================================================
class _FeaturedCard extends StatelessWidget {
  final NewsItem item;

  const _FeaturedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 230,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => openNewsLink(context, item),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NewsImage(url: item.imageUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
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
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            newsTimeAgo(item.publishedAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
// BARIS BERITA (thumbnail kecil + teks, tanpa kotak)
// ================================================================
class _NewsRow extends StatelessWidget {
  final NewsItem item;
  final AuthTokens t;

  const _NewsRow({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: kAuthOrange.withOpacity(0.10),
      onTap: () => openNewsLink(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: kAuthOrange,
                          ),
                        ),
                      ),
                      Text(
                        '  •  ${newsTimeAgo(item.publishedAt)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: NewsImage(url: item.imageUrl, width: 84, height: 84),
            ),
          ],
        ),
      ),
    );
  }
}