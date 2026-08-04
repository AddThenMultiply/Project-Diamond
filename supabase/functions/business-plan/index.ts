// ATM Founder Platform — Edge Function: business-plan
// Drafts the first cut of the buyer-credible business plan (Business Readiness
// phase) from the engagement's gap analysis and roadmap. AI drafts; the advisor
// reviews, edits and signs off (human_signoffs gate 'business_plan').
//
// Secrets (set via `supabase secrets set` — NEVER commit): ANTHROPIC_API_KEY

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
    const { engagement_id, company_context } = await req.json();
    if (!engagement_id) {
      return Response.json({ error: "engagement_id is required" }, { status: 400, headers: CORS });
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );

    const [{ data: eng, error: engErr }, { data: gaps }, { data: actions }, { data: assessments }] =
      await Promise.all([
        userClient.from("engagements").select("*").eq("id", engagement_id).single(),
        userClient.from("gap_items").select("dimension, description, severity, status").eq("engagement_id", engagement_id),
        userClient.from("roadmap_actions").select("action, due, status").eq("engagement_id", engagement_id),
        userClient.from("assessments").select("face_dimension, dimension, score, evidence").eq("engagement_id", engagement_id),
      ]);
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
      "Draft the first cut of a buyer-credible business plan for an exit-readiness engagement,",
      "following the ATM (Add Then Multiply) methodology and the Funded Female Founders",
      "fundraising-asset discipline (30–50 page plan structure — produce the skeleton with",
      "drafted key sections, not 50 pages). UK English. Mark clearly as AI-DRAFTED, for advisor review.",
      "",
      `Company: ${eng.company_name}`,
      `Target outcome: ${JSON.stringify(eng.target_outcome ?? {})}`,
      `Current phase: ${eng.phase}`,
      `Additional context from the founder/advisor: ${JSON.stringify(company_context ?? {})}`,
      "",
      `Latest assessments: ${JSON.stringify(assessments ?? [])}`,
      `Open gap items: ${JSON.stringify(gaps ?? [])}`,
      `Roadmap actions: ${JSON.stringify(actions ?? [])}`,
      "",
      "Structure: executive summary; the business and its 'why'; market; commercial engine;",
      "leadership and founder-independence plan; financials narrative (with the reverse-engineered",
      "trajectory to the target exit number); risk register; the readiness roadmap.",
      "Where evidence is missing, insert a clearly marked [ADVISOR INPUT NEEDED] placeholder.",
    ].join("\n");

    const aiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({ model: MODEL, max_tokens: 4096, messages: [{ role: "user", content: prompt }] }),
    });
    if (!aiRes.ok) {
      return Response.json({ error: `AI call failed: ${aiRes.status}` }, { status: 502, headers: CORS });
    }
    const ai = await aiRes.json();
    const planText = ai.content?.[0]?.text ?? "";

    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    await admin.from("ai_runs").insert({
      engagement_id,
      task: "business_plan_draft",
      model: MODEL,
      input_hash: await sha256(prompt),
      output: { plan: planText },
    });

    // Track the document at ai_drafted status (advisor moves it to review/approved)
    await admin.from("documents").upsert(
      { engagement_id, doc_type: "business_plan", checklist_key: "business_plan", status: "ai_drafted" },
      { onConflict: "engagement_id,checklist_key", ignoreDuplicates: false },
    );

    return Response.json({ plan: planText, status: "draft_awaiting_advisor_signoff" }, { headers: CORS });
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500, headers: CORS });
  }
});
