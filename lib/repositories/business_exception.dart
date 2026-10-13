/// 업무 규칙 위반 예외. message는 사용자에게 그대로 보여준다.
class BusinessException implements Exception {
  const BusinessException(this.message);

  final String message;

  @override
  String toString() => message;
}
