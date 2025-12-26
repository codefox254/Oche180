class Tournament {
  final int id;
  final String name;
  final String description;
  final String tournamentFormat;
  final String status;
  final String gameMode;
  final int organizerId;
  final String organizerName;
  final int maxParticipants;
  final int participantCount;
  final int spotsRemaining;
  final bool isRegistrationOpen;
  final bool isFeatured;
  final bool requireApproval;
  final String? minSkillLevel;
  final String? maxSkillLevel;
  final String? gameName;
  final DateTime registrationStart;
  final DateTime registrationEnd;
  final DateTime startTime;
  final num prizePool;
  final String? bannerImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.tournamentFormat,
    required this.status,
    required this.gameMode,
    required this.organizerId,
    required this.organizerName,
    required this.maxParticipants,
    required this.participantCount,
    required this.spotsRemaining,
    required this.isRegistrationOpen,
    required this.isFeatured,
    required this.requireApproval,
    this.minSkillLevel,
    this.maxSkillLevel,
    this.gameName,
    required this.registrationStart,
    required this.registrationEnd,
    required this.startTime,
    required this.prizePool,
    this.bannerImage,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tournamentFormat: json['tournament_format'] ?? json['format'] ?? '',
      status: json['status'] ?? '',
      gameMode: json['game_mode'] ?? '',
      organizerId: json['organizer_id'] ?? json['organizer'],
      organizerName: json['organizer_name'] ?? '',
      maxParticipants: json['max_participants'] ?? 0,
      participantCount: json['participant_count'] ?? json['current_participants'] ?? 0,
      spotsRemaining: json['spots_remaining'] ?? 0,
      isRegistrationOpen: json['is_registration_open'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      requireApproval: json['require_approval'] ?? false,
      minSkillLevel: json['min_skill_level'],
      maxSkillLevel: json['max_skill_level'],
      gameName: json['game_name'],
      registrationStart: DateTime.parse(json['registration_start']),
      registrationEnd: DateTime.parse(json['registration_end']),
      startTime: DateTime.parse(json['start_time']),
      prizePool: json['prize_pool'] ?? 0,
      bannerImage: json['banner_image'],
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
      'tournament_format': tournamentFormat,
      'status': status,
      'game_mode': gameMode,
      'organizer': organizerId,
      'registration_start': registrationStart.toIso8601String(),
      'registration_end': registrationEnd.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'max_participants': maxParticipants,
      'participant_count': participantCount,
      'spots_remaining': spotsRemaining,
      'is_registration_open': isRegistrationOpen,
      'is_featured': isFeatured,
      'require_approval': requireApproval,
      'min_skill_level': minSkillLevel,
      'max_skill_level': maxSkillLevel,
      'game_name': gameName,
      'prize_pool': prizePool,
      'banner_image': bannerImage,
      'settings': settings,
    };
  }

  String get formatDisplay {
    switch (tournamentFormat) {
      case 'SINGLE_ELIM':
        return 'Single Elimination';
      case 'DOUBLE_ELIM':
        return 'Double Elimination';
      case 'ROUND_ROBIN':
        return 'Round Robin';
      case 'SWISS':
        return 'Swiss System';
      case 'GROUPS_KO':
        return 'Groups + Knockout';
      case 'LADDER':
        return 'Ladder';
      case 'FFA':
        return 'Free for All';
      default:
        return tournamentFormat;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'REG_OPEN':
        return 'Registration Open';
      case 'REG_CLOSED':
        return 'Registration Closed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'PAUSED':
        return 'Paused';
      case 'DRAFT':
        return 'Draft';
      default:
        return status;
    }
  }

  bool get canRegister {
    return isRegistrationOpen && participantCount < maxParticipants;
  }

  int get currentParticipants => participantCount;
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
