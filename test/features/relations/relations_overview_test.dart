import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/relations/domain/relations_overview.dart';

void main() {
  group('RelationType.fromString', () {
    test('mapea los tres valores válidos del contrato', () {
      expect(RelationType.fromString('x2'), RelationType.x2);
      expect(RelationType.fromString('x3'), RelationType.x3);
      expect(RelationType.fromString('inverso'), RelationType.inverso);
    });

    test('valores obsoletos o desconocidos → unknown (nunca crashea)', () {
      expect(RelationType.fromString('leveraged_long'), RelationType.unknown);
      expect(RelationType.fromString('inverse'), RelationType.unknown);
      expect(RelationType.fromString(''), RelationType.unknown);
      expect(RelationType.fromString(null), RelationType.unknown);
    });
  });

  group('AssetClass.fromString', () {
    test('mapea stock e index; el resto → unknown', () {
      expect(AssetClass.fromString('stock'), AssetClass.stock);
      expect(AssetClass.fromString('index'), AssetClass.indexAsset);
      expect(AssetClass.fromString('etf'), AssetClass.unknown);
      expect(AssetClass.fromString(null), AssetClass.unknown);
    });
  });

  group('RelationLink.fromJson', () {
    test('multiplier como número se parsea a double con signo', () {
      final link = RelationLink.fromJson({
        'symbol': 'TSLL',
        'name': 'Direxion Daily TSLA Bull 2X',
        'relationType': 'x2',
        'multiplier': 2.0,
      });

      expect(link.symbol, 'TSLL');
      expect(link.name, 'Direxion Daily TSLA Bull 2X');
      expect(link.relationType, RelationType.x2);
      expect(link.multiplier, 2.0);
    });

    test('multiplier como string ("-1.00") se parsea de forma defensiva', () {
      final link = RelationLink.fromJson({
        'symbol': 'TSLS',
        'name': 'AXS TSLA Bear Daily',
        'relationType': 'inverso',
        'multiplier': '-1.00',
      });

      expect(link.multiplier, -1.0);
      expect(link.relationType, RelationType.inverso);
    });

    test('multiplier inválido/ausente cae a 0.0 sin crashear', () {
      final link = RelationLink.fromJson({
        'symbol': 'X',
        'name': 'X',
        'relationType': 'x3',
        'multiplier': 'no-numérico',
      });

      expect(link.multiplier, 0.0);
    });
  });

  group('RelationsOverview.fromJson', () {
    test('deserializa la respuesta completa del contrato', () {
      final json = {
        'assets': [
          {
            'symbol': 'TSLA',
            'name': 'Tesla, Inc.',
            'assetClass': 'stock',
            'longEtfs': [
              {
                'symbol': 'TSLL',
                'name': 'Direxion Daily TSLA Bull 2X',
                'relationType': 'x2',
                'multiplier': 2.0,
              },
            ],
            'inverseEtfs': [
              {
                'symbol': 'TSLS',
                'name': 'AXS TSLA Bear Daily',
                'relationType': 'inverso',
                'multiplier': -1.0,
              },
            ],
          },
        ],
        'sectors': [
          {
            'etf': 'XLK',
            'sectorName': 'Technology',
            'inverseEtfs': [
              {
                'symbol': 'TECS',
                'name': 'Direxion Daily Tech Bear 3X',
                'relationType': 'inverso',
                'multiplier': -3.0,
              },
            ],
          },
        ],
      };

      final overview = RelationsOverview.fromJson(json);

      expect(overview.assets, hasLength(1));
      final asset = overview.assets.first;
      expect(asset.symbol, 'TSLA');
      expect(asset.assetClass, AssetClass.stock);
      expect(asset.longEtfs.single.symbol, 'TSLL');
      expect(asset.inverseEtfs.single.multiplier, -1.0);

      expect(overview.sectors, hasLength(1));
      final sector = overview.sectors.first;
      expect(sector.etf, 'XLK');
      expect(sector.sectorName, 'Technology');
      expect(sector.inverseEtfs.single.symbol, 'TECS');
      expect(overview.isEmpty, isFalse);
    });

    test('arrays vacíos y ausentes → listas vacías, nunca null', () {
      final empty = RelationsOverview.fromJson({
        'assets': <dynamic>[],
        'sectors': <dynamic>[],
      });
      expect(empty.assets, isEmpty);
      expect(empty.sectors, isEmpty);
      expect(empty.isEmpty, isTrue);

      final missing = RelationsOverview.fromJson(<String, dynamic>{});
      expect(missing.assets, isEmpty);
      expect(missing.sectors, isEmpty);
    });
  });
}
