# Palworld 1.0 - Synergy Build Loadouts (Combat & Handiwork)

Palworld 1.0 (released July 10, 2026). Compiled days post-launch, so single-sourced numbers are flagged. Sits alongside base-pals.md, breeding.md, combat-progression.md, mounts.md, gear-accessories.md.

## How party synergy works

Three separate systems that all read like "synergy," do not conflate:
- **Partner Skills** (per-pal, party-of-5 scope): 1.0 reworked these so many now apply from just being in your active party, including **benched** (not summoned/ridden). Elemental attack/defense buffs, carry weight, capture rate, EXP, heals, mount infusions.
- **Passive Skills that buff the player** (bred/implanted traits, not partner skills): Vanguard (player ATK +10%), Stronghold Strategist (player DEF +10%), Noble (sell price). Also apply from riding in the party, and **each copy on a different pal adds again** (5 pals with Vanguard = +50% player attack). Basis of the "Gobfin bench" builds.
- **Work Auras** (base-only, combat-irrelevant): a stationed pal gives +1 to one work suitability for every OTHER pal at that base. See section 3.

### Party-wide buff carriers (combat/utility)

| Pal | Effect | Stacks w/ duplicates? |
|---|---|---|
| Cattiva | Player carry +50 | No |
| Lunaris | Player carry +80 | No |
| Broncherry / Aqua | Player carry +100 | No |
| Wumpo / Botan | Player carry +120 (also Transporting aura) | No |
| Beegarde | +12% attack per copy (also buffs Elizabee) | **Yes** |
| Gobfin / Gobfin Ignis | Player attack up | **Yes** (basis of 4-5 Gobfin high-DPS bench) |
| Vanguard (passive) | Player ATK +10% | Yes, one per pal (max 5) |
| Stronghold Strategist (passive) | Player DEF +10% | Yes, one per pal |
| Kelpsea / Kelpsea Ignis / Foxcicle / Hoocrates / Cremis / Bristla | Element attack up for that element's pals | Unconfirmed size |
| Gloopie Primo / Sibelyx Primo / Kikit / Nitemary Botan / Wistella | Element defense up for that element's pals | Unconfirmed size |
| Wispaw / Muffly / Souffline | Capture rate up (back-attack / vs Frozen / vs Ivy-Covered) | Unconfirmed |
| Omascul | Party-wide bonus EXP | Unconfirmed |

Correction: **Grintale** buffs Neutral attack while mounted, it is NOT a carry-weight pal. Use Cattiva/Lunaris/Broncherry/Wumpo for carry.

### Stacking rules (PalMods 1.0 rework, cross-checked Game8)

1. **Same-species duplicates do NOT stack by default** (5x Cattiva is pointless).
2. **~25 pals are explicit exceptions that DO stack per copy.** Attack: Gobfin(+Ignis), Sweepa, Elizabee, Leafan, Moldron, Celesdir, Eidrolon(+Ignis), Shaolong, Beegarde. Movement speed: Kingpaca(+Cryst), Beakon(+Cryst), Ghangler(+Ignis), Rayhound, Suzaku(+Aqua), Starryon Primo. Work speed (base): Jelliette, Jellroy. Other: Lullu (crop growth), Prunelia (harvest yield), Shroomer Noct (SAN drain). These are the ones worth running in multiples.
3. **Different-species buffs always stack with each other**, even same stat category (Gloopie Primo Water-def + Kelpsea Water-atk stack). Layer 5 different single-copy carriers = 5 effects at once.
4. **Work auras** cap at +1 per work type, one carrier is enough, never buff the carrier, can't push past Suitability 10.
5. Flagged: exact % of most single-copy elemental buffs is "increased" but unquantified in current guides.

## Combat team comps

### General all-purpose boss team
Type coverage + mount + buff bench. Swap the 5th slot per matchup.

