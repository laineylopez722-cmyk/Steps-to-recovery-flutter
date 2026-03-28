import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/database_models.dart';
import 'database_service.dart';
import 'encryption_service.dart';
import 'milestone_service.dart';
import 'notification_service.dart';

/// Shared app state for onboarding, local auth/session, and user preferences.
///
/// The service owns the runtime shell state and keeps the active local account
/// aligned with the encrypted on-device database.
class AppStateService extends ChangeNotifier {
  AppStateService._internal();

  static final AppStateService instance = AppStateService._internal();

  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keySignedIn = 'app_signed_in';
  static const String _keySessionToken = 'app_session_token';
  static const String _keyEmail = 'app_email';
  static const String _keyDisplayName = 'app_display_name';
  static const String _keyUserId = 'app_user_id';
  static const String _keySobrietyDate = 'sobriety_date';
  static const String _keyProgramType = 'program_type';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyAiProxyEnabled = 'ai_proxy_enabled';
  static const String _keyMorningReminder = 'morning_reminder';
  static const String _keyEveningReminder = 'evening_reminder';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAccounts = 'app_accounts_v1';

  // Supabase configuration (from environment)
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Check if Supabase is configured
  bool get hasSupabaseConfig =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  /// Get Supabase URL
  String get supabaseUrl => _supabaseUrl;

  /// Get Supabase anon key
  String get supabaseAnonKey => _supabaseAnonKey;

  final Uuid _uuid = const Uuid();
  ReminderScheduler _reminderScheduler = NotificationService();

  SharedPreferences? _prefs;
  bool _ready = false;
  bool _initializing = false;

  bool _onboardingComplete = false;
  bool _signedIn = false;
  String? _sessionToken;
  String? _email;
  String? _displayName;
  String? _userId;
  DateTime? _sobrietyDate;
  String? _programType;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _aiProxyEnabled = false;
  String _morningReminderTime = '08:00';
  String _eveningReminderTime = '20:00';
  ThemeMode _themeMode = ThemeMode.dark;

  List<_LocalAccount> _accounts = <_LocalAccount>[];

  bool get isReady => _ready;
  bool get isInitializing => _initializing;
  bool get onboardingComplete => _onboardingComplete;
  bool get isAuthenticated => _signedIn;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get currentUserId => _userId;
  String? get programType => _programType;
  DateTime? get sobrietyDate => _sobrietyDate;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get aiProxyEnabled => _aiProxyEnabled;
  String get morningReminderTime => _morningReminderTime;
  String get eveningReminderTime => _eveningReminderTime;
  ThemeMode get appThemeMode => _themeMode;

  String get userLabel {
    if (_displayName != null && _displayName!.trim().isNotEmpty) {
      return _displayName!.trim();
    }
    if (_email != null && _email!.trim().isNotEmpty) {
      return _email!.split('@').first;
    }
    return 'Recovery user';
  }

  int get sobrietyDays {
    if (_sobrietyDate == null) {
      return 0;
    }
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final sobrietyDay = DateTime(
      _sobrietyDate!.year,
      _sobrietyDate!.month,
      _sobrietyDate!.day,
    );
    return currentDay.difference(sobrietyDay).inDays;
  }

  String get sobrietySummary {
    if (_sobrietyDate == null) {
      return 'Sobriety date not set';
    }
    final days = sobrietyDays;
    if (days <= 0) {
      return 'Starting today';
    }
    if (days == 1) {
      return '1 day sober';
    }
    if (days < 30) {
      return '$days days sober';
    }
    if (days < 365) {
      final months = days ~/ 30;
      return '$months month${months == 1 ? '' : 's'} sober';
    }
    final years = days ~/ 365;
    return '$years year${years == 1 ? '' : 's'} sober';
  }

  Future<void> initialize() async {
    if (_ready || _initializing) {
      return;
    }

    _initializing = true;
    _prefs ??= await SharedPreferences.getInstance();
    await DatabaseService().initialize();
    _hydrateFromPrefs();

    if (_signedIn && _userId != null) {
      await DatabaseService().setActiveUser(_userId);
      await _ensureCurrentUserProfile();
    } else {
      await DatabaseService().setActiveUser(null);
    }

    if (_sobrietyDate != null) {
      unawaited(
        MilestoneService().checkAndScheduleApproachNotifications(_sobrietyDate!),
      );
    }

    _ready = true;
    _initializing = false;
    notifyListeners();
  }

