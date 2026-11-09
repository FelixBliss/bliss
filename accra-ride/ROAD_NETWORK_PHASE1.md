# AccraRide Phase 1 — Simplified Road Network

## Scope
Build a compact, connected road graph for major Accra destinations—not every street. The initial network starts around Kwame Nkrumah Circle and connects selected central and western corridors. Expand toward Achimota/Lapaz, Airport/37, Tema, Osu and the coastal corridor only after the core is validated.

## Phase 1 graph candidates
- N01 — Kwame Nkrumah Circle / Neoplan
- N02 — Ring Road Central corridor
- N03 — Obetsebi Lamptey interchange
- N04 — Kaneshie
- N05 — Accra Central / Kwame Nkrumah Avenue
- N06 — Ako Adjei interchange
- Expansion nodes: Apenkwa/Achimota, Airport/37, Tetteh Quarshie, Tema, Osu and coastal corridor

These are candidate graph nodes, not yet a validated turn-by-turn network. Interchange ramps and road approaches must be simplified into playable junctions while preserving real corridor connectivity.

## Geometry provenance and status
OpenStreetMap references checked:
- Kwame Nkrumah Circle: https://www.openstreetmap.org/way/11664610
- Ring Road Central segment: https://www.openstreetmap.org/way/11664763
- Map context: https://www.openstreetmap.org/#map=15/5.5695/-0.2158
- Accra Metropolitan Assembly GIS street finder: https://gis.berryict.com/gis/gis/ama/propertyidentification.php
- Department of Urban Roads, Greater Accra: https://dur.gov.gh/greater-accra-region/

The public OSM references confirm the named road features and provide map anchors, but the exact ordered centreline geometry for the full core route has not yet been imported and checked. Do not label any hand-authored curve as surveyed or map-accurate. When OSM geometry is imported, preserve attribution and comply with the OpenStreetMap ODbL.

## Curved-road prototype
`road-graph-prototype.html` is a separate mechanics sandbox. Its curve is deliberately test geometry, not a geographic reconstruction of Ring Road Central. It tests:
- road ribbon rendering through a curve
- player steering relative to the road tangent
- same-direction and opposing traffic following the same curve
- collision response while vehicles are on the curved path
- reset and mobile touch controls

The prototype is isolated from `3d-prototype.html` and `index.html`. It must not replace the current production driving page.

## Implementation gates
1. Validate the curved-road mechanics on Android landscape.
2. Import and inspect actual OSM centreline geometry for the first core corridor.
3. Replace test geometry with the verified centreline and add graph node/segment definitions.
4. Add one playable junction with explicit legal exits.
5. Regression-test steering, traffic following/overtaking, braking, collision response, reverse and RESET.
6. Expand the graph corridor by corridor.

No production changes, merge or production deployment are authorized by this plan.
