/// One country in the dialling-code picker.
class CountryCode {
  const CountryCode({
    required this.isoCode,
    required this.dialCode,
    required this.nameEn,
    required this.nameAr,
    required this.flag,
  });

  final String isoCode;
  final String dialCode;
  final String nameEn;
  final String nameAr;
  final String flag;

  String nameFor(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  /// True when either name or the dialling code contains [query].
  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    return nameEn.toLowerCase().contains(q) ||
        nameAr.contains(q) ||
        dialCode.contains(q) ||
        isoCode.toLowerCase().contains(q);
  }
}

/// The dialling codes offered by the phone field.
///
/// Playvo launches in Palestine, so Palestine is the default, but a player
/// may register with a number from anywhere — the list is sorted by name in
/// the language being displayed so it can actually be scanned.
class CountryCodes {
  CountryCodes._();

  static const String defaultIsoCode = 'PS';

  static CountryCode get defaultCountry =>
      all.firstWhere((CountryCode c) => c.isoCode == defaultIsoCode);

  /// Sorted by the displayed name for [languageCode].
  static List<CountryCode> sortedFor(String languageCode) {
    final List<CountryCode> list = List<CountryCode>.of(all);
    list.sort(
      (CountryCode a, CountryCode b) =>
          a.nameFor(languageCode).compareTo(b.nameFor(languageCode)),
    );
    return list;
  }

