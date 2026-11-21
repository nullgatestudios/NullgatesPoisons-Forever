# Nullgate's Poisons - Forever

> **Status: beta** (1.0.0-beta.1). Looking for rogues to test it. See [CHANGELOG.md](CHANGELOG.md).

**Nullgate's Poisons** is a rogue addon for **World of Warcraft: Forever**. Two buttons apply the poison you chose to each weapon at the highest rank you carry, and the addon warns you before a poison wears off or runs out of charges.

---

## How It Works

1. **Pick a poison for each hand**: Instant, Deadly, Crippling, Mind-numbing, Wound, or Forever's Numbing, Atrophic, Sebacious and Occult poisons.
2. **Click the Main Hand or Off Hand button** (or press its key binding).
3. **The addon applies the highest rank you carry** to that weapon.

Each button shows the poison's icon, the time and charges left on that weapon, and how many applications you have in your bags. Right-click a button to switch poisons. Buttons can't change in combat, so a switch made mid-fight waits until combat ends.

---

## Features

- **Main Hand and Off Hand buttons** with key bindings and a movable bar.
- **Expiry warnings** when a weapon has no poison, less than 5 minutes left, or fewer than 10 charges (you can change both limits).
- **Bag counts** for every poison type, and optionally how many more you could craft from the ingredients you carry.
- **Settings** in its own window or inside Nullgate's Addon Config.

The addon never buys anything. Use Nullgate's Restock to keep vials and poison ingredients stocked.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/npoison` or `/poisons` | Open the settings. |
| `/npoison lock` / `/npoison unlock` | Lock or unlock the bar. |
| `/npoison reset` | Reset the bar's position. |
| `/npoison check` | Test what the addon needs in your game client and save the results. |

---

## Installation

Not released yet. Once it is:

1. Download the latest release from CurseForge or the GitHub releases page.
2. Extract the `NullgatesPoisons-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a rogue and type `/npoison`.

---

## Part of the Nullgate Addon Suite

- **Nullgate's Addon Config**: one settings hub and profile manager for the whole suite.
- **Nullgate's Restock**, **Quest Tracker**, **Unit Toggles**, **Blacklist** and more.

---

## Development

| Task | Command |
| :--- | :--- |
| Refresh the poison data after a client patch | `python tools/generate_poison_data.py` (reads the latest Forever build from wago.tools) |
| Run the tests | `lua tests/run.lua`, `lua tests/smoke.lua` and `lua tests/locales.lua` |
| Build `zips/NullgatesPoisons-Forever-<version>.zip` | `.\package.ps1` (or `.\package.ps1 -Version 1.0.0` to set the version first) |

Publishing a GitHub release uploads that version to CurseForge (`.github/workflows/curseforge.yml`); pushes only run the tests.

---

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