| Pal | Role | Synergy | Passives |
|---|---|---|---|
| Jetragon | Mount + Dragon DPS | Highest attack, fastest flight; Dragon answer to Dark bosses | Legend + Ferocious + Draconic + Swift |
| Frostallion (Noct) | Ice counter | Ice beats Dragon 1.5x; premier Ice-infuse mount alt | Legend + Ferocious + Ice elemental + Swift |
| Jormuntide Ignis | Fire/Dragon sustained DPS | Best non-legendary attacker; anchors the Fire team too | Legend + Ferocious + Pyromaniac + Swift |
| Warsect or Anubis | Ground counter | Ground beats Electric 1.5x; Anubis doubles as base worker benched | Legend + Ferocious + elemental + Swift |
| Gobfin (or Hoocrates) | Bench buff | Angry Shark stacks player ATK per copy; run 2-4; Hoocrates if active fighter is Dark | Vanguard + Stronghold Strategist |

### Element nuke: Fire team
Shows how mount infusion + matching attacker + elemental accessory stack.

| Piece | Pal/item | Contributes |
|---|---|---|
| Heavy hitter | Blazamut Ryu | Elite Fire attacker/mount ("Dragon Kaiser" weak-point boost ridden) |
| Alt mount | Ragnahawk | Ridden, converts player weapon hits to Fire; best flight stamina |
| Burn applicator | Renjishi | Player attacks inflict Burn on hit |
| Burn payoff | Jormuntide Ignis | Team damage up vs Burned enemies; also best Kindling worker off-duty |
| Burn detonator | Flaracle | Fire explosions when you hit a Burned enemy (AoE) |
| Accessory | Flame Emperor's Baton | Raises active Fire pal's attack + its Fire damage |

Core = Renjishi (Burn) + Jormuntide Ignis (bonus vs Burned) + Flaracle (detonate), the standout 1.0 Fire combo. Flag: one Steam test found no player-damage change pairing Ragnahawk's mount-infusion with the Baton, so the Baton likely buffs your active summoned Fire pal, not player mount-converted hits. Same recipe generalizes to other elements (matching infuse mount + element attackers + element Emperor's Baton/ring).

### Raid team (Bellanoir / Xenolord / Hartalis)

| Role | Pal | Logic |
|---|---|---|
| Tank | Astegon | Resists Dark/Dragon; high DEF; also best mining mount off-duty |
| DPS 1 | Jormuntide Ignis or Orserk | Element-matched to the boss counter |
| DPS 2 / mobility | Frostallion (Noct) or Chillet mount | Infuse mount to reposition; Chillet + Rocket Launcher burst |
| Bench (4 slots) | 4x Gobfin | Angry Shark stacks; turns the PLAYER into main DPS (cited highest-DPS raid approach) |
| Sustain | Lyleen (~1-2k HP heal) or Felbat/Lovander (lifesteal) | Burst top-off vs always-on sustain |

Per boss: **Bellanoir** (Dark) Astegon tank + Orserk/Jormuntide DPS + Chillet-Dragon-infuse + Rocket Launcher. **Xenolord** (Dark/Dragon, summons adds) Frostallion + Astegon split resists; P1 Azurobe Electric infuse, P2 Anubis + 4-Gobfin to clear adds. **Hartalis** (Water/Grass -> Neutral) P1 counter Orserk (Electric) + Frostallion Noct Dark infuse; P2 barriers break to Electric/Fire/Dark, keep a Dark hitter (Bellanoir Libero/Selyne) ready. Strong single-lineage claim: a squad built for Xenolord (hardest standard fight) clears Blazamut Ryu, Bellanoir Libero, and Ultra variants without retooling.

