"""XP and Reward system for Oche180 training"""
from datetime import datetime


class XPCalculator:
    """Calculate XP earned from various activities"""
    
    # Base XP values
    TRAINING_SESSION_COMPLETE = 50
    TRAINING_SESSION_BONUS = 25  # Bonus if completed quickly
    DRILL_COMPLETION = 30
    CHALLENGE_COMPLETION = 100
    PERSONAL_BEST = 200
    STREAK_BONUS_PER_DAY = 5  # 5 XP per day in streak
    GAME_COMPLETION = 75
    GAME_WIN = 100
    
    @staticmethod
    def calculate_training_xp(session):
        """Calculate XP for a training session"""
        xp = XPCalculator.TRAINING_SESSION_COMPLETE
        
        # Bonus for quick completion (under 30 minutes)
        if session.elapsed_seconds and session.elapsed_seconds < 1800:
            xp += XPCalculator.TRAINING_SESSION_BONUS
        
        # Bonus for high success rate
        if session.success_rate and session.success_rate >= 80:
            xp += 25
        elif session.success_rate and session.success_rate >= 60:
            xp += 15
        
        return xp
    
    @staticmethod
    def calculate_challenge_xp(difficulty):
        """Calculate XP for completing a challenge"""
        difficulty_multipliers = {
            'easy': 1.0,
            'medium': 1.5,
            'hard': 2.0,
            'pro': 3.0,
        }
        multiplier = difficulty_multipliers.get(difficulty.lower(), 1.0)
        return int(XPCalculator.CHALLENGE_COMPLETION * multiplier)
    
    @staticmethod
    def calculate_streak_bonus(streak_days):
        """Calculate bonus XP for login streaks"""
        return streak_days * XPCalculator.STREAK_BONUS_PER_DAY
    
    @staticmethod
    def level_from_xp(total_xp):
        """Calculate player level from total XP (progression curve)"""
        # Level 1: 0-100 XP
        # Level 2: 100-300 XP (200 more)
        # Level 3: 300-600 XP (300 more)
        # Each level needs +100 more XP
        if total_xp < 100:
            return 1
        
        xp_for_next = 100
        level = 1
        remaining_xp = total_xp - 100
        
        while remaining_xp > 0 and level < 100:
            xp_for_next += 100
            if remaining_xp >= xp_for_next:
                remaining_xp -= xp_for_next
                level += 1
            else:
                break
        
        return level
    
    @staticmethod
    def xp_for_next_level(current_xp):
        """Calculate XP needed to reach next level"""
        current_level = XPCalculator.level_from_xp(current_xp)
        
        # Sum XP needed up to next level
        total_needed = 100
        for i in range(2, current_level + 1):
            total_needed += (100 * i)
        
        return max(0, total_needed - current_xp)
