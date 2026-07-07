import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/config/app_config.dart';
import '../domain/broker.dart';

/// Logo de un broker. Los assets pueden ser URL http(s) o un `data:` URI
/// embebido, y rasterizados (png/jpg) O SVG. Soporta los 4 casos y cae al ícono
/// Lucide ante ausencia o cualquier fallo de decodificación.
class BrokerLogo extends StatefulWidget {
  const BrokerLogo({super.key, required this.broker, this.size = 28});

  final Broker broker;
  final double size;

  @override
  State<BrokerLogo> createState() => _BrokerLogoState();
}

class _BrokerLogoState extends State<BrokerLogo> {
  int _currentIndex = 0;
  late List<String> _sources;

  @override
  void initState() {
    super.initState();
    _initSources();
  }

  @override
  void didUpdateWidget(covariant BrokerLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.broker.id != widget.broker.id ||
        oldWidget.broker.slug != widget.broker.slug ||
        oldWidget.broker.logo != widget.broker.logo ||
        oldWidget.broker.icon != widget.broker.icon ||
        oldWidget.broker.favicon != widget.broker.favicon) {
      _initSources();
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:')) {
      return path;
    }

    if (kIsWeb && AppConfig.r2AssetsBaseUrl.isEmpty) {
      return 'assets/images/$path';
    }

    final baseUrl = AppConfig.r2AssetsBaseUrl.isEmpty
        ? 'https://assets.investepacademy.com'
        : AppConfig.r2AssetsBaseUrl;
    return '$baseUrl/$path';
  }

  void _initSources() {
    final List<String> rawSources = [
      widget.broker.favicon,
      widget.broker.icon,
      widget.broker.logo,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    _sources = rawSources
        .map(_resolveImageUrl)
        .where((s) => s.isNotEmpty)
        .toList();

    final localSvg = _getLocalSvg(widget.broker.slug);
    if (localSvg != null) {
      _sources.add(localSvg);
    }
    _currentIndex = 0;
  }

  String? _getLocalSvg(String slug) {
    switch (slug.toLowerCase()) {
      case 'ibkr':
      case 'interactive-brokers':
        return '''
<svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="24" fill="url(#ibkrGrad)"/>
  <text x="50" y="65" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="42" fill="#FFFFFF" text-anchor="middle">IBKR</text>
  <defs>
    <linearGradient id="ibkrGrad" x1="0" y1="0" x2="100" y2="100" gradientUnits="userSpaceOnUse">
      <stop stop-color="#E50000"/>
      <stop offset="1" stop-color="#990000"/>
    </linearGradient>
  </defs>
</svg>
''';
      case 'tastytrade':
        return '''
<svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="24" fill="url(#tastyGrad)"/>
  <text x="50" y="68" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="55" fill="#FFFFFF" text-anchor="middle">t</text>
  <defs>
    <linearGradient id="tastyGrad" x1="0" y1="0" x2="100" y2="100" gradientUnits="userSpaceOnUse">
      <stop stop-color="#F20056"/>
      <stop offset="1" stop-color="#80002A"/>
    </linearGradient>
  </defs>
</svg>
''';
      case 'etrade':
      case 'e-trade':
        return '''
<svg viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" rx="24" fill="url(#etradeGrad)"/>
  <text x="45" y="68" font-family="system-ui, -apple-system, sans-serif" font-weight="800" font-size="50" fill="#FFFFFF" text-anchor="middle">e</text>
  <circle cx="70" cy="30" r="10" fill="#00FF00"/>
  <defs>
    <linearGradient id="etradeGrad" x1="0" y1="0" x2="100" y2="100" gradientUnits="userSpaceOnUse">
      <stop stop-color="#622E90"/>
      <stop offset="1" stop-color="#3B175B"/>
    </linearGradient>
  </defs>
</svg>
''';
      default:
        return null;
    }
  }

  void _onError() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex < _sources.length) {
          setState(() {
            _currentIndex++;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _sources.length) {
      return _fallback();
    }

    final src = _sources[_currentIndex];

    try {
      if (_isDirectSvg(src)) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: SvgPicture.string(
            src,
            width: widget.size,
            height: widget.size,
            errorBuilder: (context, error, stackTrace) {
              _onError();
              return _fallback();
            },
          ),
        );
      }

      final isSvg = _isSvg(src);
      final isData = src.startsWith('data:');

      final Widget image;
      if (isData) {
        final data = UriData.parse(src);
        image = isSvg
            ? SvgPicture.string(
                data.contentAsString(),
                width: widget.size,
                height: widget.size,
                errorBuilder: (context, error, stackTrace) {
                  _onError();
                  return _fallback();
                },
              )
            : Image.memory(
                data.contentAsBytes(),
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  _onError();
                  return _fallback();
                },
              );
      } else {
        image = isSvg
            ? SvgPicture.network(
                src,
                width: widget.size,
                height: widget.size,
                errorBuilder: (context, error, stackTrace) {
                  _onError();
                  return _fallback();
                },
              )
            : Image.network(
                src,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  _onError();
                  return _fallback();
                },
              );
      }
      return SizedBox(width: widget.size, height: widget.size, child: image);
    } catch (_) {
      // data: URI malformado u otra falla sincrónica.
      _onError();
      return _fallback();
    }
  }

  bool _isDirectSvg(String src) {
    final trimmed = src.trim();
    return trimmed.startsWith('<svg') || trimmed.contains('<svg ');
  }

  bool _isSvg(String src) {
    if (src.startsWith('data:image/svg')) return true;
    final path = (Uri.tryParse(src)?.path ?? src).toLowerCase();
    return path.endsWith('.svg');
  }

  Widget _fallback() => Icon(
    LucideIcons.building2,
    color: AppColors.accentSoft,
    size: widget.size,
  );
}
