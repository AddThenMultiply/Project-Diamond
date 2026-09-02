# The Two-Sided Platform: phased approach

How the platform brings the founder community and the investor community together, what data each side loads, and how that data becomes the input engine for AI analysis. UK English. Regulatory position throughout: **the platform prepares and analyses; it never arranges investments, introductions happen offline through the authorised transaction partner.**

## The two founder objectives, addressed by design

Every founder journey starts with the intent question (homepage fork, engagement creation):

1. **Grow by acquiring**: funding to buy resources from, or merge with, another company → `deal-ready.html` → Investor Ready diagnostic → intake (objective: `acquire_growth`) → Deal Ready workspace.
2. **Prepare my exit**: exit funded by the business's assets and equity, seeking the right investors/buyers → 24-metric diagnostic → intake (objective: `exit`) → Exit Ready workspace.

The intake asks each persona its own version of the two human questions (the number; life after / the combined business), then captures needs, wants, fears, business facts, capital parameters and which fundraising assets they hold.

## What each side loads

| Side | What they load | Where | Verified how |
|---|---|---|---|
| **Founders** | Objective, targets, timeline, needs/fears/non-negotiables, business facts, capital ask | `intake.html` → `founder_intake` table | Advisor reviews at first call; facts cross-checked against documents |
| **Founders** | Verified documents: deck, projections, business plan, legal/financial/commercial/HR records | `intake.html` uploads → private `dataroom` bucket (per-engagement, member-only) → `documents` table | Files are the source of truth; advisor marks status (review → approved) |
| **Investor base** | Mandates: type, cheque size, revenue/EBITDA thresholds, sectors, geographies, involvement, must-haves, dealbreakers | `investor-mandates.html` (advisor/admin only) → `investor_mandates` table | Entered from the existing 900-relationship base by the people who hold those relationships |

## The input engine

`get_ai_dossier(engagement)`: one database function that assembles everything the AI is allowed to see into a single structured object: engagement + intake + assessments + open gaps + roadmap + document status + targets. Every Edge Function builds its prompt from this dossier, so:

- the AI always works from the same audited picture the humans see;
- adding a new AI task never means new ad-hoc queries;
- every run is logged to `ai_runs`, and nothing customer-facing ships without a `human_signoffs` record.

## The phases

**Phase 1: Founder side live (this build).** Intent fork, both front doors, intake with document upload, dossier function. Pilot founders load real data. *Exit: 3 pilot engagements with completed intakes and ≥5 documents each.*

**Phase 2, Investor base structured (advisor work, no code).** Advisors enter the mandate register from the existing base, start with the 30–50 most active relationships, not all 900. *Exit: enough live mandates that every pilot dossier has plausible counterparties.*

**Phase 3: AI analysis over both sides.** New Edge Functions consume the dossier: readiness analysis, gap narratives, and **counterparty fit assessment**, scoring an engagement dossier against mandate criteria. Output goes to the **advisor console only**, as preparation for the human conversation and the partner-led introduction. Founders never see mandate data; investors never see founder data. *Exit: advisor receives a fit-ranked shortlist for one pilot engagement and uses it in a real partner conversation.*

**Phase 4, Investor self-serve (post-proof, decision gate).** Investors maintain their own mandates through a restricted portal (new `investor` role; RLS keeps them inside their own record only). Only worth building once Phase 3 shows the register earns its keep, and only with the regulatory position re-checked, since investor-facing features move closer to the FCA line.

**Phase 5: The flywheel.** Anonymised, aggregated readiness benchmarks flow back to the founder community ("businesses like yours at your stage score X"); mandate-side demand signals inform the advisory ("three active mandates want what you're building, here's what they'll test"). Both sides get smarter with every engagement, which is the platform's compounding moat.

## Persona research

Complete: see `PERSONA-RESEARCH.md` for the full cited evidence base. The findings are implemented: the intake now captures the research's top-ranked founder fields (adjusted EBITDA + basis, customer concentration, financial hygiene, valuation expectation + basis, skeletons disclosure, exit intent, emotional readiness, structure openness; acquisition criteria, integration owner, prior deals, leverage and PG willingness), and the mandate register captures the capital side's quantified routing fields (control preference, concentration tolerance %, founder-transition requirement, structures offered, leverage appetite). The design principle throughout: convert the ~47% of deals that die on diligence surprises into pre-disclosed, structured data, matched against real tolerance thresholds before any human conversation.
