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

  testWidgets('broker conocido por slug (ibkr) → renderiza SVG local (SvgPicture)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const BrokerLogo(
          broker: Broker(
            id: 1,
            slug: 'ibkr',
            name: 'Interactive Brokers',
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
