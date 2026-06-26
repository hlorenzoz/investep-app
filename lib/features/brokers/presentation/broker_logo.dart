import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/broker.dart';

/// Logo de un broker. Los assets pueden ser URL http(s) o un `data:` URI
/// embebido, y rasterizados (png/jpg) O SVG. Soporta los 4 casos y cae al ícono
/// Lucide ante ausencia o cualquier fallo de decodificación.
class BrokerLogo extends StatelessWidget {
  const BrokerLogo({super.key, required this.broker, this.size = 28});

  final Broker broker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final src = broker.logo ?? broker.icon ?? broker.favicon;
    if (src == null || src.isEmpty) return _fallback();

    try {
      final isSvg = _isSvg(src);
      final isData = src.startsWith('data:');

      final Widget image;
      if (isData) {
        final data = UriData.parse(src);
        image = isSvg
            ? SvgPicture.string(
                data.contentAsString(),
                width: size,
                height: size,
                placeholderBuilder: (_) => _fallback(),
              )
            : Image.memory(
                data.contentAsBytes(),
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _fallback(),
              );
      } else {
        image = isSvg
            ? SvgPicture.network(
                src,
                width: size,
                height: size,
                placeholderBuilder: (_) => _fallback(),
              )
            : Image.network(
                src,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _fallback(),
              );
      }
      return SizedBox(width: size, height: size, child: image);
    } catch (_) {
      // data: URI malformado u otra falla sincrónica.
      return _fallback();
    }
  }

  bool _isSvg(String src) {
    if (src.startsWith('data:image/svg')) return true;
    final path = (Uri.tryParse(src)?.path ?? src).toLowerCase();
    return path.endsWith('.svg');
  }

  Widget _fallback() =>
      Icon(LucideIcons.building2, color: AppColors.accentSoft, size: size);
}
