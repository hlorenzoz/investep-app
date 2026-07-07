import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/brokers/domain/broker.dart';
import 'package:investep_app/features/brokers/presentation/broker_logo.dart';

// 1x1 PNG transparente.
const _pngDataUri =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMCAYAAACjF7+IAAAAASUVORK5CYII=';
const _svgDataUri =
    'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('sin assets → fallback al ícono (no Image ni SvgPicture)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(id: 1, slug: 'x', name: 'X'),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('logo data: PNG → Image (raster vía memory)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(id: 1, slug: 'x', name: 'X', logo: _pngDataUri),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('logo data: SVG → SvgPicture', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(id: 1, slug: 'x', name: 'X', logo: _svgDataUri),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('logo direct SVG → SvgPicture', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(
            id: 1,
            slug: 'x',
            name: 'X',
            logo:
                '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>',
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets(
    'broker conocido por slug (ibkr) → renderiza SVG local (SvgPicture)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrokerLogo(
            broker: Broker(id: 1, slug: 'ibkr', name: 'Interactive Brokers'),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    },
  );

  testWidgets(
    'prioriza el favicon remoto de la API y lo resuelve a URL absoluta',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrokerLogo(
            broker: Broker(
              id: 1,
              slug: 'x',
              name: 'X',
              logo: 'brokers/logo.png',
              icon: 'brokers/icon.png',
              favicon: 'brokers/favicon.png',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      final networkImage = imageWidget.image as NetworkImage;
      expect(
        networkImage.url,
        'https://assets.investepacademy.com/brokers/favicon.png',
      );
    },
  );

  testWidgets('cae a localSvg si las fuentes remotas fallan al cargar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(
            id: 1,
            slug: 'ibkr',
            name: 'Interactive Brokers',
            favicon: 'brokers/broken-favicon.png',
          ),
        ),
      ),
    );

    // Primer frame: intenta cargar el favicon remoto (.png), se renderiza Image
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);

    // Disparar el frame asíncrono para que se ejecute el errorBuilder y _onError
    await tester.pump();
    await tester
        .pump(); // Procesar addPostFrameCallback y setState del fallback

    // Tras la falla, debe avanzar al localSvg y renderizar SvgPicture
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
