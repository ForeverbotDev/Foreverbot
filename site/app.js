/**
 * FOREVERBOT — INTERACTIVE WEB APPLICATION
 * Modern interactive scripts: Canvas particle system, live Discord simulator,
 * dynamic command explorer, copy utilities, and platform tabs.
 */

document.addEventListener("DOMContentLoaded", () => {
  initParticleCanvas();
  initDiscordSimulator();
  initCommandExplorer();
  initPlatformTabs();
  initCopyButtons();
  initMobileNav();
});

/* ==========================================================================
   1. AMBIENT BIOLUMINESCENT PARTICLE SYSTEM
   ========================================================================== */
function initParticleCanvas() {
  const canvas = document.getElementById("particleCanvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");

  let width = (canvas.width = window.innerWidth);
  let height = (canvas.height = window.innerHeight);

  window.addEventListener("resize", () => {
    width = canvas.width = window.innerWidth;
    height = canvas.height = window.innerHeight;
  });

  const particles = [];
  const PARTICLE_COUNT = Math.min(Math.floor(window.innerWidth / 16), 75);

  for (let i = 0; i < PARTICLE_COUNT; i++) {
    particles.push({
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.45,
      vy: (Math.random() - 0.5) * 0.45,
      radius: Math.random() * 2 + 1,
      alpha: Math.random() * 0.5 + 0.2,
      color: Math.random() > 0.4 ? "0, 240, 255" : "168, 85, 247" // Cyan or Purple
    });
  }

  function render() {
    ctx.clearRect(0, 0, width, height);

    for (let i = 0; i < particles.length; i++) {
      const p = particles[i];
      p.x += p.vx;
      p.y += p.vy;

      if (p.x < 0) p.x = width;
      if (p.x > width) p.x = 0;
      if (p.y < 0) p.y = height;
      if (p.y > height) p.y = 0;

      ctx.beginPath();
      ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(${p.color}, ${p.alpha})`;
      ctx.shadowBlur = 10;
      ctx.shadowColor = `rgba(${p.color}, 0.8)`;
      ctx.fill();

      // Connecting lines for nearby particles
      for (let j = i + 1; j < particles.length; j++) {
        const p2 = particles[j];
        const dx = p.x - p2.x;
        const dy = p.y - p2.y;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist < 110) {
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(p2.x, p2.y);
          ctx.strokeStyle = `rgba(0, 240, 255, ${0.12 * (1 - dist / 110)})`;
          ctx.lineWidth = 0.6;
          ctx.stroke();
        }
      }
    }

    requestAnimationFrame(render);
  }

  render();
}

/* ==========================================================================
   2. INTERACTIVE DISCORD SIMULATOR
   ========================================================================== */
const SIMULATOR_DATA = {
  bis: {
    userCommand: "/bis query:Warrior spec:fury",
    embedType: "embed-epic",
    title: "⚔️ Warrior (Fury) Pre-Raid BiS Gear List",
    desc: "Optimized pre-raid loadout for level 60 raiding. Configured for hit cap threshold and glancing blow efficiency vs level 63 bosses.",
    fields: [
      { name: "🪖 Head / Neck", val: "• Lionheart Helm (Blacksmithing)\n• Mark of Fordring (In Dreams Quest)" },
      { name: "🛡️ Shoulders / Chest", val: "• Truestrike Shoulders (UBRS)\n• Savage Gladiator Chain (BRD Arena)" },
      { name: "⚔️ Mainhand / Offhand", val: "• Dal'Rend's Sacred Charge (UBRS Rend)\n• Dal'Rend's Tribal Guardian (UBRS Rend)" },
      { name: "💍 Rings / Trinkets", val: "• Blackstone Ring (Maraudon Princess)\n• Blackhand's Breadth (UBRS Quest)" },
      { name: "📊 Target Hit Cap", val: "**6% Hit** with 305 Sword/Axe Skill\n**9% Hit** with standard 300 Skill" }
    ],
    footer: "Foreverbot v1.0 • Ephemeral Response (Only visible to you)"
  },
  compare: {
    userCommand: "/compare query:Vis'kag the Bloodletter weapon2:Brutality Blade race:Human character_class:Warrior",
    embedType: "embed-legendary",
    title: "⚔️ Weapon Comparison: Vis'kag vs Brutality Blade",
    desc: "Evaluated for **Human Warrior** with racial **+5 Sword Skill** against a Level 63 Raid Boss.",
    fields: [
      { name: "🗡️ Vis'kag the Bloodletter", val: "**159 - 296 Damage** (Speed: 2.60)\n**87.5 DPS** | Chance on Hit: 240 Fatal Wound\n*Verdict:* Superior Main-Hand for Whirlwind & Overpower." },
      { name: "🗡️ Brutality Blade", val: "**90 - 168 Damage** (Speed: 2.50)\n**51.6 DPS** | +9 Str, +9 Agi, +1% Crit\n*Verdict:* Outstanding Off-Hand stat stick." },
      { name: "🛡️ Glancing Blow Penalty", val: "Racial +5 Skill reduces glancing damage penalty from **35% down to 5%**! Hit cap reduced from 9% to 6%." }
    ],
    footer: "Combat Simulator Engine • Authentic WoW Formulas"
  },
  dungeons: {
    userCommand: "/dungeons query:Scarlet Crypts",
    embedType: "embed-rare",
    title: "🏰 Scarlet Monastery Crypts (Custom Forever Dungeon #1)",
    desc: "Deep subterranean chambers beneath the Scarlet Monastery catacombs. Houses high-ranking rogue inquisitors.",
    fields: [
      { name: "📍 Location & Bracket", val: "Tirisfal Glades (Under Monastery)\n**Recommended Level:** 38 - 44" },
      { name: "💀 Key Encounters", val: "• Grand Inquisitor Valthek\n• Crypt Stalker Malakai\n• Tormented Highborne Soul" },
      { name: "🎁 Notable Drops", val: "• Inquisitor's Soulcleaver (Rare Axe)\n• Shadow-Woven Crypt Mantle\n• Seal of the Scarlet Crusade" }
    ],
    footer: "WoW: Forever Database • 9 Custom Dungeons Indexed"
  },
  flightpath: {
    userCommand: "/flightpath from:Ironforge to:Light's Hope Chapel",
    embedType: "embed-gold",
    title: "🦅 Flight Route: Ironforge ➔ Light's Hope Chapel",
    desc: "Direct Gryphon transit across Khaz Modan and the Plaguelands.",
    fields: [
      { name: "🗺️ Route Waypoints", val: "1. Ironforge (Dun Morogh)\n2. Thelsamar (Loch Modan)\n3. Aerie Peak (Hinterlands)\n4. Light's Hope Chapel (Eastern Plaguelands)" },
      { name: "⏱️ Estimated Travel Time", val: "**5 minutes, 12 seconds**" },
      { name: "💰 Flight Master Fee", val: "**18 Silver, 50 Copper**" }
    ],
    footer: "Azeroth Transit System • Instant Routing Calculation"
  },
  gdkp: {
    userCommand: "/gdkp query:50000 cut:10 raiders:40 tanks:2 tank_bonus:2",
    embedType: "embed-gold",
    title: "💰 GDKP Raid Pot Distribution Calculator",
    desc: "Mathematical payout calculation for a 50,000 Gold Molten Core / BWL pot split.",
    fields: [
      { name: "🏦 Total Pot Value", val: "**50,000 Gold**" },
      { name: "👑 Guild / Host Cut (10%)", val: "**5,000 Gold** (Net Pot: 45,000g)" },
      { name: "🛡️ Tank Incentives (2%)", val: "2 Tanks @ 2% each = **1,000g each** (2,000g total)" },
      { name: "💎 Payout Per Raider", val: "**1,075 Gold** per raider (40 players)" }
    ],
    footer: "Guild Economy Engine • Zero Rounding Error"
  },
  ask: {
    userCommand: "/ask query:how does glancing blow penalty work vs level 63 bosses?",
    embedType: "embed-epic",
    title: "🤖 /ask: Glancing Blow Mitigation Mechanics",
    desc: "Against level 63 raid bosses, **40% of all melee white auto-attacks** are forced into Glancing Blows.",
    fields: [
      { name: "📉 Standard 300 Weapon Skill", val: "Glancing blows suffer a harsh **35% damage penalty** (hitting for only 65% of normal damage)." },
      { name: "📈 Racial +5 Skill (305)", val: "Having 305 weapon skill (Humans with Swords/Maces, Orcs with Axes, or Edgemaster's Handguards) crushes the penalty down to **only 5%**!" },
      { name: "🎯 Hit Cap Reduction", val: "At 305 skill, your melee special yellow-attack hit cap drops from **9% down to 6%**, saving 3 gear slots for raw Crit & Attack Power." }
    ],
    footer: "Foreverbot AI Knowledge Engine • Grounded in WoW: Forever Mechanics in SQLite"
  }
};

function initDiscordSimulator() {
  const tabs = document.querySelectorAll(".sim-tab");
  const chat = document.getElementById("discordChat");
  const input = document.getElementById("simCustomInput");
  const sendBtn = document.getElementById("simSendBtn");

  function renderMessage(data) {
    if (!chat || !data) return;

    chat.innerHTML = `
      <div class="discord-msg-group">
        <img src="assets/foreverbot_icon.png" alt="Foreverbot" class="discord-avatar">
        <div class="discord-msg-content">
          <div class="discord-user-header">
            <span class="discord-author">Foreverbot</span>
            <span class="discord-bot-badge">APP</span>
            <span class="discord-timestamp">Today at 8:00 PM</span>
          </div>
          
          <div class="ephemeral-notice">
            <span>👁️ Only you can see this • </span>
            <span style="cursor:pointer; text-decoration:underline;">Dismiss message</span>
          </div>

          <div class="discord-user-command">
            <span class="cmd-highlight">${escapeHtml(data.userCommand)}</span>
          </div>

          <div class="discord-embed ${data.embedType || 'embed-epic'}">
            <div class="embed-author">
              <img src="assets/foreverbot_icon.png" alt="Foreverbot">
              <span>World of Warcraft: Forever Companion</span>
            </div>
            <div class="embed-title">${escapeHtml(data.title)}</div>
            <div class="embed-desc">${data.desc}</div>
            
            <div class="embed-fields">
              ${data.fields.map(f => `
                <div class="embed-field">
                  <div class="embed-field-title">${escapeHtml(f.name)}</div>
                  <div class="embed-field-val">${f.val}</div>
                </div>
              `).join('')}
            </div>

            <div class="embed-footer">${escapeHtml(data.footer)}</div>
          </div>

          <div class="discord-actions-row">
            <button class="discord-btn primary">Helpful</button>
            <button class="discord-btn">Copy Output</button>
            <button class="discord-btn success">Add to Guild</button>
          </div>
        </div>
      </div>
    `;
  }

  // Initial render
  renderMessage(SIMULATOR_DATA.bis);

  // Tab switching
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");
      const key = tab.getAttribute("data-cmd");
      if (SIMULATOR_DATA[key]) {
        renderMessage(SIMULATOR_DATA[key]);
      }
    });
  });

  // Custom simulator input
  function handleCustomSend() {
    const text = input.value.trim();
    if (!text) return;

    const lower = text.toLowerCase();
    let matchedData = null;

    if (lower.includes("compare") || lower.includes("vis'kag") || lower.includes("weapon")) {
      matchedData = SIMULATOR_DATA.compare;
    } else if (lower.includes("dungeon") || lower.includes("crypt") || lower.includes("scarlet")) {
      matchedData = SIMULATOR_DATA.dungeons;
    } else if (lower.includes("flight") || lower.includes("route") || lower.includes("travel")) {
      matchedData = SIMULATOR_DATA.flightpath;
    } else if (lower.includes("gdkp") || lower.includes("gold") || lower.includes("pot")) {
      matchedData = SIMULATOR_DATA.gdkp;
    } else if (lower.includes("ask") || lower.includes("glancing") || lower.includes("math")) {
      matchedData = SIMULATOR_DATA.ask;
    } else {
      matchedData = {
        userCommand: text.startsWith("/") ? text : `/${text}`,
        embedType: "embed-rare",
        title: `🔍 Query Results: "${text}"`,
        desc: "Instant search lookup executed against the embedded WoW Forever SQLite catalog (20,000+ entries).",
        fields: [
          { name: "⚡ Response Time", val: "**Sub-second** (Fast local execution)" },
          { name: "🔒 Privacy", val: "Rendered as **ephemeral per-user reply** (Zero channel spam)" },
          { name: "💡 Available Commands", val: "Try `/bis`, `/compare`, `/dungeons`, `/flightpath`, `/gdkp`, `/roll`, `/signup`, or `/ask`!" }
        ],
        footer: "Foreverbot Database Search • 100% Offline Engine"
      };
    }

    renderMessage(matchedData);
    input.value = "";
  }

  if (sendBtn) sendBtn.addEventListener("click", handleCustomSend);
  if (input) {
    input.addEventListener("keydown", e => {
      if (e.key === "Enter") handleCustomSend();
    });
  }
}

/* ==========================================================================
   3. COMMAND CATALOG EXPLORER (ALL 42 COMMANDS)
   ========================================================================== */
const ALL_COMMANDS = [
  // Combat & Theorycrafting
  { name: "/bis", cat: "combat", desc: "Pre-raid BiS gear lists across all classes & specs.", example: "/bis query:Warrior spec:fury" },
  { name: "/compare", cat: "combat", desc: "Compare weapon DPS, speed, and glancing blow mitigation formulas.", example: "/compare query:Vis'kag weapon2:Brutality Blade" },
  { name: "/resist", cat: "combat", desc: "Elemental resistance mitigation formulas (Fire, Frost, Nature, Shadow, Arcane).", example: "/resist query:Fire current:200 role:Tank" },
  { name: "/build", cat: "combat", desc: "Recommended spec trees and meta builds for raiding & leveling.", example: "/build query:Rogue" },
  { name: "/talents", cat: "combat", desc: "Talent distribution codes and point-by-point pathing.", example: "/talents query:Mage spec:frost" },
  { name: "/consumes", cat: "combat", desc: "Complete raid consumables checklist for maximum DPS/HPS.", example: "/consumes query:Warrior" },
  { name: "/buffs", cat: "combat", desc: "World buffs coordination, drop timers, and cooldown management.", example: "/buffs query:Onyxia" },
  { name: "/macro", cat: "combat", desc: "Essential 1-button macros and mouseover scripts for all classes.", example: "/macro query:Priest" },

  // Dungeons & Raids
  { name: "/dungeons", cat: "dungeons", desc: "All 9 custom WoW Forever dungeons & level brackets 1-60.", example: "/dungeons query:60" },
  { name: "/raid", cat: "dungeons", desc: "Boss strategies, dispel mechanics, phases, and enrage timers.", example: "/raid query:Vaelastrasz" },
  { name: "/gdkp", cat: "dungeons", desc: "Fair GDKP pot split calculator with host cuts & tank bonuses.", example: "/gdkp query:75000 cut:10 raiders:40" },
  { name: "/roll", cat: "dungeons", desc: "Interactive public loot roll with live clickable Discord UI button.", example: "/roll query:Deathbringer seconds:30" },
  { name: "/signup", cat: "dungeons", desc: "Interactive raid attendance roster with role buttons (Tank/DPS/Heal).", example: "/signup query:Onyxia max_players:40" },
  { name: "/attunement", cat: "dungeons", desc: "Step-by-step quest walkthroughs for Onyxia, BWL, and MC.", example: "/attunement query:Onyxia" },
  { name: "/keys", cat: "dungeons", desc: "Requirements for Shadowforge, Skeleton, Crescent, and Scarlet keys.", example: "/keys query:Shadowforge" },
  { name: "/resets", cat: "dungeons", desc: "Live countdown clocks for 3-day, 5-day, and 7-day raid lockouts.", example: "/resets" },

  // Class, PvP & Community
  { name: "/pvp", cat: "class", desc: "Honor ranks 1-14 formulas with Tuesday 20% decay math.", example: "/pvp query:rank 10" },
  { name: "/twink", cat: "class", desc: "Level 19, 29, 39, and 49 bracket BiS gear recommendations.", example: "/twink query:19 warrior" },
  { name: "/comp", cat: "class", desc: "Raid composition synergy optimizer and totem weaving matrix.", example: "/comp query:Alliance" },
  { name: "/addons", cat: "class", desc: "Top 5 essential class addons with direct download links.", example: "/addons query:Warrior" },
  { name: "/race", cat: "class", desc: "Racial trait breakdown (+5 Weapon Skill, Hardiness, WotF).", example: "/race query:Orc" },
  { name: "/trivia", cat: "class", desc: "Interactive lore and dungeon boss trivia mini-game.", example: "/trivia category:raids" },
  { name: "/profile", cat: "class", desc: "Personal user stats, roll history, and saved preferences.", example: "/profile" },

  // World, Travel & Economy
  { name: "/item", cat: "world", desc: "Lookup 27,072 items (including 6,671 WoW: Forever items) with stats, drop rates, and sources.", example: "/item query:Ironfoe" },
  { name: "/disenchant", cat: "world", desc: "Disenchant yields, material probabilities & vendor vs DE value calculator.", example: "/disenchant query:Shadowfang" },
  { name: "/mob", cat: "world", desc: "NPC stats, locations, resistances, immunities, and loot tables.", example: "/mob query:Ragnaros" },
  { name: "/flightpath", cat: "world", desc: "Direct flight hubs and multi-hop origin-to-destination transit routes.", example: "/flightpath from:Ironforge to:Light's Hope" },
  { name: "/route", cat: "world", desc: "Optimized 1-60 leveling routes and zone transitions.", example: "/route level:30" },
  { name: "/farm", cat: "world", desc: "High-yield gold farming locations and solo dungeon pulls.", example: "/farm query:Mage" },
  { name: "/gather", cat: "world", desc: "Herbalism, Mining, and Skinning farming routes by zone.", example: "/gather query:Black Lotus" },
  { name: "/vendor", cat: "world", desc: "NPC vendor inventory lookups (e.g. Bronze Tube, patterns).", example: "/vendor query:Bronze Tube" },
  { name: "/quest", cat: "world", desc: "Quest chain prerequisites, turn-ins, XP, and reward stats.", example: "/quest query:In Dreams" },
  { name: "/rep", cat: "world", desc: "Reputation factions, repeatable turn-ins, and reward tiers.", example: "/rep query:Argent Dawn" },
  { name: "/zones", cat: "world", desc: "Zone level ranges, flight masters, and dungeon locations.", example: "/zones query:Stranglethorn" },
  { name: "/map", cat: "world", desc: "Cartography, coordinates, and regional zone guides.", example: "/map query:Desolace" },
  { name: "/profession", cat: "world", desc: "1-300 profession leveling guides and material requirements.", example: "/profession query:Engineering" },
  { name: "/level", cat: "world", desc: "Level progression roadmap and zone recommendations.", example: "/level query:45" },
  { name: "/events", cat: "world", desc: "Seasonal world events (Darkmoon Faire, Stranglethorn Fishing).", example: "/events" },

  // AI & Intel
  { name: "/ask", cat: "ai", desc: "Deep natural language AI assistant grounded in WoW Forever.", example: "/ask query:what are the 9 custom dungeons?" },
  { name: "/intel", cat: "ai", desc: "Live realm status, Tuesday maintenance updates & announcements.", example: "/intel" },
  { name: "/forever", cat: "ai", desc: "Core WoW Forever features, custom mechanics, and distinctions.", example: "/forever" },
  { name: "/setup_server", cat: "ai", desc: "1-click automated Discord channel and permissions builder.", example: "/setup_server" }
];

function initCommandExplorer() {
  const grid = document.getElementById("commandsGrid");
  const pills = document.querySelectorAll("#categoryPills .pill");
  const searchInput = document.getElementById("commandSearchInput");
  if (!grid) return;

  let currentCategory = "all";
  let searchQuery = "";

  function renderCommands() {
    const filtered = ALL_COMMANDS.filter(cmd => {
      const matchCat = currentCategory === "all" || cmd.cat === currentCategory;
      const matchSearch =
        searchQuery === "" ||
        cmd.name.toLowerCase().includes(searchQuery) ||
        cmd.desc.toLowerCase().includes(searchQuery);
      return matchCat && matchSearch;
    });

    if (filtered.length === 0) {
      grid.innerHTML = `
        <div style="grid-column: 1/-1; text-align: center; padding: 3rem; color: var(--text-dim);">
          No commands matched your search. Try another keyword or reset the filter.
        </div>
      `;
      return;
    }

    grid.innerHTML = filtered.map(cmd => `
      <div class="cmd-card" data-cmd-syntax="${escapeHtml(cmd.example)}">
        <div>
          <div class="cmd-header">
            <span class="cmd-name">${escapeHtml(cmd.name)}</span>
            <span class="cmd-tag">${escapeHtml(cmd.cat)}</span>
          </div>
          <p class="cmd-desc">${escapeHtml(cmd.desc)}</p>
        </div>
        <div class="cmd-footer">
          <code>${escapeHtml(cmd.example)}</code>
          <span class="copy-hint">Copy</span>
        </div>
      </div>
    `).join('');

    // Attach click-to-copy to every card
    grid.querySelectorAll(".cmd-card").forEach(card => {
      card.addEventListener("click", () => {
        const syntax = card.getAttribute("data-cmd-syntax");
        if (syntax) {
          copyToClipboard(syntax);
          showToast(`Copied ${syntax} to clipboard!`);
        }
      });
    });
  }

  // Initial render
  renderCommands();

  // Category pill listeners
  pills.forEach(pill => {
    pill.addEventListener("click", () => {
      pills.forEach(p => p.classList.remove("active"));
      pill.classList.add("active");
      currentCategory = pill.getAttribute("data-category") || "all";
      renderCommands();
    });
  });

  // Search input listener
  if (searchInput) {
    searchInput.addEventListener("input", e => {
      searchQuery = e.target.value.toLowerCase().trim();
      renderCommands();
    });
  }
}

/* ==========================================================================
   4. MULTI-PLATFORM TABS
   ========================================================================== */
function initPlatformTabs() {
  const tabs = document.querySelectorAll(".plat-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      const os = tab.getAttribute("data-os");
      document.querySelectorAll(".platform-tab-content").forEach(content => {
        content.classList.remove("active");
      });
      const target = document.getElementById(`plat-${os}`);
      if (target) target.classList.add("active");
    });
  });
}

/* ==========================================================================
   5. COPY UTILITIES & TOASTS
   ========================================================================== */
function initCopyButtons() {
  document.querySelectorAll(".copy-code-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const targetId = btn.getAttribute("data-target");
      const targetElem = document.getElementById(targetId);
      if (targetElem) {
        copyToClipboard(targetElem.innerText);
        showToast("Copied command to clipboard!");
        btn.innerText = "Copied!";
        setTimeout(() => (btn.innerText = "Copy"), 2000);
      }
    });
  });
}

function copyToClipboard(text) {
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(text);
  } else {
    const textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      document.execCommand("copy");
    } catch (err) {}
    textArea.remove();
  }
}

function showToast(message) {
  const container = document.getElementById("toastContainer");
  if (!container) return;

  const toast = document.createElement("div");
  toast.className = "toast";
  toast.innerHTML = `
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
      <polyline points="20 6 9 17 4 12"/>
    </svg>
    <span>${escapeHtml(message)}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.animation = "slide-in 0.3s reverse forwards";
    setTimeout(() => toast.remove(), 300);
  }, 2500);
}

/* ==========================================================================
   6. MOBILE NAVIGATION DRAWER
   ========================================================================== */
function initMobileNav() {
  const btn = document.getElementById("mobileMenuBtn");
  const nav = document.getElementById("navLinks");
  if (!btn || !nav) return;

  btn.addEventListener("click", () => {
    nav.classList.toggle("open");
  });

  nav.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", () => {
      nav.classList.remove("open");
    });
  });
}

/* Helper */
function escapeHtml(str) {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
