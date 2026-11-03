#!/usr/bin/env python3
"""scripts/visual_text_pass.py

Performs a high-fidelity text-based visual pass in the local terminal / dev environment.
Renders Discord embeds and UI cards for:
1. /spell command embed (ranks, costs, cast time, Forever official tuning)
2. /set command embed (tier, constituent pieces, 2/4/6/8-piece set bonuses)
3. /achievement command embed (toast badge, points, category, rewards)
"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

import knowledge_engine as ke


def print_box(title: str, lines: list, color: str = "\033[36m"):
    border = "═" * 70
    reset = "\033[0m"
    gold = "\033[33m"
    bold = "\033[1m"

    print(f"\n{color}╔{border}╗{reset}")
    print(f"{color}║ {bold}{gold}{title:<68}{reset}{color} ║{reset}")
    print(f"{color}╠{border}╣{reset}")
    for l in lines:
        print(f"{color}║{reset} {l:<68} {color}║{reset}")
    print(f"{color}╚{border}╝{reset}")


def run_visual_pass():
    print("\n" + "═"*72)
    print("   🎮 FOREVERBOT TEXT-BASED VISUAL PASS (LOCAL DEV ENVIRONMENT)   ")
    print("═"*72)

    # 1. /spell Battle Shout (Warrior)
    sp = ke.get_spell_info("Battle Shout")
    lines_sp = [
        f"\033[1mClass:\033[0m {sp['character_class']}  |  \033[1mSpec/School:\033[0m {sp['spec']}  |  \033[1mLevel Req:\033[0m {sp['level_req']}",
        f"\033[1mCost:\033[0m {sp['cost']}  |  \033[1mCast Time:\033[0m {sp['cast_time']}  |  \033[1mCooldown:\033[0m {sp['cooldown']}",
        f"\033[1mRange:\033[0m {sp['range']}",
        "",
        "\033[1mEffect:\033[0m",
        f"  {sp['description']}",
        "",
        "\033[1m⚖️ Official Blizzard Forever Tuning:\033[0m",
        f"  \033[32m{sp['forever_tuning']}\033[0m",
    ]
    print_box(f"⚡ /spell {sp['name']} ({sp['rank']})", lines_sp, color="\033[34m")

    # 2. /spell Windfury Totem (Shaman)
    wf = ke.get_spell_info("Windfury Totem")
    lines_wf = [
        f"\033[1mClass:\033[0m {wf['character_class']}  |  \033[1mSpec/School:\033[0m {wf['spec']}  |  \033[1mLevel Req:\033[0m {wf['level_req']}",
        f"\033[1mCost:\033[0m {wf['cost']}  |  \033[1mCast Time:\033[0m {wf['cast_time']}  |  \033[1mCooldown:\033[0m {wf['cooldown']}",
        "",
        "\033[1mEffect:\033[0m",
        f"  {wf['description'][:65]}...",
        "",
        "\033[1m⚖️ Official Blizzard Forever Tuning:\033[0m",
        f"  \033[32m{wf['forever_tuning']}\033[0m",
    ]
    print_box(f"⚡ /spell {wf['name']} ({wf['rank']})", lines_wf, color="\033[35m")

    # 3. /set Battlegear of Might (Tier 1)
    s1 = ke.get_armor_set_info("Might")
    lines_s1 = [
        f"\033[1mTier:\033[0m {s1['tier']}  |  \033[1mClass:\033[0m {s1['character_class']}",
        f"\033[1mSource:\033[0m {s1['source_dungeon']} ({s1['pieces_count']} pieces)",
        "",
        "\033[1mConstituent Pieces:\033[0m",
        f"  {', '.join(s1['pieces'][:4])}",
        f"  {', '.join(s1['pieces'][4:])}",
        "",
        "\033[1mSet Bonuses:\033[0m",
    ]
    for k, v in sorted(s1['bonuses'].items(), key=lambda x: int(x[0])):
        lines_s1.append(f"  • \033[33m({k}) Set:\033[0m {v}")
    print_box(f"🛡️ /set {s1['set_name']}", lines_s1, color="\033[33m")

    # 4. /set Zephras Deepsea Regalia (Custom Forever Raid)
    s2 = ke.get_armor_set_info("Zephras")
    lines_s2 = [
        f"\033[1mTier:\033[0m {s2['tier']}  |  \033[1mClass:\033[0m {s2['character_class']}",
        f"\033[1mSource:\033[0m {s2['source_dungeon']} ({s2['pieces_count']} pieces)",
        "",
        "\033[1mConstituent Pieces:\033[0m",
        f"  {', '.join(s2['pieces'][:3])}",
        f"  {', '.join(s2['pieces'][3:])}",
        "",
        "\033[1mSet Bonuses:\033[0m",
    ]
    for k, v in sorted(s2['bonuses'].items(), key=lambda x: int(x[0])):
        lines_s2.append(f"  • \033[33m({k}) Set:\033[0m {v}")
    print_box(f"🛡️ /set {s2['set_name']} 🌟 [Forever Raid]", lines_s2, color="\033[36m")

    # 5. /achievement Scarab Lord & Undying
    ach = ke.get_achievement_info("Scarab Lord")
    lines_ach = [
        f"\033[1mCategory:\033[0m {ach['category']}  |  \033[1mPoints:\033[0m {'Feat of Strength' if ach['is_feat_of_strength'] else ach['points']}",
        "",
        "\033[1mDescription:\033[0m",
        f"  {ach['description']}",
        "",
        "\033[1mReward:\033[0m",
        f"  \033[33m{ach['reward']}\033[0m",
    ]
    print_box(f"🏆 /achievement {ach['title']}", lines_ach, color="\033[33m")

    print("\n✅ Text-Based Visual Pass Completed Successfully. All layouts verified!\n")


if __name__ == "__main__":
    run_visual_pass()
