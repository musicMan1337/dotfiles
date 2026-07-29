# Palworld 1.0 — Breeding

Compiled July 2026 from post-1.0 sources. 1.0 (July 2026) reworked breeding significantly vs early access / Feybreak; see the "What changed" section. Older EA-era combos are flagged.

## What changed in 1.0 (verified)

- **Mutation system (new).** Low chance an egg hatches a stronger same-species pal with boosted stat potential and access to mutation-exclusive passives (Immortality, Idiosyncratic, Babysitter, Heavily Armored, Skymarcher). Base rate ~1% per egg (community sampling ~0.7%); the **Extravagant Vegetable Cake** raises it to ~3%.
- **Four new cakes added** (was one generic cake). See below.
- **Passive inheritance reworked** (less coin-flip); the new Special Cake boosts inheritance odds. New passives added.
- **Big restriction change: several former tower-boss pals became self-only breeders.** In EA, Grizzbolt, Orserk, Lyleen, Faleris, Shadowbeak had cross-species combos (e.g. Mossanda + Rayhound → Grizzbolt). In 1.0 they're flagged `IgnoreCombi=1`, meaning **they only breed true from two of themselves** (catch a wild pair first). Any pre-1.0 cross-species recipe for these five is dead. Bellanoir (and reportedly Bastigor/Selyne, lower confidence) joined the self-only list.
- **Anubis lost its EA shortcut:** Penking + Bushi now makes **Sibelyx**, not Anubis. Anubis is still cross-breedable via other (later) pairs.
- **Astegon and Blazamut were NOT moved to self-only** — both still have normal cross-species recipes.

## Breeding mechanics

**Breeding Farm:** tech unlock at **level 19** (2 tech pts). ~100 Wood/10 Wooden Planks, 20 Stone, 50 Fiber (check tooltip). Assign one male + one female (any two breedable, opposite sex) by dropping them inside. A **Cake** must sit in the chest just outside or breeding won't start. ~4 min for the progress ring to fill, then an egg spawns.

**Cakes** (all need a Cooking Pot, unlocked lvl 17):

| Cake | Unlock | Ingredients | Effect |
|---|---|---|---|
| Cake (standard) | 17 | 5 Flour, 8 Red Berries, 7 Milk, 8 Eggs, 2 Honey | Base; one egg |
| Mushroom Cake | 30 | 5 Flour, 5 Mushroom, 3 Cavern Mushroom, 8 Eggs, 2 Honey | Better IV roll |
| Vegetable Cake | 47 | 8 Flour, 8 Tomato, 7 Lettuce, 8 Eggs, 4 Honey | **2 eggs** per cycle (stacks with Grintale egg-duplication for ~4; see Breeding-support pals) |
| Extravagant (Deluxe) Vegetable Cake | 60 | 12 Flour, 8 Cotton Candy, 10 Potato, 6 Onion, 8 Carrot | Boosts **mutation** (~3%) + stat growth |
| Special Cake | 74 | 20 Flour, 8 Caramel Cotton Candy, 15 Milk, 15 Eggs, 2 Mammorest Meat | Improves **passive inheritance** odds |

Ingredient sourcing: Flour = 3 Wheat at a Mill; Red Berries = Berry Plantation; Milk = Mozzarina ranch; Eggs = Chikipi ranch; Honey = Beegarde ranch. Ranch-pal passives do NOT affect ranch speed, so save good passives for active workers.

**Offspring species (Combi Rank):** every pal has a hidden Combi Rank (breeding power), from low double digits up to ~3,100. Breeding averages the two parents' Combi Ranks; the egg hatches the species whose own Combi Rank is closest to that average. `IgnoreCombi=1` pals (legendaries + reworked tower bosses) can't be selected as the closest-match child; they only come from an explicit Unique Combo (usually self+self, occasionally a fixed pair). They can still be used as parents feeding their rank into other pairings.

**Incubator / temperature:** eggs escalate Normal → Large → Huge (bigger = longer). Temp preference: Fire/Rock/Dragon want hot; Electric/Grass/Normal neutral; Ice/Water/Dark cold. Heat = Campfire or Heater (needs Kindling pal / electric); cool = Cooler (needs Cooling pal) or Electric Cooler. Comfort scales speed: perfect ("very comfortable") = +100%; "a little cold/hot" = +50%; overshoot into "too hot/cold" = 0%. **Base duration is governed by difficulty:** on Normal a Huge egg is up to ~2h; on Hard the same egg can be up to 72h at 0% comfort. Always max comfort.

