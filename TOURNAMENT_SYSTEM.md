# Tournament System

## Overview
A comprehensive tournament management system for Oche180 Darts application, supporting multiple tournament formats with features inspired by online chess platforms like Lichess.

## Features

### Tournament Formats
- **Single Elimination**: Traditional knockout bracket. Lose once and you're out.
- **Double Elimination**: Players get a second chance via a losers bracket.
- **Round Robin**: Everyone plays everyone. Best overall record wins.
- **Swiss System**: Pair players with similar records each round.
- **Groups + Knockout**: Group stage followed by knockout playoffs.
- **Ladder**: Challenge players ranked above you to climb the ladder.
- **Free for All**: Multiplayer matches with points-based scoring.

### Organizer Features
- Create tournaments with customizable settings
- Set participant limits (4-128 players)
- Skill level restrictions (beginner to master)
- Manual approval for registrations
- Featured tournament designation
- Batch player addition (comma-separated IDs)
- Single player addition
- Entry management (approve/reject registrations)
- Start tournament (generates bracket automatically)
- Match result reporting

### Player Features
- Browse featured tournaments
- View upcoming tournaments
- Filter by format and status
- Register for tournaments
- View tournament details and brackets
- Live bracket visualization
- Withdraw from tournaments

### Registration System
- Open registration (instant approval)
- Manual approval workflow
- Automatic entry validation
- Skill level requirements
- Participant limit enforcement
- Registration status tracking (pending, approved, rejected, withdrawn)

## Backend API Endpoints

### Tournament Endpoints
```
GET    /api/tournaments/                 - List all tournaments
POST   /api/tournaments/                 - Create tournament
GET    /api/tournaments/{id}/            - Get tournament details
PATCH  /api/tournaments/{id}/            - Update tournament
DELETE /api/tournaments/{id}/            - Delete tournament
GET    /api/tournaments/featured/        - Get featured tournaments
GET    /api/tournaments/upcoming/        - Get upcoming tournaments
GET    /api/tournaments/my_tournaments/  - Get user's tournaments
POST   /api/tournaments/{id}/register/   - Register for tournament
POST   /api/tournaments/{id}/withdraw/   - Withdraw from tournament
POST   /api/tournaments/{id}/add_players/ - Batch add players (organizer)
POST   /api/tournaments/{id}/approve_entry/ - Approve entry (organizer)
POST   /api/tournaments/{id}/start_tournament/ - Start tournament (organizer)
```

### Match Endpoints
```
GET    /api/tournament-matches/          - List matches
GET    /api/tournament-matches/{id}/     - Get match details
POST   /api/tournament-matches/{id}/report_result/ - Report match result
```

## Database Models

### Tournament
- name: Tournament name
- description: Tournament description
- format: Tournament format (single_elimination, double_elimination, etc.)
- status: Tournament status (pending, registration, in_progress, completed, cancelled)
- organizer: Tournament organizer (User FK)
- game: Associated game mode (Game FK, optional)
- start_time: Scheduled start time
- end_time: Completion time
- max_participants: Maximum number of participants
- min_skill_level: Minimum skill level requirement
- max_skill_level: Maximum skill level requirement
- require_approval: Whether registration requires approval
- is_featured: Whether tournament is featured
- settings: Additional tournament settings (JSON)

### TournamentEntry
- tournament: Associated tournament (FK)
- player: Player (User FK)
- status: Entry status (pending, approved, rejected, withdrawn)
- seed_number: Seeding position
- registered_at: Registration timestamp
- approved_at: Approval timestamp

### TournamentRound
- tournament: Associated tournament (FK)
- round_number: Round number (1, 2, 3, etc.)
- name: Round name (Round 1, Quarter Finals, Semi Finals, Final)
- status: Round status (pending, in_progress, completed)

### TournamentMatch
- tournament: Associated tournament (FK)
- round: Associated round (FK)
- round_number: Round number
- match_number: Match number within round
- player1: First player (User FK)
- player2: Second player (User FK)
- winner: Match winner (User FK)
- status: Match status (pending, in_progress, completed, walkover)
- player1_score: Player 1's score
- player2_score: Player 2's score
- scheduled_time: Scheduled match time
- completed_at: Completion timestamp
- bracket_position: Position in bracket
- next_match: Next match for winner (FK, self-referential)
- next_match_position: Position in next match (1 or 2)

