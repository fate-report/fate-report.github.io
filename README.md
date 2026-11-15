# Fate Report (만세 리포트)

만세력 기준 AI 사주·궁합 리포트 서비스 (Flutter Web).

## 🔗 링크

- 🌍 **실제 앱 (바로 사용)** : **https://fate-report.pages.dev**
- 📦 **소스 코드 (GitHub)** : https://github.com/jooyong0125-jpg/fate-report

> 모바일 브라우저에서 바로 접속해 사용할 수 있습니다.

## 소개

- **만세력 계산은 코드가, 해석만 AI가** 담당합니다. (AI가 명식·점수를 지어내지 못하도록 분리)
- 좋은 점과 조심할 점을 함께 제시하는 **신뢰형 리포트** (립서비스 방지)
- 궁합은 코드 규칙으로 **신호등(초록/노랑/빨강/보류)** 판정
- 정보가 부족하면 억지 단정 없이 **판정 보류**

## 기술 스택

- Flutter 3.35.4 / Dart 3.9.2 (Web)
- Provider (상태 관리)
- google_fonts (Noto Serif KR / Noto Sans KR)
- Google Gemini (gemini-2.5-flash) — Cloudflare Pages Functions 프록시 경유
- 배포: Cloudflare Pages

## 주요 구조

```
lib/
  manseryeok/   만세력 계산 엔진 (사주팔자, 진태양시, 절기 등)
  compat/       궁합 규칙 엔진 (충·형·해·합·삼합, 신호등 판정)
  services/     AI 서비스(프록시 호출), 프롬프트 빌더, 상태 관리
  screens/      홈 / 입력 / 결과 화면
  widgets/      공통 UI 위젯
  theme/        디자인 시스템
  models/       데이터 모델
  content/      노출 문구(copy)
functions/
  api/analyze.js   Cloudflare Function (앱 ↔ Gemini 안전 프록시)
```

## 빌드 & 실행

```bash
flutter pub get

# 목업 모드 (AI 없이 UI 확인)
flutter run -d chrome

# 실제 AI 모드 (프록시 필요)
flutter build web --release \
  --dart-define=USE_MOCK=false \
  --dart-define=AI_PROXY_URL=/api/analyze
```

AI 키(`GEMINI_API_KEY`)는 코드에 포함되지 않으며, Cloudflare Pages의 환경변수(secret)로만 저장됩니다.

## 주의

참고용 리포트입니다. 건강·투자·법률·결혼·이별·합격·실패를 확정하는 판단으로 사용하지 마세요.
