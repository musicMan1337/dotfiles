# Palworld 1.0 — Best Base / Work Pals

## Baseline facts

Palworld exited Early Access on **July 10, 2026** (1.0). As of mid-July 2026 the game is only days old, so guide coverage is fresh but less battle-tested; single-source claims below are flagged.

| Fact | Value | Notes |
|---|---|---|
| 1.0 release | July 10, 2026 | After 2+ years of EA |
| Player/Pal level cap | **80** | History: 50 → 55 → 60 (Feybreak) → 65 → 80 (1.0) |
| Base Level cap | **35** | Separate from player level; all bases share one Base Level |
| Max bases (default) | **4** | 3rd base at Base Lv15, 4th at Base Lv24 |
| Max pals per base (default) | **15** | Scales to 15 by Base Lv15+ |
| World-settings ceiling | 10 bases / 50 pals | Custom setting, not default |

Unresolved: one aggregator claims Base Lv35 grants 30 workers by default; Game8 says default 15 (adjustable to 50). Treating Game8 as authoritative.

## Work Suitability system

1.0 rebuilt Work Suitability from a **1–4 scale to 1–10** and rebalanced every pal. Most wild pals cap around 7–8 in their best job (Transporting ~7, Farming ~4); 9–10 is an investment ceiling, not a wild catch.

| Work type | What it does |
|---|---|
| Kindling | Heat tasks: cooking, refining ore to ingots, furnaces/torches |
| Watering | Water wheels, Water Fountain, Mill |
| Planting | Plants crops at Silo/Flower Bed |
| Generating Electricity | Feeds a Power Generator (distributes base-wide) |
| Handiwork | Builds structures, crafts at workbenches |
| Gathering | Harvests crops/flower beds, supplies food |
| Lumbering | Chops trees / Logging Sites for Wood/Fiber |
| Mining | Stone/ore nodes; Mining Lv2+ needed for Ore, not just Stone |
| Medicine Production | Crafts medicine/consumables |
| Cooling | Refrigerators (stop food spoiling) |
| Transporting | Moves items from stations to storage; classic bottleneck |
| Farming | Ranch-only; every pal is Lv1, drops a fixed resource |

**New 13th type, immature at launch: Oil Extraction** (Oil Rigs/crude oil). No pal has natural suitability yet; appears player-operated only. Single-sourced; expect change.

**Work priority + monitoring stand (creator guide, 2026-07-20).** Each pal follows a fixed work-suitability PRIORITY order (lower number = higher priority); it defaults to its highest-priority eligible task and will NOT drop to a lower one unless you disable the higher task on the Pal Monitoring Stand. Consequences: (1) Cooling is the lowest priority, so a pal with any higher-priority full-time job never cools unless you toggle that job off; (2) Kindling is player-queued and effectively part-time, so a kindling pal needs a lower-priority full-time fallback (mining/lumbering/transport) or it idles while you are away. Give overlap pals a sensible fallback and pin roles on the Monitoring Stand.

### How a pal reaches Lv10

