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

#### Practical checklist (pin to your monitor)

- No IO, Repo, DateTime.utc_now/0, System.*, :rand, send/2 inside core modules.
- Core returns data & results, never performs effects.
- Effects live in adapters that implement behaviours.
- GenServers delegate to a pure reducer.
- Tests for core are pure & blazing fast (property-based with StreamData).
- Seeds/clocks/UUIDs passed in.
- Data is plain structs; APIs are small & orthogonal.
- Errors are values ({:error, reason}), not raises.

#### Paradigms & tools that map well

- Algebraic thinking: Make illegal states unrepresentable (structs + smart constructors).
- Pipelines & combinators: tiny fns that compose (then/2 helpers for {:ok, _} chains).
- State machines: encode states & allowed transitions (pure apply/2).
- Event calculus: “What happened?” not “What is.”
- Property-based testing: enforce invariants as properties.
- Data-first design: start from the data model; functions are transformations over it.

#### Where purity stops (and that’s okay)

- Talking to the outside world: DB, HTTP, filesystem, message buses.
- Real time: clocks, timers, Process.send_after.
- Randomness & IDs.
- Shared in-memory state (ETS, Agent) and processes themselves.

#### Core

- Does this function always give the same result if I give it the same input?
- Does this code avoid sneaky stuff like printing, saving to the database, or grabbing the current time/date?
- Is all the messy “real-world” work (saving, emailing, logging, randomness) pushed to the edges instead of mixed inside?
- If I swap out one outside service (like clock or database), is it easy?
- Can I test the main logic without starting the app or a database?

#### State & Processes

- If this piece holds state (like a GenServer), is the actual decision-making written as a simple “given state + input -> new state + output”?
- Are those “wrappers” around the state machine small and dumb?
- Is the state stored as a plain map/struct, not hidden in some global thing?
- Does time/timers only live at the outer layer, not buried inside?
- Can I play through a whole series of steps without spinning up actual processes?

#### Data Safety

- Can the data ever get into an “impossible” or “nonsense” shape?
- Are all the valid states clearly written down (e.g. status can only be new, paid, or canceled)?
- Do we check that lists/collections actually hold the right kind of stuff?
- When behavior depends on type of data, is it obvious and clean?
- Do we check important rules in one place, not scattered everywhere?

#### Handling Problems

- Do functions say clearly whether they worked or failed (no surprises)?
- Are exceptions rare and only used for truly unexpected crashes?
- Do we chain steps cleanly (not nested if/else jungles)?
- Are error reasons short and predictable, not random strings?
- Is logging only happening at the “edges” where we touch the real world?

#### Time, IDs, Randomness

- When we need “now” or “a new ID,” do we pass it in instead of grabbing it magically?
- Is randomness controlled so tests always run the same way?
- Do we get IDs through a helper, not straight from the system inside the core logic?
- Is time math always based on a value we pass in?
- Can we replay the same steps and always get the same result?

#### Events & History (if using events)

- Do we write down what happened (events) rather than jumping straight to side effects?
- Is state always rebuilt by replaying events?
- Are side effects (emails, saves) triggered after the events are decided?
- Are events stored in a clear, stable format?
- Can we rebuild everything just from the event history?

#### Dealing with Outside Systems

- For each outside thing (database, HTTP, file), do we have a small, clear adapter that just translates?
- Is there exactly one “real” adapter per outside thing in production?
- Do tests swap in fake adapters instead of calling the real thing?
- Do adapters turn weird system errors into simple, known errors?
- Are adapters skinny (no business rules in them)?

#### Small Lego Bricks

- Are most functions small enough to explain in one sentence?
- Can we snap them together like Lego pieces (pipe/compose)?
- Do we avoid doing real-world stuff in the middle of a pipeline?
- Do arguments and names line up in a consistent, predictable way?
- Could each function be described as a “command” over the data?

#### Testing

- Can we run core tests in milliseconds without a database?
- Do tests cover both “normal” cases and weird edge cases?
- Can we generate lots of random inputs to stress test the rules?
- Do tests assert both “good” and “bad” behavior?
- Can we simulate whole sequences of steps and still test them fast?

#### Observability

- Do we only log/measure things at the edges (not deep inside)?
- Do we carry IDs through so we can follow one request end-to-end?
- Can we see what went wrong without reading the code?
- Do metrics/logs talk in business words (“order failed”) not technical noise?
- Are logs structured (fields) instead of messy strings?
