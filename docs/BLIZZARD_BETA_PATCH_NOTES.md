# 📜 Official Blizzard WoW: Forever Beta Development Notes
> **Tracked Source:** [Official Blizzard EU/US Blue Tracker — Topic #631316](https://www.wowhead.com/blue-tracker/topic/eu/wow-forever-beta-development-notes-updated-26-october-631316)
> **Latest Official Build Post:** `2026-10-26 15:35:53` • **Total Tracked Build Posts:** `5`
> **Auto-Sync Status:** Actively monitored and synced by `scripts/sync_blizzard_blue_tracker.py`

---

## ⚡ Executive Summary of Latest Build (26 October 2026)
- **Weapon Skill Racials Removed:** Human Sword/Mace Spec, Dwarf Mace Spec, and Orc Axe Spec have been replaced so future raid/dungeon loot tables are never locked to mandatory weapon types.
- **Racial Identity Pass (Oct 26):**
  - **Human:** *Ruthless* (+1% Crit Chance, tuned from 2%); *The Human Spirit* increased to **+10% Spirit** (was 5%).
  - **Dwarf:** *Earth Fury* removed; added **Artisan's Precision (+1% Hit with spells and attacks)**; *Find Treasure* grants extra items from chests.
  - **Orc:** *Savage* (1% crit) removed; **Command re-added (+5% Warlock and Hunter pet damage)**; *Blood Fury* 3m CD; *Shatter Curse* dispels Curses/Banes (-5% Magic damage taken).
  - **Tauren:** *Plainsrunning* grants **2% movement speed per stack up to 60% max** (does not affect mounts); *Endurance* is pure **+5% Health**; *War Stomp* 90s CD; *Cultivation* 15m CD.
  - **Skyborne:** *Wind-Blessed* **2% Haste**; *Read Leyline* (+50% Mana/HP regen for 15s, **+100% when Attuned** at a Ley Line for 1 hr, persists through death); *Skysight* (+15% move speed for 15s, **+30% when Charged** at an Elemental Convergence for 1 hr, persists through death).
  - **Gnome / Undead / Troll:** Gnome *Eureka!* (**10% Mana, Rage, or Energy discount** for 8s); Undead *Touch of the Dead* (30% caster / 20% melee proc, 25s ICD, CC-safe); Troll *Regeneration* increased to **20%**.
- **Raid-Wide Buffs & Totems (Oct 15):** Warrior *Battle Shout*, Shaman *Windfury / Grace of Air / Strength of Earth / Flametongue Totems*, Hunter *Trueshot Aura*, and Druid *Leader of the Pack / Moonkin Aura* are now **Raid-Wide**! Paladins gain non-exclusive *Salvation / Mass Salvation* + *Revoke*.

---

## 🟦 Build Update #5 — 2026-10-26 15:35:53 (Post ID: `6453379` by Kaivax)

As we approach the launch of WoW Forever, we’ve been reflecting on feedback we’ve heard on racial abilities and passive traits: Some players have expressed that some of the new racial traits feel too generic, while others have raised concerns that some are objectively stronger than others.

In taking a final pass on these, we’ve prioritized racial identity, which means that some races will naturally be slightly more effective than others at certain combat roles. In some places where we had replaced role- or class-focused racials with generic ones, we’re rolling those changes back. One exception to this is the weapon specialization racials, like humans’ Sword Specialization or orcs’ Axe Specialization. While those have a strong fantasy component to them, it is not healthy in the long run for future raid and dungeon loot tables to be evaluated through the lens of “required” weapon types.

At the same time, we’re doing a tuning pass on some of the remaining passive bonuses to help ensure that they aren’t skewing outcomes in a way that limits player preferences.

### Racial Abilities and Traits

- **Human**

- Ruthless now increases critical chance by 1% (was 2%).

- Human Spirit now increases Spirit by 10% (was 5%).

- **Dwarf**

- Earth Fury (2% increased critical strike damage and healing) removed.

- Added: Artisan’s Precision - Increases hit chance with spells and attacks by 1%.

- **Tauren**

- Plainsrunning now grants 2% movement speed per stack (was 1%), for a total max increase of 60% (was 30%).

- Plainsrunning no longer increases mounted movement speed.

- Endurance no longer provides any modifiers beyond 5% increased Health (no hit chance or critical damage modifiers).

- **Orc**

- Savage removed (1% increased critical strike chance).

- Command re-added, increasing Warlock and Hunter pet damage by 5%.

- **Skyborne**

- Wind-Blessed Haste bonus reduced to 2% (was 3%).

- Read Leyline now increases Mana and Health regeneration by 50% (was 100%), with a 15-second duration. This ability cannot be used while Innervate is active, and will be replaced by Innervate as a more powerful effect.

- Using Read Leyline at a Ley Line now also grants “Attuned” for 1 hour. While Attuned, the benefit of Read Leyline is increased to 100% regeneration increase. Attuned persists through death.

- Skysight is now a 15% increased movement speed (was 10%), with a 15-second duration.

- Using Skysight at an elemental convergence now also grants “Charged” for 1 hour. While Charged, the benefit of Skysight is a 30% movement speed increase. Charged persists through death.

---

## 🟦 Build Update #4 — 2026-10-15 19:16:31 (Post ID: `6435321` by Kaivax)

**We’ve updated the WoW Forever Beta with a new build that includes the following.**

**CHANGE LOG**

**Bug Fixes**

- Resolved an issue with extra bright fog at lower shadow settings.

- Fixed an issue allowing Horde players to gain Kirin Tor reputation.

- Creatures will now properly regenerate health when out of combat.

- Fixed an issue with various Horde characters holding the Night Watchman’s Torch.

- Fixed an issue with various drink tooltips that were not displaying the correct amount of total Mana regeneration.

**Changes and Updates**

-

Added a new tutorial experience for new players.

-

Improved control over Lighting ‘Bloom Intensity’ in options to be a slider that has moved to the ‘Advanced’ graphics section.

-

Added ‘Auto Attack/Auto Shot’ setting. If enabled, Hunters will automatically switch between auto attack and auto shot. This is now also supported for gamepad.

-

Racial abilities have been updated.

- Tauren

- Endurance: Now grants 2% increased critical damage and healing (was 1% hit chance).

- Plainsrunning: Also grants 3% increased mounted movement speed. This increase stacks with other mounted movement speed increases.

- Plainsrunning now requires the Tauren to move a minimum distance per second to keep the effect.

- *Developers’ notes: Stutter-stepping is no longer sufficient to maintain the effect. This minimum does make some allowance for movement speed penalties.*

- Cultivation: Cooldown reduced to 15 minutes (was 60 minutes).

- War Stomp: Cooldown reduced to 90 seconds (was 2 minutes).

- Dwarf

- Mace Specialization: Replaced with Earth Fury: 2% increased critical damage and healing.

- Find Treasure: Now also grants a chance to find additional items in most chests.

- Skyborne

- Wind Blessed: Haste bonus increased to 3% (was 1%).

- Skysight: Now castable while moving.

- Read Leyline: Now castable while moving. Minimum duration increased to 30 seconds (was 20 seconds).

- Walk on Air: Cooldown reduced to 90 seconds (was 2 minutes).

- Increased the number of spawn locations of Elemental Convergences and Leylines in most Eastern Kingdoms and Kalimdor zones.

- Human

- Sword Specialization: Replaced with Ruthless: 2% increased critical strike chance.

- Orc

- Axe Specialization: Replaced with Savage: 1% increased critical strike chance.

- Blood Fury: Cooldown increased to 3 minutes (was 2 minutes).

- Shatter Curse: Now dispels Curses and Banes (was granting immunity). Magic damage taken reduced by 5% (was 15%).

- Undead

- Touch of the Grave: Proc chance and cooldown adjusted to make benefit more consistent. Improvements made to visuals.

- Undead will no longer have Will of the Forsaken available to them while under the effects of Scatter Shot.

- Touch of the Dead now has a 30% chance to activate for casters and a 20% chance to activate for Paladins/Rogues/Warriors, as well as a 25 second internal cooldown.

- Touch of the Dead no longer scales with Shadow increases on the target or the caster.

- Touch of the Dead no longer suffers from a decreased multiplier when a lower ranked spell is used.

- *Developers’ notes: This shouldn’t have been in place because it’s a racial, not a Class spell or ability.*

- Gnome

- Eureka!: Now an 8 second buff with no charges. Same effect on damage and ability costs. Now also benefits Power Word: Shield.

- Eureka! cannot correctly be used while in stealth or invisibility.

- Night Elf

- Quickness: Movement speed increase now stacks with other movement speed increases.

- Night Elves no longer display their shields while in Wisp Form.

- Troll

- Regeneration: Health regeneration bonuses increased to 20% (was 10%).

**Classes**

- Wands now require you to stand still for 0.5 seconds before shooting, matching early versions of World of Warcraft.

- **Druid**

- Fixed an issue where high ranks of Rejuvenation were preventing other Druids from applying Rejuvenation to the target.

- Omen of Clarity: Fixed a bug where this could be triggered by Faerie Fire while in Cat Form, Bear Form, or Dire Bear Form. Since Faerie Fire costs no resources in those forms, it cannot trigger Omen of Clarity.

- Faerie Fire: Now generates threat while in Bear Form or Dire Bear Form (instead of just initiating combat at 0 threat).

- Fixed an issue allowing multiple Faerie Fire debuffs to be active on a target.

- Shred (Rank 1) is now learned at level 20 (was 22). It was possible to get Shredding Attacks before knowing Shred or Lacerate

- Fixed an issue where Heart of the Wild, Feral Swiftness, Thick Hide, and Leader of the Pack were not applying correctly to characters when they logged in.

- **Balance**

- Multiple instances of Insect Swarm will no longer continue to reduce the target’s hit chance.

- Moonkin Aura now only increases Spell Critical Strike chance, and is Raid wide.

- **Feral**

- Leader of the Pack now only increases Melee and Ranged Critical Strike chance, and is Raid wide.

- The flat damage on Shred’s tooltip will now correctly scale with the % damage increase of the Savage Fury talent.

- *Developers’ notes: This was just a visual bug. The damage is unchanged.*

- Furor now allows the player to retain the Energy they had when they were last in Cat Form even if they go into Bear or Dire Bear Form.

- *Developers’ notes: Bear and Dire Bear Form still prevent Energy regeneration.*

- **Hunter**

- Auto Shot now requires you to stand still for 0.5 seconds before shooting, matching early versions of World of Warcraft.

- *Developers’ notes: Your character will still fire Auto Shot while casting spells like Aimed Shot or Sniper Shot.*

- Arrows should now be visible when a character has their bow drawn back.

- Pets now correctly benefit from Expertise.

- The Hunter’s Fire traps now correctly scale with Attack Power.

- The Hunter may now correctly have 1 active Fire Trap and 1 active Ice Trap (was 1 Trap among all types).

- **Pets**

- Fixed an issue where pets were only ever inheriting the player’s Melee Critical Strike chance instead of whichever is higher, melee or ranged.

- Dismember (Crocolisk)

- Healing reduction reduced to 25% (was 50%).

- Duration reduced to 6 seconds (was 10 seconds).

- Cooldown increased to 15 seconds (was 6 seconds).

- Sonic Blast (Bat)

- Cast speed reduction reduced to 30% (was 60%).

- Duration reduced to 20 seconds (was 30 seconds).

- Cooldown increased to 60 seconds (was 30 seconds).

- Mine! (Bird of Prey)

- Duration reduced to 3 seconds (was 4 seconds).

- Cooldown increased to 90 seconds (was 60 seconds).

- **Beast Mastery**

- Summon Hawk will now correctly cause the Hawk to spawn at the target the spell was cast on.

- Summon Hawk will now stick your Hawk to the target that it was summoned on.

- Fixed an issue causing the Improved Mend Pet talent to increase the Mana cost of Mend Pet instead of decrease.

- **Marksmanship**

- Trueshot Aura is now Raid wide.

- Fixed an issue where Sniper Shot was not benefitting from a few Marksmanship talents.

- **Survival**

- Strider Kick can now be used while disarmed or while no weapon is equipped in your Main Hand.

- Resourcefulness now correctly reduces the Mana cost of Strider Kick.

- Resourcefulness now correctly activates when landing a critical strike, but it has been changed to only activating on melee and ranged ability critical strikes to prevent spamming.

- *Developers’ notes: Is not activated by Traps.*

- Updated the tooltip for Predator’s Edge changed to better convey that it only increases the critical strike damage of your abilities.

- **Mage**

- Frost Blast: This new spell is learned at level 24. It deals damage and slows the target’s movement by 40%. It has a 1.5 second cast time, and is affected by all talents that affect Frostbolt.

- *Developers’ notes: The purpose of this spell is to provide the functionality formerly granted by Rank 1 Frostbolt despite the penalization of “down-ranking”. It does have a higher Mana cost and deals a little more damage as well.*

- **Arcane**

- Fixed an issue where Presence of Mind would not be consumed by spell casts.

- Fixed an issue where Missile Barrage could reduce the cost and duration of a second Arcane Missiles cast.

- Missile Barrage: This talent has moved to the first row and become a 2-point talent. It now also grants a chance for Arcane Missiles hits to trigger Missile Barrage.

- Arcane Blast: Redesigned. This spell is now a 1.5 second cast, and each time it is cast it grants the casting Mage 15% of their Intellect as additional Spell Damage. This effect also increases the cost of Arcane Blast as before and still stacks to 4 times. However, the effect now lasts 15 seconds from when it is first applied, instead of just until the next spell cast. Mana cost unchanged, but damage done and Spell Damage coefficients both reduced 40%.

- Arcane Wrath: New 16-point gold medal talent. This new spell deals base damage similar to Fireball, with a 3.5 second cast, but also deals damage as if the Mage had additional Spell Power equal to 5% of the Mage’s maximum Mana. 6 second cooldown.

- Fire

- Heating Up is no longer consumed if the Mage also had Presence of Mind active for the Pyroblast cast. Heating up also always gains an additional charge each time the Mage casts Fire Blast. This does mean Fire Blast critical strikes generate 2 charges.

- Wake of Fire: Talent reverted back to Improved Fire Blast and no longer grants a bonus when the Mage kills a target. It also now increases the range of Fire Blast by 8/15 yards.

- Critical Mass: Mages can now spend up to 5 points in this talent for 10% total critical strike increase.

- Fire Power: Redesigned. Now only 3 talent points. Increases damage done by Fire spells by 1/2/3% per the Mage’s Fire effects on the target, up to a maximum increase of 12%. Spells that mix multiple schools of magic do not grant this bonus.

- *Developers’ notes: Specifically, the effects which can grant increased Fire damage from this talent are Ignite, Improved Scorch, Fireball, and Pyroblast, and Impact. Frostfire Bolt does not grant the damage increase but can benefit from it.*

- Frost Channeling now correctly reduces the Mage’s threat.

- Fixed an issue where Ice Block was too transparent.

- Fixed various issues around Clearcasting. Clearcasting now correctly does not roll for every target struck by a spell. Clearcasting no longer has a chance to activate off of Dampen Magic and Amplify Magic. Clearcasting no longer has a chance to be activated by abilities cast when not in combat.

- **Frost**

- Fixed an issue preventing Frostbite and Fingers of Frost from activating from your Ice Armor and Frost Armor spells.

- Ice Lance damage against Frozen targets changed to a 200% increase (Was 300%).

- Cone of Cold: Movement speed of the first 4 targets hit is decreased by an additional 10% and the slow lasts an additional 3 seconds on those targets.

- *Developers’ notes: The ability of this spell to control massive number of targets was the primary reason it was previously reduced in effectiveness and duration. It feels reasonable to let it retain this level of power when used against 4 or fewer targets.*

- Winter’s Chill: Redesigned. No longer increases critical strike chance. Instead, it causes Cone of Cold to deal 40% increase damage per stack of Winter’s Chill on the target, consumed by next Cone of Cold.

- Slightly changed the positioning of the spell visual for Cone of Cold.

- New spell Frost Blast. 1.5 second cast. Deals low frost damage. Slows/chills. Benefits from talents that benefit Frostbolt.

- Winter’s Chill change to: Gives your Frostbolt, Frost Blast, and Fingers of Frost empowered Ice Lance spells a 20/40/60/80/100% chance to apply Winter’s Chill, increasing the target’s damage taken from your next Cone of Cold by 5% and it gains an additional 7% of your spell damage, stacking up to 5 times.

- **Paladin**

- Seal of Fury is no longer overwritten by Power Word: Shield.

- Blessing of Salvation and Greater Blessing of Salvation have been replaced with Salvation and Mass Salvation. These are applied in the same manner as the blessings were, but are not exclusive with blessings.

- Paladins now also learn Revoke when Salvation is learned. Revoke removes target party or raid member’s Salvation or Mass Salvation.

- *Developers’ notes: This is to restore the functionality of giving the Paladin more finesse and control over who has Salvation active and who doesn’t.*

- Judgement of Righteousness and Judgement of Fury now have the correct spell power coefficients for instant cast spells.

- Fixed an issue causing Seal of Righteousness to gain almost twice as much benefit from Spell Damage than intended.

- Fixed an issue where Judgement of Righteousness had an incorrect Spell Damage coefficient.

- Consecration’s Spell Power Coefficient per tick has been changed to 0.042 (was 0.095).

- Righteous Fury’s Holy damage threat generation increased to 90% (was 60%).

- Seal of Fury Rank 3 is now correctly available for training at level 26 (was incorrectly level 25).

- **Holy**

- Fixed an issue where using a focus macro to cast Light’s Vigil was causing it to not go onto the appropriate target.

- Fixed an issue causing Infusion of Light to grant Holy Shock 50% increased damage against enemies.

- **Protection**

- Shield Specialization Mana restored to the Paladin lowered to 4% with a 3 second internal cooldown (was 6% with a 3 second internal cooldown).

- Reckoning: This talent has been adjusted so you gain a charge of Reckoning each time it triggers. Your next melee swing (auto attack) will trigger all accumulated charges for 1 extra attack each. You may have a maximum of 4 charges.

- This restores the Classic Era functionality of storing up to 4 charges and delays all the triggers until your next swing so that it does not cause the auto attack timer to be reset by instant attacks.

- **Retribution**

- Champion of the Light now increases your spell damage by 10/20/30% of your Intellect (was 20/40/60%).

- Sanctified Judgement’s Mana restore effect no longer generates threat.

- **Priest**

- Fixed an issue where high ranks of Renew were preventing other Priests from applying Renew to the target.

- Fixed an issue causing Holy Fire Rank 5 periodic damage to be higher than Rank 6.

- Power Word: Shield will now correctly tell the player they can’t replace a Power Word: Shield on a target if the Power Word: Shield they have is stronger.

- Fixed an issue where casting Power Word: Shield would say SHIELDED twice in your scrolling combat text.

- Devouring Plague cooldown reduced to 24 seconds (was 1 minute).

- Shadow Word: Death cooldown increased to 18 seconds (was 12 seconds).

- Fixed an issue where casting Mind Vision would cause the target to stand up and interrupt drinks.

- **Discipline**

- Inner Focus will now correctly only be used on a single spell, even if you spell queue another spell into Penance’s channel.

- Added to the tooltip for Divine Aegis explicitly that it is activated by Non-Periodic critical heals.

- Added to the tooltip for Divine Aegis what the maximum value for the shield is.

- Power in Light now increases Smite and Penance if the target is afflicted by Holy Fire or Shadow Word Pain.

- Silence Resolve threat reduction now applies to all spells.

- Mental Strength moved to Row 2 from Row 4 and changed to increase your intellect by 2/4/6/8/10%.

- Improved Power Word: Shield moved to Row 3 from Row 2.

- Twin Disciplines now correctly benefits Shadow Word: Death, Mind Flay, Starshards and Penance.

- **Shadow**

- Fixed an issue where Shadow Word: Death was not benefitting from Shadowform’s increase to critical strike damage.

- Fixed an issue where Devouring Contagion was causing the bounced Devouring Plague to cost Mana, perform a cast animation, and put the caster’s Devouring Plague back on full cooldown.

- Changed Vampiric Embrace so that it can’t be resisted.

- Vampiric Embrace cooldown reduced to 30 seconds (was 1 minute).

- Improved Fade removed.

- Shadow Infinity removed.

- Improved Mind Blast moved from Row 3 to Row 2.

- New talent (Row 4): Dark Inspiration – Your Mind Blast and fully channeled Mind Flay causes Dark Inspiration, increasing yours and your party’s Spirit by 3/6/9/12/15% for 10 seconds.

- Improved Mind Flay changes to: Each instance of damage of Mind Flay deals 10/20% more damage than its previous instance of damage.

- Devouring Contagion now spreads to 2 targets.

- Fixed an issue with Shadow Weaving’s Tooltip. It now correctly states that it causes the target to take increased damage from you.

- **Rogue**

- Rogue Poisons will no longer incorrectly activate against targets that are attacking them.

- Sap no longer has a chance to activate weapon procs.

- Fixed an issue where Rogues could swap specializations to keep their energy full.

- **Assassination**

- Cold Blood is now correctly consumed when Mutilate lands a critical strike.

- **Shaman**

- Fixed an issue where Totemic Recall cost 70 silver on the trainer instead of 22 silver, as intended.

- Grounding Totem is now correctly destroyed after redirecting a spell.

- Windfury Weapon’s attacks now appear as White hits in the scrolling combat text.

- Grace of Air Totem is no longer exclusive with Windfury Totem and Flametongue Totem.

- Windfury Totem and Flametongue Totem retain their exclusivity.

- Grace of Air Totem, Strength of Earth Totem, Windfury Totem, and Flametongue Totem are now Raid wide.

- Chain Lightning: Mana cost reduced by approximately 35% on all four ranks.

- Fire Nova’s Spell Power Coefficient has been changed to 0.143 (was 0.214).

- Fire Nova’s base damage has been significantly reduced.

- Fire Nova’s mana cost has been significantly reduced.

- Flametongue Totem and Windfury Totem now correctly only affect players.

- Added a little green to the visual of Chain Heal without overpowering the original effect.

- **Elemental**

- Your Clearcasting from the Elemental Focus talent will no longer have a way to be spent on the same Fire Nova that activates it.

- Elemental Mastery: This talent has returned as the new 31-point gold medal talent. Reduces the cast time of Lightning Bolt and Lava Burst by 0.5 seconds and removes the cooldown from Chain Lightning for 15 seconds. 3-minute CD. Lava Burst is pre-requisite.

- Lava Burst: Moved from the 7th row to the 5th row as the 21-point gold medal talent. New rank 4 added and ranks reflowed. No longer has any pre-requisite.

- Elemental Fury: Now has Lightning Overload as pre-requisite.

- Lightning Overload: Now has Elemental Alacrity as pre-requisite.

- Elemental Alacrity: Moved from 3rd row to 2nd row.

- Elemental Warding: Moved from 2nd row to 3rd row.

- Call of Thunder: Talent removed.

- Earthbound: Moved to 4th row as the 16-point gold medal talent.

- Elemental Reach: Now also reduces the cooldown on Totemic Projection by 10/20 seconds.

- Call of Flame: Now also extends duration of Flame Shock by 3/6/9 seconds.

- Column Arrangement: Many talents moved to make room for other talents and their connections.

- Clearcasting will no longer be consumed by Lightning Overload activations.

- Fire Nova’s tooltip now correctly increases when placing talents into Trial By Fire (the talent formerly known as Improved Fire Nova).

- **Enhancement**

- Your Stormstrike debuff is no longer consumed if your spell does not land.

- Fixed an issue where Stormstrike could be consumed by other players or pets that weren’t the casting Shaman.

- Stormstrike’s cost changed to 8% of Base Mana (was 125 Mana at all points in the game).

- **Restoration**

- Added an additional Rank of Mana Tide Totem that is learned at level 38, so now you have ranks at level 25, 38, 48, 58 (was levels 25, 48, 58).

- The Restorative Totems talent now correctly increases the effect of the entirety of Healing Stream totem (was the base value).

- Tidal Focus and Totemic Focus have swapped locations. Tidal Focus is now in the 1st row, and Totemic Focus is now in the 2nd row.

- Water Shield: Can now trigger from any critical spell cast by the Shaman (was only critical heals).

- **Warlock**

- Fixed an issue where Summon Incubus was available to summon at no Soul Shard cost with the Reagent Economy Legacy Perk.

- Fixed an issue allowing multiple Curse of Recklessness debuffs to be active on a target.

- **Affliction**

- Malediction replaced with Grim Reach, which increases the range of your Affliction spells by 10/20%.

- Shadow Mastery changed to increasing your Shadow spell damage by 2/4/6/8/10% (Was 1/2/3/4/5%).

- **Demonology**

- Fixed an issue where you couldn’t cast Soul Link on your pet.

- **Destruction**

- Destructive Reach changed to Increases the range of your Destruction spells by 10/20%.

- **Warrior**

- Battle Shout is now Raid wide.

- Slam is no longer subject to spell pushback.

- Fixed an issue where Overpower was not able to activate vs. significantly lower level enemies.

- **Arms**

- Fixed an issue where Weaponmaster’s Sword Specialization could be activated by Shield Bash and Shield Slam.

- **Fury**

- Lingering Rage no longer stops the player’s Health Regeneration after combat.

- Fixed an issue where Improved Berserker Rage was not removing Movement Impairing Effects.

**Gamepad Support**

- Added a swing timer to the center reticle.

- Added bindings to enable and disable Voice Channel Transcription via the Chat Channels menu.

- Ensured your own fishing bobber is always targetable.

- Fixed using ground-targeted items. Using them a second time will now confirm the placement.

- Fixed an issue causing the gamepad action bar to be invisible upon relogging after creating and selecting a custom Edit Mode layout.

- Fixed an issue causing the cast bar to not be properly customizable with Edit Mode.

- Fixed an issue making it difficult to activate actions using the class-specific flyouts.

- Fixed an issue with quest reward selection that prevented completion of certain quests.

- Fixed an issue where quests offered by interactive objects or other non-character quest givers could not be turned in with a gamepad.

- Made the “Press and Hold Casting” setting compatible with gamepad.

- Updated the Trade confirmation dialog to be usable with a gamepad.

- Updated the Guild & Communities dialogs to be usable with a gamepad.

- Updated the Chat Channels menu to be usable with a gamepad.

- Updated the Transmog frame to be usable with a gamepad.

**Items**

- Mystic Mushroom now correctly increases Spirit.

- The Insight enchant now correctly increases Spirit.

- Morbent’s Bane no longer causes other nearby players to play visual effects.

- Scrolls now incur a global cooldown when used.

- Many items created by professions have had their vendor sell price reduced.

- Draught of Predatory Senses is now a Potion, on the Combat Potion cooldown, and had its duration reduced to fit within this design space.

**Legacy System**

- Fixed an issue where Bartering was discounting training and repairing.

- Visually moved the Master Chef and Luremaster perks 1 row to the left.

- *Developers’ notes: They were already available with only 5 points committed, so this is only a visual change.*

- The Quick and the Dead should now affect more Priest spells.

**Quests**

- General

- Fixed several quest items that were multi-drop and should not be.

- Ashenvale

- There are more Bloodtooth Guards available during the quest “Raene’s Cleansing”

- Dalaran

- Members of the Horde are no longer welcome in Dalaran under any circumstances and will be attacked on sight. This does not affect access to the City of Dalaran dungeon, but the Horde questline to obtain the Dalaran Sewer Key no longer grants unrestricted access to the city in the open world.

- Darkshore

- Fixed an issue where many of the furbolg camps would not grant credit for the quest “How Big a Threat?”

- The quest “For Love Eternal” can now be turned in to Cerellian Whiteclaw at all times.

- “Body and Heart”: Cenarion Moondust is no longer used up when you sprinkle it on the stone, so if you need to try again, you can come back later and use it again to re-summon Lunaclaw.

- Mulgore

- The Novice Warriors will no longer flag players for PvP during the quest “Sparring Match”.

- Stormwind

- “The Attack!” is no longer an escort quest and is now shareable, even while the event is active. Speak to Tyrion to begin the event if it is not active.

- Teldrassil

- Lord Melenas no longer evades at low health during the quest “Twisted Hatred”.

- Wetlands

- Several areas have had their respawn rates increased and evened out, including Dragonmaw Orcs, Gnolls, and Incendicite Ore.

- Zephras Isle

- Addressed an issue that could prevent players from using Halaan’s Gift to scry on the anchors of Zephras and progress the quest “The Anchors of Zephras.”

**Player versus Player**

- Battleground Marks of Honor now stack up to 30 (was 20).

**User Interface**

- Unit Frames display has been updated.

- Minimap header display has been updated.

- Spells with different rankings now behave as a single entry in the Cooldown Manager.

- Auction House now displays a column for equippable level.

- Auction House will now properly display equipment stats from items with suffixes (example: “___ of the Monkey”).

- Added detailed Scrolling Combat Text options under Options > Gameplay > Combat > Scrolling Combat Text for Self > Text on Me/Text on Target.

- Searching for “Threat” will now pull up the Aggro Display option.

- To reduce Nameplate clutter, the distance visibility for Nameplates for enemies and NPCs above and below the player have been adjusted. Your current target’s nameplate is not affected.

- Restored level-up messages showing stat increases and talent points gained.

- In-game Tutorials have been updated.

- If party members are different character levels, the Looking For Group UI will now properly update the eligibility statuses of the dungeon list.

- Group Finder checkbox “Show All Level Ranges” will properly update the dungeon list.

- Fixed an issue where art assets were running amok on the Professions UI panel.

- Who List search now supports subzones (example: characters in Northshire Valley will show up in both queries “/who northshire” and “/who elwynn”).

- Players can no longer accept the ‘refresh world’ prompt while in combat.

---

## 🟦 Build Update #3 — 2026-10-08 16:32:57 (Post ID: `6421463` by Kaivax)

Today, we updated the WoW Forever Beta with a new build that includes the following.

### CHANGE LOG

**Bug Fixes**

- This build reintroduces Classic looting behavior, where creatures that dropped no loot can still be interacted with.

- Fixed visual effects flickering on large creatures.

- Fixed creature behavior that could result in unintended long-distance pulls.

**Changes and Updates**

-

**Now available for testing: the new City of Dalaran dungeon.**

-

Players will once again be able to swap multiple weapons within the same GCD, for example via a macro to swap from a two-handed weapon, to a sword and shield.

-

The experience earned from killing creatures in dungeons has been increased by approximately 20%.

-

Fixed a bug that reduced XP granted to players who were in a party with higher-level players killing lower-level enemies.

- *Developers’ notes: So far in WoW: Forever, experience for killing lower-level enemies while in a party was penalized based on the highest-level member of the party. In Classic Era, that adjustment was made individually for each party member without regard for the highest-level party member. We’ve reverted the calculation to the Classic Era behavior, where only the individual’s level matters. We believe the combination of these two changes will dramatically increase experience earned in dungeons for most players.*

- *Developers’ notes: As before, if a member of the party is at a vastly higher level than the enemy being killed, then no player in the party will receive XP, as intended.*

-

**Cooldown Manager**

- All classes, racial abilities, and trinkets are now supported.

- *Developers’ notes: Additional support for consumables will come in a later patch.*

-

**Gamepad Support**

- Updated the input indicator for actions that require holding a button as opposed to pressing it.

- Fixed an issue that could prevent inputs from working as intended after looting.

- Opening the map UI will now start focus on the Quest Log. This allows players to continue running unless actively using map cursor.

- Raid frame traversal updates.

- Gamepad Action Bar now has edit mode support.

- Edit Mode layouts are now saved and loaded per ui type

- Gamepad Action Bar settings such as compact action bar have been moved into edit mode from the options menu.

- Users will need to go into edit mode, click the gamepad action bar and set any desired options as they will not be moved over from the previous options in the options menu.

-

**Legacy System**

- All Beta players have been granted completion of the Legacy Challenge. This awards 16 Legacy Points to fully test out the system.

- The lowest-cost talent point re-spec for Legacy Points now costs 1s, and the cost to re-spec will reduce by one re-spec per hour.

- *Developers’ notes: This is similar to how re-spec costs work for class talents and only applies during the Beta.*

**Classes**

- *Developers’ notes: There have been several bugs in the calculation of Rage gained from taking damage, and the bugs are fixed in this build. The typical Warrior or Druid should be gaining more Rage from taking damage.*

- Fixed a bug where the Rage calculation was incorrectly using the player’s health to determine Rage gained, instead of an expected creature’s health. This incorrectly resulted in less Rage earned while wearing more Stamina gear.

- Fixed a bug where the Rage calculation was not correctly handling increased damage taken from combat multipliers, in particular from taking critical strikes or crushing blows.

- Fixed a bug where Rage calculations on Damage absorbs were not being handled correctly. Damage absorbs should now be properly ignored when calculating Rage received from attacks (as if the Warrior/Druid had no absorb active).

- *Developers’ notes: Previously, we were balancing Rage gained around Warriors having 50% Armor. While this was appropriate for a tank, it was not appropriate for questing Warriors. We have rebalanced Rage gains based on appropriate values per level in the 20% to 40% range, varying by level.*

- **Druid**

- Fixed a bug where Druids couldn’t use Mana Potions while in Bear/Dire Bear/Cat Form.

- Additional Rage generated from landing Critical Strikes increased to 100% increased Rage (Was 75%).

- The base damage of Thorns has been returned to the Vanilla WoW values and the spell power ratio has been reduced to 6% (was 13.3%).

- Fixed an issue where Cat Form was reducing your maximum health.

- Bear Form and Dire Bear Form: Threat bonus increased to 50% from 30%.

- The effects that override shapeshifting now more closely resemble Classic wow.

- *Developers’ notes: The Druid’s form is a critical piece of information in combat and preserving the ability for players to see what form the Druid is currently in is important. We appreciate the desire for Druid players to still transform, so there are effects that will still work, it is just now much more limited and largely based on if that transform has other benefits (for example, Noggenfogger Elixir will still transform you because it lets you breathe underwater.)*

- Demoralizing Roar: Fixed an issue where it generated no threat. Now puts some threat on all affected targets.

- Wrath: The base points and points per level of ranks 1-5 of this spell have been adjusted to make the growth rate of ranks 1-6 more consistent, and new ranks always an upgrade.

- **Feral**

- Predatory Instincts: This talent has been renamed “Natural Instinct” and now also increases spell healing by 12/25% of Intellect.

- Shifting Power can no longer be used while already at Full Energy.

- Thick Hide: This talent is now properly implemented in code, rather than script, resolving some bugs with equipping gear while shapeshifted not triggering it.

- **Hunter**

- Disengage: Threat reduction was intended to be doubled but was missed. Now implemented.

- Fixed a bug causing Hunter pets to gain health repeatedly when low health.

- **Beast Mastery**

- Unleashed Fury now correctly increases your pet’s damage.

- **Marksmanship**

- Improved Concussive Shot now has the correct chance to activate.

- **Survival**

- Improved Wing Clip now has the correct chance to activate and reduced chance to activate if using ranks substantially below your current level.

- Expose Prey now lasts 10 sec (was 5).

- Entrapment now correctly has diminishing returns.

- Entrapment now correctly only activates on Frost Trap’s initial activation, not periodically.

- **Mage**

- Fixed an issue where Impact could proc off of Flamestrike’s periodic damage.

- Frostbolt: The base points and points per level of ranks 1-5 of this spell have been adjusted to make the growth rate of ranks 1-6 more consistent, and new ranks always an upgrade.

- Fireball: The base points and points per level of ranks 1-5 of this spell have been adjusted to make the growth rate of ranks 1-6 more consistent, and new ranks always an upgrade.

- Arcane Missiles: The base points and points per level of ranks 1-3 of this spell have been adjusted to make the growth rate of ranks 1-4 more consistent, and new ranks always an upgrade.

- **Paladin**

- Fixed an issue with Retribution Aura that caused it to use the target being struck’s spell power instead of the casting Paladin’s spell power.

- The base damage of Retribution Aura has been returned to the Vanilla WoW values (about a 33% reduction) and the spell power ratio has been reduced to 6% (was 13.3%).

- **Protection**

- Reckoning: Now has a 1.5 second cooldown on how often it can be triggered.

- Fixed an issue where Seal of Fury was granting Mana back to the Paladin even if the Improved Seal of Fury talent was not active.

- Improved Seal of Fury and Shield Specialization no longer generate threat when restoring Mana.

- *Developers’ notes: Paladins restoring enough Mana to sustain combat while tanking was causing more threat to be generated than intended.*

- **Priest**

- Smite: The base points and points per level of ranks 1-4 of this spell have been adjusted to make the growth rate of ranks 1-5 more consistent, and new ranks always an upgrade.

- Lesser Heal and Heal: The base points of ranks 1-3 of Lesser Heal and ranks 1-2 of Heal have been adjusted to make the growth rate of this family of spells up to Heal Rank 3 more consistent, and new ranks always an upgrade.

- **Discipline**

- *Developers’ notes: Penance has received multiple updates to bring it more in line with powerful spells that have a cooldown.*

- Reduced Penance spell damage and healing to resolve a bug where it was being treated like a 3-second channel instead of a 2-second channel.

- Adjusted Penance mana costs so that it has a consistent advantage in mana efficiency over the Heal/Greater Heal family of spells. Rank 1 mana cost was increased by 50%.

- Healing done by Penance has been increased on Penance ranks 2 and 4.

- **Shaman**

- Flametongue Totem will now correctly use the target’s attack speed if they are Shapeshifted, instead of using the speed of their equipped weapon.

- Lightning Bolt: The base points and points per level of ranks 1-5 of this spell have been adjusted to make the growth rate of ranks 1-6 more consistent, and new ranks always an upgrade.

- **Elemental**

- Elemental Focus is no longer activated and immediately consumed when using Fire Nova.

- **Restoration**

- Water Shield now accurately displays the mana restored in the buff tooltip.

- Water Shield no longer says it has a 15 second cooldown (it didn’t have one).

- Mana Tide Totem will once again display its visual when pulsing.

- **Warlock**

- A Warlock’s current pet will now be stunned while summoning a new pet.

- Shadow Bolt: The base points and points per level of ranks 1-4 of this spell have been adjusted to make the growth rate of ranks 1-5 more consistent, and new ranks always an upgrade.

- **Demonology**

- Demonic Brand bonus pet damage now only does high threat when it deals Shadow damage.

- **Warrior**

- Demoralizing Shout: Fixed an issue where it generated no threat. Now puts some threat on all affected targets.

- **Arms**

- Deep Wounds is once again a required talent to reach Impale.

- Fixed a bug where Deep Wounds was scaling with attack power for your Offhand weapon.

- *Developers’ notes: Deep Wounds does not scale with Attack Power but is a rolling DoT compared to Classic/Vanilla.*

- **Protection**

- Fixed an issue causing Last Stand to not grant the correct amount of health to the player on activation.

**Items**

- Reduced the visual size of new armorset shoulder pieces to correct size.

- Wolfshead Helm’s effect has changed to granting 5 additional Energy when shifting power is used. Rage portion of the helm’s effect remains the same.

- Various Dungeon Quest Rewards have had their rarity lowered to Uncommon from Rare. Stats have been updated to reflect the change in rarity.

- The Truthseeker’s Bow from the Greater Friend of the Library quest now has the correct level requirement of level 40. The other two rewards from this quest chain had a level 40 equipped item requirement so it has been changed to match these items.

- Transformative Cocoon is now correctly a debuff.

- The Revelation Enchant’s buff will no longer be removed when the caster Shapeshifts into Ghost Wolf or Druid Forms.

- The recipe for Peace Tea now sells to vendors for 10c.

- Various Enchanting-produced items have had their vendor prices adjusted as follows:

- Minor Wizard Oils now sells for 1s.

- Novice’s Practice Wand now sells for 5c.

- Lesser Magic Wand now sells for 1s 10c.

- Greater Magic Wand now sells for 2s.

- Lesser Mystic Wand now sells for 4s 50c.

- Greater Mystic Wand now sells for 6s.

- Twisted Nether Wand now sells for 10s.

- Dreambough Wand now sells for 15s.

- Lesser Eternal Wand now sells for 20s.

- Greater Eternal Wand now sells for 25s.

- Booty Bay Bruiser’s Buckshot no longer has a knockback effect.

- The following rewards from the new Gelkis and Magram quests in the Desolace have received tuning adjustments. In an upcoming hotfix, these will be changed to require Level 35 to equip, matching the quest adjustments.

- Abandoned Ferocity

- Blade of the Magram Clan

- Bludgeon of Betrayed Virtues

- Centaur Spear

- Ceremonial Centaur Blanket

- Desert Crawler’s Claw

- Desperate Barrier

- Greatstaff of the Necrokhans

- Kolkar Hunter’s Belt

- Kolkar Marauder Chain

- Scavenged Magram Armament

- Soulsplatter Mace

- Staff of Revelations

- Thrice-Damned Effigy

- Traitor’s Finger

- Wanderer’s Broadsword

- *Developers’ notes: Most of the items above have simply had their power level adjusted to the expected value from the quest, but some received stat changes.*

- Damage from Discolored Healing Potions no longer breaks Crowd Control effects.

**Player versus Player**

- Critical strikes in PvP no longer have reduced efficacy.

- Fixed an issue where the capture point for Shipwreck Cove appeared in the incorrect location.

**Professions**

- Armor Kits that grant Attack Power no longer incorrectly grant twice as much Ranged Attack Power.

- Fixed an issue where Enchant Weapon - Recovery was not working for Druids while shapeshifted.

**Races**

- Undead

- Fixed an issue where Will of the Forsaken could sometimes not be used while asleep or charmed.

**Quests**

- Fixed an issue where players could become unable to start “Blood Tithe” after completing certain quests.

- The Night Watchman’s Torch no longer has a visible aura on the players it is illuminating, only the torch bearer.

- Barbers across capital cities have been sacked and replaced with local barbers. We anticipate no fallout from this among the goblin cartels.

- Barrens

- The Horn of Echeyakee is no longer consumed on use during the quest “Echeyakee”.

- There is now a map marker for the quest “The Principal Source”.

- Desolace

- The new quests for the Gelkis and the Magram beginning with “Valley of Bones” now require a minimum level of 35 (was 30).

- The power of these rewards have been adjusted. See Items section for more details.

- Dun Morogh

- Moving and turning inputs no longer cancel Far Sight during the quest “Farsen’s Watch”. It can still be right-click cancelled at any time.

- Durotar

- The Taillasher Eggs for the quest “Break A Few Eggs” now respawn more quickly, and there are more eggs available.

- Lazy Peons are now lazier for the quest “Lazy Peons”, and the map marker now includes the super secret northern peons.

- Duskwood

- Stitches is once again hostile as he enters the unsuspecting town of Darkshire. DARKSHIRE…I HUNGER!!

- Excavation Site: Wetlands

- The Titan Relic item from the quest “Elder Knowledge” or “Lost Relic Carry” is given back to players for the follow-ups “Earthen Echo” or “Prehistoric Prism”, so that you do not need to get another relic.

- Hillsbrad Foothills

- During the quest “Elixir of Pain” Stanley no longer gives XP, and the quest now gives the XP that formerly came from him.

- Loch Modan

- Reduced the frequency of Dark Iron Ambushers at Miran’s camp during the quest “Resupplying the Excavation.”

- Mulgore

- The turn-in marker for “Grim Tidings” has been updated for accuracy.

- Creatures in Gloomrise now respawn more evenly, and Gloomrise Hatchlings give appropriate XP for their difficulty.

- Orgrimmar

- Neeru Fireblade now has a map marker and mouseover tooltip during the quest “Hidden Enemies”. Ironic.

- Redridge Mountains

- Increased the respawn rate of the Weapon Racks, Stolen Weapons, and Blackrock Supplies for the quest “Blackrock Blockade”.

- Rogue

- Added map markers for the quest “Plundering the Plunderers”.

- Shaman

- The various creatures needed for the quest “Storm, Earth, and Fire” respawn more quickly, creatures drop their twisted totems more often, Maraudine Scouts now drop Twisted Air Totems, Ongeku can now drop a Twisted Earth Totem, Murdaloc can now drop a Twisted Fire Totem. The Twisted Fire Totem can now additionally be obtained via Dustbelcher ogres across the Badlands. Larger encampments like Dustbelch Grotto will respawn more quickly, but smaller ones will not.

- The Eye of the Tempest for “Heed My Call” is now multi-drop.

- Stonetalon Mountains

- Jin’Zil now allows quests to be turned in to him after someone completes the quest “Jin’Zil’s Forest Magic.”

- Teldrassil

- During the quest “Destiny Calls”, Sethir the Ancient now spawns more Minions of Sethir after having been reset, and his respawn time has been decreased.

- Sentinel Lynessa Duskblossom now moves more slowly during the quest “Escaping Ban’ethil.”

- Tirisfal Glades

- Increased the level of the quests and creatures around Shadowvale and Bandarion Keep.

- *Developers’ notes: These were lower level than the content that preceded them, which didn’t have the escalation we wanted and could result in the quests being green by the time you got to them.*

- Warrior

- Fixed an issue where the Mausoleum Trigger for the quest “Ulag the Cleaver” would take a long time to reactivate.

**User Interface**

- Voice Chat can now be set to use Discord Voice under Audio settings and is used for the entire party based on the party leader’s setting.

- An In-Game Voice Mode can now be chosen for Group Finder postings which result in party members receiving a prompt to join the selected voice chat.

- Inspect player window has been updated.

- Combo points have been updated in the Target Frame and Personal Resource Display.

- Quest Types are now displayed as text in the Quest Log, Quest Tracker, and Quest Dialogue.

- Quest level requirements are now displayed in the Quest Tracker.

- Fixed an issue where buffed stats were not highlighted in the Character Info panel.

- Fixed an issue where Specific Macros were showing General Macros.

- Clicking on an earned Legacy Challenge will now open the Legacy Challenge window.

- View Talents is now an option below Inspect in the target frame’s context menu.

- Character level and class is now displayed on the left frame of the Character Info pane.

**Known Issues – New with this build**

- While texture updates to Skyborne druid bear and travel form are updated, texture updates to Skyborne druid cat form, various creatures in Zephras Isle, and some mounts, pets, and other creatures will arrive in a future build.

- Hunters who selected the Ferocity talent will not see the critical strike chance of their pet increase on the character sheet. This is a visual bug only.

- Some of the icons in the Professions window appear broken.

---

## 🟦 Build Update #2 — 2026-10-01 18:11:55 (Post ID: `6407957` by Kaivax)

Today, we updated the WoW Forever Beta with a new build that includes the following.

### CHANGE LOG

**Bug Fixes**

- Improved rain visibility.

- Removed the ‘Ray Traced Shadows’ option. This setting will be re-added to the game in a future update, after the functionality is fixed.

- Fixed an issue where the Night Watchman’s Torch was causing some unintended lag in certain situations and could not be cancelled.

- The visual size of weapons when held in hand and sheathed on the back has been adjusted across all races to be more consistent.

**Changes and Updates**

- Players can now level up to a maximum of level 30.

- **New Dungeon - Excavation Site: Wetlands (26-31).**

- Players now have access to Razorfen Downs (25+) and Uldaman (30+), in addition to the following, already available, dungeons:

-

- Ragefire Chasm

- Hall of Thanes

- Ruins of Lordaeron

- Wailing Caverns

- The Deadmines

- Shadowfang Keep

- The Stockade

- Blackfathom Deeps

- Gnomeregan

- Razorfen Kraul

- Scarlet Monastery

- There are now barbershops in Darnassus and Thunder Bluff, all barbershops now have barbers working at them, and city guards will give directions to barbershops.

- **Camping**

- The Boosted Rest debuff caused by this camp feature now has a different icon intended to make the effect clearer, and the tooltip has been rewritten to be clearer.

- Wording on camping features has been adjusted to use the term “mutually exclusive” instead of just “exclusive” to reduce some confusion around functionality.

- Campfires no longer deal damage to players below level 5, and they deal reduced damage to players with less than 90% health.

- **Items**

- Savory Whimsyfin Delight now uses an orc equivalent of the Ninja and Pirate outfits from the Savory Deviate Delight.

- *Developers’ notes: The prior transformations were placeholder, but we may reintroduce similar ones in the future!*

- When selling to a vendor a BoE item which has an appearance you have not collected, the item will now become soulbound (was Bound to Account).

**Classes**

- **Druid**

- Bear Form and Dire Bear Form now generate 75% increased Rage when landing a Critical Strike.

- Fixed a bug causing Swipe to not scale with Attack Power. It will now correctly gain 3% of the Druid’s attack power.

- *Developers’ notes: The tooltip will not update correctly until a future update*.

- Tiger’s Fury has been removed.

- All Shapeshift Forms are now IMMUNE to Disarm effects.

- *Developers’ notes: This is a gameplay adjustment to match how it felt in original WoW. If a Druid gets disarmed before entering a form, their form will not remove the Disarm effect, and they will also deal reduced damage for the duration of the disarm effect, so disarming a Druid before they shift will result in them dealing reduced damage.*

- Faerie Fire no longer resets your swing timer when used.

- **Feral**

- Primal Bite: Threat generated by this ability has been roughly doubled.

- The King of the Jungle talent has been removed.

- Tiger’s Fury has been removed.

- Connected to Shredding Attacks in the 4th row is a new talent - Shifting Power.

- Cat Form Only. 16 second cooldown. Costs 55% of Base Mana.

- Instantly convert 55% of Base Mana into 40 Energy. Shifting Power’s cost is reduced by effects that reduce the cost of Shapeshifting.

- Shifting Power costs the same amount of Mana as Cat Form.

- Connected to Shifting Power in the 5th row is a new talent - Improved Shifting Power.

- Reduces the cooldown of your Shifting Power spell by 4/8 seconds.

- **Hunter**

- **Marksmanship**

- Icon for Improved Stings changed to be more Vanilla feeling.

- The 31st talent Sniper Shot now has a 45-yard Range and increases the range of your next 3 shots made within 10 seconds by 10 yards.

- **Survival**

- Icon for Predator’s Edge changed to be more Vanilla feeling.

- Deflection’s Parry increase changed to 1/2/3/4/5% (Was 2/4/6/8/10%).

- **Pets**

- Aggressive Mode has been brought back and can be found under the pet tab in your spell book.

- *Developers’ notes: There were some tameable beasts with ranks of pet abilities that were too high level for that creature. They have all been fixed. This could result in a bug where your pet “forgot” the pet ability which should not happen after this fix.*

- **Mage**

- All Mage scrolls from comprehension have had an additional balance pass and can no longer be cast while moving.

- **Fire**

- Hot Streak has been renamed to Heating Up, since it is no longer dependent on having a ‘streak’.

- The number of charges of Combustion has returned to 3 (was 4).

- Improved Scorch’s Fire Vulnerability will not roll a second time to see if it resists.

- **Frost**

- Winter’s Chill’s application does not roll to see if it is resisted, since the original spell needed to hit.

- **Paladin**

- **Protection**

- Redoubt’s chance to Block changed to 4/8/12/16/20% (was 6/12/18/24/30%).

- Holy Shield’s chance to Block changed to 30% (was 20%).

- **Retribution**

- Champion of the Light’s Intellect to Spell Damage ratio changed to 20/40/60% (Was 33/66/100%).

- *Developers’ notes: Champion of the Light had a tooltip issue saying it increased Healing; it did not. This tooltip has been removed.*

- **Priest**

- Devouring Plague can now correctly critically strike.

- Fixed an issue where Shadow Word: Death was always benefitting from the Early Demise talent regardless of the target’s health %.

- **Discipline**

- Inner Focus no longer applies its Critical Strike increase to Periodic Effects.

- **Shadow**

- Shadow Weaving can no longer fail to apply.

- **Rogue**

- Fixed an issue where Expose Armor missing would cause you to lose all of your combo points.

- **Subtlety**

- Setup will now only add combo points to your current target if they are the one you dodged or resisted a spell from.

- **Shaman**

- Ghost Wolf should now be more visible while in well-lit areas.

- Fixed an issue where Disease Cleansing Totem wasn’t a 5-minute duration.

- Fixed an issue where Totemic Recall was not restoring Mana.

- **Warlock**

- Drain Soul is now correctly interrupted if the Warlock begins casting another spell.

- The Incubus pet model has been replaced with a lower resolution model.

- Hellfire can now critically strike.

- **Affliction**

- Soul Harvesting has been renamed to Soul Harvest. It now correctly grants its 50/100% increase to Mana regeneration.

- **Pets**

- Aggressive Mode is back and can be found under the pet tab in your spell book.

- **Warrior**

- Players now generate 75% increased Rage when landing a critical strike with a basic attack.

- Rend and Sunder Armor will now instantly tap enemies to the Warrior.

- Queueing Heroic Strike will no longer increase off-hand hit chance.

- Additional Rage generated from landing Critical Strikes increased to 100% increased Rage (was 75%).

- Fixed a bug that was causing Dual Wield Specialization to grant its increase to Hit Chance to both weapons.

- *Developers’ notes: Because of the above bug, our tests needed some correcting, so we did another pass on Fury Warrior.*

- **Arms**

- Spearing Strike no longer requires a 2-handed weapon. Spearing Strike requires Battle Stance.

- **Fury**

- Dual Wield Specialization no longer provides a 20/40/60/80/100% increase to your Off-Hand weapon’s Rage generation.

- Fixed an issue with Unbridled Rage having a lower proc chance than intended.

- *Developers’ notes: Our goal here is to give Fury more access to utility and meaningful choices early in the tree for leveling, and free up points later for more choices instead of being stuck placing points into Enrage to get Flurry.*

- Booming Voice is now a 10/20/30/40/50% increase area of effect to your Shouts and a 5/10/15/20/25% reduction to their Rage costs.

- Unbridled Wrath no longer grants twice as much Rage to two-handed weapons.

- New Talent Lingering Rage in Row 2 of Fury. Lingering Rage increases the time before your Rage begins to decay when leaving combat by 2/4/6/8/10 seconds.

- Blood Craze no longer activates off of Bloodthirst casts.

- The Improved Cleave talent has been removed.

- The Boundless Rage talent has been removed.

- New Talent Furious Precision in Row 3 of Fury. Furious Precision increases your chance to hit with off-hand attacks by 4/7/10%.

- Raging Blows now reduces the Rage cost of your Cleave and Whirlwind abilities by 3.

- Raging Blows no longer causes your Whirlwind to strike with your offhand. Whirlwind will now always strike with both weapons without requiring a talent point.

- Dual Wield Specialization no longer grants hit to your off-hand attacks.

- Enrage is no longer required to reach the Flurry talent.

- Death Wish is now required to reach the Flurry talent.

- New Talent Gore Drinker in Row 6 of Fury, requires the Enrage talent. Your Enrage, Berserker Rage, Bloodrage, Death Wish, and Bloodthirst abilities cause your next 3 melee attacks to restore 0.5/1% of your maximum Health.

- Improved Berserker Rage moved to Row 5 of Fury (Was Row 6).

- Berserker Rage is now available at level 30 (Was 32)

- Bloodthirst’s Attack Power ratio has been increased to 45% (Was 35%).

- **Protection**

- *Developers’ notes: Our goal is to give non-shield users a clear path to the middle of the tree, where Protection could serve as a PvP tech secondary specialization, with more access to Improved Bloodrage, Iron Will, Improved Disarm, Last Stand, and Improved Shield Bash.*

- Iron Will moved to the Row 1 of Protection (Was Row 2 of Fury).

- Anticipation moved to Row 2 (Was Row 1).

- Toughness has been removed.

- Improved Bloodrage moved to Row 1 (Was Row 2).

- Improved Revenge moved to Row 2 (Was Row 3).

- Improved Disarm moved to Row 3 (Was Row 4).

- Improved Shield Bash moved to Row 4 (Was Row 5).

**Cooldown Manager**

- Racial abilities are now supported.

- Rogue is now supported.

- Duplicate entries for each spell rank on already supported classes should no longer be present.

**Gamepad Support**

- The pet stable interface has been updated for gamepad support.

- The gamepad UI bindings are now static, and any gamepad rebinding only affects the keyboard and mouse interface.

- The compact Raid and Party manager frames have been updated for gamepad support.

- Fixed an issue preventing macros placed on a gamepad action bar from being able to be moved.

**Player versus Player**

- Honor costs for PvP gear and upgrade tokens have been adjusted, with most item costs increasing by approximately 50% to better align with gear acquisition targets.

- The Honor cap has been increased from 15,000 to 25,000 to better accommodate the above new costs.

**Professions**

- Shenthul in Orgrimmar will now train Windshaper Skyborne.

- A number of recipes intended for Blacksmithing and Leatherworking as random drops in dungeons are now available.

- **Enchanting**

- All crafted common and uncommon quality wands now sell at vendors for 1 copper.

- **Mining**

- Reduced the amount of Poor Copper Vein nodes available in starter areas.

- **Skinning**

- Creatures can once again only be skinned a single time before disappearing.

**Quests**

- *Developers’ notes: We appreciate the feedback on leveling speed as we continue ongoing discussions about the Beta. As part of those discussions, we’ve decided to reduce the amount of XP granted from dungeon quests with this release. Certain quest rewards have also been recalibrated.*

- Dungeon quests now reward 50% less extra experience beyond normal quest values.

- Resolved an issue with players being unable to start escort quests if their quest log contained 25 or more quests.

- Resolved an issue with certain quest items being multi-drop.

- Resolved an issue with some quests that give items on start being shareable.

- Resolved an issue with some quests that come from items being shareable.

- Increased the respawn rate across many different creatures and objects in Hillsbrad Foothills, Ashenvale, Wetlands, Duskwood, and Thousand Needles.

- *Developers’ notes: Redridge Mountains and Stonetalon Mountains were adjusted in a previous build. Please continue to submit any areas where you have difficulty completing quests, and we will continue to make adjustments.*

- Darkshore

- Resolved an issue with the Tharnariun’s Hope item during the quest “Plagued Lands”.

- Deadmines

- “Destruction in Deadmines” now sorts correctly in the quest log for the dungeon.

- Druid

- Fixed an issue where players were not receiving loot reliably during the quests “The Great Cat Spirit” and “The Great Windborne Cat Spirit.”

- High Order Skyborne can now do the quest “Power Over Poison” to learn the Cure Poison spell.

- Dun Morogh

- Shimmer Ridge trolls will respawn more evenly, and faster in areas where they were sluggish. It be the cold, mon.

- Loch Modan

- Troggs in the Loch now respawn slightly more slowly for the quest “In Defense of the King’s Lands.”

- Mulgore

- The quest “Kyle’s Gone Missing!” has been added.

- Orgrimmar

- Smooth Boulder should be far more plentiful and available to gather for the quest “Rocks to Rests”

- Redridge Mountains

- The quest “Blackrock Blockade” has been updated. Spawn rates have also been adjusted.

- Ruins of Lordaeron

- “A Frightened Request” now sorts correctly in the quest log under the dungeon.

- Resolved an issue where players could receive multiple copies of the Bloodied Insignia quest item.

- Wailing Caverns

- Serpentbloom Snakes now despawn after a couple of minutes. Why’d it have to be snakes?

- Westfall

- Significantly reduced the respawn rate of the pocket watch in Furlbrow’s Wardrobe for the quest “The Forgotten Heirloom”.

- Increased respawn rate for the undead for the quest “Collecting Memories” and Foreman Thistlenettle for the quest “Oh Brother…”

**Races**

- **Gnome**

- Eureka! no longer benefits periodic effects at all. Channeled spells do not count as periodics.

- **Undead**

- Cannibalize cannot be used if the caster is IMMUNE to Physical damage.

**User Interface**

- On the character sheet, when mousing over Spell Damage and Spell Healing, it is now explained that spells cast using spell ranks vastly below your current level receive less benefit from your Spell Damage and Spell Healing and have a reduced chance to activate your Class abilities and Talents. (examples: Frostbite and Omen of Clarity)

- *Developers’ notes: Another example of this reduction in activation chance – Using a Rank 1 Frostbolt at level 60 will result in a 0% chance to get a Frostbite activation. So you now are making a decision between getting a slow off quickly, or using a spell that can potentially get a Frostbite activation, instead of getting both.*

- Character Creation will display matching icons when Standard Definition models are toggled.

- Stables frame art has been updated.

- Combo points on the target frame and Personal Resource Display has updated art.

- Fixed loot rolls in chat not displaying a player’s full name.

- The auction house will now correctly display item suffixes.

**World**

- Adjustments have been made to world instances.

- Party leaders should no longer be transferred when creating or updating party composition.

- *Developers’ notes: As we continue to iterate on features that impact player populations and grouping, we look forward to your feedback and bug reports.*

**Known Issues - New to this build**

- Chaining Spells together does not play the precast spell effects and sounds of the next cast until the first cast finishes.

- For example: When you cast Fireball and cast another Fireball right away, you finish your Fireball cast, your hands won’t glow or make the crackling sound of the new Fireball you’re casting, and then once your hand comes down from the first Fireball cast, you then begin the precast animation of the next Fireball spell.

- Enemies can Parry and Block from behind if the player is close to them. Until this is fixed, it can be avoided by not being too close to targets.

- The size of the total installation of WoW: Forever is larger than intended. We’re working to reduce it in a future Beta update.

- Switching to or from Gamepad UI mode resets the active edit mode layout to the default preset.

- Scroll of Liminal Passage does not function correctly.

- Dwarf player-characters do not have updated splash sounds in water. This is fixed in a later build.

- Eureka does not affect every Damaging Spell or Healing Spell for some classes. This is fixed in a later build.

- Multiple debuffs like Faerie Fire and Demoralizing Shout don’t cause threat.

- Mages who learn Research can be prevented from accessing it.

- Warriors’ Dual Wield Specialization is granting both your Main hand and Off-hand 2/4/6/8/10% hit chance. It should only be granted to your Off-hand.

- Retribution Aura uses the target’s spell power instead of the Paladin’s.

- The Taillasher Eggs for the quest “Break A Few Eggs” do not respawn as quickly as intended. This will be fixed in a later build.

- Anduin Wrynn - and many other children – unintentionally have hats. We’re in the process of removing them, but they keep giggling and running away, so this is going to take a while.

Our full Known Issues post is here.

---

## 🟦 Build Update #1 — 2026-09-24 17:37:36 (Post ID: `6391795` by Kaivax)

Today, we updated the WoW Forever Beta with a new build that includes the following updates.

### Change Log

- **Bugfixes**

- Fixed a bug with casters not playing their precast animations and sometimes standing while casting.

- Changed the sound effect that plays while jumping in water to be more aesthetically pleasing.

- Adjusted Human death sounds.

- Fixed an issue where attempting to craft items or cast spells was causing players to stand up while waiting to obtain their Campfire buff.

- Players may now buff each other, cast, and craft while waiting for their Campfire buffs.

- Players may now obtain a Campfire buff if they are sitting, sitting in a chair, sleeping, lying down, or using the kneeling emote.

- Resolved an issue where Huey Sunnydale’s legs failed to render properly.

- Fixed an issue that made a Season of Discovery rune ability visible.

- Fixed an issue where Pet Happiness was not decreasing once your pet was at max loyalty.

- Fixed an issue causing the Undercity Canal ooze to be much brighter than intended.

- Removed a setting that could disable fog in an unintended manner.

- Resolved a water display issue and fixed various other display artifacts on Mac.

- Fixed a memory leak causing gradual performance degradation for some players.

- Fixed an issue where in-game mail could ignore surnames.

- **Classes**

- If you have not recently changed your talents, the cost is now 1 silver to re-spec. This is temporary for the Beta only. After your first talent reset, the subsequent cost will be much higher, but it will drop to 1 silver after 1 hour has passed.

- **Druid**

- Corrected an issue and now Rejuvenation can land critical hits.

- Corrected an issue and now Tranquility can land critical hits.

- Wrath base damage increased ~50%.

- Thorns will now dynamically update its values based on the caster’s spell power.

- If the caster cannot be found or is too far away, Thorns reverts to its base values.

- **Feral**

- Mangle has been renamed Primal Bite. Its signature debuff has been removed, so the former name no longer accurately represented the ability.

- All talents referencing Mangle now reference Primal Bite.

- The Primal Fury talent has been renamed and the icon replaced with the original Blood Frenzy name and icon.

- Fixed a bug where Feral Charge (Cat) could be cast on allies.

- **Restoration**

- Corrected an issue and now Wild Growth can land critical hits.

- **Hunter**

- **Pets**

- Furious Howl Attack Power bonus reduced 40%.

- Sonic Blast ability now properly available to Bat pets.

- Tame Beast no longer works on Beasts that are higher than the Hunter’s level.

- **Marksmanship**

- Talenting out of Lone Wolf will no longer cause the Hunter to have -4% damage while their pet is active.

- **Survival**

- Corrected an issue and now Lacerating Strikes can land critical hits.

- Strider Kick now increases movement speed by 30% for 3 seconds.

- **Mage**

- Arcane Missiles no longer checks line of sight on each missile, just once at the beginning of the channel. So targets moving out of line of sight during the channel will not prevent the missiles.

- **Fire**

- Wake of Fire buff duration has been increased to 30 seconds (was 20 seconds).

- *Developers’ notes: Wake of Fire was difficult to make proper use of while leveling, due to the Mage needing to restore mana between combat. The increased duration should help smooth out the experience.*

- Hot Streak buff duration has been increased to 20 seconds (was 15 seconds).

- Ignite no longer double dips on % damage increase modifiers.

- **Paladin**

- Retribution Aura will now dynamically update its values based on the caster’s spell power.

- Fixed a bug causing the Flash of Light cast animation to not play at the end of the spell cast.

- Fixed various issues with Consecration.

- Fixed an issue where Consecration would fail to apply its increased damage effect to some targets.

- Fixed an issue where Consecration’s Z axis wasn’t functioning consistently.

- Fixed an issue where Consecration could pull targets vertically above or below the caster.

- Holy Strike’s % of weapon damage per rank changed to 25%/29%/32%/36%/39%/43%/46%/50% (was 25%/25%/30%/30%/35%/35%/40%/40%).

- *Developers’ notes: This increases Holy Strike’s damage at all points while leveling, and increases how much it contributes to your rotation. Early ranks of Holy Strike didn’t always feel like an upgrade when purchasing a new rank, and we wanted to adjust that.*

- Fixed a bug with Echo of Justice, causing it to have a higher than intended chance to activate.

- Righteous Fury: Holy threat increase increased to 60% (was 90%).

- **Holy**

- Holy Strike’s cooldown lowered to 10 seconds (was 12 seconds).

- Improved Holy Strike removed from the Talent Tree.

- *Developers’ notes: Even though there are sometimes cases where talents feel ‘required’ by classes, like Relentless Strikes for Rogues, having one that reduces the cooldown of a core ability so early on in a healing talent tree made this feel like a talent that was required. So we’ve removed it and made its behavior baseline.*

- Light’s Vigil’s tooltip has been reorganized to make it more clear that the damage component is the only version that returns some of the Mana cost.

- Holy Power now increases the Critical Strike chance of Holy Strike by 15% and retains all of its old effects.

- **Retribution**

- Vengeance now activates off of non-periodic critical strikes.

- Vengeance’s maximum stacks lowered to 3 (was 5).

- Two-Handed Weapon Specialization’s damage increase reduced to 2/4/6% (was 3/6/9%).

- Sacred Arbiter now increases the damage of Holy Strike by 20% (was 10%).

- Twist of Light now additionally reduces the Mana cost of your Seal spells by 20%.

- **Priest**

- Corrected an issue and now Renew can land critical hits.

- Power Word: Shield can now always overwrite an existing Power Word: Shield on a target that does not have Weakened Soul.

- **Gnome**

- Corrected an issue and now Contingency Plan can land critical hits.

- Confounding Flash now has a cast visual. The casting visual is now more Holy oriented than Arcane and the sounds have been updated to match.

- **Night Elf**

- Starshards now correctly gains resistance to spell pushback from the Twilight Focus talent.

- **Undead**

- Dark Sacrifice no longer breaks Crowd Control that breaks on damage.

- Dark Sacrifice’s tooltip now correctly displays that the Mana gained from the ability scales with Spirit.

- **Rogue**

- Sap now correctly flags the Rogue for PvP when used on a target that is PvP flagged.

- **Shaman**

- Lightning Bolt: Damage on ranks 3 and 4 increased to make these spells always upgrades over previous ranks (despite changing cast times).

- Windfury Totem: Buff from this spell now displays as “Windfury Totem” instead of “Windfury Totem Passive”.

- Flametongue Totem: Buff from this spell now displays as “Flametongue Totem” instead of “Flametongue Totem Effect”.

- Flametongue Totem no longer has a duration and is instantly replaced when placing another totem.

- Flametongue Totem is no longer able to be stacked by repeatedly casting Flametongue Totem.

- Flametongue Totem no longer stacks with Flametongue Weapon.

- Flametongue Totem no longer stacks with Windfury Totem.

- Tranquil Air Totem, Windfury Totem, and Grace of Air Totem no longer stack together even if used by different Shamans in the same group.

- **Elemental**

- Swapped the positions of the Elemental Fury (Row 3) and Elemental Alacrity (Row 6) talents.

- *Developers’ notes: Critical Strike damage increases early on in trees are exciting for other specializations, but its not as exciting for the core specialization while leveling, since they don’t have enough critical strike chance to really appreciate it. So we’re moving one of the better talents for Elemental Shaman functionality, earlier in the tree, to allow them to feel like they’re hitting important progression moments (something Elemental has lacked in the early levels). We understand that this affects Enhancement Shaman’s critical strike damage with spells, but we will use this room created to add more to Enhancement Shaman in the future.*

- Lava Burst damage on ranks 1 and 2 increased to be about 10% more base damage than the Lightning Bolt rank learned around the same level.

- **Enhancement**

- Rage of the Far Seer (Row 7) no longer increases the Shaman’s Spell Casting Speed.

- *Developers’ notes: Rage of the Far Seer’s spell casting speed was not necessary to include for the core functionality of this ability. So we removed it.*

- **Restoration**

- Corrected an issue and now Riptide can land critical hits.

- **Warlock**

- Tooltip of Life Tap has been updated to correctly display the amount of Life converted, and only states that it scales with Spirit.

- Voidwalker Sacrifice now correctly scales with 10% of the Warlock’s spell healing.

- **Warrior**

- Sunder Armor: Corrected the threat values on all ranks, including a small increase to threat generated from Attack Power.

- **Protection**

- Swapped the positions of the Bastion (Row 5) and Focused Rage (Row 6) talents.

- *Developers’ notes: We wanted to give players Focused Rage sooner to smooth out progression, as opposed to more damage from Bastion. This should smooth out some of the feeling while leveling as Protection before obtaining Shield Slam.*

- **Arms**

- Bloodthrill’s chance to activate increased to 4/8/12/16/20% (was 2/4/6/8/10%).

- Bloodthrill only activates off of Main Hand melee attacks. This includes Cleave and Heroic Strike.

- Slam’s cooldown has been increased to 18 seconds (was 15 seconds).

- Improved Slam now reduces the cooldown of Slam by 1.5/3 seconds.

- **Races**

- **Gnome**

- Changed Eureka on every class to a 10% discount on Mana, Rage, or Energy abilities.

- **Human**

- Changed the Will to Survive visual to match Dispel Magic instead of Will of the Forsaken.

- **Tauren**

- Cultivation now has a player-level requirement for every Herb. The level required is equal to the Herb’s level required to pick it divided by 5. Herbs that require a higher than 300 Herbalism skill to pick can be Cultivated at player level 60.

- Touch of the Grave no longer breaks CC or activates from spells and abilities that don’t have a damage component to them.

- *Developers’ notes: This means that Shadow Word: Pain activates it on cast, but not on periodic damage. Distract won’t activate it, you can’t pull Rogues and Druids out of Stealth with Distract and it activating, and you won’t activate it off of Pickpocketing. Spells like Polymorph already didn’t get broken by Touch of the Grave, but Polymorph will no longer be able to activate it.*

- **Cooldown Manager**

- The Cooldown Manager in World of Warcraft: Forever is intended to enhance gameplay by pulling critical information from the buff bar or action bar and placing it in a fully customizable location. By default, the Cooldown Manager is disabled, and it can be enabled in Options under the Gameplay Enhancement settings.

- Druid, Mage, Priest, Warrior, and Warlock are available for testing the Cooldown Manager.

- Additional classes will become testable in future updates.

- The most desired feedback for this feature is currently: spells that you wish were tracked by default.

- The Cooldown Manager does not yet support spell ranks. This will be resolved in a future Beta update.

- **Gamepad Support**

- Class specific flyouts have been added to the action bar interface of some classes.

- Shapeshift flyout for Druids.

- Pet control and pet spell flyouts for Hunters and Warlocks.

- Aura flyout for Paladins.

- Stance flyout for Warriors.

- The pet bar no longer replaces the bottom gamepad action bar for Hunters and Warlocks.

- New options have been added to the Gamepad (Alpha) section of the game options.

- Use Compact Action Bar: Replaces the normal gamepad action bar layout with one that only shows the currently active action bar at any given time.

- Fixed Party Targeting: While in a non-raid party, rather than having the directional pad act as directions in the party interface, each button on the directional pad is assigned to a specific party member.

- Swap Target Modifier Sides: Swaps sides of the friendly and hostile targeting modifiers, putting friendly targeting on the right and hostile on the left.

- Swap Friendly Target Action Sides: Swaps the directional pad and face button actions when using the friendly targeting modifier.

- Swap Hostile Target Action Sides: Swaps the directional pad and face button actions when using the hostile targeting modifier.

- Fixed an issue preventing edit mode layouts from being applied while the gamepad UI is enabled.

- Updated Map and Quest Log bindings.

- New hover functionality for POI pins.

- Updated support for Compact Raid Frame Manager and Role Poll Frames.

- **Items**

- A handful of guns and bows were not correctly consuming or using ammunition. They have been corrected.

- A number of quests have had their rewards updated to be the correct item level.

- A small number of early caster rewards have been adjusted.

- Wizard Oil: Minor Wizard Oil has been reverted to Classic Era value of 8 spell power, Lesser Wizard Oil to 16, and Wizard Oil to 24. Brilliant Wizard Oil remains unchanged.

- Wands: Wands no longer gain any additional damage from the user’s spell damage.

- **Quests**

-

- Resolved an issue where several dungeon quests were shareable, which granted the receiving player a quest item when shared.

- Dalaran - Faction adjustments. Spawns are now present in the area just outside the city entrance.

- Dun Morogh - Snow Leopard Prowler has a much faster respawn time.

- Dun Morogh - Resolved an issue where some players were unable to loot the rifle for “Treacherous Cold”.

- Durotar - Reduced the respawn time for the escort NPC for “Lost in the Shadows”.

- Elwynn Forest - The quest “Book Return” now properly removes the extra Book Bag from the player’s inventory when the quest is completed.

- Elwynn Forest - Increased the amount of crates for the quest “Stolen Enchanting Supplies”.

- Elwynn Forest - Murloc camps around Crystal Lake should respawn more quickly. Mrrglrlrlrmgrr!

- Elwynn Forest - Mother Fang respawns a bit more slowly, and does not always drop a green item.

- Elwynn Forest - Shinyfinder Narf respawns more quickly. The quest item may now be looted by all party members.

- Elwynn Forest - Nimsy now respawns more quickly.

- Elwynn Forest - You can now learn skinning from Helene Peltskinner even while you have a quest with her.

- Elwynn Forest - Increased the amount of supply spawns for “Stolen Enchanting Supplies”.

- Elwynn Forest - Jasperlode Mine and Fargodeep Mine are a little more deadly than intended for solo players, so we’re taking their candles away. We do not anticipate any fallout from this theft.

- Mulgore - Water Pitchers now respawn faster for the quest “A Humble Task”.

- Silithus - Khonsu’s arrival has been removed from the beta phase, and in the future will return to Azeroth once more.

- Silverpine Forest - Pyrewood Village worgen respawn more quickly.

- Teldrassil - The objective count for the quest “Bounty: Gnarlpine Furbolg” has been reduced to 15 (was 20).

- Undercity - The Skyborne quest “Exploring the Horde” now completes the objective to talk with Lady Sylvanas Windrunner. Dark Lady watch over you

- Westfall - Increased the spawn rate of the Defias Messenger.

- Zephras Isle - The High Order Skyborne quest “Catching Wind” has been redesigned and adjustments were made to the spawns at the Overlook Standing Stones in Shen’dar Highlands.

- Zephras Isle - The druids of Nightclaw Cavern now award credit for “Wounds of Betrayal” properly when healed.

- Zephras Isle - “A Firm Response” no longer fails to grant credit to players.

- **User Interface**

-

- Updated the Nameplate selection display.

- Personal Resource Display textures are updated.

### New to this build - Known Issues

- Banes and Curses do not properly track if you drop your target and re-acquire a target with an existing bane or curse.

- Healthstone cooldown cannot be tracked.

- Priest tracks all spells by default.

- Arcane Blast cannot be tracked.

- Mana gem requires an additional spell to be cast by the mage to properly begin tracking its cooldown.

- Creating or changing party composition may transfer players to a different world instance. We’re working on improvements and will provide an update soon.

- Pet cooldowns cannot be tracked.

- Item enhancements (such as Windfury or rogue poisons) cannot be tracked

- The minimap in Stormwind has display issues and will be fixed in a later build.

- Personal Resource Display doesn’t show combo points.

Our full Known Issues post is here.

---
