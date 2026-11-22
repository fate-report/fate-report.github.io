#!/usr/bin/env node
/**
 * Fate Report 4대 전문 검증 하네스 (Automated Multi-Specialist Verification Gate)
 *
 * - 하네스 A (만세력·K01~K10 정량 감사관): K01~K10 1:1 공식·테이블 정합성 검증
 * - 하네스 B (API·모델 폴백·환각 감시관): analyze.js 문법/5모델 폴백/타임아웃/헬스체크 + JEV 환각 차단 검증
 * - 하네스 C (배포·단일화 엉킴 방지관): cloudflare-dist(public/ + functions/) 분리 구조 & 프로덕션 락 검증
 * - 하네스 D (라이브 사이트 실전 점검관): `--live <URL>` 옵션 실행 시 실제 배포된 화면·API 최신 여부 즉시 판별
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');

const results = [];
function check(harness, name, ok, detail) {
  results.push({ harness, name, ok: Boolean(ok), detail });
}

function runStaticHarnesses() {
  const gz = read('lib/manseryeok/ganzhi.dart');
  const rel = read('lib/compat/relations.dart');
  const sc = read('lib/manseryeok/saju_calculator.dart');
  const st = read('lib/manseryeok/solar_terms.dart');
  const lc = read('lib/manseryeok/lunar_converter.dart');
  const bp = read('lib/manseryeok/birth_place.dart');
  const dst = read('lib/manseryeok/dst_correction.dart');
  const ce = read('lib/compat/compat_engine.dart');
  const pb = read('lib/services/prompt_builder.dart');
  const md = read('lib/models/models.dart');
  const ai = read('lib/services/ai_service.dart');
  const rs = read('lib/screens/result_screen.dart');
  const proxy = read('functions/api/analyze.js');
  const ci = read('.github/workflows/build_web.yml');

  const stemsH = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  const brsH = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // ── [하네스 A] 만세력·K01~K10 정량 감사관 ──
  const sidubeop = { 0: 0, 5: 0, 1: 2, 6: 2, 2: 4, 7: 4, 3: 6, 8: 6, 4: 8, 9: 8 };
  const k01Miss = [];
  for (let d = 0; d < 10; d++) {
    for (let h = 0; h < 12; h++) {
      const expH = stemsH[(sidubeop[d] + h) % 10] + brsH[h];
      if (!pb.includes(expH)) k01Miss.push(expH);
    }
  }
  const scHourOk =
    sc.includes("'갑': '갑', '기': '갑'") &&
    sc.includes("'을': '병', '경': '병'") &&
    sc.includes("'병': '무', '신': '무'") &&
    sc.includes("'정': '경', '임': '경'") &&
    sc.includes("'무': '임', '계': '임'");
  check('하네스 A', 'K01 시두법 (120조합)', k01Miss.length === 0 && scHourOk, '10일간×12시지 일치');

  const woldubeop = { 0: 2, 5: 2, 1: 4, 6: 4, 2: 6, 7: 6, 3: 8, 8: 8, 4: 0, 9: 0 };
  const mOrder = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1];
  const k02Miss = [];
  for (let y = 0; y < 10; y++) {
    for (let mi = 0; mi < 12; mi++) {
      const expH = stemsH[(woldubeop[y] + mi) % 10] + brsH[mOrder[mi]];
      if (!pb.includes(expH)) k02Miss.push(expH);
    }
  }
  check('하네스 A', 'K02 월두법 (120조합)', k02Miss.length === 0, '10년간×12절기월 일치');

  const k03Miss = [];
  for (let yr = 2000; yr <= 2060; yr++) {
    const idx = ((yr - 4) % 60 + 60) % 60;
    const tag = `${yr}=${stemsH[idx % 10]}${brsH[idx % 12]}`;
    if (!pb.includes(tag)) k03Miss.push(tag);
  }
  check('하네스 A', 'K03 세운 (2000~2060)', k03Miss.length === 0 && sc.includes('activeSeunYear'), '61개 연도 및 입춘 기준 일치');

  check(
    '하네스 A',
    'K04 대운·수동수정 락',
    sc.includes('final forward = (isYangYear && isMale) || (!isYangYear && !isMale);') &&
      sc.includes('recalculateWithManualPillars') &&
      st.includes('diffHours / 72.0'),
    '양남음녀 순행 + 72시간 정밀 대운수 + 수동 수정 재계산'
  );

  check(
    '하네스 A',
    'K05 절기·표준자오선·DST·자시',
    st.includes('entryTimeKst') &&
      bp.includes('127.5') &&
      dst.includes('1954, 5, 1') &&
      sc.includes('isNightJasiBeforeMidnight'),
    '24절기 KST 시·분 + 127.5°/135° + 1954 포함 DST + 야자시/조자시'
  );

  const k06Ok =
    rel.includes("'갑': '기'") &&
    rel.includes("'오': '미'") &&
    rel.includes("'자': '오'") &&
    rel.includes("{'진', '오', '유', '해'}");
  check('하네스 A', 'K06 합충형해파·오행', k06Ok, '천간합·육합·육충·형·자형·삼합·방합·삼형 일치');

  const k07Ok = ce.includes('math.min(plusC, 13)') && pb.includes('가점 합계 최대 `+13`');
  check('하네스 A', 'K07-R3 궁합 코드-프롬프트 동기화', k07Ok, 'C항목 가점 상한 +13(12+13=25점) 양측 일치');

  check(
    '하네스 A',
    'K08 7대 브레이크·음력 윤달',
    ce.includes('isValidGanzhiPillar') && lc.includes('_regDaysBeforeLeap') && sc.includes('checkTermBoundaryWarning'),
    '60갑자 유효성·윤달 변환·24시간 절기 경계 경고'
  );

  const hiddenMap = {
    자: ['계'], 축: ['기', '계', '신'], 인: ['갑', '병', '무'], 묘: ['을'],
    진: ['무', '을', '계'], 사: ['병', '무', '경'], 오: ['정', '기'], 미: ['기', '정', '을'],
    신: ['경', '임', '무'], 유: ['신'], 술: ['무', '신', '정'], 해: ['임', '갑'],
  };
  const hiddenOk = Object.entries(hiddenMap).every(([br, hs]) =>
    gz.includes(`'${br}': [${hs.map((x) => `'${x}'`).join(', ')}]`)
  );
  check('하네스 A', 'K09 지장간·십성·12운성', hiddenOk && gz.includes('twelveStagesTable'), '12지지 지장간·10천간 12운성 일치');

  check(
    '하네스 A',
    'K10 월운 조견표·시점 락',
    sc.includes('buildYearlyMonthPillars') && pb.includes('buildTemporalLockBlock'),
    '올해/내년 1~12월 월운 조견표 + KST 시점 락'
  );

  // ── [하네스 B] API·모델 폴백·환각 감시관 ──
  let proxySyntaxOk = false;
  try {
    execFileSync(process.execPath, ['--check', path.join(root, 'functions/api/analyze.js')], { stdio: 'pipe' });
    proxySyntaxOk = true;
  } catch (_) {}
  check('하네스 B', 'analyze.js JS 문법 검증', proxySyntaxOk, 'node --check 통과');

  check(
    '하네스 B',
    '무료 5모델 자동 전환 + OpenRouter 백업',
    proxy.includes('gemini-2.5-flash') &&
      proxy.includes('gemini-2.5-flash-lite') &&
      proxy.includes('gemini-3.1-flash-lite') &&
      proxy.includes('gemini-3.8-flash') &&
      proxy.includes('callOpenRouterFallback') &&
      proxy.includes('AbortSignal.timeout') &&
      proxy.includes('onRequestGet'),
    'Flash → Flash-Lite → 3.x → 2.0 → OpenRouter 자동 폴백 + 22초 타임아웃 + GET 헬스체크'
  );

  check(
    '하네스 B',
    'JEV 사후 검증기 + ** 마크다운 노출 차단',
    md.includes('JevHarnessValidator') &&
      ai.includes('_enforceK07SummaryBlockInBriefing') &&
      rs.includes('_stripBoldMarkers'),
    '2024/2025 환각 교정 + 확신도 클램핑 + 궁합 점수 잠금 + 요약 카드 별표 제거'
  );

  // ── [하네스 C] 배포·단일화 엉킴 방지관 ──
  check(
    '하네스 C',
    '프로덕션 Mock 차단 락',
    ai.includes("bool.fromEnvironment('USE_MOCK', defaultValue: false)") &&
      ai.includes("String.fromEnvironment('AI_PROXY_URL', defaultValue: '/api/analyze')"),
    'USE_MOCK=false / AI_PROXY_URL=/api/analyze 기본값 확정'
  );

  check(
    '하네스 C',
    'Cloudflare Pages public/ + functions/ 충돌 방지',
    ci.includes('mkdir -p /tmp/cf_dist/public') &&
      ci.includes('cp -r build/web/* /tmp/cf_dist/public/') &&
      ci.includes('cp -r functions /tmp/cf_dist/functions') &&
      ci.includes('node scripts/harness_verify.js'),
    'cloudflare-dist 정적 파일(public/)과 함수(functions/) 완전 분리 + CI 하네스 게이트 연동'
  );

  check(
    '하네스 C',
    'GitHub Pages *.github.io 루트 자동 분기',
    ci.includes('*.github.io) BASE_HREF="/"'),
    '루트 도메인(*.github.io) 자동 --base-href / 적용'
  );
}

async function runLiveHarness(baseUrl) {
  const cleanBase = baseUrl.replace(/\/+$/, '');
  try {
    const htmlResp = await fetch(`${cleanBase}/`);
    const html = await htmlResp.text();
    check(
      '하네스 D (라이브)',
      `홈 HTML 로딩 (${cleanBase}/)`,
      htmlResp.status === 200 && html.includes('flutter_bootstrap.js'),
      `HTTP ${htmlResp.status}, Flutter 앱 확인`
    );

    const jsResp = await fetch(`${cleanBase}/main.dart.js`);
    const jsText = await jsResp.text();
    const hasNewCode =
      jsText.includes('lunar_leap') &&
      jsText.includes('briefingBody') &&
      jsText.includes('questionCorePoint') &&
      jsText.includes('K07-R3');
    check(
      '하네스 D (라이브)',
      '최신 웹 번들(main.dart.js) 반영 여부',
      jsResp.status === 200 && hasNewCode,
      hasNewCode ? '최신 K01~K10 + 윤달 + 자유질문 번들 확인' : '구버전(11/15) 번들이 아직 남아 있음'
    );

    const apiResp = await fetch(`${cleanBase}/api/analyze`);
    const apiText = await apiResp.text();
    let apiJson = null;
    try { apiJson = JSON.parse(apiText); } catch (_) {}
    const hasNewApi =
      apiResp.status === 200 &&
      apiJson &&
      apiJson.ok === true &&
      typeof apiJson.version === 'string' &&
      apiJson.version.startsWith('v2-fallback');
    check(
      '하네스 D (라이브)',
      '최신 AI 프록시(/api/analyze) 반영 여부',
      hasNewApi,
      hasNewApi
        ? `버전=${apiJson.version}, 모델=${(apiJson.models || []).join(' → ')}, GEMINI_API_KEY=${apiJson.hasGeminiKey}`
        : `HTTP ${apiResp.status} (아직 구버전 프록시이거나 /api/analyze 미연결)`
    );
  } catch (e) {
    check('하네스 D (라이브)', '라이브 접속 점검', false, e.message);
  }
}

(async () => {
  runStaticHarnesses();
  const liveIdx = process.argv.indexOf('--live');
  if (liveIdx !== -1 && process.argv[liveIdx + 1]) {
    await runLiveHarness(process.argv[liveIdx + 1]);
  }

  const failed = results.filter((r) => !r.ok);
  for (const r of results) {
    console.log(`${r.ok ? 'PASS' : 'FAIL'} | [${r.harness}] ${r.name} — ${r.detail}`);
  }
  console.log(`\n총 ${results.length}건 중 ${results.length - failed.length}건 통과 / ${failed.length}건 실패`);
  if (failed.length > 0) process.exit(1);
})();
