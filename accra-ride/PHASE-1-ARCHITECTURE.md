# AccraRide — Phase 1 Architecture and Road-System Foundation

Status: **In progress**  
Branch: `accraride/branching-road-network`  
Production: unchanged. This document defines contracts; it does not replace the master game or merge prototypes.

## Phase 1 objective

Establish one shared, data-driven world model for roads, lanes, junctions, vehicles, routes, missions and save data. Navigation, traffic signals, AI road users and passenger missions must consume this same model rather than inventing separate road logic.

## 1. Coordinate and identity conventions

- World coordinates: Three.js world space; X = east/west, Y = height, Z = north/south.
- Road graph IDs are stable strings, not array indexes.
- Every road segment has a stable ID, start node ID and end node ID.
- Geometry is presentation data derived from the graph; graph connectivity is authoritative.
- Distances are metres; speeds are metres/second internally. Convert to km/h only for HUD display.
- Forward direction of an edge is A → B. Reverse travel is B → A.

## 2. Road graph contract

A road network contains:
- `networkId`, `version`, `nodes[]`, `edges[]`, and optional metadata.
- A node has `id`, `position{x,y,z}`, `type` (junction, terminal, waypoint), and `connectionIds[]`.
- An edge has `id`, `fromNodeId`, `toNodeId`, `geometry[]`, `lengthM`, `roadClass`, `speedLimitKmh`, `lanes[]`, and `allowedVehicleTypes[]`.
- An edge is traversable only when the vehicle type is allowed and the lane/direction rules permit it.
- Geometry must start at the from-node and end at the to-node. Reversing direction reverses geometry and tangent.
- No runtime system may infer a junction merely because two rendered road meshes visually overlap. Connectivity must be explicit in graph data.

## 3. Lane contract

Each lane has:
- Stable `id`, parent `edgeId`, `direction` (forward/reverse), `index`, `widthM`, `laneType` (driving, turning, shoulder), and optional `turnPermissions[]`.
- Lane centreline is derived from the road centreline and lane offset.
- Traffic stays in its lane except during a legal graph-defined lane-change manoeuvre.
- Lane changes have start/end lane IDs, duration, and a safe-gap check; they cannot teleport a vehicle across lanes.
- Opposing directions must be represented separately, not as a single undirected traffic lane.

## 4. Junction contract

A junction owns:
- `nodeId`, connected edge/lane movements, conflict groups, and optional control type (uncontrolled, give-way, stop, signalised, roundabout).
- A movement is an explicit incoming-lane → outgoing-lane connection.
- Vehicles may select only movements present in the junction definition.
- Signal phases and right-of-way rules will be added in the traffic phase; the graph must already expose the movement/conflict structure.
- Dead ends are valid only when explicitly marked terminal. Loop connections must not be fabricated from visual proximity.

## 5. Vehicle state contract

Shared vehicle state:
- `id`, `vehicleType`, `position`, `headingRad`, `speedMps`, `accelerationMps2`, `currentEdgeId`, `currentLaneId`, `edgeProgress01`, `travelDirection`, `targetSpeedMps`, `routeId`, `routeCursor`, `collisionState`.
- Controls are inputs (steer, throttle, brake, gear); physics owns speed and position updates.
- Internally store SI units. UI converts speed to km/h.
- Forward/reverse gear, acceleration, coasting, braking, curved-road steering and collision recovery must follow the accepted master/curved prototype behaviour.
- Player and AI use the same vehicle-state representation, with different control policies.
- A collision changes velocity/state; it must not delete either vehicle. AI recovery is gradual. Vehicles remain in the simulation until they are sufficiently far outside the active camera/simulation range and safe to despawn.

## 6. Route contract

A route is an ordered list of directed edge/lane movements:
- `id`, `networkId`, `startNodeId`, `destinationNodeId`, `steps[]`, `totalDistanceM`, `status`.
- Each step identifies `edgeId`, `direction`, `laneId`, and the junction movement to the next step.
- Route validation checks continuity: each step's exit node equals the next step's entry node.
- Re-routing may replace remaining steps, but must preserve the vehicle's current valid position and lane.
- Map guidance and turn instructions are derived from the route; they do not maintain a second road network.

## 7. Mission contract

A passenger mission is data attached to the same route system:
- `id`, `pickupNodeId`, `dropoffNodeId`, `routeId`, `deadlineAt`, `fare`, `rewardCoins`, `status`.
- Status values: available, accepted, goingToPickup, passengerOnboard, completed, expired, cancelled.
- Pickup/drop-off points must resolve to valid graph nodes or explicit roadside stops connected to the graph.
- Mission distance and ETA are computed from valid route steps, not straight-line distance.

## 8. Save-data contract

- Save payload includes `schemaVersion`, `savedAt`, player progression, currency, settings, and active mission state.
- Save data must not persist transient render objects, Three.js meshes, or live object references.
- Migrations are required when schemaVersion changes; unknown future versions must not be overwritten.
- Local save is authoritative for the offline-first game; cloud sync can be layered on later without changing the schema.

## 9. System boundaries

- Road graph: authoritative connectivity and road metadata.
- Road geometry renderer: draws graph data only.
- Vehicle physics: updates vehicle state from control inputs.
- Player controller: maps touch/keyboard controls to control inputs.
- AI controller: chooses graph-valid route movements and safe speeds.
- Navigation: computes routes and guidance from the graph.
- Traffic system: controls junction right-of-way, signals, congestion and lane changes.
- Mission/economy system: consumes routes and vehicle arrival events.
- Save system: serializes versioned game state only.

No subsystem should directly mutate another subsystem's private state. Exchange typed state/events through defined interfaces.

## 10. Phase 1 acceptance criteria

1. Every road segment has stable IDs and explicit endpoint nodes.
2. Every junction movement is graph-valid; no AI chooses a non-connected road.
3. Forward and reverse lanes are represented explicitly.
4. A route can be validated from start to destination and rejected if disconnected.
5. Player and AI vehicle states use the same units and field conventions.
6. The same vehicle can traverse straight and curved edges without a speed/heading discontinuity at joins.
7. Collision recovery does not delete vehicles or reset the player's speed to zero without a defined stop condition.
8. Mission pickup/drop-off references resolve to the graph.
9. Save data can be serialized, loaded and migrated by schema version.
10. Master and curved prototype behaviour remains preserved as the reference; production remains unchanged until explicit approval.

## 11. Work sequence

- **1A — Contracts:** this document and matching typed data definitions.
- **1B — Graph validation:** connectivity, lane direction, junction movement and route-continuity validators.
- **1C — Small reference network:** a small connected straight/curved/junction network that exercises all contracts.
- **1D — Vehicle traversal:** run player and AI state through the reference network, including collision/recovery regression checks.
- **1E — Acceptance:** record test results before expanding the Accra road network or starting navigation/traffic features.

## Non-goals for Phase 1

Do not implement passenger economy, map UI, full Accra geography, traffic lights, pedestrian simulation, or production integration in this phase. Their interfaces are defined now so they can be added later without replacing the road model.
