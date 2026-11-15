---
name: saju-graph-harness
description: >-
  fate-report 프로젝트 전용 그래프 엔지니어링(Graph Engineering) 전문가 하네스.
  프롬프트 교체, 만세력/궁합 수식 변경, 아키텍처 설계 시 3인의 도메인 전문가 에이전트가
  독립 분석(Node 1) -> 상호 교차 비평(Node 2) -> 극단적 토론 및 합의 도출(Node 3)을 수행한다.
---

# Fate-Report 그래프 엔지니어링(Graph Engineering) 하네스

이 스킬은 `fate-report` 프로젝트의 사주·운세·궁합 엔진 고도화 및 코드/프롬프트 설계 변경 시, 단일 시점의 편향을 막고 완성도 높은 결론을 도출하기 위한 **다중 전문가 그래프 워크플로우(Multi-Agent Graph Topology)**입니다.

## 1. 그래프 노드(전문가 에이전트) 구성

1. **`saju-quant-auditor` (만세력·궁합수식 정량 감사관)**
   - **담당 영역**: `lib/manseryeok/`, `lib/compat/`, 프롬프트 `K01~K08` 및 `K07-R3`
   - **핵심 관점**: 수학적/규칙적 일관성, 1점의 오차도 없는 궁합 채점, 절입/시지/야자시 7대 경계 브레이크, 코드 계산 vs AI 계산의 역할 분리.
2. **`myeongri-prompt-expert` (명리 통변·프롬프트 아키텍트)**
   - **담당 영역**: `lib/services/prompt_builder.dart`, 프롬프트 `0~3절(JEV 4인 하네스)` 및 `K09~K10`
   - **핵심 관점**: 다정한 일상어 번역, 투트랙 문단 설계(순수 문단 vs 비교/궁합 요약), 실전 통변 4대 축(조후·억부·정서적 결·에너지 유통 경로), BLIND-FIRST 및 확신도 표기.
3. **`app-system-architect` (Flutter·Cloudflare 시스템 아키텍트)**
   - **담당 영역**: `lib/screens/`, `lib/models/`, `lib/services/ai_service.dart`, `functions/api/analyze.js`
   - **핵심 관점**: Gemini API 설정(`thinkingBudget`, `maxOutputTokens`, `responseMimeType`), JSON 스키마와 UI 카드 렌더링 호환성, 단발성 리포트 vs 다회차(꼬리 질문) 세션 구조, 응답 속도 및 토큰 비용.

---

## 2. 그래프 엔지니어링 실행 토폴로지 (3-Stage Graph)

```
[문제/안건 입력]
       │
       ├───► [Node A: saju-quant-auditor] ───────┐
       ├───► [Node B: myeongri-prompt-expert] ───┼──► (Stage 1: 독립 진단)
       └───► [Node C: app-system-architect] ─────┘
                                                 │
       ┌─────────────────────────────────────────┘
       ▼
[Stage 2: 교차 비평 & 상호 토론 (Cross-Critique & Debate Edges)]
  - A ↔ B: "코드 계산값과 프롬프트 조견표(K01~K07-R3) 중복/충돌을 어떻게 처리할 것인가?"
  - B ↔ C: "투트랙 줄글/꼬리질문 프롬프트와 현재 고정 JSON 카드 UI/thinkingBudget:0의 충돌을 어떻게 풀 것인가?"
  - C ↔ A: "K08 7대 강제 브레이크(보류)와 대운/세운/월운 데이터를 프론트엔드에서 어떻게 주입할 것인가?"
       │
       ▼
[Stage 3: 의장 에이전트 통합 합의 (Synthesis & Action Plan)]
  - 기존 버전 vs 신규 버전 핵심 비교표
  - 전문가 토론으로 발견된 치명적 충돌 지점과 해결책
  - 단계별 적용 로드맵 (쉬운 요약 결론)
```
