/// 공통코드 Model (TB_COMMON_CODE). 그룹 코드 + 코드 값이 복합 키.
class CommonCode {
  const CommonCode({
    required this.groupCd,
    required this.code,
    required this.codeName,
    this.sortOrder = 0,
  });

  /// 코드 그룹 (예: ROLE, COURSE_STATUS).
  final String groupCd;

  /// 코드 값.
  final String code;

  /// 코드 이름 (화면 표시용).
  final String codeName;
  final int sortOrder;
}