### TournamentInvitation
- tournament: Associated tournament (FK)
- inviter: User who sent invitation (FK)
- invitee: User who received invitation (FK)
- status: Invitation status (pending, accepted, declined)
- sent_at: Invitation sent timestamp
- responded_at: Response timestamp

## Frontend Screens

### TournamentsScreen
- Tab navigation (Featured, Upcoming, My Tournaments)
- Tournament cards with format, status, participant count
- Filter by format and status
- Create tournament button
- Pull to refresh

### CreateTournamentScreen
- Tournament name and description
- Format selection with descriptions
- Max participants slider (4-128)
- Start time picker
- Skill level restrictions (min/max dropdowns)
- Registration options (require approval, featured)
- Form validation

### TournamentDetailScreen
- Tab navigation (Overview, Bracket, Participants)
- Tournament information and status
- Registration/withdraw button
- Organizer controls (manage entries, start tournament)
- Bracket visualization
- Participant list with seeding

### ManageEntriesScreen (Organizer only)
- Tab navigation (All, Pending, Approved, Rejected)
- Entry cards with player info
- Approve/reject buttons for pending entries
- Add players dialog (batch/single mode)
- Entry status badges

### Widgets
- **TournamentBracket**: Interactive bracket visualization with rounds, matches, and live status indicators
- **TournamentCard**: Tournament preview card with key information
- **MatchCard**: Individual match display with players, scores, and status

## Bracket Generation

### Single Elimination
- Generates knockout bracket based on participant count
- Handles byes automatically for non-power-of-2 participant counts
- Seeding determines initial matchups
- Winner advances, loser is eliminated

### Double Elimination
- Main bracket (upper bracket) for undefeated players
- Losers bracket (lower bracket) for one-loss players
- Grand final between upper bracket winner and lower bracket winner
- Complex bracket linking for automatic advancement

### Round Robin
- All-play-all format
- Each player plays every other player once
- Standings based on wins/losses
- Tiebreakers: head-to-head, point differential

## UI/UX Design

### Design Principles
- **Professional**: Clean, organized layouts with clear information hierarchy
- **Futuristic**: Neon gradients, glassmorphism effects, modern animations
- **Responsive**: Adapts to different screen sizes
- **Intuitive**: Clear navigation, action buttons, status indicators

### Color Scheme
- Primary: Neon green (#00FF94)
- Secondary: Cyan (#00D9FF)
- Accent: Hot pink (#FF006E)
- Background: Dark blues (#0A0E27, #151932)

### Visual Elements
- Gradient backgrounds for cards and buttons
- Status badges (registration, in progress, completed)
- Format chips with icons
- Live match indicators (blue border)
- Winner badges (trophy icon)
- Participant counters with progress

## Usage Examples

### Creating a Tournament
1. Navigate to Tournaments screen
2. Tap "Create Tournament" button
3. Fill in tournament details (name, description, format)
4. Set max participants and start time
5. Configure skill restrictions (optional)
6. Enable/disable approval requirement
7. Tap "Create Tournament"

### Registering for a Tournament
1. Browse tournaments (Featured or Upcoming tab)
2. Tap on a tournament card
3. Review tournament details on Overview tab
4. Tap "Register for Tournament" button
5. Wait for approval if required

### Managing Tournament Entries (Organizer)
1. Open tournament detail screen
2. Tap "Manage Entries" button
3. View pending registrations
4. Approve or reject entries
5. Add players manually (batch or single)
6. Start tournament when ready

### Starting a Tournament
1. Ensure sufficient participants are approved
2. Tap "Start Tournament" button
3. Confirm action
4. Bracket is generated automatically
5. Matches are created based on format

### Reporting Match Results
1. View tournament bracket
2. Select a match
3. Enter scores for both players
4. Select winner
5. Submit result
6. Winner advances automatically

## Future Enhancements

### Planned Features
- Real-time bracket updates via WebSocket
- Push notifications for match start times
- Live match streaming
- Chat/messaging between participants
- Tournament analytics and statistics
- Recurring tournaments (weekly, monthly)
- Team tournaments
- Spectator mode
- Bracket export (PDF, image)
- Email invitations
- Prize/reward system integration
- Elo/rating adjustments based on tournament results

### Technical Improvements
- Pagination for large tournament lists
- Advanced search and filtering
- Tournament templates
- Automated scheduling
- Conflict detection (player availability)
- Tournament history and archives
- Performance optimizations for large brackets
- Offline support for bracket viewing
- Accessibility improvements
