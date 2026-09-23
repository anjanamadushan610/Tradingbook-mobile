import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.statusCode,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  final List<String> issues;
  const ValidationFailure({
    required super.message,
    super.code,
    this.issues = const [],
  });
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
