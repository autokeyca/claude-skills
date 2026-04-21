---
name: autokey-business
description: AutoKey business reference — company profile, customers, staff, systems, agent fleet, operational rules. Use when the user or a task mentions AutoKey operations, customer data, commercial accounts (Enterprise/ADESA/IAA/FedEx/Holand/Hertz/H.Grégoire), AKCRM/AKINV/ScriptCase, pricing, DPC, SMS, invoicing, or the agent fleet (Archie/Aura/Claura/Optimus/Sophie/Loremaster/Accounts/Inbox). Pull before acting on anything that touches AutoKey customers, jobs, pricing, or business workflow.
---

# AutoKey — Business Reference

Source of truth for any agent needing context on AutoKey the business, the team, the systems, and the agent fleet. Pull this when you're about to act on customer, pricing, CRM, or operational work — do not memorize it into every agent's context window.

## Company

- **Business:** Automotive locksmithing — key cutting, programming, remotes. Retail + on-site mobile + commercial accounts.
- **Location:** Decarie Blvd, Montreal, QC. In-house walk-in counter.
- **Owner:** Jerry Arnstein (`jarnstein@autokey.ca`, `+1 514-290-4646`). **Orthodox Jewish, Shabbat observant** — no agent escalations to Jerry from Friday sundown through Saturday nightfall.
- **Preferred comms with Jerry:** Symphony is primary (replaced Slack 2026-04-07). Telegram (`858441656`) for alerts.

## Related businesses

- **KeyGrunt** — B2B parts-lookup platform. Managed by Archie.
- **CodeGuard** — Vehicle anti-theft system.

## Revenue lines

1. **Retail** — walk-in / phone / web. Key cut + program, key cut only, remotes. Highest volume.
2. **On-site mobile** — service at customer location.
3. **Commercial accounts** — fleet, auction, rental. Bulk / contracted pricing.

DPC is an **internal pricing process** (we query dealerships for OEM parts pricing), **not** a revenue line.

## Commercial accounts

| Client | CUST_ID | Type | Notes |
|---|---|---|---|
| Enterprise | 2239 | Multi-location corporate | Dedicated rules file |
| ADESA / Openlane | 158 | Auto auction | High volume |
| Impact / IAA | — | Salvage auction | Dedicated rules |
| FedEx | — | Logistics fleet | CUST_ID TBD |
| Holand Fleet | — | Fleet | CUST_ID TBD. Email routing fix landed 2026-04-17 |
| Hertz | 3267 | Car rental | Active e2e test in-flight 2026-04-17 |
| H. Grégoire | 97 | Used-car reseller | **NOT commercial** — refers retail customers. `CUSTTYPEID=7` |

## Staff

| Name | Role | USER_ID | Ext | Telegram |
|---|---|---|---|---|
| Jerry Arnstein | Owner | 1 | 710 | 858441656 |
| Ron (Rafael Ron) | Technician | 107 | 703 | 5099441624 |
| Ben Arnstein | Technician | 78 | 704 | 5862355555 |
| Daniel Arnstein | — | 4 | — | 5420364011 |
| Amal Rekik | DPC operator | 106 | 933 | 7694842110 |
| Mayssa | Reception | — | 930 | 8234458799 |
| Aura (bot) | Email/pricing agent (legacy) | 1112 | — | — |

## Infrastructure

| Host | IP | Role |
|---|---|---|
| aidev (Archie) | 192.168.1.250 | Dev server; Symphony backend (`:8450`) + frontend (`:5173`); OpenClaw gateway; Moneris/e-Transfer payments |
| Aura | 192.168.1.21 | Aura agent host; `aura-redesign` + `claura-assist` codebases; call-transcription systemd services |
| DB | 192.168.1.4 | MSSQL — AKCRM, AKINV, DPC, SUPPLIERS (TI + KD), VIN_NEW, PRICE_REQUESTS_INTERNAL, SMS_QUEUE, CALL_TRANSCRIPTIONS |
| ScriptCase | 192.168.1.19 (`scase.autokey.ca:8092`) | CRM/Inventory UI (being replaced by AutoCRM) |
| Wiki | `wiki.autokey.ca` | Internal DokuWiki |
| Fleet VMs | 192.168.1.{10,14,16,17,18,20,22,24,25} | Other OpenClaw agents (R2D2, Jarvis, Max, Victor, Polo, Elle, Invenio, Chip, Libra) |

## Core systems

- **AKCRM** — customers, jobs (~18,500+), quotes. Authoritative customer data.
- **AKINV** — inventory.
- **VIN_NEW** — VIN lookup/tracking.
- **DPC table** — dealer price check responses (internal pricing input).
- **PRICE_REQUESTS_INTERNAL** — pricing request queue.
- **SMS_QUEUE** — VoIP.ms delivery. Never call VoIP.ms API directly.
- **MONERIS** — credit card + e-Transfer payments.
- **Symphony** — `http://192.168.1.250:8450` — agent orchestration + chat (partial OpenClaw replacement).

