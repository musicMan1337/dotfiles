# Palworld 1.0 — Base Building

Current as of the 1.0 full release. Base level cap, pal limits, and the raid system were reworked from early access / Feybreak. Uncertainty is flagged inline.

## Fundamentals

- **Bases per guild:** default max **4**, raisable to **10** via World Settings.
- **Working pals per base:** default max **15**, raisable to **50** via World Settings.
- **Base level cap:** **35** in 1.0. (Older wiki pages showing 25/30 are stale.)
- **Base level is shared** across all your bases: leveling up applies to every base at once, so a brand-new outpost starts with full worker capacity already unlocked.
- **Raising base level:** interact with the **Palbox**, complete listed **Base Missions** (build structure X, deploy N pals, etc.), then apply **Base Upgrades**. Early levels add worker slots (up to the ~15 default, reached mid-teens player level); later levels unlock more base slots and gate advanced structures (assembly lines, electric furnaces).
- **Uncertain:** exact level thresholds to unlock the 2nd/3rd/4th base vary by source (reported 10/15/25 or 14/24). Shape is consistent; treat the fine-grained numbers as approximate.
- **Palbox:** the base anchor. Defines the base location and its circular boundary (faint blue disc; yellow warning line near the edge). Anything built outside the circle does not count as "in base" (pals ignore it, it decays). Also stores captured pals: 32 boxes x 30 slots = **960 storage slots**, separate from working-pal limits.
- **Base footprint:** roughly 9 foundation tiles radius (safely ~8, since circle vs square grid); vertical limit ~16 tiles. A structure counts as in-base if ~half its footprint overlaps the circle, so push bulky buildings outward to reclaim interior space.
- **Moving a base:** the Palbox cannot be picked up; you must dismantle it. Dismantling refunds base-exclusive structures (100% materials dropped on the ground); general structures (chests, houses, walls) remain but decay outside a new Palbox radius; stored pals are always safe. Because extra base slots are cheap, most guides say build a new base rather than relocate.
- **Building on water:** possible in 1.0 via the **Foundation Kit** (Ancient Tech unlock at **Lv66**, late).

## World Settings

Free multipliers worth tuning:
- **Structure Deterioration OFF:** builds can sprawl beyond the Palbox circle without decay (pals still only WORK inside the circle).
- **Halve the damage-to-structure multiplier** to blunt raids.
- **Grazing/ranch production-rate multiplier up to 3x.**
- **Pal appearance rate ~1.9x:** many extra spawns without the duplicate-boss spawns that begin at 2.0x (community tip, unverified).

## Placement strategy

What to look for:
- **Flat ground** is the single biggest factor (pathing). Uneven terrain = stuck pals, falls, unreachable stations.
- **Resource proximity:** ore / coal / sulfur / quartz plus stone/wood inside or adjacent to the circle so miners don't path far.
- **Water access** for hydration and for water pals to fight fires.
- **Raid safety:** some elevated/plateau spots are effectively unraidable because ground-raid AI can't path up (raiders spawn below and despawn).

Named locations (coords approximate):

| Location | Approx coords | Why |
|---|---|---|
| Plateau near Sealed Realm of the Guardian | ~(190, -40) | Community "best all-round" / main base: ~8 ore nodes + nearby coal in one radius, and raid-safe elevation. |
| Verdant Brook ore field | (189, -38) | Abundant ore + enough coal for furnaces; mining/smelting outpost. |
| Twilight Dunes (central desert, Anubis spawn) | (desert) | Best early coal. |
| Volcano peak behind Tower of the Brothers (Mount Obsidian W) | ~(-594, -525) | Best sulfur; fast travel nearby. |
| Astral Mountain / Garden Beneath | ~(-210, 250) | Best pure quartz (9+ nodes); also raid-safe elevation. |
| Sunlit Isle (east of start, near spawn) | near spawn | Early crude oil (a creator guide counts two oil wells + a pond; other sources say 6 nodes), easy to defend, room for a second base, reachable very early; no nearby ore, good as a dedicated oil base. |
| Moonflower Tower area (NW; cherry blossoms, triple waterfall) | NW (approx) | Two oil nodes + sulfur nodes + flat terrain; cliff-vulnerable from one side. Cited as one of the best overall, reachable later. |
| Isles of Murmur | (approx) | Natural water/wall defense, single raid opening; large enough for two bases side by side. |
| Sakurajima Oil Fields | (-646, 270) | Endgame oil farm. |

Multi-node clusters cited (coords not given): 9 sulfur + 1 ore + 6 pure quartz in one radius; 9 coal near the Alpha Suzaku desert; 3 Hexalite Quartz + 1 crude-oil node (lets you use the cheap extractor); two Sky-Island spots with 6 Sulfurite nodes each.