1. **Natural/wild level** (usually 1–8).
2. **Star Condensation** (Pal Essence Condenser): 1.0 reportedly needs **max 48 pals** to fully condense (down from EA's 116). Each star adds **+1 to the pal's currently-highest suitability** (working down one stat at a time); the **4th star adds +1 to EVERY suitability at once.** (This is why guides quote different numbers for the same pal, e.g. Anubis Handiwork 4 vs 6, wild vs condensed.) **Conflict:** other sources still describe EA-style condensation (116 pals, +5% HP/ATK/DEF per star). The stat-% effect and the work-suitability effect may both exist; the 48-vs-116 pal count is genuinely disputed 5 days post-launch. Verify in-game before quoting as fact. See [breeding.md](breeding.md).
3. **Applied Handbooks**: 12 consumables (one per work type except Oil Extraction) from the Medal Merchant, each a permanent +1 to one suitability on one pal. Reported ~300 "Dog Coins"; price unconfirmed, mechanic corroborated.
4. **Work Auras**: a partner-skill type where one stationed pal gives +1 to that work type for every OTHER pal at the base (not itself, doesn't stack with a duplicate):

| Work | Aura carrier |
|---|---|
| Kindling | Katress Ignis |
| Watering | Amione |
| Planting | Petallia |
| Generating Electricity | Puffolt |
| Handiwork | Ribbunya |
| Gathering | Clovee |
| Lumbering | Eikthyrdeer Terra |
| Mining | Tetroise |
| Medicine Production | Mycora |
| Cooling | Smokie Cryst |
| Transporting | Wumpo |
| Farming | Cinnamoth |

(Aura list from PalMods, partially cross-checked; not verified pal-by-pal against a second full table.)

**Reaching Lv10 without handbooks (creator guide, 2026-07-20).** Handbooks are scarce, so the useful question is which pals hit a suitability of 10 on their own (natural high level, or via 4-star condense) versus which need book investment. Reach 10 naturally in their signature job (so spend books elsewhere): Mining = Astegon, Aegidron; Watering = Shaolong, Neptilius, Jormuntide (Suzaku Aqua reaches 10 at 4-star); Kindling = Renjishi (World Tree), with Jormuntide Ignis available earlier; Electricity = Orserk; Lumbering = Celesdir Noct; Medicine = Silvance; Cooling = Bastigor, Frostallion; Handiwork = Selyne; Gathering = Jetragon, Frostallion/Noct, Starryon Primo, Hartalis. The video also names a single-role natural-10 Transporting pal (caption "Hydrolon") and a lumbering one (caption "Silverist"), both spelling-unverified. The guide's book-priority tip: spend handbooks on planting/gathering utility pals (whose yield/growth passives compound) over lumbering (which falls off late-game).

**Dark type = free Insomnia (24/7 work).** Dark-type pals never sleep, so they keep working through the night while other pals rest: more uptime, not a coverage hole. The guide treats this as the biggest tiebreaker when picking overlap/backup workers (Astegon, Sootseer, Splatterina, Bushi Noct, Magix, Vanwyrm Cryst, Prunelia, etc. are chosen partly for it). See the corrected Pitfalls note below.

## Best base pal by work type & tier

Tiers: Early 1–20, Mid 20–40, Late 40–60, Endgame 60+. Levels are commonly-quoted suitability at typical condensation; where sources disagreed, the higher-confidence value is shown.

| Work | Early (1–20) | Mid (20–40) | Late (40–60) | Endgame (60+) |
|---|---|---|---|---|
| Kindling | Ragnahawk (Kdl 3, Trn 3), Arsox (Kdl 3, Alpha Lv15) | Blazamut/Ryu (Kdl 6, Min 7) | Jormuntide Ignis (Kdl 7→10 @3★), Dupin, Flaracle | **Renjishi** (Kdl 8, + Hdwk 6/Gth 5/Trn 5) |
| Watering | Pengullet, Penking (Wtr 2), Turtacle (Wtr 2) | Azurobe / Elphidran Aqua / Broncherry Aqua | Suzaku Aqua (Wtr 6→10 @4★), Faleris Aqua (Wtr 6, Trn 5) | **Shaolong** (Wtr 8→10 @3★); Jormuntide (Wtr 7) 2nd |
| Planting | Broncherry, Petallia (aura), Mammorest (Plt 4), Clovee (early Plt+Gth) | Prunelia | Lyleen (Plt 7, + Gth 6/Hdwk 5/Med 5) | **Dandilord** (Plt 8, + Hdwk 6/Med 6/Gth 5); Ophydia (Plt 7) |
| Electricity | none dedicated; Puffolt (aura) once caught | Grizzbolt (Elec 5, + Hdwk 4/Trn 5) | Relaxaurus Lux, Azurmane | **Orserk** (Elec 8→10 @4★); best-in-slot, nothing close |
| Handiwork | Cattiva (multi + carry buff), Lamball, Penking (Hdwk 2), Wispaw (Hdwk 2, night) | Lifmunk/Tanzee (5-job), Anubis | Selyne (Hdwk 7, Med 6), Splatterina, Flaracle | **Solenne** (Hdwk 8→10 @4★, Dark = night work); Anubis+Sekhmet (below) |
| Gathering | Cattiva, Cremis, Clovee (early Gth+Plt) | Verdash (Gth 5, quad-role), Beegarde | Lyleen (Gth 6), Knocklem (Gth 4) | Starryon Primo (Gth 7), Jetragon (Gth 7–8, disputed), Hartalis (Gth 7 + Lmb 7) |
| Lumbering | Pupperai, Mammorest (Lmb 4) | Wumpo/Botan (Lmb 5, quad + aura), Elgrove (Lmb 3, Trn 3) | Bastigor (Lmb 6, Min 5/Cool 8) | **Celesdir Noct** (Lmb 8→10 @3★, night); Hartalis dual |
| Mining | Cattiva, Penking (Min 3), Mammorest (Min 4) | Anubis (Min 6, + Hdwk 6/Trn 4, best all-round early) | Knocklem/Ignis (Min 7, Trn 7), Cryolinx Terra | **Aegidron** (Min 8, best hands-off); Astegon (Min 7→10 @3★, nocturnal), Blazamut (Min 7) |
| Medicine | none dedicated | Vaelet, Felbat, Lyleen (Med 5) | Lyleen Noct (Med 7, Hdwk 5/Gth 6), Mycora (Med 6, aura) | **Silvance** (Med 8, Plt 6/Hdwk 6); Bellanoir/Libero (Med 7, Hdwk 6) |
| Cooling | Pengullet, Penking (Cool 2) | Azurobe Cryst / Loupmoon Cryst / Kingpaca Cryst (1.0 nums unconfirmed) | Bastigor (Cool 8, dual) | **Frostallion** (Cool 8, Gth 6); Whalaska (single source) |
| Transporting | Lamball, Pupperai, Cattiva, Penking (Trn 3) | Ragnahawk (Trn 3), Vanwyrm (Trn 3), Faleris (Trn 5), Elgrove (Trn 3, Lmb 3) | Dualith/Noct (Trn 6, Min 6/Lmb 5) | **Knocklem/Ignis** (Trn 7; some guides misname as "Nox"); Wumpo (Trn 6, aura), Eidrolon (Trn 6, ultra-fast single-purpose) |
| Farming | see Ranch section | | | |

**Jack-of-all-trades** (broad coverage, valuable when slots are scarce):
- **Beegarde** — 7 work types (widest spread in game per Game8): Plt 2, Hdwk 2, Lmb 2, Med 2, Trn 2, Gth 3, Farming/Honey 3.
- **Elizabee** (Beegarde evo) — Plt 4, Hdwk 4, Gth 4, Lmb 3, Med 4; no Transporting. 1.0 ~doubled these.
- **Lifmunk / Tanzee** — 5 jobs each (Plt, Hdwk, Lmb, Med, Gth); good early filler.
- **Cattiva** — Hdwk, Min, Gth, Trn; Cat Helper skill gives +100 carry capacity while in your active party. Best day-one pickup.
- **Penking** (Alpha, Lv15 Sealed Realm): early 5-job generalist, Trn 3 / Min 3 / Wtr 2 / Hdwk 2 / Cool 2. Grab-it-no-matter-what early pickup.
- **Wumpo/Botan** — Hdwk 3, Lmb 5, Cool 5, Trn 6, plus the Transporting aura. Relevant mid-to-endgame on breadth alone.
- **1.0 shift:** top-tier specialists (Dandilord, Silvance, Renjishi, Solenne, Anubis) are ALSO broad now, so the specialist-vs-generalist tension mostly disappears at endgame.
- **Overlap over specialists (creator guide, 2026-07-20):** whole-base coverage via role-overlap can beat slotting one specialist per work type, and overlap value is base-specific (not universal). Strong claim: three pals, Beegarde + Penking Lux + Waska Ignis, can cover every work suitability in the game for a maximally simplified base. ("Penking Lux" electric variant and "Waska Ignis" kindling/cooling pal are creator-named, unverified against paldb.)

## Boss-pal gating (1.0)

User-confirmed 2026-07-16: in 1.0 you **cannot tame the tower-fight boss pal**, and the former tower-boss species are effectively **endgame to obtain**. This compounds the self-only-breeder change in [breeding.md](breeding.md) (Lyleen, Grizzbolt, Orserk, Faleris, Shadowbeak, Bellanoir cannot be bred from cheaper pals). So beating a tower does NOT give you its pal, and these are late/endgame catches, not early-base workers. Notably affected in the tier table above: **Lyleen** (Planting/Gathering/Medicine), **Grizzbolt** and **Orserk** (Electricity). Plan non-boss alternatives for early/mid bases:
- Planting: Broncherry (Plt 5, field Alpha Lv23) + Petallia (aura). Gathering: Verdash (Gth 5, field). Medicine: Vaelet / Felbat.
- Electricity: Puffolt (Elec 2, ~Lv19, + electricity aura) or a couple of Sparkits, until an endgame Orserk. Handiwork: Lifmunk / Tanzee / Lunaris (Hdwk 4) / Cattiva.

Field Alphas (Broncherry, Penking, Arsox, Mammorest, etc.) are still tameable, only the human-partner tower and raid boss pals are gated.

## Standout must-have pals

- **Anubis** — Hdwk 6, Min 6, Trn 4. Best all-round worker obtainable relatively early; stays endgame-viable via Sekhmet synergy.
- **Sekhmet + Anubis** — Sekhmet's *Desert Empress* boosts Anubis work speed +20–40% just by being at the base; if Sekhmet also works a Handiwork station alongside, +30–60% more (doesn't stack with the base bonus). **Alpha Sekhmet** version reaches **+400%** at max skill vs +60% normal. One of the best base combos in 1.0.
- **Digtoise** — nuance: only Mining 4 stationed (mediocre in 1.0). Real value is the **Drill Crusher ride skill** (huge ore output while you ride/mine). Field/active-mining tool, NOT a top base worker. Contradicts its EA reputation.
- **Astegon** — Min 7 (→10 @3★), nocturnal (works nights). Beats higher-raw picks in practice because it never needs a day-shift swap. (One weak source says Min 4–5; trust 7.)
- **Blazamut/Ryu** — Kindling 6 + Mining 7 dual-specialist, also a strong raid defender. Genuinely dual-purpose.
- **Orserk** — Electricity 8 (→10 @4★). No endgame competition; Grizzbolt/Relaxaurus Lux/Azurmane are placeholders.
- **Jormuntide / Ignis** — Watering 7 / Kindling 7 respectively, both →10 @3★. Low-fuss specialists.
- **Vanwyrm** — DOWNGRADED in 1.0: only Kdl 1 / Trn 3, nocturnal. Now a breeding-chain stepping stone, not an endgame worker. (Common outdated EA assumption.)
- **Ragnahawk** — Kdl 3, Trn 3. Easy mid-game bridge "until you get Jormuntide Ignis or Knocklem."
- **Beegarde / Elizabee** — Beegarde's Worker Bee buffs Elizabee ATK/DEF up to 24% per Beegarde in party; a Beegarde swarm + Elizabee is combat+ranch.
- **Mozzarina** — only Milk auto-producer. **Chikipi** — only Egg auto-producer.
- **Lamball** — Wool + Hdwk 1 + Trn 1, fine day-one worker.
- **Mammorest**: very early but a hard catch (~2% on the starting island, or via egg hatch), Lmb 4 / Min 4 / Plt 4 base worker AND boosts mining + lumbering while ridden. Big early power spike (Lv3+ suitabilities normally don't appear until ~Lv25 zones).
- **Turtacle**: Water, ~Lv10, Wtr 2 plus a Partner Skill that cuts carried Ore weight ~80%. Pair with a carry-capacity pal for hauling.

## Passives for work speed / base efficiency

| Passive | Effect | Tier | Breed onto workers? |
|---|---|---|---|
| Artisan | +50% Work, no downside | rare | Yes, best work passive; bottleneck is landing it |
| Work Slave | +30% Work / −30% ATK | common | Yes for pure workers (ATK penalty irrelevant) |
| Serious | +20% Work, no downside | mid | Yes, easy filler |
| Lucky | +15% Work / +15% ATK | rare | Yes, esp. dual-purpose defenders (Blazamut) |
| Conceited | +10% Work / −10% DEF | common | Cheap floor filler |
| Nocturnal | Never sleeps, works nights | common | Situational: non-Dark pal on a 24/7 station (Transport/Electricity) |
| Workaholic | ~15% less sanity/hunger drain while working | rare | Probably good; exact effect unconfirmed |

Distinct (not "work speed," don't confuse): **Mine/Logging Foreman** (+25% to the PLAYER's own mining/logging in active party, not base work); **Philanthropist** (+100% breeding speed at a Breeding Farm).

## Ranch pals

| Pal | Product | Notes |
|---|---|---|
| Mozzarina | Milk | Only auto-producer |
| Chikipi | Eggs | Only auto-producer |
| Beegarde | Honey | Doesn't spoil; classic early SAN food |
| Lamball / Cremis / Melpaca | Wool | Cremis makes 2 baseline (2–6 at higher rank) |
| Caprity | Red Berries | Common 4th ranch slot |
| Vixy | Pal Spheres, Arrows, Gold | Dig Here skill unearths these while grazing; best early ranch pick (removes sphere/arrow bottleneck) |
| Rooby / Flambelle / Kelpsea Ignis | Flame Organ | Rooby earliest; equivalent options |
| Foxicle | Ice Organ | Farming Lv3; Alpha at Lv15, efficient early |
| Sparkit | Electric Organ | Only ranch source |
| Depresso / Caprity Noct | Venom Gland | Depresso earlier; Caprity Noct is Alpha (Lv23 Sealed Realm) |
| Kelpsea | Pal Fluids | Common early fishing reward |
| Dumud / Dumud Gild | High Quality Pal Oil | Dumud Gild (caption "Dumud Guild") starts higher, drops oil + a gold chance |
| Sibelyx / Sibelyx Primo | High Quality Cloth | Primo (NEW variant) starts higher; bred Sibelyx + Lapure (caption "Lupore", from Sunreach; spelling unverified) |
| Surfent | Leather | Ranchable ~Lv15 |
| Mau / Dumud Gild | Gold | Mau bred Chikipi + Depresso |
| Sootseer | Bones | User-confirmed 2026-07-16 (resolves caption "Sweepaeler"). Sakurajima, night; Farming Lv2 |
| Woolipop | Cotton Candy | Early |
| Woolipop Terra | Caramel Cotton Candy | NEW variant; bred Woolipop + Kikit per paldb, video said Killamari, verify; Special Cake ingredient |
| Shroomer | Mushrooms | ~Lv40 Sakurajima; passive lowers base-pal sanity drain |

Cake ranch = Mozzarina + Beegarde + Chikipi + Caprity (feeds Cake with Mill-made Flour). Milk & Eggs spoil; Honey & Cotton Candy don't. Keep a Cooling pal on a Refrigerator near the ranch.

Drop-pals graze and drop passively at Farming Lv1 unless the row notes otherwise. Ranch output has three stackable levers (optimize all before swapping a pal): (1) work-suitability level (raise via Handbooks and Lucky-pal guaranteed drops, so always catch Lucky pals), (2) condensation/star rank (boosts Partner-Skill potency even without raising the suitability number), (3) work speed (work-speed food + passives: Remarkable Craftsmanship, Artisan, Work Slave, or Nocturnal for overnight). The **Farm Hand** passive gives +1 farm suitability to its holder; **Cinnamoth** (the Farming aura above) gives +1 to ALL base pals. Neither stacks past Lv10.

## Pitfalls

- **Sanity (SAN) is the hidden productivity killer.** Low SAN = slacking / refusing / sickness (looks like a stuck pal). Fix: stocked feed box (Honey is ideal, no spoil + restores SAN), a bed per pal, a Hot Spring (tier 9). A ranched **Shroomer** (Sakurajima, ~Lv40) carries a passive that lowers base-pal sanity drain.
- **Stuck pals are usually layout, not a bug.** Causes: feedbox tucked in a corner (put it central/open), a geometry trap within 1 tile of the path, or a station under a roof/overhang. Check before assuming an AI bug.
- **Transporting is the classic bottleneck.** Everything feeds it; understaffed = output piles up unclaimed, capping the whole base. Two hidden factors (creator guide, 2026-07-20): a transporter's MOVEMENT speed (traveling between nodes) and TRANSPORTING speed (carrying to storage) are separate stats (favor movement speed when storage sits close to production); and bigger pals reach a drop box from farther away, so larger/Alpha haulers deposit sooner despite the clutter.
- **Narrow specialists idle without a matching station.** Match headcount to station count per job.
- **Work auras don't stack.** A second copy of the same carrier is wasted; use the slot for a real worker.
- **Dark-type / Nocturnal pals work 24/7 (correction, creator guide 2026-07-20).** Earlier this file said Astegon/Solenne/Celesdir Noct "work nights only"; the guide says Dark-type pals have innate Insomnia and work through the night WHILE other pals sleep, so they are extra uptime, not a coverage hole. Prefer them for always-on stations (Transport/Electricity). The real hole is the opposite: NON-Dark pals sleep, so a base can stall overnight unless key stations have a Dark/Nocturnal worker. (Verify the exact day/night behavior in-client.)
- **"Great mount/field tool" ≠ "great base worker"** (Digtoise). Check base suitability numbers, not general strength.
- **Ranch goods spoil, but don't over-invest in cooling.** A Cooling pal on a fridge slows Milk/Egg spoilage, but the creator guide (2026-07-20) argues a DEDICATED cooling pal/power slot is usually a waste: you net more food by putting that slot on another producer and overproducing than by preventing decay. Reconcile with the cake-ranch note above: keep cooling opportunistic (a Dark overlap pal that falls back to it), not a dedicated slot.

## Sources
Game8 (best base pals tier list, work suitabilities, level cap, base rewards, Artisan, Beegarde), palworld.gg (base-work tier list), PalMods (1.0 work suitability 1–10, work auras), NextTier (best base pals), GameRant (work passives), Mobalytics (early base pals), xGamingServer (sanity), Palworld Companion / Switchblade (pathing/navmesh), 4netplayers (ranch), AllThings.How (Sekhmet / Alpha Sekhmet). Pocketpair/GosuGamers/TechTimes for 1.0 launch facts.
