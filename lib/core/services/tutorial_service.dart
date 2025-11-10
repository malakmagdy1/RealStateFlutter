import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialKey = 'tutorial_seen';
  static const String _homeKey = 'tutorial_home_seen';
  static const String _searchKey = 'tutorial_search_seen';
  static const String _compoundsKey = 'tutorial_compounds_seen';
  static const String _companiesKey = 'tutorial_companies_seen';
  static const String _webKey = 'tutorial_web_seen';

  /// Check if tutorial has been seen for a specific screen
  Future<bool> hasSeen(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(screenKey) ?? false;
  }

  /// Mark tutorial as seen for a specific screen
  Future<void> markAsSeen(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(screenKey, true);
  }

  /// Check if main tutorial has been seen
  Future<bool> hasSeenMainTutorial() async {
    return hasSeen(_tutorialKey);
  }

  /// Mark main tutorial as seen
  Future<void> markMainTutorialAsSeen() async {
    return markAsSeen(_tutorialKey);
  }

  /// Check if home screen tutorial has been seen
  Future<bool> hasSeenHomeTutorial() async {
    return hasSeen(_homeKey);
  }

  /// Mark home screen tutorial as seen
  Future<void> markHomeTutorialAsSeen() async {
    return markAsSeen(_homeKey);
  }

  /// Check if search screen tutorial has been seen
  Future<bool> hasSeenSearchTutorial() async {
    return hasSeen(_searchKey);
  }

  /// Mark search screen tutorial as seen
  Future<void> markSearchTutorialAsSeen() async {
    return markAsSeen(_searchKey);
  }

  /// Check if compounds screen tutorial has been seen
  Future<bool> hasSeenCompoundsTutorial() async {
    return hasSeen(_compoundsKey);
  }

  /// Mark compounds screen tutorial as seen
  Future<void> markCompoundsTutorialAsSeen() async {
    return markAsSeen(_compoundsKey);
  }

  /// Check if companies screen tutorial has been seen
  Future<bool> hasSeenCompaniesTutorial() async {
    return hasSeen(_companiesKey);
  }

  /// Mark companies screen tutorial as seen
  Future<void> markCompaniesTutorialAsSeen() async {
    return markAsSeen(_companiesKey);
  }

  /// Check if web tutorial has been seen
  Future<bool> hasSeenWebTutorial() async {
    return hasSeen(_webKey);
  }

  /// Mark web tutorial as seen
  Future<void> markWebTutorialAsSeen() async {
    return markAsSeen(_webKey);
  }

  /// Reset all tutorials (useful for testing or if user wants to see them again)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialKey);
    await prefs.remove(_homeKey);
    await prefs.remove(_searchKey);
    await prefs.remove(_compoundsKey);
    await prefs.remove(_companiesKey);
    await prefs.remove(_webKey);
  }

  /// Reset specific tutorial
  Future<void> resetTutorial(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(screenKey);
  }
}
