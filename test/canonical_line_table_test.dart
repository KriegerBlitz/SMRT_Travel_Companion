import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/transit/canonical_line_table.dart';

void main() {
  group('GroundLevel Parsing', () {
    test('handles variations of above-ground, at-grade, and elevated as aboveGround', () {
      expect(GroundLevel.fromString('at-grade'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('at_grade'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('atgrade'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('atGrade'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('AT-GRADE'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('aboveground'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('ABOVEGROUND'), equals(GroundLevel.aboveGround));
      expect(GroundLevel.fromString('elevated'), equals(GroundLevel.aboveGround));
    });

    test('handles underground and subsurface as underground', () {
      expect(GroundLevel.fromString('underground'), equals(GroundLevel.underground));
      expect(GroundLevel.fromString('UNDERGROUND'), equals(GroundLevel.underground));
      expect(GroundLevel.fromString('subsurface'), equals(GroundLevel.underground));
      expect(GroundLevel.fromString('sub-surface'), equals(GroundLevel.underground));
      expect(GroundLevel.underground.isUnderground, isTrue);
      expect(GroundLevel.aboveGround.isUnderground, isFalse);
    });
  });

  group('Canonical Line Table Mappings', () {
    test('reconciles TrainServiceAlerts codes (STL -> SLRT, PTL -> PLRT)', () {
      final sengkangLines = CanonicalLineTable.fromAlertsCode('STL');
      expect(sengkangLines.single.canonicalCode, equals('SLRT'));

      final punggolLines = CanonicalLineTable.fromAlertsCode('PTL');
      expect(punggolLines.single.canonicalCode, equals('PLRT'));
    });

    test('maps station codes to crowd query lines (CGL, CEL, SLRT, PLRT)', () {
      expect(CanonicalLineTable.toCrowdQueryLine('CG1'), equals('CGL'));
      expect(CanonicalLineTable.toCrowdQueryLine('CE2'), equals('CEL'));
      expect(CanonicalLineTable.toCrowdQueryLine('STL'), equals('SLRT'));
      expect(CanonicalLineTable.toCrowdQueryLine('PTL'), equals('PLRT'));
      expect(CanonicalLineTable.toCrowdQueryLine('EW14'), equals('EWL'));
    });

    test('maps crowd codes back to alert codes', () {
      expect(CanonicalLineTable.toAlertsLineCode('SLRT'), equals('STL'));
      expect(CanonicalLineTable.toAlertsLineCode('PLRT'), equals('PTL'));
      expect(CanonicalLineTable.toAlertsLineCode('CGL'), equals('EWL'));
      expect(CanonicalLineTable.toAlertsLineCode('CEL'), equals('CCL'));
    });

    test('verifies persona station records', () {
      // Rachel: Tampines -> Raffles Place
      final tampines = CanonicalLineTable.findStationByCode('EW2');
      expect(tampines, isNotNull);
      expect(tampines!.name, equals('Tampines'));
      expect(tampines.isInterchange, isTrue);

      final raffles = CanonicalLineTable.findStationByName('Raffles Place');
      expect(raffles, isNotNull);
      expect(raffles!.groundLevel, equals(GroundLevel.underground));

      // Mdm Lim: Bedok -> Outram Park (SGH)
      final bedok = CanonicalLineTable.findStationByCode('EW5');
      expect(bedok, isNotNull);
      expect(bedok!.name, equals('Bedok'));

      final outram = CanonicalLineTable.findStationByName('Outram Park');
      expect(outram, isNotNull);
      expect(outram!.hasLine('EWL'), isTrue);
      expect(outram.hasLine('NEL'), isTrue);
      expect(outram.hasLine('TEL'), isTrue);
    });
  });
}
