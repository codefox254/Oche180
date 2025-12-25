class Tournament {
  final int id;
  final String name;
  final String description;
  final String format;
  final String status;
  final int organizerId;
  final String organizerName;
  final int? gameId;
  final String? gameName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int maxParticipants;
  final int currentParticipants;
  final String? minSkillLevel;
  final String? maxSkillLevel;
  final bool requireApproval;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    this.gameId,
    this.gameName,
    this.startTime,
    this.endTime,
    required this.maxParticipants,
    required this.currentParticipants,
    this.minSkillLevel,
    this.maxSkillLevel,
    required this.requireApproval,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      format: json['format'],
      status: json['status'],
      organizerId: json['organizer_id'] ?? json['organizer'],
      organizerName: json['organizer_name'] ?? '',
      gameId: json['game_id'],
      gameName: json['game_name'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      maxParticipants: json['max_participants'],
      currentParticipants: json['current_participants'] ?? 0,
      minSkillLevel: json['min_skill_level'],
      maxSkillLevel: json['max_skill_level'],
      requireApproval: json['require_approval'],
      isFeatured: json['is_featured'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'format': format,
      'status': status,
      'organizer': organizerId,
      'game': gameId,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'max_participants': maxParticipants,
      'min_skill_level': minSkillLevel,
      'max_skill_level': maxSkillLevel,
      'require_approval': requireApproval,
      'is_featured': isFeatured,
      'settings': settings,
    };
  }

  String get formatDisplay {
    switch (format) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss':
        return 'Swiss System';
      case 'groups_knockout':
        return 'Groups + Knockout';
      case 'ladder':
        return 'Ladder';
      case 'free_for_all':
        return 'Free for All';
      default:
        return format;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'registration':
        return 'Registration Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isRegistrationOpen {
    return status == 'registration' || status == 'pending';
  }

  bool get canRegister {
    return isRegistrationOpen && currentParticipants < maxParticipants;
  }
}

class TournamentEntry {
  final int id;
  final int tournamentId;
  final int playerId;
  final String playerName;
  final String status;
  final int? seedNumber;
  final DateTime registeredAt;
  final DateTime? approvedAt;

  TournamentEntry({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.playerName,
    required this.status,
    this.seedNumber,
    required this.registeredAt,
    this.approvedAt,
  });

  factory TournamentEntry.fromJson(Map<String, dynamic> json) {
    return TournamentEntry(
      id: json['id'],
      tournamentId: json['tournament_id'] ?? json['tournament'],
      playerId: json['player_id'] ?? json['player'],
      playerName: json['player_name'] ?? '',
      status: json['status'],
      seedNumber: json['seed_number'],
      registeredAt: DateTime.parse(json['registered_at']),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';
}

class TournamentMatch {
  final int id;
  final int tournamentId;
  final int roundNumber;
  final int matchNumber;
  final int? player1Id;
  final String? player1Name;
  final int? player2Id;
  final String? player2Name;
  final int? winnerId;
  final String? winnerName;
  final String status;
  final int? player1Score;
  final int? player2Score;
  final DateTime? scheduledTime;
  final DateTime? completedAt;
  final int bracketPosition;
  final int? nextMatchId;
  final int? nextMatchPosition;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.matchNumber,
    this.player1Id,
    this.player1Name,
    this.player2Id,
    this.player2Name,
    this.winnerId,
    this.winnerName,
    required this.status,
    this.player1Score,
    this.player2Score,
    this.scheduledTime,
    this.completedAt,
    required this.bracketPosition,
    this.nextMatchId,
    this.nextMatchPosition,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      tournamentId: json['tournament_id'] ?? json['tournament'],
      roundNumber: json['round_number'],
      matchNumber: json['match_number'],
      player1Id: json['player1_id'],
      player1Name: json['player1_name'],
      player2Id: json['player2_id'],
      player2Name: json['player2_name'],
      winnerId: json['winner_id'],
      winnerName: json['winner_name'],
      status: json['status'],
      player1Score: json['player1_score'],
      player2Score: json['player2_score'],
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      bracketPosition: json['bracket_position'],
      nextMatchId: json['next_match_id'],
      nextMatchPosition: json['next_match_position'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isWalkover => status == 'walkover';

  bool get hasPlayers => player1Id != null && player2Id != null;
  bool get isBye => player1Id == null || player2Id == null;
}

class TournamentRound {
  final int roundNumber;
  final String name;
  final List<TournamentMatch> matches;
  final String status;

  TournamentRound({
    required this.roundNumber,
    required this.name,
    required this.matches,
    required this.status,
  });

  factory TournamentRound.fromJson(Map<String, dynamic> json) {
    return TournamentRound(
      roundNumber: json['round_number'],
      name: json['name'],
      matches: (json['matches'] as List)
          .map((m) => TournamentMatch.fromJson(m))
          .toList(),
      status: json['status'],
    );
  }
}
