"""Automatic bracket generation for various tournament formats"""
import math
import random
from django.utils import timezone
from django.db.models import Q
from .models import TournamentRound, TournamentMatch, TournamentEntry, TournamentStanding


class BracketGenerator:
    """Generate tournament brackets based on format"""
    
    @staticmethod
    def generate_single_elimination(tournament):
        """Generate single elimination bracket"""
        entries = list(tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED).order_by("seed_number", "registered_at"))
        num_players = len(entries)
        
        if num_players < 2:
            return False
        
        # Calculate rounds needed
        num_rounds = math.ceil(math.log2(num_players))
        bracket_size = 2 ** num_rounds
        
        # Add byes if needed
        num_byes = bracket_size - num_players
        
        # Create rounds
        round_names = BracketGenerator._get_round_names(num_rounds)
        rounds = []
        for i in range(num_rounds):
            round_obj = TournamentRound.objects.create(
                tournament=tournament,
                round_number=i + 1,
                name=round_names[i]
            )
            rounds.append(round_obj)
        
        # Create first round matches
        first_round = rounds[0]
        matches_in_round = bracket_size // 2
        
        match_list = []
        for i in range(matches_in_round):
            match = TournamentMatch.objects.create(
                tournament=tournament,
                round=first_round,
                match_number=i + 1
            )
            
            # Assign players (handle byes)
            if i * 2 < len(entries):
                match.player1_entry = entries[i * 2]
            if i * 2 + 1 < len(entries):
                match.player2_entry = entries[i * 2 + 1]
            
            # Automatic walkover for byes
            if match.player1_entry and not match.player2_entry:
                match.winner_entry = match.player1_entry
                match.status = TournamentMatch.Status.WALKOVER
                match.player1_score = 1
            elif match.player2_entry and not match.player1_entry:
                match.winner_entry = match.player2_entry
                match.status = TournamentMatch.Status.WALKOVER
                match.player2_score = 1
            
            match.save()
            match_list.append(match)
        
        # Link matches to next round
        for round_idx in range(1, num_rounds):
            prev_matches = list(rounds[round_idx - 1].matches.all())
            current_round = rounds[round_idx]
            num_matches = len(prev_matches) // 2
            
            for i in range(num_matches):
                next_match = TournamentMatch.objects.create(
                    tournament=tournament,
                    round=current_round,
                    match_number=i + 1
                )
                
                # Link previous matches
                prev_matches[i * 2].next_match = next_match
                prev_matches[i * 2].save()
                
                if i * 2 + 1 < len(prev_matches):
                    prev_matches[i * 2 + 1].next_match = next_match
                    prev_matches[i * 2 + 1].save()
        
        return True
    
    @staticmethod
    def generate_double_elimination(tournament):
        """Generate double elimination bracket (winners + losers)"""
        # Similar to single elim but with losers bracket
        # Implementation would be more complex
        # For now, create single elim and add losers bracket placeholder
        BracketGenerator.generate_single_elimination(tournament)
        
        # Create losers bracket rounds
        entries = tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED)
        num_players = entries.count()
        num_rounds = math.ceil(math.log2(num_players))
        
        # Losers bracket has 2*(num_rounds - 1) - 1 rounds
        losers_rounds = 2 * (num_rounds - 1) - 1
        
        for i in range(losers_rounds):
            TournamentRound.objects.create(
                tournament=tournament,
                round_number=i + 1,
                name=f"Losers Round {i + 1}",
                is_losers_bracket=True
            )
        
        return True
    
    @staticmethod
    def generate_round_robin(tournament):
        """Generate round-robin (everyone plays everyone)"""
        entries = list(tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED).order_by("seed_number", "registered_at"))
        num_players = len(entries)
        
        if num_players < 2:
            return False
        
        # Calculate total rounds (n-1 for even, n for odd)
        num_rounds = num_players if num_players % 2 == 1 else num_players - 1
        
        # Add dummy player for odd number
        if num_players % 2 == 1:
            entries.append(None)  # Bye round
        
        # Create rounds and matches using round-robin algorithm
        for round_num in range(num_rounds):
            round_obj = TournamentRound.objects.create(
                tournament=tournament,
                round_number=round_num + 1,
                name=f"Round {round_num + 1}"
            )
            
            # Create matches for this round
            for i in range(len(entries) // 2):
                player1 = entries[i]
                player2 = entries[len(entries) - 1 - i]
                
                if player1 and player2:  # Skip if bye
                    TournamentMatch.objects.create(
                        tournament=tournament,
                        round=round_obj,
                        match_number=i + 1,
                        player1_entry=player1,
                        player2_entry=player2
                    )
            
            # Rotate players (keep first fixed)
            entries = [entries[0]] + [entries[-1]] + entries[1:-1]
        
        return True
    
    @staticmethod
    def _get_round_names(num_rounds):
        """Get descriptive names for rounds"""
        names = {
            1: ["Final"],
            2: ["Semifinals", "Final"],
            3: ["Quarterfinals", "Semifinals", "Final"],
            4: ["Round of 16", "Quarterfinals", "Semifinals", "Final"],
            5: ["Round of 32", "Round of 16", "Quarterfinals", "Semifinals", "Final"],
            6: ["Round of 64", "Round of 32", "Round of 16", "Quarterfinals", "Semifinals", "Final"],
        }
        
        if num_rounds in names:
            return names[num_rounds]
        
        # For larger tournaments
        result = []
        for i in range(num_rounds):
            if i < num_rounds - 3:
                result.append(f"Round {i + 1}")
            elif i == num_rounds - 3:
                result.append("Quarterfinals")
            elif i == num_rounds - 2:
                result.append("Semifinals")
            else:
                result.append("Final")
        
        return result
    
    @staticmethod
    def generate_swiss_system(tournament, num_rounds=None):
        """Generate Swiss system tournament (players with similar scores face each other)"""
        entries = list(tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED).order_by("seed_number", "registered_at"))
        num_players = len(entries)
        
        if num_players < 2:
            return False
        
        # Calculate recommended number of rounds if not specified
        if num_rounds is None:
            num_rounds = math.ceil(math.log2(num_players))
        
        # Initialize standings for all players
        for entry in entries:
            TournamentStanding.objects.get_or_create(
                tournament=tournament,
                entry=entry,
                defaults={'rank': 0}
            )
        
        # Generate first round with random or seeded pairing
        first_round = TournamentRound.objects.create(
            tournament=tournament,
            round_number=1,
            name="Round 1"
        )
        
        # Shuffle for first round (or use seeds)
        random.shuffle(entries)
        
        # Pair players for first round
        for i in range(0, len(entries) - 1, 2):
            TournamentMatch.objects.create(
                tournament=tournament,
                round=first_round,
                match_number=(i // 2) + 1,
                player1_entry=entries[i],
                player2_entry=entries[i + 1]
            )
        
        # Handle bye if odd number
        if len(entries) % 2 == 1:
            bye_match = TournamentMatch.objects.create(
                tournament=tournament,
                round=first_round,
                match_number=(len(entries) // 2) + 1,
                player1_entry=entries[-1],
                status=TournamentMatch.Status.WALKOVER,
                winner_entry=entries[-1],
                player1_score=1
            )
        
        # Create placeholder rounds (pairings generated after each round completes)
        for round_num in range(2, num_rounds + 1):
            TournamentRound.objects.create(
                tournament=tournament,
                round_number=round_num,
                name=f"Round {round_num}"
            )
        
        return True
    
    @staticmethod
    def generate_swiss_round_pairings(tournament, round_number):
        """Generate pairings for a Swiss round based on current standings"""
        # Get standings sorted by points
        standings = list(TournamentStanding.objects.filter(
            tournament=tournament
        ).select_related('entry').order_by(
            '-tournament_points',
            '-buchholz_score',
            '-points_difference'
        ))
        
        if not standings:
            return False
        
        round_obj = TournamentRound.objects.get(
            tournament=tournament,
            round_number=round_number
        )
        
        # Get players who haven't faced each other
        entries = [s.entry for s in standings]
        paired = set()
        match_number = 1
        
        # Try to pair players with similar scores
        for i, entry in enumerate(entries):
            if entry in paired:
                continue
            
            # Find best opponent (similar score, haven't played before)
            opponent = None
            for j in range(i + 1, len(entries)):
                candidate = entries[j]
                if candidate in paired:
                    continue
                
                # Check if they've played before
                previous_match = TournamentMatch.objects.filter(
                    tournament=tournament,
                    status=TournamentMatch.Status.COMPLETED
                ).filter(
                    (Q(player1_entry=entry) & Q(player2_entry=candidate)) |
                    (Q(player1_entry=candidate) & Q(player2_entry=entry))
                ).exists()
                
                if not previous_match:
                    opponent = candidate
                    break
            
            if opponent:
                TournamentMatch.objects.create(
                    tournament=tournament,
                    round=round_obj,
                    match_number=match_number,
                    player1_entry=entry,
                    player2_entry=opponent
                )
                paired.add(entry)
                paired.add(opponent)
                match_number += 1
            else:
                # Give bye if no opponent available
                TournamentMatch.objects.create(
                    tournament=tournament,
                    round=round_obj,
                    match_number=match_number,
                    player1_entry=entry,
                    status=TournamentMatch.Status.WALKOVER,
                    winner_entry=entry,
                    player1_score=1
                )
                paired.add(entry)
                match_number += 1
        
        return True
    
    @staticmethod
    def update_swiss_standings(tournament):
        """Update standings after matches complete (including tiebreak scores)"""
        standings = TournamentStanding.objects.filter(tournament=tournament)
        
        for standing in standings:
            # Update basic stats from matches
            matches = TournamentMatch.objects.filter(
                tournament=tournament,
                status=TournamentMatch.Status.COMPLETED
            ).filter(
                Q(player1_entry=standing.entry) | Q(player2_entry=standing.entry)
            )
            
            standing.matches_played = matches.count()
            standing.matches_won = matches.filter(winner_entry=standing.entry).count()
            standing.matches_lost = matches.exclude(
                Q(winner_entry=standing.entry) | Q(winner_entry=None)
            ).count()
            standing.matches_drawn = matches.filter(winner_entry=None).count()
            
            # Calculate tournament points (3 for win, 1 for draw)
            standing.tournament_points = (standing.matches_won * 3) + standing.matches_drawn
            
            # Calculate scores
            for match in matches:
                if match.player1_entry == standing.entry:
                    standing.points_for += match.player1_score
                    standing.points_against += match.player2_score
                    if match.player1_score > standing.highest_score:
                        standing.highest_score = match.player1_score
                else:
                    standing.points_for += match.player2_score
                    standing.points_against += match.player1_score
                    if match.player2_score > standing.highest_score:
                        standing.highest_score = match.player2_score
            
            standing.update_statistics()
            standing.calculate_buchholz()
            standing.calculate_sonneborn_berger()
            standing.save()
        
        # Update ranks
        ranked_standings = TournamentStanding.objects.filter(
            tournament=tournament
        ).order_by(
            '-tournament_points',
            '-points_difference',
            '-buchholz_score',
            '-sonneborn_berger',
            '-points_for'
        )
        
        for rank, standing in enumerate(ranked_standings, start=1):
            standing.rank = rank
            standing.save()
        
        return True
    
    @staticmethod
    def advance_winner(match, winner_entry):
        """Advance winner to next match"""
        match.winner_entry = winner_entry
        match.status = TournamentMatch.Status.COMPLETED
        match.completed_at = timezone.now()
        match.save()
        
        # Update entry stats
        if match.player1_entry:
            if winner_entry == match.player1_entry:
                match.player1_entry.wins += 1
            else:
                match.player1_entry.losses += 1
            match.player1_entry.save()
        
        if match.player2_entry:
            if winner_entry == match.player2_entry:
                match.player2_entry.wins += 1
            else:
                match.player2_entry.losses += 1
            match.player2_entry.save()
        
        # Advance to next match if exists
        if match.next_match:
            next_match = match.next_match
            
            # Determine which position in next match
            prev_matches = list(next_match.previous_matches.all().order_by("match_number"))
            if prev_matches[0] == match:
                next_match.player1_entry = winner_entry
            else:
                next_match.player2_entry = winner_entry
            
            next_match.save()