## Agent fleet

Two platforms coexist; OpenClaw is being replaced by Symphony.

### OpenClaw agents (legacy, migrating)

- **Archie** (aidev `192.168.1.250`) — Systems engineer / PM. Fleet health, token budgets, deployments. Full SSH + MSSQL + GitHub access.
- **Aura** (`192.168.1.21`) — Email intelligence + pricing authority. **Being replaced.** See "Why Aura is being replaced" below. Currently strict draft mode — never auto-sends without Jerry approval.
- Plus 9 fleet VMs (R2D2, Jarvis, Max, Victor, Polo, Elle, Invenio, Chip, Libra) — roles TBD for COO.

### Why Aura is being replaced

Aura exhibited unreliable instruction-following and context amnesia: rules existed as 1,400+ lines of prose in a monolithic memory file, but the agent's compliance was voluntary and degraded under context pressure. Signal-to-noise dropped to ~10% on busy days (15k tokens of real instructions buried in 144k of context pollution). The redesign moves critical rules into **code / permissions / schema enforcement** instead of prose, and decomposes the monolith into narrow single-domain agents. **Reliability — not capability — is the driver.**

### Symphony / aura-redesign agents (current production, at `/home/ja/projects/redesign/` on Aura)

| Agent | Model | Channel | Role | Status |
|---|---|---|---|---|
| Dispatch Router | code-only | — | Email gateway; routes to agents (<1s, no LLM) | Live (re-enabled 2026-04-17) |
| DPC Pipeline | code-only | — | DPC send/bounce/parse lifecycle | Live |
| Sophie | Opus (headless) | — | DPC bounce recovery, website scraping | Live |
| Optimus | MiniMax | #pricing | Pricing authority; no email tools (enforced) | Live |
| Loremaster | Opus (headless) | #loremaster | Rule architect; triggered by Optimus | Live |
| Accounts | MiniMax | #accounts | Commercial client email | Testing (draft-only) |
| Inbox | MiniMax | #inbox | Retail email | Testing (draft-only) |
| Quote Blitz | MiniMax fallback | — | Auto-confirms complete call quotes | Live |
| Call Transcription | Gemini | — | 3 systemd services on Aura | Live (migrated 2026-04-14) |

### Claura-assist

**Location:** `/home/ja/projects/claura-assist/` on Aura. **Agent ID** `b1d26e2b-5a8c-46e3-8024-ec27ace53075`.

Part of the overall framework for assisting agents. Takes over some of the ad-hoc manual tasks Jerry used to ask Aura to do (CRM queries, SMS, payment requests, invoicing, supplier lookup, wiki queries, ScriptCase fixes, headless-browser automation). Generalist tool, not a domain-specialized production agent.

## Design principles (inherited from aura-redesign)

1. **Enforcement over compliance** — critical rules in code/permissions, not markdown.
2. **Context coherence** — one agent, one conversation thread, one domain.
3. **Programmatic automation first** — if it doesn't need LLM judgment, it's code.
4. **Isolation** — each agent gets its own tmux session + Symphony channel.
5. **Cost-tiered LLMs** — MiniMax for routine ops, Opus for meta/rule work.

## Hard operational rules

- **Cut-only keys** — we **do** supply key-cutting-only services. **No warranty** on cut-only work.
- **BYOP (Bring Your Own Part)** — **never proactively offered.** Handled only when the customer states from the start that they want to BYOP. Do not pitch BYOP as a fallback.
- **Pricing format** — `$X.XX + tx` with odd cents; never round.
- **DPC pricing** — when using DPC data, use list/MSRP, never the dealer's discounted price.
- **DB writes (AKCRM / AKINV)** — duplicate-check before INSERT; confirm with SELECT after; empty strings `''`, never NULL; `CONFIRMED=1` for job visibility in ScriptCase.
- **SMS** — always via `SMS_QUEUE` or stored procedures. Never call VoIP.ms directly.
- **Payment reconciliation** — mark paid only on human confirmation of deposit. Never auto-mark e-Transfer paid.
- **Corporate invoices** — auto-send permitted **only** after `PRICE_QUOTED` is verified.
- **Email send path** — no agent may send from `info@autokey.ca` directly. Pricing agents have no Gmail credentials (enforced).

## Current initiatives (as of 2026-04-20)

- **Symphony replacing OpenClaw** — chat layer cut over 2026-04-07; agent migrations ongoing.
- **aura-redesign Phase 8 live** — 4 production agents + dispatch + DPC pipeline.
- **Accounts + Inbox in TESTING** (draft-only) — pending graduation to auto-send.
- **Symphony v0.5** planned — multi-user, public/private channels, remote host picker.

## Gaps / open questions

- FedEx, IAA, Holand `CUST_ID`s not captured; fill in when known.
- Roles of the 9 fleet VM agents not yet documented here.
- OpenClaw deprecation timeline — ad-hoc per agent; no target date.
- `automation-inventory` Google Sheet — maintained? Where?
