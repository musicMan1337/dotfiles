# Palworld 1.0 — Mounts / Riding Pals

Scope: Palworld 1.0 full release (launched July 10, 2026, build 1.100.427). Conflicts or EA-era-looking data are flagged inline.

## Baseline facts (1.0)

- **Player level cap: 80** (up from EA's 65). Some coverage misreported 85; official patch notes say 80. Tech tree extended through 80 with 15 new tiers, new materials (Soralite Ingot, Paloxite Ingot), and new saddles.
- **Saddle gating is two-part:** (1) a Technology-tree level requirement (spend a tech point at that player level), and (2) for a new pal's saddle you must have **already captured that pal** before its blueprint appears. No pre-buying a saddle for an uncaught pal.
- Raid bosses, Tower Hard Mode, and oil rigs were rebalanced around level 80.

## How mounts work

Saddle pipeline: catch pal → gear unlocks in tech tree → spend a tech point at the required level → build a **Pal Gear Workbench** (Tech Lv6; 10 Paldium, 30 Wood, 2 Cloth) → craft the saddle (Leather, Cloth, Ingot, Fiber, Paldium, sometimes Pal Fluids). Saddles are Key Items (no inventory slot); once crafted you can mount that pal any time it's in your active party.

Mount types:
- **Ground** (~75 pals): run/sprint, some multi-jump; can't sprint over deep water and take drowning damage once stamina hits zero.
- **Flying** (~29 pals): use a separate mount-stamina bar; running out forces a rapid descent until it regens. Can hover/regen over water. Ascending costs extra stamina.
- **Aquatic** (~14, only a handful good): no stamina loss crossing open water.
- **Gliders** (Celaray, Killamari, Galeclaw): not full mounts; drain the player's own stamina.
- **Saddle-free exception: Panthalus** rides with no saddle (Partner Skill grants flight). Quest-unlocked (defeat Tower boss Auri, collect 4 whale-skeleton bones, craft the Echoing Flute, use the tablet on the Deserted Islet east of Ice Wind Island).

Mounted combat / partner skills (apply while mounted): elemental infusion (Ragnahawk/Beakon = Electric, Shadowbeak = Dark, Faleris = Fire), weak-point boosts (Vanwyrm "Aerial Marauder" +30–50%, Blazamut Ryu "Dragon Kaiser" +25–40% dragon weak-point), damage-type conversion (Pyrin to Fire + Attack up), or utility (Galeclaw fires ranged weapons while gliding; Astegon massively boosts ore damage/yield). Extra jumps while ridden: Fenglope double, Necromus double, Paladius triple, Hartalis triple.

## Best mounts by tier

| Tier (player Lv) | Ground | Flying | Aquatic |
|---|---|---|---|
| Early (1–20) | Direhowl (saddle Lv9) | Nitewing (Lv15) | Surfent (Lv10) |
| Mid (20–40) | Fenglope (~Lv26) | Ragnahawk (Lv33) | Azurobe (Lv24) |
| Late (40–60) | Dazemu (~Lv28) still practical (see note) | Shadowbeak (Lv47) or Selyne (Lv53) | Jormuntide (Lv39–40) |
| Endgame (60+) | Necromus or Paladius (both Lv61) | Frostallion (Lv62) → Xenolord (Lv66) → Jetragon (Lv79) | Neptilius (~Lv63–64) |

Notes:
- **Direhowl** (early ground): cheap Lv9 saddle, common plains catch. Partner Skill speed bonus scales with Condensation (up to +10%). Condense-linked ride speed applies to only some mounts (e.g. Fenglope 4-star = +20%, creator claim, verify), so Direhowl's buff is notable but not unique. Recommended movement passive stack for any mount: **Swift (+30%) + Legend (+20% SPD) + Runner (+20%)** (see [breeding.md](breeding.md)).
- **Nitewing** (early flying): most players' first flyer; simple craft. Opens up aerial traversal.
- **Fenglope** (mid ground): "Wind and Clouds" boosts speed + double-jump. Field Alpha Lv25 at Falls Mineshaft (~-249,-434).
- **Tarantriss** (early-mid traversal, saddle ~Lv20): built-in grapple/web Partner Skill for traversal; honorable-mention pick, not a top-speed mount.
- **Ragnahawk** (mid flying, top pick): best stamina economy of any flyer (drains slow, recovers fast) plus Fire infuse. Beakon (Electric) is the alternative.
- **Azurobe** (mid aquatic): Water infuse, smaller/faster than Jormuntide, best mid ocean-crosser.
- **Late-ground plateau:** no new top ground saddle between ~Lv28 (Dazemu) and Lv61 (Paladius/Necromus). You ride Fenglope/Dazemu through the 40–60 bracket.
- **Shadowbeak** (late flying): Dark infuse, Lv47; wild only in Wildlife Sanctuary No.3 (east edge). **Selyne**: Meteorite Event-only spawn at Sakurajima, Lv53.
- **Necromus / Paladius** (endgame ground, both Lv61): paired Legendary Alpha (Lv50) in the far north Desiccated Desert (~446,680). Necromus faster + better coverage (weak to Dragon only); Paladius triple-jumps.
- **Starryon Primo** (endgame-ground min-max, World Tree, saddle ~Lv77): Partner Skill +~5% speed per Neutral pal, scaling with condensation; a 4-star with a full Neutral party is claimed to beat a fully condensed Necromus in a straight line (creator claim, verify). paldb tentatively lists parents Starryon + Celesdir (name/parents unverified).
- **Frostallion / Noct** (endgame flying entry, Lv62): high stamina, best non-raid legendary flyer before Xenolord/Jetragon.
- **Xenolord** (endgame flying, saddle Lv66): raid boss, not a wild catch. Build a Summoning Altar (Lv33, 3 Ancient Tech pts; 100 Stone + 20 Paldium), use a Xenolord Slab (4 Slab Fragments from Feybreak dungeons/expeditions), beat it (Lv65, 1.4M HP, 10-min timer) for a Huge Dark Egg.
- **Jetragon** (top flyer, saddle Lv79 = highest in game): relocated in 1.0 to the Sky Islands off Sunreach (~-553,-1332), Lv60 Legendary Alpha (weak to Ice).
- **Neptilius** (endgame aquatic, ~Lv63–64): new 1.0 pal, fastest swimmer.
- **Ghangler** (mid-late aquatic, saddle ~Lv35, Feybreak shores; Dark/Water): Partner Skill scales ride speed with party comp (~+5% per Dark or Water pal at 0 stars, up to ~+25% per pal at 4 stars); fully condensed with a full Dark/Water party is claimed to be the fastest straight-line swimmer (creator claim, verify). paldb notes the Feybreak-shore form is the **Ghangler Ignis** (Fire/Water) variant (spelling/variant unverified).

## Flying-mount speed meta

Ranked by ride/sprint speed (Game8 + corroborating sources):

| Tier | Pal | Saddle Lv | Notes |
|---|---|---|---|
| SS | Jetragon | 79 | Highest top speed by a wide margin (sprint ~3300), lower stamina, best for short hops. |
| SS | Xenolord | 66 | Slightly slower (~2700) but much more stamina, best long-haul. |
| S | Panthalus | none (quest) | Sprint doesn't add speed, which helps stamina on long flights. |
| S | Astralym (EA name "Shaolong") | 77 | Among the fastest; World Tree area. |
| S | Eidrolon | 68 | Good balance; field boss SW Sunreach. |
| S | Eidrolon Ignis | 76 | Fire variant; World Tree secret area. |
| A | Frostallion / Noct | 62 | High stamina, best pre-raid-legendary long-distance flyer. |
| A | Shadowbeak | 47 | Good stamina, Dark infuse. |
| A | Selyne | 53 | High stamina; Meteorite Event catch. |
| B | Faleris | 38 (older) or 60 (post-1.0), see caveat | Fire infuse; relocated to World Tree in 1.0. |
| B | Ragnahawk | 33 | Best stamina economy mid-tier. |
| B | Beakon | 28 / 29 / 34 (disputed) | Electric infuse. |
| C | Vanwyrm | 21 | Faster than Nitewing; weak-point partner skill. |
| D | Nitewing | 15 | First flyer, baseline. |

Fastest overall: **Jetragon** (~2x the next tier). Best "fast + usable travel stamina": **Xenolord**. No top-speed flyer also mines/attacks; the gathering flyer is **Astegon** (mid speed, mobile ore rig).

**Party-synergy speed (new emphasis in 1.0):** several endgame mounts scale ride speed with party composition, so the fastest mount is build-dependent (generalizes beyond flying): **Ghangler** (Dark/Water party, aquatic), **Starryon Primo** (Neutral party, ground), and the **Eidrolon / Eidrolon Ignis** line (Dragon/Dark party, flying, ~+2-6% per pal at 4 stars). A 4-star Eidrolon line with a full Dragon/Dark party is claimed to edge Jetragon by ~3% top speed (creator claim, verify). In practice Jetragon/Xenolord stay the out-of-the-box picks; the synergy pals only win with a fully condensed, composition-tuned party.

## Utility mounts

| Pal | Type | Utility while mounted | Saddle Lv |
|---|---|---|---|
| Astegon | Flying | "Black Ankylosaur": +1100–3300% ore-node damage, +150–300% ore yield. Flying + mobile mining. | mid |
| Mammorest / Cryst | Ground | Boosts tree-cutting and ore-mining. | mid |
| Reptyro / Cryst | Ground | Improves ore-mining. | mid |
| Rushoar | Ground | Boosts boulder destruction; cheapest saddle (Lv6). | 6 |
| Galeclaw | Glider | Fastest glide + fire ranged weapons while gliding (fast fall). | 23 |
| Tarantriss | Ground | Built-in grapple/web Partner Skill for traversal; early-mid honorable mention, not top speed. | ~20 |
| Vanwyrm / Cryst | Flying | "Aerial Marauder" +30–50% weak-point dmg. Cryst is Ice variant. | 21 |
| Blazamut Ryu | Ground (raid pal) | "Dragon Kaiser" +25–40% dragon weak-point dmg. | high |
| Ragnahawk/Beakon/Shadowbeak/Faleris | Flying | Elemental infusion (Fire/Electric/Dark/Fire) = mobile weapon buff. | see above |
| Pyrin | partner | Converts damage to Fire + Attack up while mounted. | — |
| Kitsun | Ground | Negates Heat AND Cold penalties while mounted (cross volcano/snow without resist armor). | — |
| Panthalus | Flying (no saddle) | Quest-unlocked "free" mount. | none |
| Any aquatic / flying | Water/Air | Zero stamina loss crossing open water. | see above |
| Digtoise | NOT a mount | Auto-mines nearby ore as a follower, but not rideable (commonly confused). | n/a |

## Speed numbers (Run / Sprint, or Swim)

Data-table source cross-checked vs tier lists. Directionally right, not pixel-perfect.

| Pal | Category | Saddle Lv | Run / Sprint (or Swim) |
|---|---|---|---|
| Rushoar | Ground | 6 | 500 / 800 |
| Direhowl | Ground | 9 | 800 / 1050 (+≤10% Condense) |
| Univolt | Ground | 14 | 720 / 1100 |
| Dazemu | Ground | 28 | 900 / 1200 |
| Paladius | Ground | 61 | 800 / 1800 |
| Necromus | Ground | 61 | 1300 / 1900 |
| Hartalis | Ground | 70 | 900 / 1900 |
| Nitewing | Flying | 15 | 600 / 750 |
| Vanwyrm | Flying | 21 | 700 / 850 |
| Ragnahawk | Flying | 33 | 800 / 1300 |
| Beakon | Flying | 28–34 | ~1200 sprint |
| Faleris | Flying | 38 or 60 | ~1400 sprint |
| Shadowbeak | Flying | 47 | 1100 / 1600 |
| Frostallion | Flying | 62 | 1200 / 1800 |
| Xenolord | Flying | 66 | 1700 / 2700 |
| Jetragon | Flying | 79 | 1700 / 3300 |
| Chillet | Aquatic | 11 | 1890 swim |
| Jormuntide | Aquatic | 39–40 | 1800 swim |
| Neptilius | Aquatic | 63–64 | 2000 swim |

## Shortlist: if you only get a few

Travel: **Nitewing** (Lv15) asap → **Ragnahawk** (Lv33) → **Frostallion** (Lv62) → **Xenolord** (Lv66, travel) or **Jetragon** (Lv79, burst speed).
Aquatic: Surfent → Azurobe → Jormuntide → Neptilius.
Combat-mount: Vanwyrm or Blazamut Ryu (weak-point), Astegon (pays for itself in ore), Paladius/Necromus (ground boss mobility), or any infusion flyer.
No-brainer path: Direhowl → Nitewing → Ragnahawk → Necromus/Paladius → Frostallion → Xenolord/Jetragon.

## Flagged uncertainties

1. **Beakon saddle level:** 28 / 29 / 34 across sources (likely Alpha-spawn level vs tech level). Verify in your tree.
2. **Faleris saddle level/location:** older Lv38 at Wildlife Sanctuary No.3 vs 1.0-dated Lv60 at World Tree. Relocation is likely current; double-check level in-game.
3. **Frostallion/Shadowbeak absolute sprint numbers** disagree 10–25% between sources; relative order is consistent.
4. **"Shaolong" = "Astralym"** (EA/datamine name vs 1.0 localized name).
5. **Aquatic count:** ~4 that matter (Surfent, Azurobe, Jormuntide, Neptilius); paldb lists 14 water-capable but most are minor.
6. **Jetragon's old EA Lv50 saddle is obsolete;** current 1.0 value is Lv79.
7. **Surfent saddle level:** creator video says Lv16; table above says Lv10. Verify.
8. **Direhowl saddle level:** creator video says Lv8; table above says Lv9. Verify.
9. **"Ion" / "Hydrolon" (creator video)** are almost certainly two mishearings of **Eidrolon** (saddle 68) and its **Eidrolon Ignis** variant (76), already in the speed-meta table, not two separate pals.
10. **"King Packer"** (creator video, "really fast now") could not be resolved to a real pal; possibly Kingpaca (trait is carry capacity, not speed). Treat as unconfirmed.

## Sources
Game8 (fastest flying/ground mount tier lists, best mounts, per-pal pages), paldb.cc (Mounts), The Pal Professor (mount stats), BisectHosting (Xenolord/Fenglope/Paladius guides), NextTier (best mounts, 1.0 patch notes), GamesRadar (1.0 patch notes), Sportskeeda (Jetragon 1.0), Prodigy Gamers (Eidrolon 1.0), GameRant (mount partner skills), Palworld Wiki (Rideable Pals, Pal Gear Workbench).