Recommended split:
1. **Main/hub base:** flat, safe, near spawn/fast-travel, some ore+coal so early smelting needs no hauling (Sealed Realm plateau is the favorite).
2. **Dedicated mining base:** built on a dense ore/single-resource cluster; miners only, no plantation clutter.
3. **Oil / sulfur / quartz outpost:** on the richest single-resource cluster.
4. **Breeding base:** doesn't need resources; breeding pals skip normal hunger/sanity drain (aside from cake), so it runs flat-out with just farms, incubators, and a cake supply.
5. **Byproduct / drop-farm base:** organs, fluids, leather, bones from ranch drop-pals (see [base-pals.md](base-pals.md)). Oil can share with a mining or crop base, but not with breeding.

## Layout & pathing

Palworld's pathing AI is a known weak point. Design around it:
- **Build on flat ground, or flatten with foundations first.** Prevents stuck pals, falls, starvation/sanity loss from unreachable food/beds.
- **Don't cram stations.** Leave clearance around every building for approach paths; packed layouts cause idling.
- **Keep pal-interactive stations on ground level, not indoors/under roofs.** Pals often won't path to elevated/enclosed stations.
- **Leave vertical clearance for large pals:** at least 2 walls high (3 for the biggest); don't place a roof too close above the Palbox.
- **Keep walls short (2–5 tiles) near work areas.** Tall walls near stations increase clipping/stuck chance.
- **Station worker caps matter:** e.g. the Sphere Assembly Line maxes at 3 workers; a 4th produces nothing. Check each station's cap before overstaffing.
- **Centralize the Feed Box** (or run multiple in a large base). A distant/unreachable feed box is the #1 cause of "randomly idle" pals.
- **Assign a Transport pal** once you have 6+ stations; production stalls if nothing hauls output to storage.
- **Place the Palbox deep in the interior**, not near the boundary edge. Edge placement hands raiders a straight line to your base's control point (most-cited layout mistake).
- **Switch off wood ASAP.** Wood burns and fire raiders are common; stone/metal walls reduce most raid hits to ~1 damage (raiders melee walls rather than shoot them).

Zone template (commonly recommended):
- Core: crafting/production clustered within ~5 tiles, Palbox deep inside.
- Middle: furnaces, stone pit, logging, feed box centrally placed.
- Perimeter: walls, turrets, pal beds (doubles as defensive ring).

