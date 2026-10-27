# AccraRide Technical Blueprint

**Status:** Draft baseline for staged development  
**Game source baseline:** accra-ride/3d-prototype.html on master  
**Current baseline commit:** 3d66c718cd623be68d435c613e4f86cd826d6a7a  
**Rule:** Do not replace the working driving prototype with a large rewrite. Implement and verify small, reversible changes.

## 1. Product goal

Build a mobile-first 3D driving game set in Accra. The player drives a passenger vehicle through a connected road network, collects passengers, follows routes, avoids collisions and traffic, reaches destinations before deadlines, earns fares/coins, and progresses through districts and upgrades.

The game must remain usable on Android touchscreens in landscape orientation. The current HTML/Three.js prototype is a baseline to preserve, not proof that every required system is complete or tested.

## 2. Engineering principles

1. **Foundation before scale:** prove each core system in a small test district before expanding the map.
2. **One bounded change per task:** state the change, files touched, acceptance checks, and rollback point before implementation.
3. **Contracts before parallel work:** define shared data types and interfaces before separate systems or contributors work in parallel.
4. **Single source of truth:** road geometry, navigation, traffic, signals, and mission destinations must refer to the same road-network data.
5. **No duplicate world models:** do not build one road representation for visuals and a disconnected representation for navigation/traffic.
6. **Keep working behavior:** extend the existing prototype incrementally; do not replace working code without evidence that a replacement is necessary.
7. **Deploy is not gameplay verification:** HTTP success and a ready deployment are not proof of correct Android gameplay.
8. **Every phase has a gate:** do not start the next phase until its acceptance checks pass or an explicit exception is documented.
9. **Regression checks after relevant changes:** startup, controls, steering, braking, traffic, collisions, and mobile layout must not silently break.
10. **Keep the baseline recoverable:** commit known-good milestones and record the production deployment associated with them.

## 3. Target system boundaries

These are logical boundaries first. They do not require immediately splitting the current HTML into multiple files. Refactor only when a module has a stable contract and the extraction can be tested safely.

### A. Game bootstrap and lifecycle
Responsibilities: load dependencies, initialize renderer/scene/world, show startup errors, handle start/restart/pause, resize, and cleanly report initialization failures.

Contract:
- initializeGame() either returns an initialized game or reports a visible actionable error.
- startGame() is idempotent and cannot accidentally create duplicate loops/listeners.
- A failed external dependency (for example, Three.js CDN unavailable) must not leave a dead Start button without an explanation.

### B. World and road network
The road network is canonical gameplay data, not just decorative meshes.

Core concepts:
- RoadNode: stable ID, world position, node type (junction, endpoint, merge, split), connected edge IDs.
- RoadEdge: stable ID, from/to node IDs, road class, direction policy, speed limit, lane groups, and ordered centerline points.
- Lane: stable ID, parent edge ID, travel direction, lateral offset, lane type, and permitted vehicle classes.
- JunctionConnection: incoming lane to outgoing lane mapping and any signal/priority rule.
- Crossing: position/extent, connected sidewalks, crossing state and pedestrian crossing rules.

Road visuals, lane centerlines, AI paths, navigation routes, and destination placement must be derived from these shared objects. Avoid independently hard-coding each system's road positions.

### C. Vehicle movement and collision
Responsibilities: player input, acceleration, braking, reverse, steering, vehicle limits, lane-relative position, collision shapes, and response to collisions.

Contract:
- Controls produce a vehicle intent; the movement system updates vehicle state.
- Vehicle state exposes position, heading, speed, current lane/edge, and dimensions needed by traffic and collision systems.
- Collision detection must use consistent world coordinates and vehicle bounds.
- The player must not pass through traffic without detection; traffic must not occupy opposing lanes illegally during overtaking.

### D. Traffic AI
Responsibilities: vehicle and motorbike spawning, lane following, desired speed, safe following distance, lane changes, overtaking, junction behavior, traffic queues, and traffic-light compliance.

Contract:
- Every traffic agent follows a valid lane path from the road graph.
- Lane changes require a legal target lane and sufficient safe gap.
- Agents stop at red signals and resume only when permitted.
- Congestion results from vehicles interacting on the same network, not from unrelated visual tricks.

### E. Navigation
Responsibilities: route search, current route, next turn, destination, distance-to-turn, off-route detection, and recalculation.

Contract:
- Routing operates on road graph edges and legal junction connections.
- Route output is an ordered sequence of edge/lane connection IDs plus guidance metadata.
- Guidance, map/minimap, and destination markers consume the same route result.
- If no legal route exists, explain that state instead of silently generating a false route.

### F. Missions and economy
Responsibilities: mission states, pickup/drop-off, deadline, fare calculation, rewards, missed-mission recovery, coins, progression, and mission UI.

Mission state lifecycle:
available -> accepted -> pickup_reached -> passenger_onboard -> completed
Alternative outcomes: missed, cancelled, or failed, with the agreed recovery behavior.

