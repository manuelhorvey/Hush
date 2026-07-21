class RegisterRequest {
  final String username;
  final String publicKey;

  const RegisterRequest({required this.username, required this.publicKey});

  Map<String, dynamic> toJson() => {
        'username': username,
        'public_key': publicKey,
      };
}

class LoginRequest {
  final String username;

  const LoginRequest({required this.username});

  Map<String, dynamic> toJson() => {'username': username};
}

class AuthResponseDto {
  final String token;
  final String refreshToken;
  final String userId;
  final String username;

  const AuthResponseDto({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.username,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String? ?? '',
      userId: json['user_id'] as String,
      username: json['username'] as String,
    );
  }
}

class RefreshRequest {
  final String refreshToken;

  const RefreshRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

class RefreshResponseDto {
  final String token;
  final String refreshToken;

  const RefreshResponseDto({
    required this.token,
    required this.refreshToken,
  });

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshResponseDto(
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}
