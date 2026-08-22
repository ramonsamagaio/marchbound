# Frontier Contracts Pass

The Contract Board adds an optional persistent objective layer over the core expedition loop.

Current contract families:
- enemy kills;
- territory claims;
- expedition victories;
- guardian/boss kills;
- equipment recovery;
- Gold earned through expedition activity;
- reaching a higher Threat frontier.

Rules:
- up to three contracts can be active simultaneously;
- accepting a relative contract records the current stat baseline so old progress is not counted;
- absolute Threat contracts track the highest frontier reached;
- completed contracts are claimed manually for resources plus Renown;
- claiming a contract replenishes the board, creating a renewable long-term loop;
- the player can pay Gold to refresh the available board, creating a small economy sink;
- contract state persists separately in `user://marchbound_contracts.json` for the current browser/local MVP;
- the board is deliberately optional: it should create tempting side goals, not mandatory chores.

Validation target: Godot 4.7.2 parse, headless smoke and Web export.
