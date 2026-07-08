import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GlobalBannerAd extends StatefulWidget {
  const GlobalBannerAd({super.key});

  @override
  State<GlobalBannerAd> createState() => _GlobalBannerAdState();
}

class _GlobalBannerAdState extends State<GlobalBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AnchoredAdaptiveBannerAdSize? _adSize;
  double? _loadedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double currentWidth = MediaQuery.of(context).size.width;
    if (_loadedWidth != currentWidth) {
      _loadedWidth = currentWidth;
      _loadAd(currentWidth);
    }
  }

  Future<void> _loadAd(double width) async {
    // Cancel/dispose of existing ad if any
    await _bannerAd?.dispose();
    if (!mounted) return;
    
    setState(() {
      _isLoaded = false;
      _bannerAd = null;
    });

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width.truncate());

    if (size == null) {
      debugPrint('Unable to get adaptive banner size.');
      return;
    }

    if (!mounted) return;

    // For production, use: 'ca-app-pub-1829431093631944/2181376555'
    final bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner
          : 'ca-app-pub-3940256099942544/2934735716', // iOS test banner
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _adSize = size;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AnchoredAdaptiveBannerAdSize failed to load: $error');
          ad.dispose();
        },
      ),
    );
    await bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null && _adSize != null) {
      return Container(
        color: Colors.transparent,
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Return a tiny spacer while loading, to avoid layout shifts.
    return const SizedBox.shrink();
  }
}
