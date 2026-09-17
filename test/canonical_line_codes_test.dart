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

    test('verifies all MRT and LRT lines have stations populated in sequence', () {
      expect(CanonicalLineCodes.stations.length, greaterThan(130));

      // EWL has 35 stations
      final ewl = CanonicalLineCodes.getStationsForLine(MRTLine.ewl);
      expect(ewl.length, equals(35));
      expect(ewl.first.code, equals('EW1'));
      expect(ewl.any((s) => s.code == 'EW33'), isTrue); // Tuas Link

      // NSL has 27 stations
      final nsl = CanonicalLineCodes.getStationsForLine(MRTLine.nsl);
      expect(nsl.length, equals(27));
      expect(nsl.first.allCodes, contains('NS1')); // Jurong East
      expect(nsl.any((s) => s.code == 'NS12'), isTrue); // Canberra
      expect(nsl.last.code, equals('NS28')); // Marina South Pier

      // NEL has 17 stations
      final nel = CanonicalLineCodes.getStationsForLine(MRTLine.nel);
      expect(nel.length, equals(17));
      expect(nel.first.code, equals('NE1'));
      expect(nel.last.code, equals('NE18')); // Punggol Coast

      // CCL has 30 stations
      final ccl = CanonicalLineCodes.getStationsForLine(MRTLine.ccl);
      expect(ccl.length, equals(30));

      // DTL has 34 stations
      final dtl = CanonicalLineCodes.getStationsForLine(MRTLine.dtl);
      expect(dtl.length, equals(34));
      expect(dtl.first.code, equals('DT1'));
      expect(dtl.last.allCodes, contains('DT35')); // Expo

      // TEL has 27 stations
      final tel = CanonicalLineCodes.getStationsForLine(MRTLine.tel);
      expect(tel.length, equals(27));
      expect(tel.first.code, equals('TE1'));
      expect(tel.last.code, equals('TE29')); // Bayshore

      // LRT lines populated
      final bplrt = CanonicalLineCodes.getStationsForLine(MRTLine.bplrt);
      expect(bplrt.length, equals(13));

      final slrt = CanonicalLineCodes.getStationsForLine(MRTLine.slrt);
      expect(slrt.length, equals(14));

      final plrt = CanonicalLineCodes.getStationsForLine(MRTLine.plrt);
      expect(plrt.length, equals(15));
    });
  });
}