Contract:
- Pickup and destination attach to valid road-accessible points, not arbitrary coordinates on inaccessible terrain.
- Mission deadlines use one consistent game-time source.
- Fare/reward changes happen once per valid state transition; restarting or re-rendering the UI must not award duplicate coins.
- Missed missions follow an explicit recovery rule and do not permanently block progression.

### G. Save data and settings
Responsibilities: persist only the minimum required game progress, coins, unlocked content, settings, and versioned save data locally at first.

Contract:
- Save data has a schema version and safe defaults.
- Invalid or older save data is handled without crashing the game.
- Persistence is not introduced until the gameplay state that must be saved is clearly defined.

### H. UI, audio, and presentation
Responsibilities: touch controls, HUD, route guidance, mission cards, settings, audio feedback, visual polish, accessibility, and responsive landscape layout.

Contract:
- UI displays state from game systems; it does not become a second source of truth.
- Input controls must reliably release on pointer cancellation/focus loss.
- Touch targets and text remain usable on common Android screen sizes.

## 4. Canonical road-data rules

1. Use stable IDs for nodes, edges, lanes, junctions, signals, crossings, and destinations.
2. Represent each road as connected directed edges. Two-way roads use explicit legal travel directions; do not infer direction from visual appearance alone.
3. Store ordered centerline points per edge. Lane centerlines are derived from edge geometry and lane offsets.
4. Junctions explicitly describe legal lane-to-lane movements. Do not let pathfinding or traffic guess which exits are allowed.
5. Traffic signals attach to junction movements or controlled stop lines, not to an unrelated visual prop.
6. Pedestrian crossings connect sidewalk areas and specify where vehicles must yield/stop.
7. Destination and pickup locations reference a road edge/lane or a valid access point.
8. Visual meshes can be regenerated from road data; gameplay should not depend on manually positioned mesh objects.
9. Build and test one compact district before scaling up to more Accra districts.
10. Avoid real-world map-data integration until the internal road graph and routing contract are proven. The first road network may be hand-authored but must follow the same model.

## 5. Implementation roadmap and phase gates

### Phase 0 — Stabilize and document the prototype
**Goal:** retain the current highway/overtaking baseline and establish reliable startup and a repeatable test process.

Tasks:
- Inspect the actual Start Driving path and dependency loading before changing code.
- Test on Android in landscape and record exact result/errors.
- Fix only a demonstrated startup/control failure at a time.
- Record existing features and missing features accurately.
- Add lightweight diagnostics for initialization errors if needed.

Gate:
- Start Driving works repeatedly on Android.
- Scene and controls initialize without a blank/frozen game.
- Steering, acceleration, braking, gear selection, camera and restart (if present) behave as specified.
- Existing traffic/overtaking and collision behavior remain intact.
- No claim of completion without user device confirmation and a source-level review.

**Important:** passenger missions and deadline systems are not present in the restored baseline; they are planned features, not a reason to discard the baseline.

### Phase 1 — Architecture contracts and small technical tests
**Goal:** turn the blueprint into concrete data/interface definitions before building the world.

Tasks:
- Define and validate the road graph schema and lane/junction connection rules.
- Define vehicle state, traffic agent, route result, mission, and save-data shapes.
- Create a tiny sample graph and tests for connected roads, legal turns, and route reachability.
- Decide module boundaries based on the current code and extract only the smallest safe unit if useful.

Gate:
- Sample graph validates.
- Route test can find a legal path and rejects an impossible path.
- Existing prototype still starts and drives after any refactor.
- Contracts are documented before parallel implementation.

### Phase 2 — Compact Accra test district and road graph
**Goal:** build a small playable area with reusable roads.

Tasks:
- Straight road, curved segment, four-lane section, opposing directions, intersection, turn connections, sidewalks and zebra crossing.
- Derive road meshes and lane centerlines from the graph.
- Add debug overlays for node IDs, lane centerlines, directions and junction connections.

Gate:
- All road ends connect as intended.
- Every lane has a valid direction and neighbor/connection data.
- The player can drive through the sample junction without falling off the road or crossing into an illegal lane.

### Phase 3 — Navigation and map guidance
**Goal:** use the graph to find and display routes.

Tasks:
- Shortest/weighted legal route between road-accessible points.
- Destination marker, next-turn instruction, distance-to-turn, route line/minimap.
- Off-route detection and recalculation.

Gate:
- Route follows connected legal edges.
- Turning at junctions matches the route.
- Unreachable destinations are handled clearly.
- Map, guidance, and destination marker agree on the same route.

### Phase 4 — Vehicle and controls integration
**Goal:** align player driving and collision with the road model.

Tasks:
- Lane-relative steering and vehicle bounds.
- Stable acceleration, braking, reverse and camera behavior.
- Safe mobile pointer handling and audio controls.