  void _hydrateFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    _onboardingComplete = prefs.getBool(_keyOnboardingComplete) ?? false;
    _signedIn = prefs.getBool(_keySignedIn) ?? false;
    _sessionToken = prefs.getString(_keySessionToken);
    _email = _readMaybeEncryptedString(_keyEmail);
    _displayName = _readMaybeEncryptedString(_keyDisplayName);
    _userId = prefs.getString(_keyUserId);

    final sobrietyDate = prefs.getString(_keySobrietyDate);
    _sobrietyDate = sobrietyDate == null
        ? null
        : DateTime.tryParse(sobrietyDate);
    _programType = prefs.getString(_keyProgramType);
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _biometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    _aiProxyEnabled = prefs.getBool(_keyAiProxyEnabled) ?? false;
    _morningReminderTime = prefs.getString(_keyMorningReminder) ?? '08:00';
    _eveningReminderTime = prefs.getString(_keyEveningReminder) ?? '20:00';

    final themeModeStr = prefs.getString(_keyThemeMode);
    _themeMode = themeModeStr == 'light'
        ? ThemeMode.light
        : themeModeStr == 'system'
            ? ThemeMode.system
            : ThemeMode.dark;

    _accounts = _readAccounts();
  }

  Future<void> completeOnboarding() async {
    await initialize();
    _onboardingComplete = true;
    await _prefs?.setBool(_keyOnboardingComplete, true);
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    String? displayName,
    DateTime? sobrietyDate,
    String? programType,
  }) async {
    await initialize();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw ArgumentError('Email and password are required.');
    }

    try {
      final account = _accounts.firstWhere(
        (entry) => entry.email == normalizedEmail,
        orElse: () =>
            throw StateError('No local account exists for that email.'),
      );

      final hash = _hashPassword(trimmedPassword, account.salt);
      if (hash != account.passwordHash) {
        throw StateError('Incorrect password.');
      }

      // Successful login - clear failed attempts
      await _clearFailedAttempts();

      _signedIn = true;
      _sessionToken = _uuid.v4();
      _email = normalizedEmail;
      _displayName = displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : account.displayName;
      _userId = account.userId;
      _sobrietyDate = sobrietyDate ?? _sobrietyDate;
      _programType = programType?.trim().isNotEmpty == true
          ? programType!.trim()
          : _programType;

      await DatabaseService().setActiveUser(account.userId);
      await _ensureCurrentUserProfile();
      await _syncCurrentUserProfile();
      await _persistSession();
      notifyListeners();
    } catch (e) {
      // Record failed attempt for any error
      await _recordFailedAttempt();
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    DateTime? sobrietyDate,
    String? programType,
  }) async {
    await initialize();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw ArgumentError('Email and password are required.');
    }
    if (trimmedPassword.length < 8) {
      throw ArgumentError('Password must be at least 8 characters.');
    }
    if (_accounts.any((entry) => entry.email == normalizedEmail)) {
      throw StateError('An account already exists for that email.');
    }

    final userId = _uuid.v4();
    final salt = _uuid.v4();
    final cleanProgramType = _cleanName(programType);
    final cleanDisplayName = _cleanName(normalizedEmail.split('@').first);

    _accounts = <_LocalAccount>[
      ..._accounts,
      _LocalAccount(
        email: normalizedEmail,
        userId: userId,
        passwordHash: _hashPassword(trimmedPassword, salt),
        salt: salt,
        displayName: cleanDisplayName,
      ),
    ];
    await _persistAccounts();

    _signedIn = true;
    _sessionToken = _uuid.v4();
    _email = normalizedEmail;
    _displayName = cleanDisplayName;
    _userId = userId;
    _sobrietyDate = sobrietyDate;
    _programType = cleanProgramType;

    await DatabaseService().saveUser(
      UserProfile(
        id: userId,
        email: normalizedEmail,
        sobrietyStartDate: sobrietyDate ?? DateTime.now(),
        programType: cleanProgramType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await DatabaseService().setActiveUser(userId);
    await _persistSession();
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    await initialize();
    const guestEmail = 'guest@steps.local';
    const guestPassword = 'guest-account';

    if (_accounts.any((entry) => entry.email == guestEmail)) {
      await signIn(email: guestEmail, password: guestPassword);
      return;
    }

    await signUp(
      email: guestEmail,
      password: guestPassword,
      sobrietyDate: DateTime.now(),
      programType: 'Guest',
    );
    await updateDisplayName('Guest');
  }

  /// Request password reset email via Supabase
  Future<void> resetPassword(String email) async {
    await initialize();

    final normalizedEmail = email.trim().toLowerCase();

    // Check if Supabase is configured
    if (!hasSupabaseConfig) {
      throw StateError(
        'Supabase is not configured. Please add SUPABASE_URL and SUPABASE_ANON_KEY '
        'to your environment variables.',
      );
    }

    try {
      // Request password reset
      await Supabase.instance.client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo:
            'steps-to-recovery://reset-password', // Deep link for mobile
      );
    } catch (e) {
      // Handle common errors
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('No account found with this email address');
      } else if (e.toString().contains('Email not confirmed')) {
        // Still send reset email even if email not confirmed
        rethrow;
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await initialize();
    _signedIn = false;
    _sessionToken = null;
    _email = null;
    _displayName = null;
    _userId = null;
    _sobrietyDate = null;
    _programType = null;
    await DatabaseService().setActiveUser(null);
    await _prefs?.remove(_keySignedIn);
    await _prefs?.remove(_keySessionToken);
    await _prefs?.remove(_keyEmail);
    await _prefs?.remove(_keyDisplayName);
    await _prefs?.remove(_keyUserId);
    await _syncReminderPreferences();
    notifyListeners();
  }

  Future<void> updateDisplayName(String value) async {
    await initialize();
    _displayName = _cleanName(value);
    _accounts = _accounts.map((account) {
      if (account.userId == _userId) {
        return account.copyWith(displayName: _displayName);
      }
      return account;
    }).toList();
    await _persistAccounts();
    if (_displayName != null) {
      await _writeEncryptedString(_keyDisplayName, _displayName!);
    } else {
      await _prefs?.remove(_keyDisplayName);
    }
    notifyListeners();
  }

  Future<void> updateSobrietyDate(DateTime? value) async {
    await initialize();
    _sobrietyDate = value;
    if (value == null) {
      await _prefs?.remove(_keySobrietyDate);
    } else {
      await _prefs?.setString(_keySobrietyDate, value.toIso8601String());
    }
    if (value != null) {
      unawaited(
        MilestoneService().checkAndScheduleApproachNotifications(value),
      );
    }
    await _syncCurrentUserProfile();
    notifyListeners();
  }

  Future<void> updateProgramType(String? value) async {
    await initialize();
    _programType = _cleanName(value);
    if (_programType == null) {
      await _prefs?.remove(_keyProgramType);
    } else {
      await _prefs?.setString(_keyProgramType, _programType!);
    }
    await _syncCurrentUserProfile();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await initialize();
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotificationsEnabled, value);
    await _syncReminderPreferences();
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await initialize();
    _biometricEnabled = value;
    await _prefs?.setBool(_keyBiometricEnabled, value);
    notifyListeners();
  }

  Future<void> setAiProxyEnabled(bool value) async {
    await initialize();
    _aiProxyEnabled = value;
    await _prefs?.setBool(_keyAiProxyEnabled, value);
    notifyListeners();
  }

  Future<void> setMorningReminderTime(String value) async {
    await initialize();
    _morningReminderTime = _normalizeReminderTime(
      value,
      fallback: _morningReminderTime,
    );
    await _prefs?.setString(_keyMorningReminder, _morningReminderTime);
    await _syncReminderPreferences();
    notifyListeners();
  }

  Future<void> setEveningReminderTime(String value) async {
    await initialize();
    _eveningReminderTime = _normalizeReminderTime(
      value,
      fallback: _eveningReminderTime,
    );
    await _prefs?.setString(_keyEveningReminder, _eveningReminderTime);
    await _syncReminderPreferences();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await initialize();
    _themeMode = mode;
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.system
        ? 'system'
        : 'dark';
    await _prefs?.setString(_keyThemeMode, modeStr);
    notifyListeners();
  }

  Future<void> resetLocalData() async {
    await initialize();
    await DatabaseService().clearAllData();
    await _prefs?.clear();

    _ready = false;
    _initializing = false;
    _signedIn = false;
    _sessionToken = null;
    _email = null;
    _displayName = null;
    _userId = null;
    _sobrietyDate = null;
    _programType = null;
    _notificationsEnabled = true;
    _biometricEnabled = false;
    _aiProxyEnabled = false;
    _morningReminderTime = '08:00';
    _eveningReminderTime = '20:00';
    _themeMode = ThemeMode.dark;
    _onboardingComplete = false;
    _accounts = <_LocalAccount>[];

    await _syncReminderPreferences();
    notifyListeners();
  }

  Future<void> syncReminderPreferences() async {
    await initialize();
    await _syncReminderPreferences();
  }

  @visibleForTesting
  void setReminderSchedulerForTest(ReminderScheduler scheduler) {
    _reminderScheduler = scheduler;
  }

  Future<void> _persistSession() async {
    await _prefs?.setBool(_keySignedIn, _signedIn);
    if (_sessionToken != null) {
      await _prefs?.setString(_keySessionToken, _sessionToken!);
    }
    if (_userId != null) {
      await _prefs?.setString(_keyUserId, _userId!);
    }
    if (_email != null) {
      await _writeEncryptedString(_keyEmail, _email!);
    }
    if (_displayName != null) {
      await _writeEncryptedString(_keyDisplayName, _displayName!);
    }
    if (_sobrietyDate != null) {
      await _prefs?.setString(
        _keySobrietyDate,
        _sobrietyDate!.toIso8601String(),
      );
    }
    if (_programType != null) {
      await _prefs?.setString(_keyProgramType, _programType!);
    }
  }

  Future<void> _persistAccounts() async {
    final payload = jsonEncode(
      _accounts.map((account) => account.toJson()).toList(),
    );
    final encrypted = EncryptionService().encrypt(payload);
    await _prefs?.setString(_keyAccounts, encrypted);
  }

  List<_LocalAccount> _readAccounts() {
    final raw = _prefs?.getString(_keyAccounts);
    if (raw == null || raw.isEmpty) {
      return <_LocalAccount>[];
    }

    try {
      final decrypted = _decryptMaybe(raw);
      final decoded = jsonDecode(decrypted);
      if (decoded is! List<dynamic>) {
        return <_LocalAccount>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => _LocalAccount.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return <_LocalAccount>[];
    }
  }

  String? _readMaybeEncryptedString(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return _decryptMaybe(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _writeEncryptedString(String key, String value) async {
    await _prefs?.setString(key, EncryptionService().encrypt(value));
  }

  String _decryptMaybe(String value) {
    try {
      return EncryptionService().decrypt(value);
    } catch (_) {
      return value;
    }
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }

  Future<void> _ensureCurrentUserProfile() async {
    if (_userId == null || _email == null) {
      return;
    }

    final database = DatabaseService();
    final existing = await database.getCurrentUser();
    if (existing != null) {
      _sobrietyDate ??= existing.sobrietyStartDate;
      _programType ??= existing.programType;
      if (_sobrietyDate != null) {
        await _prefs?.setString(
          _keySobrietyDate,
          _sobrietyDate!.toIso8601String(),
        );
      }
      if (_programType != null) {
        await _prefs?.setString(_keyProgramType, _programType!);
      }
      return;
    }

    await database.saveUser(
      UserProfile(
        id: _userId!,
        email: _email!,
        sobrietyStartDate: _sobrietyDate ?? DateTime.now(),
        programType: _programType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _syncCurrentUserProfile() async {
    if (_userId == null || _email == null) {
      return;
    }

    final database = DatabaseService();
    final current = await database.getCurrentUser();
    await database.saveUser(
      UserProfile(
        id: _userId!,
        email: _email!,
        sobrietyStartDate:
            _sobrietyDate ?? current?.sobrietyStartDate ?? DateTime.now(),
        programType: _programType ?? current?.programType,
        createdAt: current?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  String? _cleanName(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  String _normalizeReminderTime(String value, {required String fallback}) {
    final normalized = value.trim();
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(normalized);
    if (match != null) {
      return normalized;
    }
    return fallback;
  }

  Future<void> _syncReminderPreferences() async {
    await _reminderScheduler.syncDailyCheckInReminders(
      enabled: _notificationsEnabled,
      morningTime: _morningReminderTime,
      eveningTime: _eveningReminderTime,
    );
  }
}

class _LocalAccount {
  const _LocalAccount({
    required this.email,
    required this.userId,
    required this.passwordHash,
    required this.salt,
    this.displayName,
  });

  final String email;
  final String userId;
  final String passwordHash;
  final String salt;
  final String? displayName;

  _LocalAccount copyWith({
    String? email,
    String? userId,
    String? passwordHash,
    String? salt,
    String? displayName,
  }) {
    return _LocalAccount(
      email: email ?? this.email,
      userId: userId ?? this.userId,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'userId': userId,
      'passwordHash': passwordHash,
      'salt': salt,
      'displayName': displayName,
    };
  }

  factory _LocalAccount.fromJson(Map<String, dynamic> json) {
    return _LocalAccount(
      email: json['email'] as String,
      userId: json['userId'] as String? ?? const Uuid().v4(),
      passwordHash: json['passwordHash'] as String,
      salt: json['salt'] as String,
      displayName: json['displayName'] as String?,
    );
  }
}
