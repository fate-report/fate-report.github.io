// Cloudflare Pages Function — AI 프록시 (앱 → 여기 → Gemini 무료 최상위 모델 자동 폴백 체인)
// 앱에서 { system, prompt } 를 받아 2026년 기준 무료 티어 최상위 Gemini 모델을 우선 호출하고,
// 할당량(429)·일시 장애(503)·미지원(404/400) 시 자동으로 다음 무료 모델로 폴백한다.
// API 키는 서버 환경변수(GEMINI_API_KEY)에만 존재.
//
// 경로: POST /api/analyze

const FREE_MODEL_CHAIN = [
  'gemini-4-hydrogen',
  'gemini-3.8-flash',
  'gemini-3.5-flash-lite',
  'gemini-2.5-flash',
];

function endpointFor(model) {
  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
}

const STEMS = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
const STEMS_HANJA = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const BRANCHES = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
const BRANCHES_HANJA = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

function yearGanzhi(y) {
  const idx = ((y - 4) % 60 + 60) % 60;
  const s = idx % 10;
  const b = idx % 12;
  return `${STEMS[s]}${BRANCHES[b]}(${STEMS_HANJA[s]}${BRANCHES_HANJA[b]})`;
}

function buildKstTimeAnchor() {
  const kst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  const rawY = kst.getUTCFullYear();
  const y = rawY >= 2026 ? rawY : 2026;
  const m = kst.getUTCMonth() + 1;
  const d = kst.getUTCDate();
  const sajuYear = (m === 1 || (m === 2 && d < 4)) ? y - 1 : y;
  return [
    `[시스템 절대 시간 락 (KST 실시간 기준 — 하네스 1 최우선 강제)]`,
    `- 오늘 실제 날짜: ${y}년 ${m}월 ${d}일`,
    `- '올해(현재 연도)' = ${y}년 ${yearGanzhi(sajuYear)}년 세운`,
    `- '내년' = ${y + 1}년 ${yearGanzhi(sajuYear + 1)}년 / '작년' = ${y - 1}년 ${yearGanzhi(sajuYear - 1)}년`,
    `- [절대 금지 경고]: 모델의 과거 사전학습 시점(2024년 갑진년이나 2025년 을사년)을 '올해/현재'라고 부르거나 2024년 기준으로 나이와 대운을 역산하는 환각을 엄격히 금지합니다. 모든 '올해/지금' 표현은 반드시 ${y}년(${yearGanzhi(sajuYear)}년)으로만 해석하세요.`,
  ].join('\n');
}

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

function json(obj, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS, ...extraHeaders },
  });
}

export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: CORS });
}

export async function onRequestPost(context) {
  const { request, env } = context;

  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) {
    return json({ error: 'server_misconfigured', message: 'GEMINI_API_KEY 없음' }, 500);
  }

  let body;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: 'bad_request', message: '잘못된 요청' }, 400);
  }
  const system = (body.system || '').toString();
  const prompt = (body.prompt || '').toString();
  if (!prompt) {
    return json({ error: 'bad_request', message: 'prompt 없음' }, 400);
  }

  const timeAnchor = buildKstTimeAnchor();
  const finalSystem = system.includes('Temporal Hard Lock')
    ? system
    : (system ? `${timeAnchor}\n\n${system}` : timeAnchor);
  const finalPrompt = prompt.includes('Temporal Hard Lock')
    ? prompt
    : `${timeAnchor}\n\n${prompt}`;

  const customModel = (env.GEMINI_MODEL || '').toString().trim();
  const candidates = customModel
    ? [customModel, ...FREE_MODEL_CHAIN.filter((m) => m !== customModel)]
    : FREE_MODEL_CHAIN;

  const baseBody = {
    system_instruction: { parts: [{ text: finalSystem }] },
    contents: [{ role: 'user', parts: [{ text: finalPrompt }] }],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.65,
      maxOutputTokens: 8192,
    },
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_ONLY_HIGH' },
    ],
  };

  let lastStatus = 502;
  let lastDetail = '';
  let usedModel = candidates[0];
  let data = null;

  for (const model of candidates) {
    usedModel = model;
    const reqBody = {
      ...baseBody,
      generationConfig: model.startsWith('gemini-2.5')
        ? { ...baseBody.generationConfig, thinkingConfig: { thinkingBudget: 0 } }
        : baseBody.generationConfig,
    };

    let resp;
    try {
      resp = await fetch(endpointFor(model), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify(reqBody),
      });
    } catch (e) {
      lastStatus = 502;
      lastDetail = `network error on ${model}`;
      continue;
    }

    if (resp.status === 402 || resp.status === 403) {
      return json({ error: 'credit', message: '크레딧/권한 문제' }, 402);
    }

    if (!resp.ok) {
      lastStatus = resp.status;
      try {
        lastDetail = (await resp.text()).slice(0, 300);
      } catch (_) {
        lastDetail = '';
      }
      // 400/404(모델 미지원), 429(무료 한도 초과), 5xx(일시 과부하) 시 다음 무료 모델로 자동 폴백
      if ([400, 404, 429, 500, 502, 503, 504].includes(resp.status)) {
        continue;
      }
      return json({ error: 'upstream', message: `Gemini ${resp.status}`, detail: lastDetail }, 502);
    }

    try {
      data = await resp.json();
      break;
    } catch (_) {
      lastStatus = 502;
      lastDetail = `invalid JSON envelope from ${model}`;
      continue;
    }
  }

  if (!data) {
    if (lastStatus === 429) {
      return json({ error: 'rate_limit', message: '요청 과다 (전체 무료 모델 한도 도달)' }, 429);
    }
    return json(
      { error: 'upstream', message: `Gemini ${lastStatus}`, detail: lastDetail },
      502,
    );
  }

  // thinking 토큰(thought: true)을 제외한 실제 출력 텍스트 파트 추출
  const parts = data?.candidates?.[0]?.content?.parts ?? [];
  const textPart = parts.find((p) => !p.thought && typeof p.text === 'string') || parts[parts.length - 1];
  const text = textPart?.text ?? '';
  if (!text) {
    return json({ error: 'empty', message: '빈 응답' }, 502);
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (_) {
    let cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      cleaned = cleaned.slice(firstBrace, lastBrace + 1);
    }
    try {
      parsed = JSON.parse(cleaned);
    } catch (e2) {
      return json({ error: 'parse', message: 'JSON 해석 실패', raw: text.slice(0, 300) }, 502);
    }
  }

  return json(parsed, 200, { 'X-Fate-Model': usedModel });
}
