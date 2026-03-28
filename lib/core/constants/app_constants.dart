/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Steps to Recovery';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'steps_recovery.db';
  
  // Secure storage keys
  static const String keyEncryptionKey = 'encryption_key';
  static const String keyEncryptionIv = 'encryption_iv';
  static const String keyUserId = 'user_id';
  static const String keyAuthToken = 'auth_token';
  static const String keySobrietyDate = 'sobriety_date';
  
  // Shared preferences keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyTheme = 'theme';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
  
  // Check-in reminders
  static const String morningReminderTime = '08:00';
  static const String eveningReminderTime = '20:00';
  
  // Mood scale
  static const int moodMin = 1;
  static const int moodMax = 5;
  
  // Craving scale
  static const int cravingMin = 0;
  static const int cravingMax = 10;
  
  // Sobriety milestones (in days)
  static const List<int> sobrietyMilestones = [
    1,      // 1 day
    7,      // 1 week
    14,     // 2 weeks
    30,     // 1 month
    60,     // 2 months
    90,     // 3 months
    180,    // 6 months
    365,    // 1 year
    730,    // 2 years
    1095,   // 3 years
    1460,   // 4 years
    1825,   // 5 years
  ];
  
  // Crisis resources
  static const String suicideHotline = '988';
  static const String samhsaHelpline = '1-800-662-4357';
  
  // Animation durations
  static const int animationDurationShort = 200;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;
  
  // API timeouts
  static const int apiTimeoutSeconds = 30;
  
  // Sync
  static const int syncRetryAttempts = 3;
  static const int syncRetryDelaySeconds = 5;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Character limits
  static const int maxJournalTitleLength = 100;
  static const int maxJournalContentLength = 10000;
  static const int maxChatMessageLength = 2000;
  
  // Meeting types
  static const List<String> meetingTypes = [
    'in-person',
    'online',
    'hybrid',
    'phone',
  ];
  
  // Meeting formats
  static const List<String> meetingFormats = [
    'Discussion',
    'Speaker',
    'Step Study',
    'Tradition Study',
    'Big Book',
    'Beginner',
    'Open',
    'Closed',
    'Men',
    'Women',
    'LGBTQ',
    'Young People',
  ];
  
  // Program types
  static const List<String> programTypes = [
    'AA',  // Alcoholics Anonymous
    'NA',  // Narcotics Anonymous
    'CA',  // Cocaine Anonymous
    'MA',  // Marijuana Anonymous
    'OA',  // Overeaters Anonymous
    'GA',  // Gamblers Anonymous
    'Other',
  ];
}

abstract final class AppStoreLinks {
  // Configure via --dart-define=APP_STORE_URL for production builds.
  // Keep empty by default so non-production builds never ship a fake public URL.
  static const String appStore = String.fromEnvironment(
    'APP_STORE_URL',
    defaultValue: '',
  );
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.stepstorecovery.app';
  static const String shareUrl = 'https://stepstorecovery.app';
}

abstract final class NotificationIds {
  // Daily check-in reminders use IDs < 1000
  static const int milestoneApproachBase = 2000;
  // 2001 = 7-day approach, 2002 = 30-day, 2003 = 90-day, 2004 = 1-year
}

/// Achievement keys
class AchievementKeys {
  AchievementKeys._();
  
  // Milestone achievements
  static const String milestone24Hours = 'milestone_24h';
  static const String milestone7Days = 'milestone_7d';
  static const String milestone30Days = 'milestone_30d';
  static const String milestone90Days = 'milestone_90d';
  static const String milestone1Year = 'milestone_1y';
  
  // Streak achievements
  static const String streak3Days = 'streak_3d';
  static const String streak7Days = 'streak_7d';
  static const String streak30Days = 'streak_30d';
  
  // Step completion achievements
  static const String step1Complete = 'step_1_complete';
  static const String step4Complete = 'step_4_complete';
  static const String allStepsComplete = 'all_steps_complete';
  
  // Journal achievements
  static const String firstJournal = 'first_journal';
  static const String journal7Days = 'journal_7d';
  static const String journal30Days = 'journal_30d';
  
  // Meeting achievements
  static const String firstMeeting = 'first_meeting';
  static const String meeting30 = 'meeting_30';
  static const String meeting90 = 'meeting_90';
  
  // Challenge achievements
  static const String challengeComplete = 'challenge_complete';
}

/// Notification channels
class NotificationChannels {
  NotificationChannels._();
  
  static const String checkIns = 'check_ins';
  static const String reminders = 'reminders';
  static const String achievements = 'achievements';
  static const String crisis = 'crisis';
}

/// Routes
class AppRoutes {
  AppRoutes._();
  
  // Auth
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Main tabs
  static const String home = '/home';
  static const String journal = '/journal';
  static const String steps = '/steps';
  static const String meetings = '/meetings';
  static const String profile = '/profile';
  
  // Home stack
  static const String morningIntention = '/morning-intention';
  static const String eveningPulse = '/evening-pulse';
  static const String emergency = '/emergency';
  static const String dailyReading = '/daily-reading';
  static const String progress = '/progress';
  static const String cravingSurf = '/craving-surf';
  static const String gratitude = '/gratitude';
  static const String inventory = '/inventory';
  static const String safetyPlan = '/safety-plan';
  static const String companionChat = '/companion-chat';
  
  // Journal stack
  static const String journalEditor = '/journal/editor';
  
  // Steps stack
  static const String stepDetail = '/steps/detail';
  static const String stepReview = '/steps/review';
  
  // Meetings stack
  static const String meetingDetail = '/meetings/detail';
  static const String favoriteMeetings = '/meetings/favorites';
  
  // Profile stack
  static const String sponsor = '/profile/sponsor';
  static const String settings = '/profile/settings';
  static const String aiSettings = '/profile/ai-settings';
  static const String securitySettings = '/profile/security';
  
  // Emergency
  static const String beforeYouUse = '/before-you-use';
  static const String dangerZone = '/danger-zone';
  static const String safeDialIntervention = '/safe-dial';
}
