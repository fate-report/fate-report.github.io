// Cloudflare Pages Function — AI 프록시 (앱 → 여기 → Gemini)
// 앱에서 { system, prompt } 를 받아 Gemini(gemini-2.5-flash)를 호출하고
// 순수 JSON 결과만 돌려준다. API 키는 서버 환경변수(GEMINI_API_KEY)에만 존재.
//
// 경로: POST /api/analyze

const MODEL = 'gemini-2.5-flash';
const ENDPOINT =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

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

  const geminiBody = {
    system_instruction: { parts: [{ text: system }] },
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.75,
      maxOutputTokens: 2048,
      // 2.5-flash의 내부 추론(thinking)을 꺼서 응답 속도를 크게 높인다.
      thinkingConfig: { thinkingBudget: 0 },
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

  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  if (!text) {
    return json({ error: 'empty', message: '빈 응답' }, 502);
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (_) {
    const cleaned = text.replace(/```json/gi, '').replace(/```/g, '').trim();
    try {
      parsed = JSON.parse(cleaned);
    } catch (e2) {
      return json({ error: 'parse', message: 'JSON 해석 실패', raw: text.slice(0, 300) }, 502);
    }
  }

  return json(parsed, 200);
}
