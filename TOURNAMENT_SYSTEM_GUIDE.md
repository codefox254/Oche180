# Tournament System Complete Guide

## Overview
Oche180 features a comprehensive tournament system supporting multiple formats, automatic bracket generation, advanced pairing algorithms, and sophisticated tiebreak rules.

## Features

### Tournament Formats
1. **Single Elimination** - Traditional knockout bracket
2. **Double Elimination** - Winners and losers brackets
3. **Round Robin** - Everyone plays everyone
4. **Swiss System** - Players with similar scores face each other
5. **Groups + Knockout** - Group stage followed by playoffs
6. **Ladder** - Continuous ranking system
7. **Free-for-All** - Open competition format

### Privacy & Registration
- **Public Tournaments** - Visible to all users, open registration
- **Private Tournaments** - Hidden from public listing, invitation/password only
- **Registration Controls**:
  - Password protection
  - Organizer approval required
  - Skill level requirements
  - Participant limits (min/max)

### Automatic Pairing & Brackets
- **Single/Double Elimination**: Automatic seeding and bracket generation
- **Round Robin**: Complete round-robin scheduling
- **Swiss System**: Intelligent pairing based on standings
  - Avoids repeat matches
  - Pairs similar-ranked players
  - Automatic bye handling

### Tiebreak System
When players have equal tournament points, the following tiebreak rules apply (in order):

1. **Direct Comparison** (Head-to-head record)
2. **Buchholz Score** - Sum of opponents' tournament points
3. **Sonneborn-Berger** - Weighted opponent score (wins count full, draws half)
4. **Points Difference** - (Points For) - (Points Against)
5. **Points For** - Total points scored

#### Buchholz Score
```
Buchholz = Σ(opponent's tournament points)
```
Higher Buchholz means you played against stronger opponents.

#### Sonneborn-Berger
```
SB = Σ(result × opponent's tournament points)
Where result: 1.0 for win, 0.5 for draw, 0.0 for loss
```
Rewards beating strong opponents more than weak ones.

## Tournament Lifecycle

### 1. Draft → Registration Open
- Organizer creates tournament
- Sets all parameters (format, dates, limits, privacy)
- Opens registration

### 2. Registration Open → Registration Closed
- Players register (with approval if required)
- Organizer can manually add players
- Auto-closes at registration deadline

### 3. Registration Closed → In Progress
- Organizer starts tournament
- System generates brackets/pairings
- First round becomes available

### 4. In Progress → Completed
- Matches are played and scored
- Winners advance (elimination) or standings updated (Swiss/RR)
- Tournament completes when all matches finish

### 5. Completed
- Final standings locked
- Awards distributed
- XP/ratings updated

## API Endpoints

### Tournament Management
```
GET    /api/tournaments/              # List all tournaments
POST   /api/tournaments/              # Create tournament
GET    /api/tournaments/{id}/         # Get tournament details
PATCH  /api/tournaments/{id}/         # Update tournament
DELETE /api/tournaments/{id}/         # Delete tournament

GET    /api/tournaments/upcoming/     # Upcoming tournaments
GET    /api/tournaments/in_progress/  # Active tournaments
GET    /api/tournaments/completed/    # Past tournaments
GET    /api/tournaments/my_tournaments/ # User's tournaments
GET    /api/tournaments/featured/     # Featured tournaments
```

### Registration
```
POST   /api/tournaments/{id}/register/       # Register for tournament
POST   /api/tournaments/{id}/withdraw/       # Withdraw from tournament
POST   /api/tournaments/{id}/approve_entry/  # Approve pending entry (organizer)
```

### Tournament Control
```
POST   /api/tournaments/{id}/start_tournament/ # Start and generate brackets
POST   /api/tournaments/{id}/generate_passcode/ # Generate score submission passcode
POST   /api/tournaments/{id}/verify_passcode/  # Verify passcode
```

### Standings & Results
```
GET    /api/tournaments/{id}/standings/  # Get current standings
POST   /api/tournaments/{id}/submit_score/ # Submit match score
```

## Backend Models

### Tournament
Main tournament model with:
- Format, game mode, settings
- Registration controls (public/private, password, approval)
- Timing (registration period, start time)
- Participant limits and skill requirements
- Prize pool and rewards
- Status tracking

### TournamentEntry
Player registration:
- Status (pending, confirmed, withdrawn, disqualified)
- Seed number
- Statistics (wins, losses, points)
- Final placement and rewards

### TournamentRound
Represents each round:
- Round number and name
- Losers bracket flag (for double elimination)
- Timing

### TournamentMatch
Individual matches:
- Players (via TournamentEntry)
- Scores
- Winner
- Next match (bracket progression)
- Game reference

### TournamentStanding
Real-time leaderboard:
- Rank
- Match statistics (played, won, lost, drawn)
- Scoring (points for/against/difference)
- Tournament points
- **Tiebreak scores** (Buchholz, Sonneborn-Berger)
- Performance metrics

### PlayerTournamentRating
ELO-style rating system:
- Current rating (default 1500)
- Peak/lowest ratings
- Tournament history (played, won, placements)
- Match record
- Skill tier (Bronze → Grandmaster)

### TournamentInvitation
Private tournament invitations:
- Status (pending, accepted, declined, expired)
- Expiry date
- Custom message

