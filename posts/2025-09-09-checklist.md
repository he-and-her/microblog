---
title: checklist
datetime: 2025-09-09 09:19:00
id: no-response
---

#### Practical checklist (pin to your monitor)

- No IO, Repo, DateTime.utc_now/0, System.*, :rand, send/2 inside core modules.
- Core returns data & results, never performs effects.
- Effects live in adapters that implement behaviours.
- GenServers delegate to a pure reducer.
- Tests for core are pure & blazing fast (property-based with StreamData).
- Seeds/clocks/UUIDs passed in.
- Data is plain structs; APIs are small & orthogonal.
- Errors are values ({:error, reason}), not raises.
