class CodeGroup {
  static const courseStatus = 'COURSE_STATUS';
  static const enrollStatus = 'ENROLL_STATUS';
  static const role = 'ROLE';
  static const major = 'MAJOR';

  static const submitStatus = 'SUBMIT_STATUS';

  /// 트리 상위(그룹)에 보여줄 한글 이름. 목록에 없으면 그룹 코드를 그대로 보여준다.
  static const labels = {
    courseStatus: '과정 상태',
    enrollStatus: '수강 신청 상태',
    role: '사용자 역할',
    major: '전공',
    submitStatus: '과제 제출 상태',
  };
  static String label(String group) => labels[group] ?? group;
}