## Breeding-support pals

Grab/condense these early to speed an operation (community-derived Partner Skill claims; verify):
- **Grintale** (boss variant ~Lv17, close to spawn): Partner Skill gives a chance a picked egg duplicates. Stacks with the Vegetable Cake (2 eggs/cycle) for up to ~4 eggs per production; biggest raw-volume lever for the brute-force stage.
- **Broncherry + Broncherry Aqua** (pair): each raises the chance a picked egg becomes an **Alpha egg**; skills stack, both fully condensed claimed ~100%. Alpha offspring have identical stats but let you farm Alpha-boss legendary blueprints via the disassembly line and butcher for Ancient Civilization Parts (see [base-building.md](base-building.md)).
- **Braloha** (Grass/Ground, ~Lv33 spawn): Partner Skill boosts breeding-farm speed (~+20-50%, condense-scaling). Its mutation-exclusive **Babysitter** passive adds a further ~+30% breeding and +30% incubation speed.
- **Wispaw** (nocturnal Dark): capture-rate boost is a Partner Skill (scales with condensation), roughly a one-tier-higher sphere when active (the video's "Wispaura" likely the same pal, not separate).

## Passive inheritance

- A pal holds **0–4 passives**, no duplicates.
- The child draws from the combined pool of both parents' passives (up to 8 candidates), rolls a subset, possibly tops up with random extras, capped at 4.
- **Key rule: keep the combined parent pool at EXACTLY 4 target passives** (2+2, 1+3, 4+0). Going over 4 desired just raises the chance an unwanted passive rolls in over a target.
- With a clean 4-target pool and no contamination, a perfect 4/4 offspring is ~10% per egg (~52% by 7 eggs, ~79% by 15). The Special Cake pushes this higher (exact numbers TBD).

**Standard 2+2 consolidation:**
1. Build clean parent A carrying exactly 2 target passives (Surgery Table implant + breed out contamination, cull extras).
2. Build clean parent B carrying the other 2 targets the same way (easier if a wild catch already has a rainbow-tier one).
3. Breed A x B (combined pool = your 4 targets); cull everything that isn't 4/4 until one lands.
- From scratch, a 4-passive stack is commonly 15–25 cycles. The **Surgery Table** (Lv38) can implant a passive for Gold to seed parents, but the best breed-only passives (Legend-tier) cannot be implanted. Artifact-tier implants and the artifact recycler unlock at **Lv74** (artifacts from expeditions and World Tree hunting; decoded implants have a small chance to upgrade to Legendary).

**Yakumo passive-transfer (community-derived, not dev-confirmed; verify):** an actively-summoned Yakumo can force its own passives onto a newly caught pal's EMPTY passive slots. The game rolls the caught pal's natural passives first, THEN checks remaining empty slots against Yakumo's passives, rolling each empty slot independently. Because it is per-slot compound probability, transferring all 4 is under ~1%; run Yakumo with only **1-2 passives** loaded for workable odds.

## Best passives to breed

Percentages corroborated across wiki.gg + guides; tier labels are community shorthand.

**Combat**

| Passive | Effect | Notes |
|---|---|---|
| Legend | ATK +20%, DEF +20%, SPD +15% | Top ("Rainbow"), breed-only (Paladius/Necromus/Frostallion/Jetragon lineage). Not implantable. |
| Demon God | ATK +30%, DEF +5% | Top, breed-only, best single-target, no downside. |
| Ferocious | ATK +20% | Also a Surgery Table implant (~50k Gold), no drawback; the practical "clean" attack passive for Stage-1 parents. |
| Musclehead | ATK +30%, Work −50% | Combat-only (ruins base work). |
| Burly Body | DEF +20% | Vendor (Battle Tickets); good vs physical. |
| Elemental attack passives (Pyromaniac, Hydromaniac, Capacitor, etc.) | +10% that element | Stack on element specialists alongside Legend/Ferocious. |

Recommended combat 4-set: **Legend + Ferocious + [matching elemental] + Swift** (Swift+Legend = +45% SPD to reposition through boss phases; cited as current meta over pure ATK-stacking).

**Movement (mounts)**

| Passive | Effect | Notes |
|---|---|---|
| Swift | SPD +30% | Top, breed-only (Fenglope, Katress carry it). |
| Runner | SPD +20% | Vendor implant. |
| Nimble | SPD +10% | Filler. |
| Legend | +SPD 15% (and combat) | Dual-purpose. |

Recommended flying-mount 4-set: **Swift + Legend + Runner + (stamina/combat 4th)** — mount speed is ~linear-additive, so stack SPD.

**Work (base)**

| Passive | Effect | Notes |
|---|---|---|
| Remarkable Craftsmanship | Work +75% | Top, breed-only. |
| Artisan | Work +50% | Vendor implant; practical clean work passive. |
| Serious | Work +20% | Default Surgery implant, no drawback. |
| Work Slave | Work +30%, ATK −30% | Pure workers only. |
| Lucky | ATK +15%, Work +15% | Top, breed-only (gold-sparkle spawns); dual-purpose. |

Recommended worker 4-set: **Remarkable Craftsmanship (or Artisan) + Serious + Lucky + Work Slave** (nearly pure work speed; useless in a fight, fine for a dedicated worker).

## Notable recipes

**1.0 caveat:** Necromus, Paladius, Frostallion, Jetragon, Grizzbolt, Orserk, Lyleen, Shadowbeak, Faleris, Bellanoir **cannot be cross-bred in 1.0** — catch a wild male+female and self-breed for passives/mutations. Any cross-species recipe for these is EA-era and dead.

| Target | 1.0 status | Recipe |
|---|---|---|
| Necromus | Self-only | catch pair → Necromus + Necromus |
| Paladius | Self-only | catch pair → Paladius + Paladius |
| Frostallion | Self-only | catch pair → Frostallion + Frostallion |
| Frostallion Noct | Fixed cross-combo (works) | **Frostallion x Helzephyr** |
| Jetragon | Self-only | catch pair → Jetragon + Jetragon |
| Blazamut | Normal cross-breeding works | multiple pairs via averaging; Blazamut **Ryu** is raid-only, not breedable |
| Lyleen | Self-only | catch pair → Lyleen + Lyleen |
| Lyleen Noct | Fixed cross-combo | **Lyleen x Menasting** |
| Grizzbolt | Self-only (was Mossanda+Rayhound) | catch pair → self |
| Orserk | Self-only (was Relaxaurus+Grizzbolt) | catch pair → self |
| Faleris | Self-only per 1.0 guides (medium confidence; PalDB ambiguous) | catch pair → self. EA's Vanwyrm+Anubis likely dead. |
| Shadowbeak | Self-only (was Astegon+Kitsun) | catch pair → self |
| Astegon | Normal cross-breeding works | candidates (verify with a 1.0 calc): Cryolinx+Helzephyr, Orserk+Helzephyr, Grizzbolt+Orserk, Cryolinx+Lyleen Noct |
| Anubis | Normal cross-breeding works | ~18–19 pairs; easiest cited **Arsox + Quivern**. EA's Penking+Bushi now makes Sibelyx. |

**Jetragon:** can be "bred" only from two captured Jetragon; no cross-species pairing makes one. Same for Necromus/Paladius/Frostallion.

**Mutation examples (community-derived, verify with a 1.0 calculator; auto-caption sourcing):**
- **Incineram + Fuack -> Yakumo** (early route to Yakumo; Lv10 Incineram spawns below the Windswept Island watchtower, Fuack common in starting zones).
- **Cattiva (Lucky) + Lamball (Ferocious) -> mutated offspring** that inherited both Lucky + Ferocious plus 2 new passives (Heavily Armored / King of Waves / Babysitter cited), IVs far above the low-IV parents, 2-star rating. A mutation-farming example, not a fixed recipe.
- **Wixen + Turtecul -> mutated Warsect** (claimed). CONFLICT: paldb research found no breeding link; the real Turtacle variant path differs. Treat as an unverified mutation anecdote.

## IVs, condensation, souls

**IVs:** each pal rolls HP/Attack/Defense 0–100 (up to ~+30% total). On breeding, each stat independently has ~30% to inherit from a parent, rest is a fresh roll; at least one stat always inherits from a parent (can't pick which). Both parents need top IVs to reliably push a max-IV child. View IVs with the **Ability Glasses** accessory (Lv34) or a calculator; **IV Fruits** lock a parent's stat.

**Condensation (Pal Essence Condenser):** 0 → 4 stars, +5% HP/ATK/DEF per star (+20% at 4★). 4★ also raises every Work Suitability by 1 and Partner Skill level by 1 (to lvl 5). Dupe cost: 4 → 1★, 16 → 2★, 32 → 3★, 64 → 4★ (116 total to max). Condensation essence from dog-coin/ruined-church vendors grants an instant star. **Conflict (unresolved, 1.0 is days old):** some 1.0 sources say condensation was reworked to a **max of 48 pals** total, with each star adding **+1 to the pal's highest Work Suitability** (4th star = +1 to all). The stat-% and work-suitability effects may coexist; the 48-vs-116 pal count is disputed. Verify in-game. See [base-pals.md](base-pals.md).

**Pal Souls (Statue of Power):** permanently +3% per rank up to rank 20 (+60% max) on ONE of HP/ATK/DEF/Work Speed. Souls (Small → Medium → Large → Giant) drop from chests, field pals, dungeon/tower bosses.

**Endgame pal recipe:** (1) breed the ideal 4-passive set, (2) breed/select high IVs with IV-locked parents, (3) condense to 4★, (4) pour souls into the key stat (usually ATK or Work Speed), (5) **Awaken** once at the World Tree. Do breeding (passives+IVs) before sinking condensation/souls, so you don't invest in a pal you later cull.

**Awakening (new 1.0 endgame):** requires **Radiant Gems + Holy Tree Water** from the World Tree map (gem element matches the enemy you defeat to get it); craft the gem at the **Ancient Crafting Bench**; applied **once per pal**. CONFLICT (magnitude): combat-progression.md's facts describe Awakening as **+50% stat**; the video says a cosmetic aura + roughly **111 flat stat points**. Verify actual scaling in-game; see [combat-progression.md](combat-progression.md).

## Efficient workflow

1. **Dedicated cake base** (~20 pals): Wheat→Mill (Flour), Berry Plantation, Mozzarina (Milk), Chikipi (Eggs), Beegarde (Honey). Keep lines running so cake never dries up. Good planting/watering/hauling picks: Lyleen (plant), Jormuntide/Ignis (water), Verdash (haul).
2. **Dedicated breeding base/paddock:** flat, feed chest outside, stocked with the right cake (standard for volume, Vegetable for 2x eggs, Extravagant for mutations, Special for a target 4-passive combo).
3. Run parents → collect egg (~4 min) → move to incubator.
4. **Max incubator comfort** matched to the egg's temp preference; stack heaters/coolers for +100%. Biggest lever on hatch time.
5. **Cull aggressively;** feed non-keepers into the Condenser.
6. Repeat with progressively cleaner parents through the 2+2 chain.
7. Difficulty setting hugely affects hatch time (Normal ~2h vs Hard ~72h for a Huge egg).

**Cake sequencing (by stage, not a linear upgrade):**
1. **Vegetable Cake** (+ Grintale) for raw volume, brute-forcing passive merges; ignore IVs/mutations.
2. **Special Cake** (Lv74, pairs with the Lv74 ancient breeding farm) to lock in good passives and flush bad ones; claimed ~near-100% inheritance when the combined parent pool is EXACTLY 4 desired passives (matches the "keep the pool at 4" rule; exact rate unverified).
3. **Extravagant Vegetable Cake** last, for the final IV + mutation push (perfect IVs, 2-star, rainbow passives).
4. **Ancient Hatchery** (Lv76) only at the very end: eggs go straight to the hatchery without manual pickup, so egg-doubling Partner Skills like Grintale's do NOT apply. Use it for rare-skill inheritance-rate boosting, not volume.

## Sources
Boostmatch (1.0 breeding), Game8 (cake, chain breeding, high-stat, condenser, souls, per-pal pages), Nodecraft (new cakes), PalDB (Mutation, IgnoreCombi flags, per-pal), PalMods (mutation), KeenGamer (1.0 combos), EIP/Prima (incubator temp), palworld.gg / GamesOMG / GameWith (breeding calculators), wiki.gg (passives, condensation), PinDrop (Anubis/Blazamut), Mobalytics (souls, best combos), Switchblade (passives), MMOPIXEL / Steam guide (IVs). Confidence: self-only flags high (PalDB + guides); Faleris medium; best Astegon pair + exact Special Cake numbers open (use a live 1.0 calculator).
