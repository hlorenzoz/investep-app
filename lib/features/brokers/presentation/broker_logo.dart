import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
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
        oldWidget.broker.logo != widget.broker.logo ||
        oldWidget.broker.icon != widget.broker.icon ||
        oldWidget.broker.favicon != widget.broker.favicon) {
      _initSources();
    }
  }

  void _initSources() {
    _sources = [
      widget.broker.logo,
      widget.broker.icon,
      widget.broker.favicon,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    _currentIndex = 0;
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
