import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../local/dao/user_dao.dart';
import '../local/models/user_model.dart';

class AuthRepository extends ChangeNotifier {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserRole = 'auth_user_role';

  final ApiClient _apiClient;
  final UserDao _userDao;
  UserModel? _currentUser;
  bool _isInitialized = false;

  AuthRepository({
    ApiClient? apiClient,
    UserDao? userDao,
  })  : _apiClient = apiClient ?? ApiClient(),
        _userDao = userDao ?? UserDao();

  ApiClient get apiClient => _apiClient;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _apiClient.isAuthenticated;
  bool get isInitialized => _isInitialized;

  /// Load session from SharedPreferences and SQLite on startup
  Future<UserModel?> restoreSession() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserId = prefs.getString(_keyUserId);

      if (savedToken != null && savedToken.isNotEmpty) {
        _apiClient.setAuthToken(savedToken);
      }

      if (savedUserId != null) {
        _currentUser = await _userDao.getById(savedUserId);
      }

      // Fallback to active user in SQLite
      _currentUser ??= await _userDao.getActiveUser();

      _isInitialized = true;
      notifyListeners();
      return _currentUser;
    } catch (e) {
      debugPrint('Error restoring auth session: $e');
      _isInitialized = true;
      notifyListeners();
      return null;
    }
  }

  /// Sign In with phone/email and password
  Future<UserModel> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    try {
      final res = await _apiClient.login(phoneOrEmail, password);
      final token = res['access_token'] as String?;
      final userData = res['user'] as Map<String, dynamic>? ?? {};

      final now = DateUtilsHelper.nowUtcIso();
      final user = UserModel(
        id: (userData['id'] as String?) ?? const Uuid().v4(),
        name: (userData['name'] as String?) ?? phoneOrEmail,
        phone: userData['phone'] as String?,
        role: (userData['role'] as String?) ?? 'citizen',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      await _persistSession(token, user);
      return user;
    } catch (apiError) {
      // Offline fallback: check local database credentials if offline
      debugPrint('API login failed, checking offline credentials: $apiError');
      final localUser = await _userDao.getActiveUser();
      if (localUser != null && (localUser.phone == phoneOrEmail || localUser.email == phoneOrEmail)) {
        _currentUser = localUser;
        notifyListeners();
        return localUser;
      }
      rethrow;
    }
  }

  /// Register a new Citizen account
  Future<UserModel> register({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    try {
      final res = await _apiClient.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      final token = res['access_token'] as String?;
      final userData = res['user'] as Map<String, dynamic>? ?? {};

      final now = DateUtilsHelper.nowUtcIso();
      final user = UserModel(
        id: (userData['id'] as String?) ?? const Uuid().v4(),
        name: name,
        phone: phone,
        email: email,
        role: 'citizen',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      await _persistSession(token, user);
      return user;
    } catch (apiError) {
      // Offline fallback: save locally so user is not blocked during disaster
      debugPrint('API register failed, saving offline local profile: $apiError');
      final now = DateUtilsHelper.nowUtcIso();
      final user = UserModel(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
        email: email,
        role: 'citizen',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      await _userDao.insert(user);
      _currentUser = user;
      notifyListeners();
      return user;
    }
  }

  /// Emergency Guest Access (Distress Survivor Fast Track)
  Future<UserModel> emergencyGuestAccess() async {
    try {
      final res = await _apiClient.emergencyGuest();
      final token = res['access_token'] as String?;
      final userData = res['user'] as Map<String, dynamic>? ?? {};

      final now = DateUtilsHelper.nowUtcIso();
      final user = UserModel(
        id: (userData['id'] as String?) ?? const Uuid().v4(),
        name: 'Emergency Guest',
        phone: userData['phone'] as String? ?? 'N/A',
        role: 'citizen',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      await _persistSession(token, user);
      return user;
    } catch (apiError) {
      // Offline fallback
      final now = DateUtilsHelper.nowUtcIso();
      final user = UserModel(
        id: const Uuid().v4(),
        name: 'Emergency Guest',
        phone: 'N/A',
        role: 'citizen',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      await _userDao.insert(user);
      _currentUser = user;
      notifyListeners();
      return user;
    }
  }

  /// Logout: revoke token on server and clear local session
  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserRole);

    if (_currentUser != null) {
      await _userDao.deleteSoft(_currentUser!.id);
      _currentUser = null;
    }

    _apiClient.clearAuthToken();
    notifyListeners();
  }

  Future<void> _persistSession(String? token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_keyToken, token);
      _apiClient.setAuthToken(token);
    }
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserRole, user.role);

    await _userDao.insert(user);
    _currentUser = user;
    notifyListeners();
  }
}
