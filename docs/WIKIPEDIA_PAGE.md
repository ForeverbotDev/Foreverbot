# Sparky (Forever Guide)

{{Short description|Open-source companion and in-game database add-on for World of Warcraft}}
{{Infobox software
| name                   = Sparky (Forever Guide)
| logo                   = 
| screenshot             = 
| caption                = In-game interface showing Sparky the wisp companion alongside the Forever Guide codex window
| developer              = Forever Community / ForeverbotDev
| released               = {{Start date and age|2026|11|04}}
| latest release version = 0.1.0-alpha
| latest release date    = {{Start date and age|2026|11|06}}
| programming language   = [[Lua (programming language)|Lua 5.1]], [[XML]]
| operating system       = [[Microsoft Windows]], [[Linux]] ([[Wine (software)|Wine]] / [[Proton (software)|Proton]])
| platform               = [[World of Warcraft: Classic]] (Patch 1.14.x / 1.15.x), ''Warcraft Forever'' (Patch 16.0.x)
| size                   = ~3.24 [[Megabyte|MB]] (distributed archive)
| genre                  = [[World of Warcraft]] [[Video game modding|user interface modification]] (Add-on)
| license                = [[MIT License]]
| website                = {{URL|https://github.com/ForeverbotDev/foreverbot}}
}}

'''''Sparky''''', also known by its system package name '''''Forever Guide''''', is a free and open-source [[World of Warcraft]] user interface modification (add-on) developed by the Forever Community. First made publicly available in pre-alpha form in November 2026, the software serves a dual role: it provides an autonomous, animated companion entity named "Sparky"—modeled as an interactive kaldorei-style wisp—and an offline, zero-latency database browser (the "Codex") containing comprehensive information on items, non-player characters (NPCs), quest chains, vendors, and dungeons for the ''Warcraft Forever'' custom expansion and ''World of Warcraft: Classic'' clients.<ref name="github-repo">{{cite web |title=Foreverbot & ForeverGuide Addon Repository |url=https://github.com/ForeverbotDev/foreverbot |website=GitHub |publisher=ForeverbotDev |access-date=2026-11-06}}</ref>

Designed to alleviate the need for players to switch between the game client and third-party web encyclopedias (such as [[Wowhead]]), ''Sparky'' operates entirely within Blizzard Entertainment's Lua 5.1 sandbox. The add-on is distinguished by its proprietary virtual scrolling engine, real-time spatial area radar ("Nearby"), and user interface principles derived from visual ergonomics and linguistic optometry to minimize cognitive load and ocular fatigue.<ref name="blizz-addon-policy">{{cite web |title=World of Warcraft AddOn Development Policy |url=https://us.battle.net/support/en/article/13594 |website=Blizzard Support |publisher=Blizzard Entertainment |access-date=2026-11-06}}</ref>

== Background and Development ==
In classic iterations of ''World of Warcraft'', players routinely rely on external databases and crowd-sourced wikis to discover quest objectives, mob spawn locations, item drop probabilities, and vendor inventories. The introduction of customized private and community emulation projects, most notably ''Warcraft Forever'', introduced substantial new lore, custom instance level brackets, unique dungeon additions (such as the *Hall of Thanes* and *Blackmaw Hold*), and altered loot tables that rendered standard vanilla web databases obsolete or inaccurate.<ref name="forever-lore">{{cite web |title=Warcraft Forever Expansion Overview & Custom Content Documentation |url=https://github.com/ForeverbotDev/foreverbot/blob/main/README.md |website=Foreverbot Project |access-date=2026-11-06}}</ref>

The project originally began as an automated Discord knowledge engine bot (*Foreverbot*) that queried an SQLite-backed ground-truth game database via slash commands.<ref name="deep-quality-tests">{{cite journal |last=Dev Team |first=Forever |date=2026-11-04 |title=Deep Quality & Authenticity Architecture of Foreverbot Knowledge Engine |journal=Forever Technical Whitepaper |volume=1 |issue=2 |pages=12–19}}</ref> To provide direct, sub-second lookup in-game without requiring external chat software or web overlays, the developers extracted the catalog into an indexed in-game Lua table (`ForeverGuide_Data.lua`), wrapped by a visual interface (`ForeverGuide.lua`) structured around the character of Sparky.

On November 6, 2026, following an extensive security audit and data re-anchoring across 905 global game vendor inventories, the project was officially promoted to **Version 0.1.0-alpha** on [[CurseForge]].<ref name="curseforge-release">{{cite web |title=ForeverGuide (Sparky) CurseForge Release Page |url=https://curseforge.com/wow/addons/foreverguide |website=CurseForge |access-date=2026-11-06}}</ref>

== Features ==

=== Autonomous Wisp Companion (Sparky) ===
Sparky is rendered as a lightweight particle frame featuring layered high-resolution textures (`blue_spark_core.tga`, `sparky_cloud_main.tga`, and ambient aura wisps). The entity is controlled by a continuous mathematical physics loop executed inside a clamped `OnUpdate` frame script:
* **Ambient Floating Mechanics**: Utilizes compound sine-wave and cosine-wave drift trajectories to mimic the erratic, organic hovering of an ancient wisp without stationary repetition.
* **Tethering and Resting States**: When left idle, Sparky settles into a gentle "resting" oscillation near its anchored home point.
* **Game State Reactivity**: Sparky monitors core combat and character status events via the Blizzard event bus:
** Upon player death (`PLAYER_DEAD`), Sparky enters an alarmed "edge-dash" routine, rapidly tracing the peripheral boundaries of the player's monitor.
** Upon player resurrection (`PLAYER_UNGHOST`) or level progression (`PLAYER_LEVEL_UP`), Sparky discharges a celebratory particle burst.
* **Customization**: Players can drag, lock, rescale (from 50% to 200% native size), toggle mouse click-through behavior, or dismiss the companion entirely using slash commands.

=== The In-Game Codex ===
The core knowledge engine of ''Forever Guide'' is a structured reference browser organized in a hierarchical, multi-level file directory layout reminiscent of Unix file managers (such as [[KDE Dolphin]]):
* **Items Catalog (27,072 entries)**: Every item includes its equipment slot, armor/weapon type, vendor buy and sell values, drop tables, item quality colorization, and associated item set linkages. Equip, Use, and Chance-on-Hit procs are rendered in standard green (`#20ff20`).
* **Creatures & Rares (10,122 entries)**: Displays creature classification (Humanoid, Beast, Demon, Dragonkin, Undead, Elemental), level ranges, health brackets, and canonical coordinates (`XX.X, YY.Y`). Clicking an entry can generate an instant `/target` macro.
* **Quests (4,258 entries)**: Complete objective outlines, narrative quest dialogue, turn-in requirement checklists, and reward options.
* **Vendors & Flight Paths (905 entries)**: Specific wares catalogs for food, drink, ammunition, profession patterns, and reagents. Flight masters display all interconnected transit hubs and copper costs.
* **Dungeon Tactician**: Covers all 46 vanilla dungeons alongside the 9 bespoke ''Warcraft Forever'' instances, outlining minimum level requirements, key attunement quests, and boss ability primers.

=== Real-Time Spatial Radar ("Nearby") ===
The add-on features an automated environmental radar that actively listens to `ZONE_CHANGED`, `ZONE_CHANGED_INDOORS`, and `ZONE_CHANGED_NEW_AREA` events. By cross-referencing over 1,032 known subzone names with canonical parent zones, the Nearby module dynamically populates a list of:
# Rare spawns and elite bosses residing in the current subzone;
# Active quest hubs and quest-givers;
# Local flight masters and trade merchants;
# Regional drop tables.

=== Linguistic Optometry & Ergonomic UI Design ===
To combat the visual fatigue common to dense statistical add-ons, the user interface incorporates principles of linguistic optometry:
* **Ocular Calming Palette**: High-contrast pure white on black is avoided in favor of a muted slate-blue background canvas (`#0f1217` at 94% opacity) bordered by antique Blizzard gold (`#a68c47`).
* **Typographic Hierarchy**: Distinct, proportional font scalings separate titles, subtitles, metadata, and coordinates, minimizing saccadic eye movement during scanning.
* **Character Set Normalization**: Replaces missing or unrendered Unicode symbols with native ASCII glyphs (`>`, `<`, `*`) to eliminate "question mark" boxes and unrendered character glyph artifacts.
* **Alphabetical Categorization**: Enforces strict case-insensitive alphabetical sorting across all list indexes.

== Architecture and Performance ==

=== Virtual Scrolling Engine ===
Standard World of Warcraft interface frames that render thousands of UI elements simultaneously can experience severe client degradation, frame rate drops, and memory bloat. ''Forever Guide'' resolves this by implementing a **virtual scrolling architecture**:
* Rather than instantiating 27,000 distinct button objects, the viewport maintains a constant, small pool of recycled row frames (typically 12 to 16 visible frames).
* As the user scrolls via mouse-wheel or slider, the engine updates only the data pointers of the active pool in $O(1)$ constant time.
* This architecture preserves steady 60+ FPS scrolling speeds with negligible heap allocation during movement.

=== Security and Blizzard Policy Compliance ===
As a client-side modification for World of Warcraft, the add-on is subject to Blizzard Entertainment's strict AddOn Development Policy.<ref name="blizz-addon-policy" /> In an independent code and security audit performed in November 2026, the software achieved a zero-defect compliance rating across several security criteria:
* **Sandboxing**: The codebase contains zero prohibited Lua calls (e.g., `loadstring`, `setfenv`, `getfenv`, `rawset`, `dofile`, `require`, or `os.execute`).
* **Zero Automation**: The add-on exposes no automated combat rotations, macro triggers, or hardware event simulation, fully preserving gameplay integrity.
* **Taint Free**: Execution pathways avoid interfering with Blizzard protected frames, preventing the "Interface action failed because of an AddOn" error during combat.
* **Local Processing**: All data queries execute against local tables in memory; the add-on performs zero network telemetry or outbound communication.

== Quality Assurance and Testing ==
The add-on is maintained under an automated continuous-integration testing harness. The test matrix consists of:
* **Addon Simulation & Virtual Scroll Tests**: 36 unit tests validating frame pooling, slider math, and event listener detachment.
* **Deep Knowledge Engine Suite**: 81 comprehensive checks covering mathematical algorithms (e.g. defense glancing penalties, weapon skill modifiers, GDKP pot calculations, and resistance mitigation curves).
* **Random Catalog Verification Audit**: An automated stress test auditing 6,911 randomly sampled game entries across items, quests, NPCs, and vendor tables for structural validity and referential integrity.

== See Also ==
* [[World of Warcraft user interface modification]]
* [[Questie]]
* [[AtlasLoot Enhanced]]
* [[TomTom (add-on)]]
* [[CurseForge]]

== References ==
{{Reflist}}

== External Links ==
* [https://github.com/ForeverbotDev/foreverbot Official GitHub Repository]
* [https://curseforge.com/wow/addons/foreverguide ForeverGuide on CurseForge]

[[Category:World of Warcraft add-ons]]
[[Category:Video game mods]]
[[Category:Free and open-source software]]
[[Category:Software using the MIT license]]
[[Category:2026 software]]
