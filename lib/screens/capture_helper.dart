// 결과 이미지를 PNG로 저장(다운로드). 플랫폼별 구현을 조건부 임포트로 분기.
import 'capture_helper_stub.dart'
    if (dart.library.js_interop) 'capture_helper_web.dart';

class CaptureHelper {
  static Future<void> savePng(List<int> bytes, String fileName) =>
      savePngImpl(bytes, fileName);

  static void openUrl(String url) => openUrlImpl(url);
}
