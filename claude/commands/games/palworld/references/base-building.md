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
| Sunlit Isle (east of start) | — | Early crude oil (6 nodes), easy to defend, but no nearby ore; good as a dedicated oil base. |
| Sakurajima Oil Fields | (-646, 270) | Endgame oil farm. |

Recommended split:
1. **Main/hub base:** flat, safe, near spawn/fast-travel, some ore+coal so early smelting needs no hauling (Sealed Realm plateau is the favorite).
2. **Dedicated mining base:** built on a dense ore/single-resource cluster; miners only, no plantation clutter.
3. **Oil / sulfur / quartz outpost:** on the richest single-resource cluster.
4. **Breeding base:** doesn't need resources; breeding pals skip normal hunger/sanity drain (aside from cake), so it runs flat-out with just farms, incubators, and a cake supply.

## Layout & pathing

Palworld's pathing AI is a known weak point. Design around it:
- **Build on flat ground, or flatten with foundations first.** Prevents stuck pals, falls, starvation/sanity loss from unreachable food/beds.
- **Don't cram stations.** Leave clearance around every building for approach paths; packed layouts cause idling.
- **Keep pal-interactive stations on ground level, not indoors/under roofs.** Pals often won't path to elevated/enclosed stations.
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
