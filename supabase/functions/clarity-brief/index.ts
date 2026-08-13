// ATM Founder Platform — Edge Function: clarity-brief
// Synthesises the founder's pre-meeting questionnaire answers into a
// draft Founder Clarity Brief. AI drafts; the advisor reviews and signs off
// (human_signoffs gate 'clarity_statement') before anything is customer-facing.
//
// Secrets (set via `supabase secrets set` or the dashboard — NEVER commit):
//   ANTHROPIC_API_KEY
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MODEL = "claude-sonnet-4-5";

async function sha256(text: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const { engagement_id, answers } = await req.json();
    if (!engagement_id || !answers) {
      return Response.json({ error: "engagement_id and answers are required" }, { status: 400, headers: CORS });
    }

    // Caller identity (RLS enforced with the caller's JWT)
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );
    const { data: eng, error: engErr } = await userClient
      .from("engagements").select("id, company_name, target_outcome").eq("id", engagement_id).single();
    if (engErr || !eng) {
      return Response.json({ error: "Engagement not found or not a member" }, { status: 403, headers: CORS });
    }

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      return Response.json(
        { error: "ANTHROPIC_API_KEY is not configured. Set it with: supabase secrets set ANTHROPIC_API_KEY=..." },
        { status: 501, headers: CORS },
      );
    }

    const prompt = [
      "You are drafting a Founder Clarity Brief for an exit-readiness advisory engagement,",
      "based on the ATM (Add Then Multiply) Exit Advisory Process. UK English.",
      "The brief synthesises the founder's pre-meeting questionnaire. It prepares the advisor",
      "for the founder-clarity conversation — it does not replace it. The two core questions",
      "(the financial target; life the day after the sale) are asked and heard by a person.",
      "",
      `Company: ${eng.company_name}`,
      `Target outcome (if recorded): ${JSON.stringify(eng.target_outcome ?? {})}`,
      "",
      "Questionnaire answers:",
      JSON.stringify(answers, null, 2),
      "",
      "Produce: 1) a one-paragraph synthesis of where the founder stands;",
      "2) the founder's stated number and what appears to sit behind it;",
      "3) 'day after the sale' signals — clarity or ambivalence;",
      "4) five tailored questions the advisor should ask in the clarity conversation;",
      "5) any red flags or inconsistencies. Mark the draft clearly as AI-drafted, for advisor review.",
    ].join("\n");

    const aiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({ model: MODEL, max_tokens: 2048, messages: [{ role: "user", content: prompt }] }),
    });
    if (!aiRes.ok) {
      return Response.json({ error: `AI call failed: ${aiRes.status}` }, { status: 502, headers: CORS });
    }
    const ai = await aiRes.json();
    const briefText = ai.content?.[0]?.text ?? "";

    // Audit trail: log the run with the service role (ai_runs has no user insert policy)
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    await admin.from("ai_runs").insert({
      engagement_id,
      task: "clarity_brief",
      model: MODEL,
      input_hash: await sha256(prompt),
      output: { brief: briefText },
    });

    return Response.json({ brief: briefText, status: "draft_awaiting_advisor_signoff" }, { headers: CORS });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500, headers: CORS });
  }
});
