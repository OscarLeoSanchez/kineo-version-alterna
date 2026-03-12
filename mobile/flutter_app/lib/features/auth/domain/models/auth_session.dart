class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.email,
    required this.fullName,
  });

  final String accessToken;
  final String email;
  final String fullName;

  Map<String, String> toStorage() {
    return {'access_token': accessToken, 'email': email, 'full_name': fullName};
  }

  factory AuthSession.fromStorage(Map<String, String> data) {
    return AuthSession(
      accessToken: data['access_token'] ?? '',
      email: data['email'] ?? '',
      fullName: data['full_name'] ?? '',
    );
  }
}
