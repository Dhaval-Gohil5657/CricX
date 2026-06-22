import 'player_model.dart';

class Team {
  final String id;
  final String name;
  final String abbreviation;
  final String logoEmoji; // Simple modern representations since we don't have images
  final int logoColorHex; // Hex color for the logo avatar
  List<Player> players;
  int matchesPlayed;
  int matchesWon;
  int matchesLost;
  double netRunRate;

  Team({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.logoEmoji,
    required this.logoColorHex,
    required this.players,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.netRunRate = 0.0,
  });

  int get points => matchesWon * 2;
}
