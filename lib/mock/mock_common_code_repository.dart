// [MOCK] 백엔드 연동 시 이 파일은 삭제하고 공통코드 API 구현체로 교체한다.
import '../models/common_code.dart';
import '../repositories/business_exception.dart';
import '../repositories/common_code_repository.dart';

/// 메모리 기반 임시 공통코드 저장소.
class MockCommonCodeRepository implements CommonCodeRepository {
  final List<CommonCode> _items = [
    const CommonCode(groupCd: 'ROLE', code: 'S', codeName: '학생', sortOrder: 1),
    const CommonCode(groupCd: 'ROLE', code: 'T', codeName: '강사', sortOrder: 2),
    const CommonCode(groupCd: 'ROLE', code: 'A', codeName: '관리자', sortOrder: 3),
    const CommonCode(
      groupCd: 'COURSE_STATUS',
      code: '10',
      codeName: '준비중',
      sortOrder: 1,
    ),
    const CommonCode(
      groupCd: 'COURSE_STATUS',
      code: '20',
      codeName: '모집중',
      sortOrder: 2,
    ),
    const CommonCode(
      groupCd: 'COURSE_STATUS',
      code: '30',
      codeName: '진행중',
      sortOrder: 3,
    ),
    const CommonCode(
      groupCd: 'COURSE_STATUS',
      code: '40',
      codeName: '종료',
      sortOrder: 4,
    ),
    const CommonCode(
      groupCd: 'COURSE_STATUS',
      code: '50',
      codeName: '폐강',
      sortOrder: 5,
    ),
    const CommonCode(
      groupCd: 'ENROLL_STATUS',
      code: '10',
      codeName: '신청',
      sortOrder: 1,
    ),
    const CommonCode(
      groupCd: 'ENROLL_STATUS',
      code: '20',
      codeName: '승인',
      sortOrder: 2,
    ),
    const CommonCode(
      groupCd: 'ENROLL_STATUS',
      code: '30',
      codeName: '반려',
      sortOrder: 3,
    ),
    const CommonCode(
      groupCd: 'SUBMIT_STATUS',
      code: '10',
      codeName: '제출',
      sortOrder: 1,
    ),
    const CommonCode(
      groupCd: 'SUBMIT_STATUS',
      code: '20',
      codeName: '채점완료',
      sortOrder: 2,
    ),
  ];

  int _indexOf(String groupCd, String code) =>
      _items.indexWhere((c) => c.groupCd == groupCd && c.code == code);

  @override
  Future<List<CommonCode>> fetchAll() async {
    await _latency();
    final list = List<CommonCode>.of(_items);
    list.sort((a, b) {
      final g = a.groupCd.compareTo(b.groupCd);
      return g != 0 ? g : a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  @override
  Future<void> save(CommonCode code, {required bool isNew}) async {
    await _latency();
    if (code.groupCd.trim().isEmpty || code.code.trim().isEmpty) {
      throw const BusinessException('코드 그룹과 코드 값은 필수입니다.');
    }
    if (code.codeName.trim().isEmpty) {
      throw const BusinessException('코드 이름은 필수입니다.');
    }
    final index = _indexOf(code.groupCd, code.code);
    if (isNew) {
      if (index >= 0) {
        throw const BusinessException('이미 존재하는 코드입니다.');
      }
      _items.add(code);
    } else {
      if (index < 0) {
        throw const BusinessException('존재하지 않는 코드입니다.');
      }
      _items[index] = code;
    }
  }

  @override
  Future<void> delete(String groupCd, String code) async {
    await _latency();
    _items.removeWhere((c) => c.groupCd == groupCd && c.code == code);
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  @override
  Future<List<CommonCode>> fetchByGroup(String groupCd) async {
    await _latency();
    return _items.where((c) => c.groupCd == groupCd).toList();
  }
}
