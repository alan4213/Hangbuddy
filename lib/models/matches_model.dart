class MatchesModel {
  static final MatchesModel _instance = MatchesModel._internal();
  factory MatchesModel() => _instance;
  MatchesModel._internal();

  List<Map<String, dynamic>> _matches = [];
  
  List<Map<String, dynamic>> get matches => _matches;
  
  void addMatch(Map<String, dynamic> match) {
    _matches.add(match);
  }
  
  void removeMatch(Map<String, dynamic> match) {
    _matches.remove(match);
  }
}