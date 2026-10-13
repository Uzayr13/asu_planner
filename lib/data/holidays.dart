import 'calendar_math.dart';

/// Public holidays of Mauritius, 2027.
///
/// SOURCE: Cabinet decision of 28 August 2026 (as reported by mauritiusbiz.com
/// and newsmoris.com; the two lists agree). The government's own page could not
/// be reached when this was compiled, so check it against the Government
/// Information Service / Gazette notice before release.
///
/// Only Eid-Ul-Fitr is flagged `provisional`: the Cabinet list says its date is
/// subject to moon sighting. To correct a date, edit it here.
class Holiday {
  const Holiday(this.month, this.day, this.en, this.ar, {this.provisional = false});
  final int month, day;
  final String en, ar;
  final bool provisional;
  DateTime get date => DateTime(planYear, month, day);
}

// Arabic names are draft translations for the ASU team to review.
const holidays = <Holiday>[
  Holiday(1, 1, 'New Year’s Day', 'رأس السنة الميلادية'),
  Holiday(1, 2, 'New Year Holiday', 'عطلة رأس السنة'),
  Holiday(1, 22, 'Thaipoosam Cavadee', 'عيد التايبوسام كافادي'),
  Holiday(2, 1, 'Abolition of Slavery', 'ذكرى إلغاء العبودية'),
  Holiday(2, 6, 'Chinese Spring Festival', 'عيد الربيع الصيني'),
  Holiday(3, 6, 'Maha Shivaratree', 'ماها شيفاراتري'),
  Holiday(3, 10, 'Eid-Ul-Fitr', 'عيد الفطر', provisional: true), // moon sighting
  Holiday(3, 12, 'Independence and Republic Day', 'عيد الاستقلال والجمهورية'),
  Holiday(4, 7, 'Ougadi', 'عيد أوغادي'),
  Holiday(5, 1, 'Labour Day', 'عيد العمال'),
  // Ganesh Chaturthi falls on a Sunday, so Monday 6 Sep is also a holiday
  // (Public Holidays Act, s.3(3)).
  Holiday(9, 5, 'Ganesh Chaturthi', 'غانيش شاتورثي'),
  Holiday(9, 6, 'Ganesh Chaturthi (day in lieu)', 'عطلة بدل غانيش شاتورثي'),
  Holiday(10, 29, 'Divali', 'ديوالي (عيد الأنوار)'),
  Holiday(11, 1, 'All Saints Day', 'عيد جميع القديسين'),
  Holiday(11, 2, 'Arrival of Indentured Labourers', 'وصول العمال المتعاقدين'),
  Holiday(12, 25, 'Christmas Day', 'عيد الميلاد'),
];

List<Holiday> holidaysOn(DateTime d) => d.year != planYear
    ? const []
    : holidays.where((h) => h.month == d.month && h.day == d.day).toList();

List<Holiday> holidaysInMonth(int month) => holidays.where((h) => h.month == month).toList();

bool isHoliday(DateTime d) => holidaysOn(d).isNotEmpty;
