// 웹에서 PNG 바이트를 Blob으로 만들어 브라우저 다운로드를 트리거.
import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> savePngImpl(List<int> bytes, String fileName) async {
  final b64 = base64Encode(Uint8List.fromList(bytes));
  final dataUrl = 'data:image/png;base64,$b64';
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = dataUrl
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
