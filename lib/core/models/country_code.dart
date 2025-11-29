class CountryCode {
  final String name;
  final String nameAr;
  final String code;
  final String dialCode;
  final String flag;
  final int minLength;
  final int maxLength;

  const CountryCode({
    required this.name,
    required this.nameAr,
    required this.code,
    required this.dialCode,
    required this.flag,
    this.minLength = 7,
    this.maxLength = 12,
  });

  String get displayName => '$flag  $nameAr';
  String get displayDialCode => '$flag $dialCode';

  static const List<CountryCode> arabCountries = [
    // Gulf Countries
    CountryCode(
      name: 'Saudi Arabia',
      nameAr: 'السعودية',
      code: 'SA',
      dialCode: '+966',
      flag: '🇸🇦',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'United Arab Emirates',
      nameAr: 'الإمارات',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Kuwait',
      nameAr: 'الكويت',
      code: 'KW',
      dialCode: '+965',
      flag: '🇰🇼',
      minLength: 8,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Qatar',
      nameAr: 'قطر',
      code: 'QA',
      dialCode: '+974',
      flag: '🇶🇦',
      minLength: 8,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Bahrain',
      nameAr: 'البحرين',
      code: 'BH',
      dialCode: '+973',
      flag: '🇧🇭',
      minLength: 8,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Oman',
      nameAr: 'عُمان',
      code: 'OM',
      dialCode: '+968',
      flag: '🇴🇲',
      minLength: 8,
      maxLength: 8,
    ),

    // Levant Countries
    CountryCode(
      name: 'Egypt',
      nameAr: 'مصر',
      code: 'EG',
      dialCode: '+20',
      flag: '🇪🇬',
      minLength: 10,
      maxLength: 10,
    ),
    CountryCode(
      name: 'Jordan',
      nameAr: 'الأردن',
      code: 'JO',
      dialCode: '+962',
      flag: '🇯🇴',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Lebanon',
      nameAr: 'لبنان',
      code: 'LB',
      dialCode: '+961',
      flag: '🇱🇧',
      minLength: 7,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Syria',
      nameAr: 'سوريا',
      code: 'SY',
      dialCode: '+963',
      flag: '🇸🇾',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Palestine',
      nameAr: 'فلسطين',
      code: 'PS',
      dialCode: '+970',
      flag: '🇵🇸',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Iraq',
      nameAr: 'العراق',
      code: 'IQ',
      dialCode: '+964',
      flag: '🇮🇶',
      minLength: 10,
      maxLength: 10,
    ),

    // North Africa
    CountryCode(
      name: 'Morocco',
      nameAr: 'المغرب',
      code: 'MA',
      dialCode: '+212',
      flag: '🇲🇦',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Algeria',
      nameAr: 'الجزائر',
      code: 'DZ',
      dialCode: '+213',
      flag: '🇩🇿',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Tunisia',
      nameAr: 'تونس',
      code: 'TN',
      dialCode: '+216',
      flag: '🇹🇳',
      minLength: 8,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Libya',
      nameAr: 'ليبيا',
      code: 'LY',
      dialCode: '+218',
      flag: '🇱🇾',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Sudan',
      nameAr: 'السودان',
      code: 'SD',
      dialCode: '+249',
      flag: '🇸🇩',
      minLength: 9,
      maxLength: 9,
    ),

    // Other Arab Countries
    CountryCode(
      name: 'Yemen',
      nameAr: 'اليمن',
      code: 'YE',
      dialCode: '+967',
      flag: '🇾🇪',
      minLength: 9,
      maxLength: 9,
    ),
    CountryCode(
      name: 'Mauritania',
      nameAr: 'موريتانيا',
      code: 'MR',
      dialCode: '+222',
      flag: '🇲🇷',
      minLength: 8,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Somalia',
      nameAr: 'الصومال',
      code: 'SO',
      dialCode: '+252',
      flag: '🇸🇴',
      minLength: 7,
      maxLength: 8,
    ),
    CountryCode(
      name: 'Djibouti',
      nameAr: 'جيبوتي',
      code: 'DJ',
      dialCode: '+253',
      flag: '🇩🇯',
      minLength: 6,
      maxLength: 6,
    ),
    CountryCode(
      name: 'Comoros',
      nameAr: 'جزر القمر',
      code: 'KM',
      dialCode: '+269',
      flag: '🇰🇲',
      minLength: 7,
      maxLength: 7,
    ),
  ];

  static CountryCode getDefault() {
    return arabCountries.firstWhere(
      (country) => country.code == 'EG',
      orElse: () => arabCountries.first,
    );
  }

  static CountryCode? findByCode(String code) {
    try {
      return arabCountries.firstWhere((country) => country.code == code);
    } catch (_) {
      return null;
    }
  }

  static CountryCode? findByDialCode(String dialCode) {
    try {
      return arabCountries.firstWhere((country) => country.dialCode == dialCode);
    } catch (_) {
      return null;
    }
  }
}
