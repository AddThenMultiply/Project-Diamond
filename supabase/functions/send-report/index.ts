// send-report: email a founder the report they asked to keep.
//
// Called from the assessment pages after the lead row is inserted, with the
// row id the page generated. Runs with the service role so it can read the
// row and mark it sent. Sends through Resend. Never returns the row to the
// caller, and never sends twice.
//
// Environment (set with `supabase secrets set`):
//   RESEND_API_KEY   the Resend API key
//   REPORT_FROM      e.g. "Add Then Multiply <reports@addthenmultiply.com>"
//   REPORT_BCC       optional: an adviser inbox that receives every copy
//   SITE_URL         e.g. https://addthenmultiply.github.io/Project-Diamond
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const INSTRUMENT_NAMES: Record<string, string> = {
  multiplier_diagnostic: "Multiplier Diagnostic",
  investor_ready: "Funding Scorecard",
  transaction_readiness: "Transaction Readiness Assessment",
  ethical_acquisitions: "Ethical Acquisitions Scorecard",
};

const PAGE_FOR: Record<string, string> = {
  multiplier_diagnostic: "diagnostic.html",
  investor_ready: "investor-ready.html",
  transaction_readiness: "transaction-readiness.html",
  ethical_acquisitions: "ethical-acquisitions.html",
};

function escape(s: unknown): string {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { lead_id } = await req.json();
    if (typeof lead_id !== "string" || !/^[0-9a-f-]{36}$/i.test(lead_id)) {
      return new Response(JSON.stringify({ ok: false, error: "bad id" }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: lead, error } = await admin.from("leads")
      .select("id, instrument, score_pct, band, first_name, email, company, consent, report_requested, report_html, report_sent_at, source_page")
      .eq("id", lead_id).single();
    if (error || !lead) return new Response(JSON.stringify({ ok: false, error: "not found" }), { status: 404, headers: { ...cors, "Content-Type": "application/json" } });
    if (!lead.consent || !lead.report_requested || !lead.email) {
      return new Response(JSON.stringify({ ok: false, error: "not requested" }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
    }
    if (lead.report_sent_at) return new Response(JSON.stringify({ ok: true, already: true }), { headers: { ...cors, "Content-Type": "application/json" } });

    const name = INSTRUMENT_NAMES[lead.instrument] ?? "assessment";
    const site = (Deno.env.get("SITE_URL") ?? "https://addthenmultiply.github.io/Project-Diamond").replace(/\/$/, "");
    const page = `${site}/${PAGE_FOR[lead.instrument] ?? "index.html"}`;
    const first = escape(lead.first_name || "there");
    const body = `<!doctype html><html lang="en-GB"><body style="margin:0;background:#F8FAFC;font-family:-apple-system,'Segoe UI',Roboto,Arial,sans-serif;color:#111827;">
<div style="background:#2B2A29;border-bottom:4px solid #E4342D;padding:18px 24px;color:#fff;font-family:Georgia,serif;font-size:18px;">ADD THEN <span style="color:#F38E00">MULTIPLY</span></div>
<div style="max-width:680px;margin:0 auto;padding:24px;">
<p style="font-size:15px;">Hello ${first},</p>
<p style="font-size:15px;">Here is your ${escape(name)} report: <b>${escape(lead.score_pct)}%</b>, <b>${escape(lead.band)}</b>. An adviser will read it before your Readiness Call. Nothing in it is financial or investment advice; it indicates readiness, and what to do next is a recommendation we make on the call.</p>
<div style="background:#fff;border:1px solid #E2E8F0;border-radius:6px;padding:18px;font-size:14px;line-height:1.55;">${lead.report_html ?? "<p>Your report is on the page you completed; open the link below to see it again.</p>"}</div>
<p style="margin-top:20px;"><a href="https://api.leadconnectorhq.com/widget/booking/Av6i7gL0YzbszYFfnKqQ" style="display:inline-block;background:#2B2A29;color:#fff;padding:12px 20px;border-radius:4px;text-decoration:none;font-weight:600;">Book your free Readiness Call</a></p>
<p style="font-size:13px;color:#475569;">Take the assessment again: <a href="${page}" style="color:#C8231C;">${page}</a></p>
<p style="font-size:12px;color:#475569;border-top:1px solid #E2E8F0;padding-top:12px;margin-top:24px;">Add Then Multiply Limited is registered in England and Wales, company number 04623437. It is not authorised or regulated by the Financial Conduct Authority. This email describes advisory services and is not a financial promotion. You asked for this copy on our website; we will not add you to any list without a separate consent. To have your details deleted, reply to this email.</p>
</div></body></html>`;

    const key = Deno.env.get("RESEND_API_KEY");
    if (!key) {
      await admin.from("leads").update({ report_error: "RESEND_API_KEY not set" }).eq("id", lead.id);
      return new Response(JSON.stringify({ ok: false, error: "mail not configured" }), { status: 503, headers: { ...cors, "Content-Type": "application/json" } });
    }
    const payload: Record<string, unknown> = {
      from: Deno.env.get("REPORT_FROM") ?? "Add Then Multiply <reports@addthenmultiply.com>",
      to: [lead.email],
      subject: `Your ${name} report: ${lead.score_pct}%, ${lead.band}`,
      html: body,
    };
    const bcc = Deno.env.get("REPORT_BCC");
    if (bcc) payload.bcc = [bcc];
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!r.ok) {
      const text = await r.text();
      await admin.from("leads").update({ report_error: text.slice(0, 500) }).eq("id", lead.id);
      return new Response(JSON.stringify({ ok: false, error: "send failed" }), { status: 502, headers: { ...cors, "Content-Type": "application/json" } });
    }
    await admin.from("leads").update({ report_sent_at: new Date().toISOString(), report_error: null }).eq("id", lead.id);
    return new Response(JSON.stringify({ ok: true }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e).slice(0, 200) }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
