import 'package:family_care/core/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CivilDate', () {
    test('parses and formats ISO dates', () {
      final d = CivilDate.parse('2026-03-08');
      expect(d.year, 2026);
      expect(d.month, 3);
      expect(d.day, 8);
      expect(d.toIso(), '2026-03-08');
    });

    test('rejects invalid dates', () {
      expect(() => CivilDate.parse('2026-02-30'), throwsFormatException);
      expect(() => CivilDate.parse('26-2-3'), throwsFormatException);
      expect(() => CivilDate.parse(''), throwsFormatException);
    });

    test('addDays crosses month, year and leap day', () {
      expect(CivilDate(2026, 1, 31).addDays(1), CivilDate(2026, 2, 1));
      expect(CivilDate(2026, 12, 31).addDays(1), CivilDate(2027, 1, 1));
      expect(CivilDate(2028, 2, 28).addDays(1), CivilDate(2028, 2, 29));
      expect(CivilDate(2026, 3, 1).addDays(-1), CivilDate(2026, 2, 28));
    });

    test('addDays is unaffected by DST transitions', () {
      // US spring-forward 2026-03-08, EU 2026-03-29, fall-back 2026-11-01.
      expect(CivilDate(2026, 3, 7).addDays(1), CivilDate(2026, 3, 8));
      expect(CivilDate(2026, 3, 8).addDays(1), CivilDate(2026, 3, 9));
      expect(CivilDate(2026, 10, 31).addDays(2), CivilDate(2026, 11, 2));
      expect(CivilDate(2026, 3, 1).addDays(30), CivilDate(2026, 3, 31));
    });

    test('addMonths clamps to month end and honours anchor day', () {
      expect(CivilDate(2026, 1, 31).addMonths(1), CivilDate(2026, 2, 28));
      expect(CivilDate(2028, 1, 31).addMonths(1), CivilDate(2028, 2, 29));
      expect(
        CivilDate(2026, 2, 28).addMonths(1, anchorDay: 31),
        CivilDate(2026, 3, 31),
      );
      expect(CivilDate(2026, 12, 15).addMonths(1), CivilDate(2027, 1, 15));
      expect(CivilDate(2026, 1, 15).addMonths(-1), CivilDate(2025, 12, 15));
    });

    test('comparison, equality, daysUntil, weekday', () {
      final a = CivilDate(2026, 9, 25);
      final b = CivilDate(2026, 10, 2);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.daysUntil(b), 7);
      expect(b.daysUntil(a), -7);
      expect(a, CivilDate(2026, 9, 25));
      expect({a, CivilDate(2026, 9, 25)}.length, 1);
      expect(a.weekday, DateTime.friday);
    });

    test('fromDateTime uses the local wall-clock date', () {
      expect(
        CivilDate.fromDateTime(DateTime(2026, 9, 25, 23, 59)),
        CivilDate(2026, 9, 25),
      );
    });

    test('formatMinutes24', () {
      expect(formatMinutes24(0), '00:00');
      expect(formatMinutes24(630), '10:30');
      expect(formatMinutes24(1439), '23:59');
    });
  });
}
