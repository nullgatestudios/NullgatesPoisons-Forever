# Changelog

All notable changes to Nullgate's Poisons - Forever.

## [1.0.0-beta.3] - 2026-11-27

### New

- **Part of Nullgate's Buffs.** Nullgate's Poisons is now also a module of the all-in-one **Nullgate's Buffs**. If you have both, Poisons runs and they share your settings, so a change in one carries over to the other.

## [1.0.0-beta.2] - 2026-11-24

### New

- **Bug report window.** `/npoison check` now opens a window with its report, ready to copy.
- Press Ctrl+C to copy the report, then paste it into the report form at nullgatestudios.com/report?addon=poisons, which opens with this addon already picked. You can report without an account.
- Every Nullgate addon now uses the same report window.

### Good to know

- The game doesn't let addons open a web browser, so type or copy the link into your browser yourself. The **Select link** button selects it for copying.

## [1.0.0-beta.1] - 2026-11-20

First test version, looking for rogues to try it.

### New

- **Main Hand and Off Hand buttons**: left-click applies your chosen poison at the highest rank you carry and can use. Right-click opens a menu to choose the poison, showing how many of each you carry.
- **Every poison type** in Forever: Instant, Deadly, Crippling, Mind-numbing, Wound, Numbing, Atrophic, Sebacious and Occult, read from the client data.
- **What's on each weapon**: the buttons show the time and charges left, and the tooltip names the poison.
- **Warnings** when a weapon has no poison, less than 5 minutes left or fewer than 10 charges (both limits can be changed or turned off), as a chat line, a sound or a glow on the button. Only for hands with a weapon, and only when you carry the poison.
- **Crafting count** (optional): the tooltip shows how many more you could craft from the reagents you carry.
- **Key bindings** for both buttons under Key Bindings > AddOns.
- **Settings** in its own window or inside Nullgate's Addon Config.
- **`/npoison check`**: tests what the addon needs in your client and reports what changes on each weapon when you apply a poison. Results are saved for bug reports.
- Available in English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文.

### Good to know

- Buttons can't change during combat. A poison chosen mid-fight is set as soon as combat ends.
