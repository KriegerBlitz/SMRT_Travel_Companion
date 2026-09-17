import 'package:flutter_test/flutter_test.dart';
import 'package:travelcompanion/core/canonical_line_codes.dart';

void main() {
  group('CanonicalLineCodes - Reconciliation', () {
    test('reconciles Sengkang LRT variants to SLRT', () {
      expect(CanonicalLineCodes.reconcileLineCode('STL'), equals('SLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('SK'), equals('SLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('SE'), equals('SLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('SW'), equals('SLRT'));
    });

    test('reconciles Punggol LRT variants to PLRT', () {
      expect(CanonicalLineCodes.reconcileLineCode('PEL'), equals('PLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('PTL'), equals('PLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('PG'), equals('PLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('PE'), equals('PLRT'));
    });

    test('reconciles Bukit Panjang LRT variants to BPLRT', () {
      expect(CanonicalLineCodes.reconcileLineCode('BPL'), equals('BPLRT'));
      expect(CanonicalLineCodes.reconcileLineCode('BP'), equals('BPLRT'));
    });

    test('reconciles Circle Line extension CEL to CCL', () {
      expect(CanonicalLineCodes.reconcileLineCode('CEL'), equals('CCL'));
      expect(CanonicalLineCodes.reconcileLineCode('CC'), equals('CCL'));
    });

    test('reconciles Changi Airport branch CGL to EWL', () {
      expect(CanonicalLineCodes.reconcileLineCode('CGL'), equals('EWL'));
      expect(CanonicalLineCodes.reconcileLineCode('CG'), equals('EWL'));
    });

    test('reconciles MRTLine enum lookup correctly', () {
      expect(MRTLine.fromCode('STL'), equals(MRTLine.slrt));
      expect(MRTLine.fromCode('CEL'), equals(MRTLine.ccl));
      expect(MRTLine.fromCode('CGL'), equals(MRTLine.ewl));
      expect(MRTLine.fromCode('EWL'), equals(MRTLine.ewl));
      expect(MRTLine.fromCode('DTL'), equals(MRTLine.dtl));
    });
  });

  group('CanonicalLineCodes - Station Lookup', () {
    test('finds station by name (exact & fuzzy)', () {
      final tampines = CanonicalLineCodes.findStationByName('Tampines');
      expect(tampines, isNotNull);
      expect(tampines!.code, equals('EW2'));
      expect(tampines.isInterchange, isTrue);

      final raffles = CanonicalLineCodes.findStationByName('raffles place');
      expect(raffles, isNotNull);
      expect(raffles!.code, equals('EW14'));

      final outram = CanonicalLineCodes.findStationByName('Outram Park');
      expect(outram, isNotNull);
      expect(outram!.allCodes, contains('EW16'));
      expect(outram.allCodes, contains('NE3'));
      expect(outram.allCodes, contains('TE17'));
    });

    test('finds station by code', () {
      final stn = CanonicalLineCodes.findStationByCode('EW5');
      expect(stn, isNotNull);
      expect(stn!.name, equals('Bedok'));

      final dtlStn = CanonicalLineCodes.findStationByCode('DT32');
      expect(dtlStn, isNotNull);
      expect(dtlStn!.name, contains('Tampines'));
    });

    test('calculates correct station sequence on same line', () {
      final tampines = CanonicalLineCodes.findStationByCode('EW2')!;
      final raffles = CanonicalLineCodes.findStationByCode('EW14')!;
      final seq = CanonicalLineCodes.getRouteSequence(tampines, raffles);

      expect(seq.first.code, equals('EW2'));
      expect(seq.last.code, equals('EW14'));
      expect(seq.any((s) => s.code == 'EW5'), isTrue); // Bedok in between
      expect(seq.length, greaterThanOrEqualTo(10));
    });
  });
}
