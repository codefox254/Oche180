import '../../../core/services/api_service.dart';
import '../models/tournament.dart';

class TournamentService {
  final ApiService _apiService;

  TournamentService(this._apiService);

  // Get all tournaments
  Future<List<Tournament>> getTournaments({
    String? status,
    String? format,
    bool? featured,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (format != null) queryParams['format'] = format;
    if (featured != null) queryParams['is_featured'] = featured.toString();

    final response = await _apiService.get(
      'tournaments/',
      queryParameters: queryParams,
    );

    final List<dynamic> data = response;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  // Get featured tournaments
  Future<List<Tournament>> getFeaturedTournaments() async {
    final response = await _apiService.get('tournaments/featured/');
    final List<dynamic> data = response;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  // Get upcoming tournaments
  Future<List<Tournament>> getUpcomingTournaments() async {
    final response = await _apiService.get('tournaments/upcoming/');
    final List<dynamic> data = response;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  // Get my tournaments
  Future<List<Tournament>> getMyTournaments() async {
    final response = await _apiService.get('tournaments/my_tournaments/');
    final List<dynamic> data = response;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  // Get tournament details
  Future<Tournament> getTournament(int id) async {
    final response = await _apiService.get('tournaments/$id/');
    return Tournament.fromJson(response);
  }

  // Create tournament
  Future<Tournament> createTournament(Map<String, dynamic> data) async {
    final response = await _apiService.post('tournaments/', data);
    return Tournament.fromJson(response);
  }

  // Update tournament
  Future<Tournament> updateTournament(int id, Map<String, dynamic> data) async {
    final response = await _apiService.patch('tournaments/$id/', data);
    return Tournament.fromJson(response);
  }

  // Delete tournament
  Future<void> deleteTournament(int id) async {
    await _apiService.delete('tournaments/$id/');
  }

  // Register for tournament
  Future<TournamentEntry> registerForTournament(int tournamentId) async {
    final response = await _apiService.post(
      'tournaments/$tournamentId/register/',
      {},
    );
    return TournamentEntry.fromJson(response);
  }

  // Withdraw from tournament
  Future<void> withdrawFromTournament(int tournamentId) async {
    await _apiService.post('tournaments/$tournamentId/withdraw/', {});
  }

  // Add players (batch)
  Future<List<TournamentEntry>> addPlayersBatch(
    int tournamentId,
    List<int> playerIds,
  ) async {
    final response = await _apiService.post(
      'tournaments/$tournamentId/add_players/',
      {'player_ids': playerIds},
    );
    final List<dynamic> data = response;
    return data.map((json) => TournamentEntry.fromJson(json)).toList();
  }

  // Approve entry
  Future<TournamentEntry> approveEntry(int tournamentId, int entryId) async {
    final response = await _apiService.post(
      'tournaments/$tournamentId/approve_entry/',
      {'entry_id': entryId},
    );
    return TournamentEntry.fromJson(response);
  }

  // Start tournament
  Future<Tournament> startTournament(int tournamentId) async {
    final response = await _apiService.post(
      'tournaments/$tournamentId/start_tournament/',
      {},
    );
    return Tournament.fromJson(response);
  }

  // Report match result
  Future<TournamentMatch> reportMatchResult(
    int matchId,
    int winnerId,
    int player1Score,
    int player2Score,
  ) async {
    final response = await _apiService.post(
      'tournament-matches/$matchId/report_result/',
      {
        'winner_id': winnerId,
        'player1_score': player1Score,
        'player2_score': player2Score,
      },
    );
    return TournamentMatch.fromJson(response);
  }

  // Get tournament bracket (all rounds and matches)
  Future<Map<String, dynamic>> getTournamentBracket(int tournamentId) async {
    final response = await _apiService.get('tournaments/$tournamentId/');
    return response;
  }

  // Get tournament entries
  Future<List<TournamentEntry>> getTournamentEntries(
    int tournamentId, {
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    final response = await _apiService.get(
      'tournaments/$tournamentId/',
      queryParameters: queryParams,
    );

    final entries = response['entries'] as List<dynamic>?;
    if (entries == null) return [];

    return entries.map((json) => TournamentEntry.fromJson(json)).toList();
  }

  // Get tournament matches
  Future<List<TournamentMatch>> getTournamentMatches(int tournamentId) async {
    final response = await _apiService.get('tournaments/$tournamentId/');
    final matches = response['matches'] as List<dynamic>?;
    if (matches == null) return [];

    return matches.map((json) => TournamentMatch.fromJson(json)).toList();
  }

  // Get tournament rounds
  Future<List<TournamentRound>> getTournamentRounds(int tournamentId) async {
    final response = await _apiService.get('tournaments/$tournamentId/');
    final rounds = response['rounds'] as List<dynamic>?;
    if (rounds == null) return [];

    return rounds.map((json) => TournamentRound.fromJson(json)).toList();
  }
}