Community/exploit-adjacent tricks (unverified for 1.0, may be patched): pillow-spacer plantation stacking for double yield per footprint; black (#000000) glass for invisible perimeter walls; fully sealing the perimeter to stop raids entirely (also blocks merchants and forfeits raid loot).

## Build order (roughly by mission/level)

1. **Palbox** (~lvl 2) — place first, defines the base.
2. **Campfire** — light, basic cooking, warmth.
3. **Primitive Workbench** — pickaxe, club, torch.
4. Player bed + a few **Straw Pal Beds**.
5. **Feed Box** — before deploying more than 1–2 workers; keep stocked or sanity tanks.
6. **Berry Plantation** (~lvl 5) — first renewable food; needs Planting/Watering/Gathering pals.
7. **Stone Pit** + **Logging Site** — stabilize raw materials at 3–4 workers.
8. **Pal Gear Workbench / Repair Bench** — gear crafting.
9. **Furnace / Crusher** — only once you have a **Kindling** pal (Foxparks early). No Kindling = no smelting, no proper cooking, stalled production.
10. **High Quality Workbench**, **Medieval Medicine Workbench**.
11. **Wheat Plantation** (~lvl 15) + **Mill** (~lvl 15) — flour, enables bread/cake tier.
12. **Hot Spring** (tech ~9), later **High Quality Hot Spring** (tech ~31) — SAN recovery.
13. **Ranch** — passive drops (eggs/wool/milk) from ranch pals.
14. **Tomato / Lettuce Plantation** (~tech 38, later than berry/wheat).
15. Refined-tier: Refined Metal Chest, Refrigerator (slower spoilage), Large Pal Beds.
16. **Power Generator** (tech 26; 50 Ingot + 20 Electric Organ) — needs a **Generating Electricity** pal (Sparkit early; Orserk/Azurmane top). Self-throttles: stops at 100% charge, resumes at 80%. Electricity Pylon speeds recharge.
17. **Breeding Farm** (tech ~19) — store cake in the farm's adjacent box (no spoilage).
18. **Large-Scale Electric Egg Incubator** (~lvl 24) — mass hatching.
19. **Assembly Lines** (mid-late) — spheres, ammo; mind per-station worker caps.
20. **Mounted defenses:** Mounted Crossbow (~lvl 26), Mounted Missile Launcher (~lvl 50); need a Handiwork pal to man them, consume ammo.

Storage: use Chest Settings to filter categories into dedicated chests (berries chest by the plantation, ore chest by the mine); keep chests near their production point to cut pal travel.

Other structures worth building:
- **Pal Monitoring Stand** (~Lv14-15): lock fixed per-pal work assignments (keep a ranch pal ranching only; allow/disallow breeding/gathering/transporting) instead of manually shuffling pals.
- **Viewing Cage** (Lv15): +40 pal display/storage slots separate from the Palbox; pairs with the **Global Pal Box** (copy a pal between saves).
- **Pal Labor Research Lab** (Lv19): researches permanent base work/facility buffs (steep first-unlock cost; plan for it).
- **Easy Bulk Storage** button (bottom-right of inventory, available Lv1): auto-deposits carried items into matching base storage from anywhere in the base.
- **Pal-box storage expansion** item: a second 320-slot pal store (vs the 32-box standard); stored pals can't run expeditions but swap freely.

## Resource automation

Once built, these stations auto-produce raw materials in-base (no map nodes needed):

| Station | Unlock Lv | Produces |
|---|---|---|
| Logging Site / Stone Pit | 7 | Wood / Stone |
| Ore Mining Site | 24 | Ore (Ore Mining Site 2 at Lv39, straight upgrade) |
| Coal Quarry | 37 | Coal |
| Logging Site 2 | 43 | Hardwood (NEW 1.0 material; distinct station, not a replacement) |
| Sulfur Quarry | 46 | Sulfur |
| Crude Oil Extractor | 50 | Crude Oil (needs an oil node under it) |
| High-Pressure Crude Oil Extractor | 51 | Crude Oil (no node required, placeable anywhere, but heavy electricity draw) |
| Quartz Quarry | 52 | Pure Quartz |
| Hexalite Quartz Mine | 62 | Hexalite Quartz |
| Sulfurite Quarry | 72 | Sulfurite (Sky Island material) |

The **Ore Mining Site is gated to Lv24** (behind defeating Lily & Lyleen), so early bases must sit on a wild ore cluster; the auto-site does not save you early.

**Crusher conversions (passive material loops):** Stone -> Palladium at 5:1; the **Refrigerated Crusher** converts Ore -> Palladium at 2:1 (better); Wood -> Fiber at 2:1 (still the only fiber automation late-game); Meteorite Fragments -> Palladium at a good rate. Meteorite trick: set the World Setting meteor/supply-drop rate to 1 so a meteor spawns ~every minute, farmable as Palladium feedstock.

## Endgame resource farming

Manual methods (no auto-station) for late materials:
- **Chromite:** any cave on **Feybreak Island**; **Smokie** (caption "Smokey") Partner Skill reveals Chromite; a specific cave with the **Silvegis** (caption "Silverghes") Alpha yields a few hundred per trip.
- **Corium Ore:** ride a swimming mount around the Feybreak coast, use a **Powerful Fishing Magnet** per salvage spot; **Jellroy** (caption "Gelaroy") Partner Skill boosts salvage yield.
- **Sulfurite / Hexalite:** Sky Island nodes and Feybreak dungeons; break the glowing weak-spot on Sulfurite nodes with the multi-cutter; a ridden **Mammorest** boosts manual mining.
- **Ancient Civilization Parts:** any pal with a mapped Alpha drops them; a **bred Alpha** of the same species shares the boss drop pool, so butcher bred/found Alpha eggs. Guarantee Alpha offspring with condensed **Broncherry + Broncherry Aqua**; raise egg count with Vegetable Cake + **Grintale**; breed in **Lavish Hospitality (+100%)** or **Service-Minded (+50%)** to boost butcher-drop quantity.

## Sanity (SAN)

The biggest hidden lever on production. A base of low-SAN pals crawls regardless of layout.
- **Drains:** overwork (Hard/Super Hard Working via the Monitoring Stand), hunger, unreachable bed/food, combat/raids, repetitive tasking.
- **Thresholds (reported):** below ~50 SAN work speed drops; below ~20 pals refuse to work and may pick fights at the Palbox.
- **Fixes:**
  - **A bed per deployed worker** (not shared). Missing beds is a top mistake.
  - **Keep the Feed Box stocked with cooked food**, not just raw berries; higher-tier meals restore more SAN.
  - **Hot Spring** / **High Quality Hot Spring**: a hot spring + decent bed can restore 0→100 SAN in ~20 min.
  - **Cake** is the strongest single SAN food (but slow to produce). Cooked dishes (Fried Chikipi, Grilled Lamball) give a work-speed buff plus SAN recovery, often better than pure work-speed food when running Hard Working modes (which drain SAN faster).
  - Rotate/add workers instead of running one pal at max intensity nonstop.

## Raids & defense (1.0 rework)

- **Wave-based:** raids arrive in successive waves; clearing all waves grants rewards.
- **Scaling:** raid level scales to your working pals' level; a stronger workforce invites tougher raids.
- **Faction-flavored** by surrounding territory (e.g. Free Pal Alliance near Crescent Moon Shore, Eternal Pyre near Mount Obsidian).
- **The Negotiator:** a new NPC that warns ~5 min before a raid and offers to cancel it for gold (pay-to-skip).
- **Walls are set-and-forget** (the passive wall layer no longer consumes ammo). Mounted turrets still consume ammo and need a Handiwork pal + Transport resupply.
- **Stone walls are strong:** most raid hits reduced to ~1 damage; enemies melee obstacles rather than shoot them.
- **Best design: a funnel.** Channel raiders through one chokepoint covered by turrets + combat pals, rather than a long perimeter with weak points. Ring the Palbox with 2+ stone-wall layers.
- Elevated/unraidable spots (Section: Placement) let you opt out of raids for that base (tradeoff: no Negotiator, no raid rewards there).
- Fire raiders can burn wood; keep a water pal or go stone/metal.

## Efficiency

- **Quality over headcount.** Pal level + work-suitability level + passives beat raw worker count. One high-level specialist out-produces two low generalists. Don't overstaff past station caps.
- **Prioritize the Artisan passive (+50% work speed)** on core producers; avoid Slacker (-30%) and Musclehead (-50%) on workers.
- **Stack work-speed:** Artisan + Statue of Power (spend Pal Souls) + Monitoring Stand Hard Working + food buffs (up to +50%) can roughly double output. But Hard Working drains SAN fast, so pair with strong SAN recovery.
- **Condense spares** to star-rank core workers (raises work-suitability level) instead of hoarding duplicates.
- Prefer **single-task workers** at fixed stations to avoid time lost task-switching.
- **Automate food early** (Berry Plantation + Feed Box before scaling workers; add Wheat + Mill for cooked meals).
- **Cake pipeline** (~lvl 17, needs Cooking Pot): 5 Flour + 8 Red Berries + 7 Milk + 8 Egg + 2 Honey. Honey is the bottleneck (no vendor; breed/rank Beegarde/Beakon-line). Milk can be bought from a merchant; eggs are easy via mass Chikipi-line capture. Store cakes in the Breeding Farm box.
- **Divide labor across bases** (hub + mining + oil/sulfur/quartz + breeding) rather than one do-everything base.
- **Electricity:** central Power Generator, Electric Pylon for recharge; remember it self-throttles at 100%/80%, so the electric pal isn't "always on."
- **Gold farming:** best passive gold is a **Dumud Gild** ranch (oil + gold); best active gold is selling specific pals. CONFLICT: a video claims a Dumud Gild sells for ~55,000 gold at ~Lv50, but paldb lists ~19,900, so verify the sell price in-game. ("Turdical Terra", a claimed ~40k-gold sale pal, could not be confirmed to exist.)

## Common mistakes

1. Building on uneven ground (pathing failures).
2. Palbox near the base edge (raiders reach the control point).
3. Forgetting a bed per new worker slot.
4. Cramming stations too close (idling/stuck pals).
5. Mission structures built just outside the blue circle (don't count / unused).
6. Ignoring Transport suitability (production stalls with nothing hauling).
7. Keeping your best workers in the combat party instead of at base.
8. Chasing rare captures before the production chain is solid.
9. Sticking with wood too long (fire raids).
10. Scaling worker count/level faster than defenses.
11. Ignoring extra base slots (one "optimized" base under-earns vs 2–4 specialized ones).
12. Feed Box inaccessible or under-stocked (hidden cause of idling).

## Sources
Game8 (base building, base locations, base level rewards, cake, electricity pals), Palworld Wiki (Base, Palbox, Sanity), PC Gamer (best 1.0 base locations), NextTier, NeonLightsMedia (1.0 base upgrades, Negotiator), xGamingServer (1.0 raids, sanity), 4netplayers, palworldbreedingcalc, Switchblade Gaming. Fine-grained base-unlock level thresholds vary by source; cap 35 / 15 workers / 4 bases (adjustable to 50/10) is corroborated across multiple 1.0-era sources.
