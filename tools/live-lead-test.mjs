// Live end-to-end against the ATM Supabase project without a browser. Writes one clearly marked test lead; delete it afterwards:
//   delete from public.leads where email = 'qa-test-delete-me@example.com';
// Run: NODE_USE_ENV_PROXY=1 node tools/live-lead-test.mjs
// Mirrors exactly what diagnostic.html sends: the same payload shape, the same headers supabase-js uses, then the send-report call.
const URL = "https://wfejarowrlalwgbqvloi.supabase.co", KEY = "sb_publishable_m2UUeC-YZWe7UVyYX553SA_6jHP2M5x";
const id = crypto.randomUUID();
const payload = { id, instrument: "multiplier_diagnostic", instrument_version: "1.0", score_pct: 59, band: "Emerging", band_tag: "md:emerging",
  theme_scores: { finance: 60, funding: 55 }, answers: [3,4,2,5,3,3,4,2,5,3,3,4,2,5,3,3,4,2,5,3],
  first_name: "QA Test", email: "qa-test-delete-me@example.com", company: "Northwind Components Ltd (TEST)", role_title: "Founder / CEO", revenue_band: "£1m to £5m",
  consent: true, source_page: "diagnostic.html", report_requested: true, report_html: "<p>Test report body from the node end-to-end run.</p>" };
const h = { apikey: KEY, Authorization: "Bearer " + KEY, "Content-Type": "application/json", Prefer: "return=minimal" };
let t = Date.now();
const ins = await fetch(URL + "/rest/v1/leads", { method: "POST", headers: h, body: JSON.stringify(payload) });
console.log("insert:", ins.status, (await ins.text()).slice(0, 200), "in", Date.now() - t, "ms");
t = Date.now();
const fn = await fetch(URL + "/functions/v1/send-report", { method: "POST", headers: { apikey: KEY, Authorization: "Bearer " + KEY, "Content-Type": "application/json" }, body: JSON.stringify({ lead_id: id }) });
console.log("send-report:", fn.status, (await fn.text()).slice(0, 200), "in", Date.now() - t, "ms");
console.log("lead id:", id);