### Capture / farming team
Two goals: bulk catch-bonus XP (don't care about the individual) vs quality capture (rare/Alpha/Lucky with good IVs).

| Pal | Role | Synergy |
|---|---|---|
| Daedream | Passive whittler | Necklace-summoned, fires Dark bolts without you attacking; dominant early catch tool |
| Hoocrates | Attack buff | Dark Knowledge buffs Daedream's attack; pure support |
| Status inducer (Foxcicle/Chillet Freeze, Univolt/Relaxaurus Shock) | HP-down + catch-rate | Status both drops HP and raises capture odds |
| Muffly (Freeze route) or Wispaw (back-attack route) | Capture-rate carrier | Stacks with the status/back-attack it matches |
| Fast mount (Direhowl -> Fenglope/Ragnahawk) | Positioning | Get behind for the Back Bonus (up to ~+20%) |

Player gear: **Ring of Mercy** (can't drop target below 1 HP), but it only protects the player's MOUNT attacks, not summoned-pal or DoT (Burn/Poison) damage, so pull those out when the target is low. Sphere tier above target level = bonus (below = penalty); save Legendary/Ultra for the 1-HP finishing throw. For pure XP grinding (5/species), skip finesse: fast mount + a one-shot whittler, chain low-value species.

### Passives per combat role

| Purpose | 4-passive set | Why |
|---|---|---|
| General attacker | Legend + Ferocious + matching elemental + Swift | Legend+Swift = +45% SPD to reposition through phases |
| Raid tank | Legend + Burly Body + Ferocious + elemental | Burly Body flat DEF% for physical mechanics |
| Glass cannon | Musclehead + Legend + Ferocious + elemental | Musclehead Work -50% irrelevant on a pure fighter |
| Flying mount | Swift + Legend + Runner + stamina/combat | Mount speed ~linear-additive, stack SPD |
| Bench buff carrier | Vanguard + Stronghold Strategist + filler | Its own combat stats barely matter, it's a stat battery |

## Handiwork / production synergy stacks

Every stack = (1) a Lv8+ specialist, (2) that job's +1 work-aura carrier, (3) a job-specific partner-skill multiplier if one exists, (4) Artisan-tier passives on the workers. Aura carriers: Kindling=Katress Ignis, Watering=Amione, Planting=Petallia, Electricity=Puffolt, Handiwork=Ribbunya, Medicine=Mycora, Gathering=Clovee, Lumbering=Eikthyrdeer Terra, Mining=Tetroise, Cooling=Smokie Cryst, Transporting=Wumpo, Farming=Cinnamoth. One carrier per job, never buffs itself, no stacking, no aura past Suitability 10. No Oil Extraction aura yet.

### Handiwork base (the standout 1.0 combo)

| Pal | Role | Synergy | Passives |
|---|---|---|---|
| Anubis | Primary | Hdwk 6/Min 6/Trn 4, best early all-rounder | Artisan + Serious + Lucky + Work Slave |
| Sekhmet | Work-speed multiplier | Desert Empress: +20-40% Anubis work speed from presence; +30-60% more if Sekhmet also works a Handiwork bench (takes the bigger, not both). **Alpha Sekhmet ~+400%** vs normal +60%. One of 1.0's best combos | Artisan + Serious |
| Ribbunya | Handiwork aura | +1 Hdwk to all other pals (stacks with Sekhmet, different effect) | aura only |
| Solenne | Endgame secondary | Hdwk 8-10 @4★, Dark = works nights | Artisan + Serious + Nocturnal |
| Artisan filler | Overflow | Extra bench hands | Artisan + Work Slave |

### Mining base

| Pal | Role | Synergy | Passives |
|---|---|---|---|
| Aegidron | Primary | Mining 8, best hands-off | Artisan + Serious + Lucky |
| Astegon | Night shift | Min 7 (10 @3★), nocturnal | Artisan + Serious |
| Tetroise | Mining aura | +1 Min to all others | aura only |
| Knocklem / Ignis | Haul-out | Min 7 AND Trn 7, prevents ore piling up unclaimed | Artisan + Serious |

Correction: Digtoise is NOT a good stationed miner (Min 4). Its value is the Drill Crusher ride skill (field/active mining). Don't spend a base slot on it.

### Kindling / smelting base
Jormuntide Ignis (Kdl 7->10 @3★; cuts cake cook time to seconds near a pot) + Renjishi (Kdl 8, also the Fire nuke anchor) + Katress Ignis (aura) + Blazamut/Ryu (Kdl 6/Min 7 hybrid) + Dupin/Flaracle overflow. Passives: Artisan + Serious.

### Lumber base
Celesdir Noct (Lmb 8->10 @3★, nocturnal) + Hartalis (Lmb 7 + Gth 7) + Eikthyrdeer Terra (aura) + Bastigor (Lmb 6 bridge). Pair Celesdir Noct with a Nocturnal day-coverer or a second daytime logger. Passives: Artisan + Serious.

### Farming / plantation + gathering base
Dandilord (Plt 8) + Lyleen (Plt 7/Gth 6/Hdwk 5) + Petallia (Planting aura) + Clovee (Gathering aura) + Starryon Primo/Hartalis (Gth 7). **Lullu (crop growth) and Prunelia (harvest yield) stack per copy**, so run 2+ of either here uniquely. Passives: Artisan + Serious. Note (single source): plantations can be stacked vertically via a cushion spacer (up to 4 tiers, ~tech Lv55) for density with no new pathing.

### Electricity setup
Orserk (Elec 8->10 @4★, only real choice) + Puffolt (aura, for placeholders Grizzbolt/Relaxaurus Lux before Orserk). Pin Orserk to the Generator, it has side suitabilities and wanders off-task otherwise. Passives: Artisan + Serious.

### Breeding cake base (~10-15 pals, feeds a separate Breeding Farm)
2x Mozzarina (Milk) + 2x Chikipi (Eggs) + 2x Beegarde (Honey, no spoil, also SAN food) + Wheat plot -> Mill (Flour, needs a planter + waterer) + Red Berry Plantation (Clovee aura if colocated) + Jormuntide Ignis at the Cooking Pot (Kindling cuts cook time to seconds) + Smokie Cryst on a Refrigerator (Milk/Eggs spoil, cool them). Classic failure: letting cake idle stalls the whole breeding chain.

### How it compounds (the math)
Game8 formula: `Time = (Workload x 100) / (Work Speed x Buffs x Research)`. Buff categories are **multiplicative**: worked example Food +50% x Traits +100% x Souls +30% x Building +20% = 4.68x base. Layer order to max a job: (1) Lv8+ specialist, (2) work-aura carrier, (3) Sekhmet-style partner multiplier if it exists (only Handiwork/Anubis confirmed), (4) Artisan or breed-only Remarkable Craftsmanship on the specialist, (5) max the Statue of Power Work Speed rank with Pal Souls (+30% @ rank 20), (6) stock a work-speed food (Mozzarina Hamburger / Dumud Chowder +50%; Fried Chikipi / Grilled Lamball +30% + SAN), (7) tech research bonuses on top.

## If you build one of each (priority order)

1. **Handiwork base** (Sekhmet + Anubis + Ribbunya + Artisan fillers). Cheapest big stack; Handiwork gates everything.
2. **Breeding cake base** (ranch + wheat/berry + Jormuntide Ignis cook + Smokie Cryst fridge). Unlocks the passive-breeding endgame.
3. **General boss team** (Jetragon + Frostallion + Jormuntide Ignis + Ground counter + Gobfin bench).
4. **Mining base** (Aegidron + Tetroise + Knocklem haul-out). Relieves the ore bottleneck gating gear tiers.
5. **Element nuke team** (Fire example: Blazamut Ryu + Ragnahawk + Renjishi + Jormuntide Ignis + Flaracle + Flame Emperor's Baton).
6. **Raid squad** (Astegon tank + matched DPS + Frostallion/Chillet + 4-Gobfin + Lyleen/Felbat sustain).
7. **Capture team** (Daedream + Hoocrates + status inducer + Muffly/Wispaw + fast mount + Ring of Mercy).
8. **Remaining sub-bases** (Kindling, Lumber, Farming, Electricity) as bottlenecks demand, same recipe each: Lv8 specialist + aura carrier + Artisan passives.

## Sources
Game8 (partner skills list, carry-capacity list, Work Speed formula, Sekhmet/Anubis, Statue of Power, raid guides), PalMods (partner-skill rework stacking rules, work-aura list), palworld.gg / fandom / wiki.gg (partner & passive DBs, Vanguard/Stronghold Strategist, Ring of Mercy), Sportskeeda (Desert Empress, Alpha Sekhmet, early teams), NextTier (tier list, raid/tower bosses), Mobalytics (Sekhmet, base pals), allthings.how (Alpha Sekhmet), 4netplayers (element team guide), Steam guides (Gobfin stacking, partner-skill stats), KeenGamer (work pals). Cross-checked against this skill's base-pals.md and breeding.md, no contradictions.

Flags: exact % of single-copy elemental party buffs; whether Flame Emperor's Baton amplifies a mount's player-weapon infusion (one test says no); Sekhmet Desert Empress exact % (20 flat vs 20-40 range; Alpha-vs-normal 400 vs 60 is consistent); carry-weight partner-skill cross-stacking. Verify in-client; 1.0 is days old.