### MatchScoreSubmission
Score submission tracking:
- Submitted scores
- Verification status
- Passcode validation
- Dispute handling

## Bracket Generation Algorithms

### Single Elimination
```python
1. Calculate rounds needed: ceil(log2(players))
2. Calculate bracket size: 2^rounds
3. Add byes for non-power-of-2 participants
4. Create rounds with descriptive names (Finals, Semifinals, etc.)
5. Assign seeded players to matches
6. Auto-advance bye winners
7. Link matches to next round
```

### Double Elimination
```python
1. Generate winners bracket (single elimination)
2. Create losers bracket rounds: 2*(rounds-1) - 1
3. Link losers from winners bracket
4. Track through both brackets
5. Grand finals with potential bracket reset
```

### Round Robin
```python
1. Calculate rounds: n-1 (even) or n (odd)
2. Add dummy player if odd
3. Use round-robin rotation algorithm:
   - Keep first player fixed
   - Rotate remaining players
4. Generate all possible matchups
5. Handle bye rounds for odd participants
```

### Swiss System
```python
1. Calculate recommended rounds: ceil(log2(players))
2. First round: Random or seeded pairing
3. Subsequent rounds:
   - Sort by tournament points + tiebreaks
   - Pair players with similar scores
   - Avoid repeat matchups
   - Handle odd player with bye
4. Update standings after each round:
   - Recalculate tournament points
   - Compute Buchholz score
   - Compute Sonneborn-Berger
   - Determine ranks with tiebreaks
```

## Admin Controls

Admins can control tournament functionality via AppSettings:

```python
- tournaments_enabled: bool          # Enable/disable tournaments globally
- max_tournaments_per_user: int     # Limit per organizer
- max_tournament_participants: int  # Global maximum size
- xp_multiplier: decimal            # XP boost for events
```

Access at `/admin/core/appsettings/`

## Score Submission System

### Passcode Protection
1. Organizer generates 6-digit passcode
2. Shared with participants
3. Required for score submission
4. Prevents unauthorized score entry

### Verification Flow
```
Player submits score → Check passcode → Create submission
                               ↓
                       Status: PENDING
                               ↓
                       Organizer reviews
                               ↓
                    VERIFIED / DISPUTED / REJECTED
```

## Rating System (ELO)

### Calculation
```python
Expected Score = 1 / (1 + 10^((opponent_rating - player_rating) / 400))
Actual Score = 1 (win) or 0 (loss)
Rating Change = K-factor × (Actual - Expected)

Default K-factor = 32
```

### Skill Tiers
```
Rating Range  → Tier
2400+         → Grandmaster
2200-2399     → Master
2000-2199     → Diamond
1800-1999     → Platinum
1600-1799     → Gold
1400-1599     → Silver
< 1400        → Bronze
```

## XP & Rewards

### Placement Points
```python
- 1st Place: base × 10
- 2nd Place: base × 6
- 3rd-4th: base × 3
- 5th-8th: base × 2
- Participation: base × 1

base = winner_xp_reward (default 500)
```

### Rating Updates
- Applied after tournament completes
- Based on match results vs opponents
- Affects future tournament seeding

## Frontend Integration

### Tournament List Screens
- **Upcoming**: Registration open + future start time
- **In Progress**: Currently active
- **Completed**: Finished tournaments
- **My Tournaments**: User's participated/organized

### Privacy Filtering
- Public tournaments: Visible to all
- Private tournaments: Only visible to:
  - Organizer
  - Registered participants
  - Invited users

### Registration Flow
```
Browse Tournaments → Select → Check Requirements
                              ↓
                   Password (if required)
                              ↓
                   Submit Registration
                              ↓
           Auto-confirm OR Pending Approval
```

## Best Practices

### For Organizers
1. Set realistic participant limits
2. Allow enough registration time
3. Use seeding for competitive balance
4. Generate passcode before tournament starts
5. Monitor score submissions
6. Handle disputes promptly

### For Participants
1. Register early (limited spots)
2. Check requirements (skill level, fees)
3. Note tournament start time
4. Keep passcode secure
5. Submit scores promptly
6. Respect tournament rules

### For Developers
1. Always update standings after match completion
2. Recalculate tiebreaks when standings change
3. Cache tournament settings for performance
4. Validate bracket integrity before starting
5. Handle concurrent score submissions carefully

## Troubleshooting

### Common Issues

**"Not enough participants"**
- Ensure min_participants is reasonable
- Check confirmed entries count
- Approve pending entries if required

**"Bracket generation failed"**
- Check for odd participants in elimination
- Verify tournament format is supported
- Ensure entries have unique seeds

**"Score submission rejected"**
- Verify passcode is correct
- Check if score submission is enabled
- Ensure user is match participant

**Tiebreak not resolving**
- All tiebreak metrics are identical (rare)
- System falls back to registration time
- Consider manual intervention

## Future Enhancements
- [ ] Live match streaming integration
- [ ] Automated scheduling with time slots
- [ ] Team tournaments
- [ ] Multi-stage tournaments
- [ ] Prize distribution automation
- [ ] Tournament templates
- [ ] Spectator mode
- [ ] Tournament analytics dashboard

## Support
For issues or questions:
- Check API documentation: `/api/schema/swagger-ui/`
- Review tournament admin panel
- Contact system administrator