  static const List<CountryCode> all = <CountryCode>[
    CountryCode(isoCode: 'PS', dialCode: '+970', nameEn: 'Palestine', nameAr: 'فلسطين', flag: '🇵🇸'),
    CountryCode(isoCode: 'JO', dialCode: '+962', nameEn: 'Jordan', nameAr: 'الأردن', flag: '🇯🇴'),
    CountryCode(isoCode: 'EG', dialCode: '+20', nameEn: 'Egypt', nameAr: 'مصر', flag: '🇪🇬'),
    CountryCode(isoCode: 'SA', dialCode: '+966', nameEn: 'Saudi Arabia', nameAr: 'السعودية', flag: '🇸🇦'),
    CountryCode(isoCode: 'AE', dialCode: '+971', nameEn: 'United Arab Emirates', nameAr: 'الإمارات', flag: '🇦🇪'),
    CountryCode(isoCode: 'QA', dialCode: '+974', nameEn: 'Qatar', nameAr: 'قطر', flag: '🇶🇦'),
    CountryCode(isoCode: 'KW', dialCode: '+965', nameEn: 'Kuwait', nameAr: 'الكويت', flag: '🇰🇼'),
    CountryCode(isoCode: 'BH', dialCode: '+973', nameEn: 'Bahrain', nameAr: 'البحرين', flag: '🇧🇭'),
    CountryCode(isoCode: 'OM', dialCode: '+968', nameEn: 'Oman', nameAr: 'عُمان', flag: '🇴🇲'),
    CountryCode(isoCode: 'YE', dialCode: '+967', nameEn: 'Yemen', nameAr: 'اليمن', flag: '🇾🇪'),
    CountryCode(isoCode: 'IQ', dialCode: '+964', nameEn: 'Iraq', nameAr: 'العراق', flag: '🇮🇶'),
    CountryCode(isoCode: 'SY', dialCode: '+963', nameEn: 'Syria', nameAr: 'سوريا', flag: '🇸🇾'),
    CountryCode(isoCode: 'LB', dialCode: '+961', nameEn: 'Lebanon', nameAr: 'لبنان', flag: '🇱🇧'),
    CountryCode(isoCode: 'TR', dialCode: '+90', nameEn: 'Türkiye', nameAr: 'تركيا', flag: '🇹🇷'),
    CountryCode(isoCode: 'LY', dialCode: '+218', nameEn: 'Libya', nameAr: 'ليبيا', flag: '🇱🇾'),
    CountryCode(isoCode: 'TN', dialCode: '+216', nameEn: 'Tunisia', nameAr: 'تونس', flag: '🇹🇳'),
    CountryCode(isoCode: 'DZ', dialCode: '+213', nameEn: 'Algeria', nameAr: 'الجزائر', flag: '🇩🇿'),
    CountryCode(isoCode: 'MA', dialCode: '+212', nameEn: 'Morocco', nameAr: 'المغرب', flag: '🇲🇦'),
    CountryCode(isoCode: 'MR', dialCode: '+222', nameEn: 'Mauritania', nameAr: 'موريتانيا', flag: '🇲🇷'),
    CountryCode(isoCode: 'SD', dialCode: '+249', nameEn: 'Sudan', nameAr: 'السودان', flag: '🇸🇩'),
    CountryCode(isoCode: 'SO', dialCode: '+252', nameEn: 'Somalia', nameAr: 'الصومال', flag: '🇸🇴'),
    CountryCode(isoCode: 'DJ', dialCode: '+253', nameEn: 'Djibouti', nameAr: 'جيبوتي', flag: '🇩🇯'),
    CountryCode(isoCode: 'KM', dialCode: '+269', nameEn: 'Comoros', nameAr: 'جزر القمر', flag: '🇰🇲'),
    CountryCode(isoCode: 'US', dialCode: '+1', nameEn: 'United States', nameAr: 'الولايات المتحدة', flag: '🇺🇸'),
    CountryCode(isoCode: 'CA', dialCode: '+1', nameEn: 'Canada', nameAr: 'كندا', flag: '🇨🇦'),
    CountryCode(isoCode: 'MX', dialCode: '+52', nameEn: 'Mexico', nameAr: 'المكسيك', flag: '🇲🇽'),
    CountryCode(isoCode: 'BR', dialCode: '+55', nameEn: 'Brazil', nameAr: 'البرازيل', flag: '🇧🇷'),
    CountryCode(isoCode: 'AR', dialCode: '+54', nameEn: 'Argentina', nameAr: 'الأرجنتين', flag: '🇦🇷'),
    CountryCode(isoCode: 'CL', dialCode: '+56', nameEn: 'Chile', nameAr: 'تشيلي', flag: '🇨🇱'),
    CountryCode(isoCode: 'CO', dialCode: '+57', nameEn: 'Colombia', nameAr: 'كولومبيا', flag: '🇨🇴'),
    CountryCode(isoCode: 'GB', dialCode: '+44', nameEn: 'United Kingdom', nameAr: 'المملكة المتحدة', flag: '🇬🇧'),
    CountryCode(isoCode: 'IE', dialCode: '+353', nameEn: 'Ireland', nameAr: 'أيرلندا', flag: '🇮🇪'),
    CountryCode(isoCode: 'FR', dialCode: '+33', nameEn: 'France', nameAr: 'فرنسا', flag: '🇫🇷'),
    CountryCode(isoCode: 'DE', dialCode: '+49', nameEn: 'Germany', nameAr: 'ألمانيا', flag: '🇩🇪'),
    CountryCode(isoCode: 'NL', dialCode: '+31', nameEn: 'Netherlands', nameAr: 'هولندا', flag: '🇳🇱'),
    CountryCode(isoCode: 'BE', dialCode: '+32', nameEn: 'Belgium', nameAr: 'بلجيكا', flag: '🇧🇪'),
    CountryCode(isoCode: 'ES', dialCode: '+34', nameEn: 'Spain', nameAr: 'إسبانيا', flag: '🇪🇸'),
    CountryCode(isoCode: 'PT', dialCode: '+351', nameEn: 'Portugal', nameAr: 'البرتغال', flag: '🇵🇹'),
    CountryCode(isoCode: 'IT', dialCode: '+39', nameEn: 'Italy', nameAr: 'إيطاليا', flag: '🇮🇹'),
    CountryCode(isoCode: 'CH', dialCode: '+41', nameEn: 'Switzerland', nameAr: 'سويسرا', flag: '🇨🇭'),
    CountryCode(isoCode: 'AT', dialCode: '+43', nameEn: 'Austria', nameAr: 'النمسا', flag: '🇦🇹'),
    CountryCode(isoCode: 'SE', dialCode: '+46', nameEn: 'Sweden', nameAr: 'السويد', flag: '🇸🇪'),
    CountryCode(isoCode: 'NO', dialCode: '+47', nameEn: 'Norway', nameAr: 'النرويج', flag: '🇳🇴'),
    CountryCode(isoCode: 'DK', dialCode: '+45', nameEn: 'Denmark', nameAr: 'الدنمارك', flag: '🇩🇰'),
    CountryCode(isoCode: 'FI', dialCode: '+358', nameEn: 'Finland', nameAr: 'فنلندا', flag: '🇫🇮'),
    CountryCode(isoCode: 'PL', dialCode: '+48', nameEn: 'Poland', nameAr: 'بولندا', flag: '🇵🇱'),
    CountryCode(isoCode: 'CZ', dialCode: '+420', nameEn: 'Czechia', nameAr: 'التشيك', flag: '🇨🇿'),
    CountryCode(isoCode: 'GR', dialCode: '+30', nameEn: 'Greece', nameAr: 'اليونان', flag: '🇬🇷'),
    CountryCode(isoCode: 'RO', dialCode: '+40', nameEn: 'Romania', nameAr: 'رومانيا', flag: '🇷🇴'),
    CountryCode(isoCode: 'UA', dialCode: '+380', nameEn: 'Ukraine', nameAr: 'أوكرانيا', flag: '🇺🇦'),
    CountryCode(isoCode: 'RU', dialCode: '+7', nameEn: 'Russia', nameAr: 'روسيا', flag: '🇷🇺'),
    CountryCode(isoCode: 'CY', dialCode: '+357', nameEn: 'Cyprus', nameAr: 'قبرص', flag: '🇨🇾'),
    CountryCode(isoCode: 'ZA', dialCode: '+27', nameEn: 'South Africa', nameAr: 'جنوب أفريقيا', flag: '🇿🇦'),
    CountryCode(isoCode: 'NG', dialCode: '+234', nameEn: 'Nigeria', nameAr: 'نيجيريا', flag: '🇳🇬'),
    CountryCode(isoCode: 'KE', dialCode: '+254', nameEn: 'Kenya', nameAr: 'كينيا', flag: '🇰🇪'),
    CountryCode(isoCode: 'ET', dialCode: '+251', nameEn: 'Ethiopia', nameAr: 'إثيوبيا', flag: '🇪🇹'),
    CountryCode(isoCode: 'GH', dialCode: '+233', nameEn: 'Ghana', nameAr: 'غانا', flag: '🇬🇭'),
    CountryCode(isoCode: 'SN', dialCode: '+221', nameEn: 'Senegal', nameAr: 'السنغال', flag: '🇸🇳'),
    CountryCode(isoCode: 'IR', dialCode: '+98', nameEn: 'Iran', nameAr: 'إيران', flag: '🇮🇷'),
    CountryCode(isoCode: 'PK', dialCode: '+92', nameEn: 'Pakistan', nameAr: 'باكستان', flag: '🇵🇰'),
    CountryCode(isoCode: 'AF', dialCode: '+93', nameEn: 'Afghanistan', nameAr: 'أفغانستان', flag: '🇦🇫'),
    CountryCode(isoCode: 'IN', dialCode: '+91', nameEn: 'India', nameAr: 'الهند', flag: '🇮🇳'),
    CountryCode(isoCode: 'BD', dialCode: '+880', nameEn: 'Bangladesh', nameAr: 'بنغلاديش', flag: '🇧🇩'),
    CountryCode(isoCode: 'ID', dialCode: '+62', nameEn: 'Indonesia', nameAr: 'إندونيسيا', flag: '🇮🇩'),
    CountryCode(isoCode: 'MY', dialCode: '+60', nameEn: 'Malaysia', nameAr: 'ماليزيا', flag: '🇲🇾'),
    CountryCode(isoCode: 'SG', dialCode: '+65', nameEn: 'Singapore', nameAr: 'سنغافورة', flag: '🇸🇬'),
    CountryCode(isoCode: 'TH', dialCode: '+66', nameEn: 'Thailand', nameAr: 'تايلاند', flag: '🇹🇭'),
    CountryCode(isoCode: 'PH', dialCode: '+63', nameEn: 'Philippines', nameAr: 'الفلبين', flag: '🇵🇭'),
    CountryCode(isoCode: 'VN', dialCode: '+84', nameEn: 'Vietnam', nameAr: 'فيتنام', flag: '🇻🇳'),
    CountryCode(isoCode: 'CN', dialCode: '+86', nameEn: 'China', nameAr: 'الصين', flag: '🇨🇳'),
    CountryCode(isoCode: 'JP', dialCode: '+81', nameEn: 'Japan', nameAr: 'اليابان', flag: '🇯🇵'),
    CountryCode(isoCode: 'KR', dialCode: '+82', nameEn: 'South Korea', nameAr: 'كوريا الجنوبية', flag: '🇰🇷'),
    CountryCode(isoCode: 'AU', dialCode: '+61', nameEn: 'Australia', nameAr: 'أستراليا', flag: '🇦🇺'),
    CountryCode(isoCode: 'NZ', dialCode: '+64', nameEn: 'New Zealand', nameAr: 'نيوزيلندا', flag: '🇳🇿'),
  ];
}
