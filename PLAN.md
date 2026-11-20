# Nullgate's Poisons - Forever: Plan

Status: planning, with no code written yet. Planned on 2026-11-20.

- **Folder:** `NullgatesPoisons-Forever`
- **Saved variables:** `NullgatesPoisonsDB` (per character)
- **Commands:** `/npoison` and `/poisons`

## Decisions made

- Rogue only: the addon stays off for other classes.
- The addon never buys anything. Buying belongs to Nullgate's Restock.
- Poison and recipe data is generated from Forever client data (wago.tools), never typed by hand.
- Ships as 1.0.0-beta.1 for testers, like Food & Water.

## The constraint that shapes the design

Applying a poison is "use the poison item, then pick the weapon slot". That has to happen on a **secure button** set in advance (item plus target slot 16 or 17), and the item can only change **out of combat**. The addon re-picks the poison whenever your bags or choice change and queues changes made in combat until it ends.

---

## Phase 0: Repo and checks

- Repo, README, plan, license, logo, CurseForge workflow, `/zips` packaging, tests.
- `/npoison check` in-game self test. Confirm in the Forever client:
  - A secure button with an item and target slot applies the poison to that weapon.
  - What `GetWeaponEnchantInfo()` returns for time left and charges on each hand.

## Phase 1: Poison data

- Generator script: every poison item by type and rank, plus recipes (ingredients and counts).
- Bag scan for the highest rank of each type.
- Unit tests.

## Phase 2: Apply buttons

- Main Hand and Off Hand secure buttons with key bindings, icons and bag counts; movable, lockable bar.
- Poison type chosen per hand; right-click menu to switch (out of combat).

## Phase 3: Warnings

- Time and charges shown on each button.
- Warnings for no poison, under 5 minutes, under 10 charges (both limits configurable).

## Phase 4: Crafting counts, settings, languages, beta

- "Can craft" counts from ingredients in your bags, using the bundled recipe data.
- Settings window and Nullgate's Addon Config page.
- The 10 client languages.
- DESCRIPTION.md, CHANGELOG.md, 1.0.0-beta.1.
