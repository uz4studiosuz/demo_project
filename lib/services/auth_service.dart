import '../models/user_role.dart';

class AuthService {
  Future<UserRole> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Realistik Mock Login qoidalari:
    if (username == 'user1' && password == '123') {
      return UserRole.surveyor;
    } else if (username == 'user2' && password == '123') {
      return UserRole.driver;
    }

    return UserRole.none; // Login yoki parol noto'g'ri
  }
}
