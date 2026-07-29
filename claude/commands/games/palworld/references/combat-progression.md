# Palworld 1.0 — Combat, Progression & What's New

Compiled July 2026, post-launch (build 1.100.427, released July 10, 2026). Flags mark disputed/unconfirmed items.

## What changed in 1.0

| Area | Early Access | 1.0 |
|---|---|---|
| Player level cap | 65 | **80** |
| Total Pals | ~215 | **287** (72 new: 47 species + 25 variants) |
| Catch bonus threshold | 10–12/species (disputed) | **5 catches/species** |
| Tower bosses | 7 | **9** (2 new: Sunreach + World Tree) |
| Tower fight timer | 10 min | **5 min** |
| Regions | Palpagos + Sakurajima + Feybreak | + **Sunreach** (sky islands) + **World Tree** (endgame) + 7 small islands |
| New materials | — | **Soralite** (Sunreach ore) and **Paloxite** (World Tree ore, top energy weapons) |
| New endgame system | — | **Awakening** (Radiant Gems → Awakening Gem → +50% stats; magnitude flag: a creator video instead says a flat ~111 stat points, verify) |
| Breeding | passive/IV averaging | + **Mutation** (rare stronger hatch) + 4 new cakes |
| Combat | dodge-roll | reworked into a **dash** (attack/reload mid-dash) |
| Raids | ammo-consuming, fixed waves | wave-based, defenses don't consume ammo, scales to Work Pals, Negotiator can cancel for gold |
| Weapons | — | 13 new (Primitive Sword → endgame energy guns: Beam Scatter, Plasma Rifle, Beam Launcher, Drone Launcher) |
| Traversal | — | **Wing Pack** craftable glider (burns Wing Cells; pal-free flight) |

Flags: one GamesRadar headline says cap 85, but its body + all other sources say **80** (80 is correct). "**Genetic Recombination**" appears in some SEO pages but NOT Pocketpair's patch notes; the real new breeding feature is **Mutation** (see [breeding.md](breeding.md)). Distrust guides built around "Genetic Recombination."

## Leveling (Player 1 → 80)

