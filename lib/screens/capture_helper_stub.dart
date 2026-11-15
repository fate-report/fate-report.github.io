// 비-웹 환경 폴백 (현재 앱은 웹 전용이라 거의 쓰이지 않음)
Future<void> savePngImpl(List<int> bytes, String fileName) async {
  // 지원하지 않는 플랫폼에서는 아무 동작도 하지 않음
}

void openUrlImpl(String url) {}