Gate:
- No unintended lane teleportation or uncontrolled drift.
- Collision checks are repeatable.
- Touch controls work across a sustained Android play session.

### Phase 5 — Traffic, signals, and pedestrians
**Goal:** move AI actors on the same graph.

Tasks:
- Cars and motorbikes, speed variation, safe following, legal lane changes/overtaking.
- Junction queues, traffic lights, congestion, pedestrian crossings and yielding.

Gate:
- Traffic stays in legal lanes and follows valid connections.
- Vehicles obey red lights and avoid overlapping traffic.
- Overtaking has a safe return path.
- Pedestrians cross at crossings and do not wander through arbitrary road areas.

### Phase 6 — Passenger missions and economy
**Goal:** implement the core AccraRide gameplay loop.

Tasks:
- Pickup/drop-off points, passenger boarding, destinations, deadlines, fares, coins, missed-mission recovery and progression.
- Mission UI and navigation integration.

Gate:
- A complete pickup-to-drop-off mission can be played.
- Each reward is applied exactly once.
- Missed deadlines and recovery follow documented rules.
- All mission destinations are reachable through navigation.

### Phase 7 — Progression and content expansion
**Goal:** add districts, unlocks, vehicle choices, upgrades and increasing challenge.

Gate:
- Unlock conditions and costs are deterministic and persisted correctly.
- New content uses existing road, traffic, mission and economy systems without special-case rewrites.

### Phase 8 — UI, audio, and environmental polish
**Goal:** improve presentation without changing core state rules.

Tasks: HUD, map controls, settings, lights/indicators, engine/brake/horn audio, ambience, feedback and accessibility.

Gate: core gameplay remains correct with UI/audio features enabled or disabled.

### Phase 9 — Persistence, performance, and release QA
**Goal:** stabilize the full game and prepare a release candidate.

Tasks:
- Versioned local save data, performance profiling, asset/dependency resilience, Android regression matrix, bug triage and release checklist.

Gate:
- Fresh start, normal play, reload, and recovery paths pass.
- No known blocker-level bugs.
- Deployment and device tests are recorded separately.

## 6. Required change workflow

For every implementation task:

1. **Baseline:** identify the exact Git commit and live deployment to preserve.
2. **Diagnosis:** reproduce or inspect the issue; state evidence before editing.
3. **Scope:** list the intended behavior and files to change.
4. **Acceptance criteria:** write observable pass/fail checks first.
5. **Implementation:** make one bounded change.
6. **Static checks:** inspect syntax, identifiers, event paths, and relevant logic; run automated checks when available.
7. **Deploy:** create a preview or controlled deployment; do not overwrite a known-good production version unnecessarily.
8. **Verify:** check HTTP/deployment health and ask for Android gameplay confirmation where device behavior is involved.
9. **Regression:** run the relevant core checklist.
10. **Record:** update the stage log with commit, deployment, test evidence, remaining issues, and next step.
11. **Promote:** proceed only after the phase gate passes or an explicit unresolved risk is accepted.

## 7. Minimum regression checklist

- [ ] Start screen renders and Start Driving responds.
- [ ] No dependency-load or initialization error is hidden.
- [ ] Landscape orientation and mobile viewport behave correctly.
- [ ] Steering responds and recenters/release behavior is correct.
- [ ] Acceleration, braking, reverse, and gear restrictions behave correctly.
- [ ] Camera controls work.
- [ ] Traffic stays in its intended direction and lane.
- [ ] Overtaking does not produce illegal lane occupancy.
- [ ] Player/traffic collisions are detected consistently.
- [ ] Traffic lights and pedestrian rules remain correct when implemented.
- [ ] Mission pickup/drop-off, deadline, and reward transitions remain correct when implemented.
- [ ] Reload/save behavior remains correct when implemented.
- [ ] Existing known-good behavior has not regressed.

Mark checks as **not implemented**, **not tested**, **pass**, or **fail**. Do not treat “not tested” as “pass.”

## 8. Current known state

Based on source inspection of the restored accra-ride/3d-prototype.html:
- Present in source: Three.js scene, touch-oriented driving controls, two-way highway traffic, lane changes/overtaking logic, traffic signal visual/timing logic, collision/coin penalty, camera modes, lights and horn audio logic.
- Not present in the restored version: a full road graph, graph-based navigation, complete passenger pickup/drop-off missions, and a mission deadline/recovery system.
- Not confirmed by source inspection alone: reliable Start Driving on the user's Android device, sustained-session stability, collision quality in live play, and real-world usability.
- Current production baseline was previously reported as deployment-ready and HTTP 200; this is a delivery check, not a device gameplay pass.

## 9. Immediate next action

Do not start Phase 2 world-building yet. First complete the Phase 0 Android startup test and inspect the startup path. Then define Phase 1 contracts and a tiny sample road graph. Keep the existing driving prototype intact while we validate the foundations.