Ranked by efficiency:
1. **Capture bonus (best XP source).** Escalating bonus XP per species, completing at **5 catches/species** in 1.0. Ignores the caught pal's level and world XP multipliers; scales with YOUR level (fresh species in Sunreach/World Tree are huge XP even near cap). Catching pays ~2x a kill. Loop: chain-catch 5 of a species, rotate.
2. **Missions/Quests** — a real progression spine in 1.0; big XP + gate fast-travel/spawns.
3. **Alpha pals, dungeon bosses, bounty/world bosses** — capture (not kill) for the biggest single hits; Alphas respawn ~15 min.
4. **Dungeon clearing** — more catches, chests, room XP; leave/re-enter to reroll spawns.
5. **Passive base XP:** arrow production at High-Quality Workbenches (~80 XP/min per crafting pal; ~320/min with 4 pals at Base Lv10); campfire cooking near a Fire pal.
6. **Food buffs** (Seafood Salad, Jelliette's Jiggly Jelly = temp EXP boost).
7. **Training Manuals** (late-game loot, direct level injections).

Pacing: Lv1–15 catch-chain + missions; 15–30 new regions + dungeons + arrow farm; 30–50 Alpha/bounty loops; 50–65 raids + sanctuaries; 65–80 Sunreach + World Tree fresh-species catch bonuses. No confirmed egg-hatch XP method or exploit beyond the (intended) catch-bonus loop.

## Best combat pals by tier

Party vs base/mount: some S-tier fighters (Jetragon, Astegon) are poor base workers, bring them for fights only.

**Early (1–20):** Chillet (Ice/Dragon, Lv11 Alpha near start, mount + Dragon infuse, best very-early all-rounder), Foxparks (Fire), Direhowl (Neutral, fast), Anubis (Ground, from ~Lv15, doubles as miner).

**Mid (20–40):** Vanwyrm (Fire/Dark, first reliable flyer), Kitsun (Fire, underrated), Grizzbolt (Electric, A), Orserk (Electric/Dragon, A), Astegon (Dragon/Dark, strong + premier miner).

**Late (40–60):** Suzaku (Fire), Bastigor/Bastigar (Ice, tower pal), Selyne (Neutral/Dark, Sakurajima tower), Warsect (Ground, carries into endgame), Jormuntide Ignis (Fire/Dragon, best non-legendary attacker + Kindling worker).

**Endgame (60–80):**

| Pal | Element | Meta status |
|---|---|---|
| Jetragon | Dragon | S+; highest raw attack, fastest flight, homing missiles. Combat only. |
| Frostallion / Noct | Ice | S+; premier Dragon counter, Ice-infuse mount. Noct rated highest raw combat by some. |
| Necromus | Dark | S+; fastest melee mobility. Paired with Paladius. |
| Paladius | Neutral | Legendary counterpart; weak to Dark. |
| Shadowbeak | Dark | S; "easiest S-tier to use," high raw Dark damage. |
| Blazamut Ryu | Fire (secondary disputed: Fire/Electric vs Fire/Dragon, verify in-game) | Elite endgame Fire. |
| Xenolord (raid) | Dark/Dragon | Highest damage ceiling among raid pals; hardest standard fight. |
| Neptilius (NEW) | Water | Best Water pick; NE Wildlife Sanctuary Dome Alpha, ~145 ATK. |
| Hartalis (NEW, raid) | Water/Grass → Neutral p2 | Big 1.0 winner for ground combat; catchable after the raid. |
| Shaolong (NEW) | Water/Dragon | Sunreach tower pal (with Auri); strong new face. |
| Astralym (NEW) | Neutral/typeless | Boss-EXCLUSIVE (World Tree final); Paldeck-only, not catchable/usable. Lv80, ~420k HP (single source). |

Type-coverage endgame picks: Fire = Blazamut Ryu · Water = Neptilius · Ice = Frostallion · Dark = Necromus/Shadowbeak · Dragon = Jetragon · Ground = Warsect/Anubis · Electric = Grizzbolt/Orserk · Grass = Lyleen · Neutral = Paladius.

## Element type chart

Nine elements: Neutral, Fire, Water, Grass, Electric, Ice, Ground, Dark, Dragon. Unchanged from EA (no 1.0 wheel rework). It's a **linear chain**, not a Pokemon grid: each element is strong vs one other (Fire is the exception with two) and weak to one.

| Element | Strong vs | Weak vs |
|---|---|---|
| Fire | Grass, **Ice** (double) | Water |
| Water | Fire | Electric |
| Electric | Water | Ground |
| Ground | Electric | Grass |
| Grass | Ground | Fire |
| Ice | Dragon | Fire |
| Dragon | Dark | Ice |
| Dark | Neutral | Dragon |
| Neutral | (none) | Dark |

Multipliers: **1.5x** strong, **0.5x** weak/resisted, same-element hits resisted (0.5x). Dual-typed stack both matchups (double-advantage ~2.25x, double-disadvantage ~0.25x). Flag: a Game8 fetch returned Pokemon types (Steel/Poison/etc.) that don't exist in Palworld, discarded; the chain chart above is corroborated by 3 sources.

## Boss / tower order

Tower bosses (9, in order; timer now 5 min, be a few levels above each):

| Boss | Faction/Region | Lv | Element | Counter |
|---|---|---|---|---|
| Zoe & Grizzbolt | Rayne Syndicate | 10 | Electric | Ground |
| Lily & Lyleen | Free Pal Alliance | 20 | Grass | Fire |
| Axel & Orserk | Brothers of the Eternal Pyre | 30 | Electric/Dragon | Ice, Ground |
| Marcus & Faleris | PIDF | 40 | Fire | Water |
| Victor & Shadowbeak | PAL Genetic Research Unit | 50 | Dark | Dragon |
| Saya & Selyne | Moonflower (Sakurajima) | 55 | Dark | Dragon |
| Bjorn & Bastigar | Feybreak | 60 | Ice | Fire |
| Auri & Shaolong (NEW) | Azure Covenant (Sunreach) | 68 | Water/Dragon | Electric, Ice |
| Zanara/Zenara & Astralym (NEW, final) | World Tree | 80 | Neutral/typeless | none |

(Final NPC name spelled "Zanara"/"Zenara" across sources, unresolved.)

**Alpha field bosses:** ~72 fixed-spawn oversized bosses. The four Legendary Alphas (Paladius, Necromus, Frostallion, Jetragon) all spawn Lv50 and are the hardest; Paladius & Necromus share coords (Desiccated Desert ~445,680) as a paired fight.

**Endgame raid bosses (recommended order):**

| Raid | Lv | Element | Notes |
|---|---|---|---|
| Bellanoir | 30 (wait to 40–45) | Dark | Entry raid |
| Bellanoir Libero | 50 | Dark | Healing phase |
| Blazamut Ryu | 55 | Fire (+?, disputed) | Element swap at low HP |
| Hartalis (NEW) | 70 | Water/Grass → Neutral | Two-phase; toughest standard pre-Ultra |
| Xenolord | 65 | Dark/Dragon | Adds + meteors; hardest overall |
| Ultra variants | 80 | same | Multi-million HP, retuned for Lv80 |
| Moon Lord | 50 (Master 80, 2.35M HP) | crossover | Flag: Terraria event content, may be time-limited/unavailable |

## Alpha, Lucky, dungeons

- **Alpha pals:** oversized fixed-spawn bosses, boosted level/HP/drops. Respawn ~15 min; every dungeon guarantees one as end boss. 1.0 raised all Alpha HP by 1.2x.
- **Lucky pals (shiny):** rare, larger, sparkling; spawn higher-level, always carry the **Lucky** passive (+15% Work/ATK), pre-loaded with a random Active Skill. Much stronger than a same-level normal.
- **Dungeons:** time-limited caves; rooms → chests (Copper/Silver/Gold keys, better in 1.0) → guaranteed Alpha boss. Leave/re-enter to reroll spawns. Great stacked gold + loot + catch XP.
- **Ancient Technology Points (ATP):** mainly from first-time defeat/capture of a mapped Alpha (1 pt) and Tower/World Boss fights; Ancient Technical Manuals from high-tier chests also grant ATP. NOT from routine dungeon clears.
- **Pal Expedition Station:** reward scales with the condensed firepower of the assigned pals (missions still finish below 100% but pay less), so condensing feeds it directly. Named destinations: Astral Mountains Cavern (Ancient Civilization Cores) and a dark cavern (Chromite, not yet auto-farmable); also a source of high-tier spheres, Giant Pal Souls, and cavern mushrooms.
- **Area/pal level doesn't scale with the local Alpha** (leftover from multiplayer design): a Lv17 or Lv31 Alpha can guard a zone whose wild pals are single-digit level. Don't assume a zone is high-level just from its boss.

## Progression roadmap (1 → 80)

**Early (1–20):** don't skip the reworked tutorial; early stat points into Weight/Work Speed/Stamina; catch broadly for the 5/species bonus; grab Cattiva turn 1 (+50 carry per copy in party) then a Nitewing-tier flyer by hour 5–10; ore is the early bottleneck (site base 2 over a copper cluster); clear Zoe & Grizzbolt (Lv10) for tech; the village/Small Settlement vendors are undervalued, buy Wheat + Berry seeds to skip the farming bottleneck (Wheat Plantation is Lv15) and check the pal vendor for species you lack (a Gobfin for a party attack boost, a Direhowl to ride).

**Mid (20–50):** push towers 2–5 in step with level; dungeon-farm chests + ATP + XP; stand up arrow-production XP; revisit roaming merchant/raider camps once they refresh for rare pals (Jolthog, Bristla, Mau, Dumud, Arsox) and a rescue item worth ~3,000 gold each (or usable to raise a low-level pal's trust/stats); start a breeding operation once target passives are identified; condense duplicate species as you catch them instead of hoarding for a "perfect" copy (invested stats/souls transfer to a better-statted dupe, and two pals at 1 star beat one partway to 2 stars; see [base-pals.md](base-pals.md) / [breeding.md](breeding.md)).

**Late (50–68):** Sakurajima + Feybreak towers; start raids (Bellanoir → Libero); hunt the four Legendary Alphas once geared for Lv50; unlock the **Ancient Hatchery at Lv76** (makes perfect-IV breeding almost trivially reliable, the real breeding-endgame gate).

**Endgame (68–80):** Sunreach opens with tower 8 (Auri & Shaolong) + Soralite gear; any landmark you can see is travelable in 1.0 (plateau, volcano, icy peaks, islands), the lone exception being the background World Tree, which opens after all towers + a Panthalus questline (craft Echoing Flute from 4 Echobones, catch Panthalus at Deserted Islet); expect Lv75+ enemies, bring a Gas Mask for the radiation biome. **Awakening**: farm Radiant Gems in World Tree → 50 Radiant Gems + 10 World Tree Holy Water at the **Ancient Workbench** (unlocks Lv67) → element-matched Awakening Gem → +50% stat on a same-element pal (magnitude flag: a creator video instead describes a flat ~111 stat points once per pal; mechanic + materials agree, the magnitude does not, verify in-game). Endgame loop: raid rotation (Blazamut Ryu → Hartalis → Xenolord → Ultra), breed 4–5 perfect passives + high IVs via the Lv76 Ancient Hatchery (buy cake ingredients (milk, eggs, berries, wheat) and organs/electric-organs in bulk from vendors instead of farming them), chase Mutations, grind Paloxite/Soralite gear.

## Catching tips

- **Back-attack bonus:** throw from behind for a flat catch-rate bonus (up to ~+20%).
- **HP is the biggest lever:** ~20% → ~1% HP swings odds another 10–20%.
- **Sphere tier vs target level:** a tier above the target = bonus, below = penalty; carry a range.
- **Status/traps:** bear traps, burn/freeze/shock all improve odds.
- **Elemental weakness** burns HP down predictably without overkill.
- **Statue of Power:** feed Lifmunk Effigies for a permanent catch-rate boost, get it ASAP.
- **Catch-bonus stacking** is independent of per-throw odds: chain-catch trash for the 5/species bonus; use full technique (back + low HP + right sphere) only when you want THAT pal's stats/passives.

## Sources
GamesRadar / Insider Gaming (1.0 patch notes), NextTier (patch notes, leveling, tower bosses, raid bosses, new pals, best-pals tier list, Awakening), Game8 (leveling, type chart), allthings.how (catch bonus + arrow farming, 1.0 ending/final boss). Flags: Blazamut Ryu secondary type, final NPC name spelling, Astralym HP, and Moon Lord availability are single-source/conflicting, verify in-client.
