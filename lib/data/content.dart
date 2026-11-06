import 'calendar_math.dart' show planYear;

/// Static, bundled content.
///
/// The vocabulary runs on a semi-monthly schedule: one word for the launch
/// fortnight of 18–31 Dec 2026, then two per calendar month through 2027 —
/// 25 in total. Each word owns an inclusive date range; `wordAt` and
/// `wordIndexAt` are the only things that reason about those ranges.
class Word {
  const Word({
    required this.from,
    required this.to,
    required this.en,
    required this.translit,
    required this.fr,
    required this.noteEn,
    required this.ar,
  });

  /// Inclusive date range this word covers.
  final DateTime from, to;

  /// English meaning, transliteration, French meaning, and a usage note.
  final String en, translit, fr, noteEn;

  /// The Arabic word itself.
  final String ar;

  bool contains(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

  /// "1–15 Jan", "16–31 Jan". The year appears only where it differs from
  /// [planYear], so the launch word reads "18–31 Dec 2026".
  String get rangeLabel {
    final month = monthsEn[from.month - 1].substring(0, 3);
    final span = '${from.day}–${to.day} $month';
    return from.year == planYear ? span : '$span ${from.year}';
  }
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

/// The 25-word schedule, in order. Slot 1 is the launch word for the
/// presentation on 18 December 2026; the rest are two per month through 2027.
///
/// Audio: `assets/audio/words/01.mp3` … `25.mp3`, numbered by position here.
///
/// Within each month the word that already had a recording comes first, and
/// the newly supplied word second.
///
/// `final` rather than `const` because `DateTime` is not const-constructible.
/// Built once at startup.
final List<Word> words = <Word>[
  // 1 — launch fortnight, 18–31 Dec 2026
  Word(
    from: DateTime(2026, 12, 18),
    to: DateTime(2026, 12, 31),
    en: 'Market',
    translit: 'sūq · market',
    fr: 'souk',
    noteEn: 'French borrowed this Arabic word for a market.',
    ar: 'سوق',
  ),
  // January 2027
  Word(
    from: DateTime(2027, 1, 1),
    to: DateTime(2027, 1, 15),
    en: 'Sugar',
    translit: 'sukkar · sugar',
    fr: 'sucre',
    noteEn: 'A word the island still uses every day. It reached French through Arabic.',
    ar: 'سُكَّر',
  ),
  Word(
    from: DateTime(2027, 1, 16),
    to: DateTime(2027, 1, 31),
    en: 'Lemon',
    translit: 'laymūn · lemon',
    fr: 'limon, limonade',
    noteEn: 'From laymūn. It reached French as limon, the word behind limonade.',
    ar: 'ليمون',
  ),
  // February
  Word(
    from: DateTime(2027, 2, 1),
    to: DateTime(2027, 2, 15),
    en: 'Cotton',
    translit: 'quṭn · cotton',
    fr: 'coton',
    noteEn: 'From quṭn. It travelled into French as coton and into English as cotton.',
    ar: 'قُطْن',
  ),
  Word(
    from: DateTime(2027, 2, 16),
    to: DateTime(2027, 2, 28),
    en: 'Mattress',
    translit: 'matraḥ · cushion or mat, historically',
    fr: 'matelas',
    noteEn: 'A word once used for a cushion or mat. Through Italian, it became matelas in French.',
    ar: 'مَطْرَح',
  ),
  // March
  Word(
    from: DateTime(2027, 3, 1),
    to: DateTime(2027, 3, 15),
    en: 'Coffee',
    translit: 'qahwa · coffee',
    fr: 'café',
    noteEn: 'Through Turkish and Italian, qahwa became café.',
    ar: 'قَهْوَة',
  ),
  Word(
    from: DateTime(2027, 3, 16),
    to: DateTime(2027, 3, 31),
    en: 'Sofa',
    translit: 'suffa · raised platform or bench',
    fr: 'sofa',
    noteEn: 'From suffa, a raised platform or bench. It reached French through Turkish as sofa.',
    ar: 'وَصَفَة',
  ),
  // April
  Word(
    from: DateTime(2027, 4, 1),
    to: DateTime(2027, 4, 15),
    en: 'Store',
    translit: 'makhāzin · stores, warehouses',
    fr: 'magasin',
    noteEn: 'The plural of makhzan, a storehouse. It gave French magasin.',
    ar: 'مَخازِن',
  ),
  Word(
    from: DateTime(2027, 4, 16),
    to: DateTime(2027, 4, 30),
    en: 'Customs',
    translit: 'dīwān · register, administrative office',
    fr: 'douane',
    noteEn: 'Borrowed into Arabic from Persian, dīwān reached French through Italian as douane.',
    ar: 'دِيوان',
  ),
  // May
  Word(
    from: DateTime(2027, 5, 1),
    to: DateTime(2027, 5, 15),
    en: 'Tamarind',
    translit: 'tamr hindī · “date of India”',
    fr: 'tamarin',
    noteEn: 'Tamr hindī, literally “date of India”, became tamarin in French.',
    ar: 'تَمْر هِنْدِيّ',
  ),
  Word(
    from: DateTime(2027, 5, 16),
    to: DateTime(2027, 5, 31),
    en: 'Gazelle',
    translit: 'ghazāl · gazelle',
    fr: 'gazelle',
    noteEn: 'The Arabic name of this animal became gazelle in French.',
    ar: 'غَزال',
  ),
  // June
  Word(
    from: DateTime(2027, 6, 1),
    to: DateTime(2027, 6, 15),
    en: 'Saffron',
    translit: 'zaʿfarān · saffron',
    fr: 'safran',
    noteEn: 'From zaʿfarān. In French it is safran.',
    ar: 'زَعْفَران',
  ),
  Word(
    from: DateTime(2027, 6, 16),
    to: DateTime(2027, 6, 30),
    en: 'Alcohol',
    translit: 'al-kuḥl · kohl, an eye cosmetic',
    fr: 'alcool',
    noteEn: 'From al-kuḥl, an eye powder. The word later gained a different meaning in European alchemy.',
    ar: 'الكُحُل',
  ),
  // July
  Word(
    from: DateTime(2027, 7, 1),
    to: DateTime(2027, 7, 15),
    en: 'Zero',
    translit: 'ṣifr · empty, zero',
    fr: 'zéro, chiffre',
    noteEn: 'Ṣifr means “empty”. It gave French both zéro and chiffre.',
    ar: 'صِفْر',
  ),
  Word(
    from: DateTime(2027, 7, 16),
    to: DateTime(2027, 7, 31),
    en: 'Carat',
    translit: 'qirāṭ · a small unit of weight',
    fr: 'carat',
    noteEn: 'From qirāṭ, a small unit of weight. It reached French through medieval Latin and Italian.',
    ar: 'قِيراط',
  ),
  // August
  Word(
    from: DateTime(2027, 8, 1),
    to: DateTime(2027, 8, 15),
    en: 'Algebra',
    translit: 'al-jabr · algebra',
    fr: 'algèbre',
    noteEn: 'From al-jabr, in the title of al-Khwārizmī’s book of the 9th century.',
    ar: 'الجَبْر',
  ),
  Word(
    from: DateTime(2027, 8, 16),
    to: DateTime(2027, 8, 31),
    en: 'Alchemy',
    translit: 'al-kīmiyāʾ · chemistry; historically, alchemy',
    fr: 'alchimie',
    noteEn: 'From al-kīmiyāʾ. It reached French through medieval Latin as alchimie.',
    ar: 'الكِيمياء',
  ),
  // September
  Word(
    from: DateTime(2027, 9, 1),
    to: DateTime(2027, 9, 15),
    en: 'Jasmine',
    translit: 'yāsamīn · jasmine',
    fr: 'jasmin',
    noteEn: 'From yāsamīn, itself borrowed from Persian. French has jasmin.',
    ar: 'ياسَمين',
  ),
  Word(
    from: DateTime(2027, 9, 16),
    to: DateTime(2027, 9, 30),
    en: 'Giraffe',
    translit: 'zarāfa · giraffe',
    fr: 'girafe',
    noteEn: 'The Arabic name travelled through Italian before becoming girafe in French.',
    ar: 'زَرافة',
  ),
  // October
  Word(
    from: DateTime(2027, 10, 1),
    to: DateTime(2027, 10, 15),
    en: 'Orange',
    translit: 'nāranj · bitter orange',
    fr: 'orange',
    noteEn: 'From nāranj, an Arabic word borrowed from Persian. French has orange.',
    ar: 'نارَنْج',
  ),
  Word(
    from: DateTime(2027, 10, 16),
    to: DateTime(2027, 10, 31),
    en: 'Safari',
    translit: 'safar · a journey',
    fr: 'safari',
    noteEn: 'Safar means “a journey”. Through Swahili, it became safari in French.',
    ar: 'سَفَر',
  ),
  // November
  Word(
    from: DateTime(2027, 11, 1),
    to: DateTime(2027, 11, 15),
    en: 'Syrup',
    translit: 'sharāb · a drink',
    fr: 'sirop',
    noteEn: 'From sharāb, “a drink”. It gave French sirop.',
    ar: 'شَراب',
  ),
  Word(
    from: DateTime(2027, 11, 16),
    to: DateTime(2027, 11, 30),
    en: 'Admiral',
    translit: 'amir · commander or prince',
    fr: 'amiral',
    noteEn: 'Amir means a commander or prince. It gave French amiral, a naval title.',
    ar: 'أمير',
  ),
  // December
  Word(
    from: DateTime(2027, 12, 1),
    to: DateTime(2027, 12, 15),
    en: 'Ḍād',
    translit: 'al-ḍād · the letter ḍād',
    fr: 'la lettre ḍād',
    noteEn:
        'The letter that gave Arabic its old nickname, “the language of the ḍād”. 18 December is World Arabic Language Day.',
    ar: 'الضّاد',
  ),
  Word(
    from: DateTime(2027, 12, 16),
    to: DateTime(2027, 12, 31),
    en: 'Arsenal',
    translit: 'dār aṣ-ṣināʿa · workshop; historically, a shipyard',
    fr: 'arsenal',
    noteEn:
        'An Arabic expression for a place of manufacture or shipyard. Through Venetian, it became arsenal.',
    ar: 'دار الصناعة',
  ),
];

/// The word covering [d], or null outside the schedule.
Word? wordAt(DateTime d) {
  for (final w in words) {
    if (w.contains(d)) return w;
  }
  return null;
}

/// 1-based position in [words] for the audio filename, or null outside the
/// schedule. `01.mp3` … `25.mp3`.
int? wordIndexAt(DateTime d) {
  for (var i = 0; i < words.length; i++) {
    if (words[i].contains(d)) return i + 1;
  }
  return null;
}

/// The words covering a calendar month, in schedule order.
///
/// A month always has two except the launch month of Dec 2026, which has one.
/// Used by the Month view to show both at once.
List<Word> wordsInMonth(int month, {int year = planYear}) =>
    words.where((w) => w.from.month == month && w.from.year == year).toList();

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
