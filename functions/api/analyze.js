// Cloudflare Pages Function — AI 프록시 (앱 → 여기 → Gemini)
// 앱에서 { system, prompt } 를 받아 Gemini(gemini-2.5-flash)를 호출하고
// 순수 JSON 결과만 돌려준다. API 키는 서버 환경변수(GEMINI_API_KEY)에만 존재.
//
// 경로: POST /api/analyze

const MODEL = 'gemini-2.5-flash';
const ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

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

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
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

  const geminiBody = {
    system_instruction: { parts: [{ text: finalSystem }] },
    contents: [{ role: 'user', parts: [{ text: finalPrompt }] }],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.65,
      maxOutputTokens: 8192,
      // K01~K10 전수 대조 및 4인 JEV 하네스 릴레이 검증을 수행하면서도
      // 응답 지연을 최소화하도록 추론 예산(1024)을 할당한다.
      thinkingConfig: { thinkingBudget: 1024 },
    },
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_ONLY_HIGH' },
    ],
  };

  let resp;
  try {
    resp = await fetch(ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: JSON.stringify(geminiBody),
    });
  } catch (e) {
    return json({ error: 'network', message: 'Gemini 연결 실패' }, 502);
  }

  if (resp.status === 429) {
    return json({ error: 'rate_limit', message: '요청 과다' }, 429);
  }
  if (resp.status === 402 || resp.status === 403) {
    return json({ error: 'credit', message: '크레딧/권한 문제' }, 402);
  }
  if (!resp.ok) {
    const t = await resp.text();
    return json({ error: 'upstream', message: `Gemini ${resp.status}`, detail: t.slice(0, 300) }, 502);
  }

  let data;
  try {
    data = await resp.json();
  } catch (_) {
    return json({ error: 'parse', message: '응답 파싱 실패' }, 502);
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

  return json(parsed, 200);
}
