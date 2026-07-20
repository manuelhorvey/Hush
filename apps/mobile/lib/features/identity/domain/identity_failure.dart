abstract final class IdentityFailure implements Exception {
  final String message;
  const IdentityFailure(this.message);

  @override
  String toString() => message;
}

final class NetworkIdentityFailure extends IdentityFailure {
  const NetworkIdentityFailure() : super('Connection failed. Check that the server is running.');
}

final class ServerIdentityFailure extends IdentityFailure {
  const ServerIdentityFailure(super.message);
}

final class UnknownIdentityFailure extends IdentityFailure {
  const UnknownIdentityFailure() : super('Something went wrong. Please try again.');
}
