/// Static, bundled content.
class MonthWord {
  final String en, translit, fr, noteEn, ar;
  const MonthWord({
    required this.en,
    required this.translit,
    required this.fr,
    required this.noteEn,
    required this.ar,
  });
}

const monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const monthsAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const daysEn = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const daysFullEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const daysAr = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

/// Month number (1-12) -> Word of the Month.
/// Audio: drop a recording named <MM>.mp3 into assets/audio/words/ (see README).
const monthWords = <int, MonthWord>{
  1: MonthWord(
    en: 'Sugar',
    translit: 'sukkar · sugar',
    fr: 'sucre',
    noteEn: 'A word the island still uses every day. It reached French through Arabic.',
    ar: 'سُكَّر',
  ),
  2: MonthWord(
    en: 'Cotton',
    translit: 'quṭn · cotton',
    fr: 'coton',
    noteEn: 'From quṭn. It travelled into French as coton and into English as cotton.',
    ar: 'قُطْن',
  ),
  3: MonthWord(
    en: 'Coffee',
    translit: 'qahwa · coffee',
    fr: 'café',
    noteEn: 'Through Turkish and Italian, qahwa became café.',
    ar: 'قَهْوَة',
  ),
  4: MonthWord(
    en: 'Store',
    translit: 'makhāzin · stores, warehouses',
    fr: 'magasin',
    noteEn: 'The plural of makhzan, a storehouse. It gave French magasin.',
    ar: 'مَخازِن',
  ),
  5: MonthWord(
    en: 'Tamarind',
    translit: 'tamr hindī · “date of India”',
    fr: 'tamarin',
    noteEn: 'Tamr hindī, literally “date of India”, became tamarin in French.',
    ar: 'تَمْر هِنْدِيّ',
  ),
  6: MonthWord(
    en: 'Saffron',
    translit: 'zaʿfarān · saffron',
    fr: 'safran',
    noteEn: 'From zaʿfarān. In French it is safran.',
    ar: 'زَعْفَران',
  ),
  7: MonthWord(
    en: 'Zero',
    translit: 'ṣifr · empty, zero',
    fr: 'zéro, chiffre',
    noteEn: 'Ṣifr means “empty”. It gave French both zéro and chiffre.',
    ar: 'صِفْر',
  ),
  8: MonthWord(
    en: 'Algebra',
    translit: 'al-jabr · algebra',
    fr: 'algèbre',
    noteEn: 'From al-jabr, in the title of al-Khwārizmī’s book of the 9th century.',
    ar: 'الجَبْر',
  ),
  9: MonthWord(
    en: 'Jasmine',
    translit: 'yāsamīn · jasmine',
    fr: 'jasmin',
    noteEn: 'From yāsamīn, itself borrowed from Persian. French has jasmin.',
    ar: 'ياسَمين',
  ),
  10: MonthWord(
    en: 'Orange',
    translit: 'nāranj · bitter orange',
    fr: 'orange',
    noteEn: 'From nāranj, an Arabic word borrowed from Persian. French has orange.',
    ar: 'نارَنْج',
  ),
  11: MonthWord(
    en: 'Syrup',
    translit: 'sharāb · a drink',
    fr: 'sirop',
    noteEn: 'From sharāb, “a drink”. It gave French sirop.',
    ar: 'شَراب',
  ),
  12: MonthWord(
    en: 'Ḍād',
    translit: 'al-ḍād · the letter ḍād',
    fr: 'la lettre ḍād',
    noteEn:
        'The letter that gave Arabic its old nickname, “the language of the ḍād”. 18 December is World Arabic Language Day.',
    ar: 'الضّاد',
  ),
};

class PlannerEvent {
  final DateTime date;
  final String en, ar;
  const PlannerEvent(this.date, this.en, this.ar);
}

/// ASU / language events (shown in gold).
final events = <PlannerEvent>[
  PlannerEvent(DateTime(2027, 12, 18), 'World Arabic Language Day', 'اليوم العالمي للغة العربية'),
];

const _arDigits = '٠١٢٣٤٥٦٧٨٩';
String toArabicDigits(Object n) =>
    n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : _arDigits[i];
    }).join();

bool isEventDay(DateTime d) =>
    events.any((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day);

List<PlannerEvent> eventsOn(DateTime d) =>
    events.where((e) => e.date.year == d.year && e.date.month == d.month && e.date.day == d.day).toList();
