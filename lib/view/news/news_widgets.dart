import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:equate/model/news_model.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/view/news/news_detail_view.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';
import 'package:equate/viewmodel/news_viewmodel.dart';

// ================================================================
// HELPER
// ================================================================
String newsTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return tr('Baru saja', 'Just now');
  if (diff.inMinutes < 60) {
    return tr('${diff.inMinutes} mnt lalu', '${diff.inMinutes}m ago');
  }
  if (diff.inHours < 24) {
    return tr('${diff.inHours} jam lalu', '${diff.inHours}h ago');
  }
  return tr('${diff.inDays} hari lalu', '${diff.inDays}d ago');
}

/// Dipanggil saat berita diketuk: buka artikel di dalam aplikasi.
void openNewsLink(BuildContext context, NewsItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => NewsDetailView(item: item)),
  );
}

/// Buka artikel asli di browser.
Future<void> openNewsInBrowser(BuildContext context, NewsItem item) async {
  try {
    final ok = await launchUrl(
      Uri.parse(item.link),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) _error(context);
  } catch (_) {
    if (context.mounted) _error(context);
  }
}

void _error(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tr('Tidak dapat membuka berita.', 'Unable to open the article.'),
      ),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ================================================================
// GAMBAR BERITA (dengan fallback gradasi oranye)
// ================================================================
class NewsImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;

  const NewsImage({super.key, required this.url, this.width, this.height});

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          color: Colors.white.withOpacity(0.8),
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url == null) return _fallback();

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: kAuthOrange.withOpacity(0.08),
        );
      },
    );
  }
}

// ================================================================
// BANNER BERITA DI BERANDA (carousel, geser otomatis, tanpa judul)
// ================================================================
class HomeNewsBanner extends StatefulWidget {
  final bool isDark;

  const HomeNewsBanner({super.key, required this.isDark});

  @override
  State<HomeNewsBanner> createState() => _HomeNewsBannerState();
}

class _HomeNewsBannerState extends State<HomeNewsBanner> {
  final NewsViewModel _vm = NewsViewModel.instance;
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _vm.load();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final count = _vm.items.take(5).length;
      if (count < 2 || !_controller.hasClients) return;
      final next = (_page + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final items = _vm.items.take(5).toList();

        if (items.isEmpty && !_vm.isLoading) return const SizedBox.shrink();

        if (items.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                color: kAuthOrange,
                strokeWidth: 2.4,
              ),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 158,
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == items.length - 1 ? 0 : 10,
                    ),
                    child: _BannerCard(item: items[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  width: active ? 18 : 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active
                        ? kAuthOrange
                        : (widget.isDark
                              ? Colors.white.withOpacity(0.18)
                              : Colors.black.withOpacity(0.12)),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final NewsItem item;

  const _BannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.78),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          newsTimeAgo(item.publishedAt),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
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
    );
  }
}