# MRT Companion — Smart Commuter Companion (PS2)

> Built strictly against Problem Statement 2 (Smart Commuter Companion) using designated public Singapore data sources.  
> **Target Stack**: Flutter Web (`flutter build web`)  
> **Personas**: **Rachel** (Fixed-schedule commuter) & **Mdm Lim** (Accessibility-constrained commuter)

---

## 🚀 Currently Working Features (Logic & Architecture)

### 1. Canonical Transit Network & Complete 182-Station Database
- **Files**: [`lib/core/transit/canonical_line_table.dart`](lib/core/transit/canonical_line_table.dart), [`assets/data/all_mrt_stations.json`](assets/data/all_mrt_stations.json)
- **Complete Island-Wide Coverage**:
  - Expanded from initial sample to **all 182 operational Singapore MRT and LRT stations**:
    - East-West Line (`EWL`), Changi Airport Branch (`CGL`), North-South Line (`NSL`), North East Line (`NEL`), Circle Line & Extension (`CCL`, `CEL`), Downtown Line (`DTL`), Thomson-East Coast Line (`TEL`), Bukit Panjang LRT (`BPL`), Sengkang LRT (`SLRT`), Punggol LRT (`PLRT`).
  - Derived from official URA Master Plan Rail Station polygon centroids ([`AmendmenttoMP2014RailStation.geojson`](assets/data/AmendmenttoMP2014RailStation.geojson)) and verified OpenStreetMap GIS nodes.
- **Elevation Classification (`GroundLevel`)**:
  - Every single station classified into official `underground` and `aboveGround` designations.
  - Normalizer handles dataset variations (`at-grade`, `elevated`, `subsurface`, `underground`).
  - Powers dead-reckoning logic when entering subterranean transit environments where satellite/cellular signals degrade.
- **Problem Solved**: Reconciles DataMall line code mismatches before joining data:
  | Transit Line | TrainServiceAlerts Code | Station Crowd Density (PCD) Code | Canonical Code |
  | :--- | :---: | :---: | :---: |
  | **Sengkang LRT** | `STL` | `SLRT` | `SLRT` |
  | **Punggol LRT** | `PTL` | `PLRT` | `PLRT` |
  | **Circle Line Extension** | `CCL` *(folded)* | `CEL` *(separate)* | `CEL` |
  | **Changi Airport Branch** | `EWL` *(folded)* | `CGL` *(separate)* | `CGL` |

---

### 2. Authentic Real-World Curved Railway Tracks & Geospatial Map Engine
- **Files**: [`web/leaflet_bridge.js`](web/leaflet_bridge.js), [`web/mrt_data.js`](web/mrt_data.js), [`assets/data/mrt_track_geometries.json`](assets/data/mrt_track_geometries.json), [`lib/core/map/leaflet_map_view.dart`](lib/core/map/leaflet_map_view.dart), [`lib/core/map/leaflet_web_impl.dart`](lib/core/map/leaflet_web_impl.dart)
- **Real Curved Railway Track Alignments**:
  - Traces the actual physical viaduct curves, tunnels, and line tracks using **~8,700 real-world GPS coordinates** extracted from OpenStreetMap relations/ways.
  - Multi-polyline rendering with dual-layer styling: high-contrast dark outer halo casing (`#0a0f1d`) + vibrant transit core lines.
- **Multicolor Pie-Chart Interchange Markers**:
  - Interchanges serving 2+ lines are dynamically rendered as multicolor pie charts using CSS `conic-gradient`, with slices proportional to each line served (e.g. Dhoby Ghaut, Raffles Place, Outram Park, Jurong East, Bishan), accented with a crisp white border and white center dot.
  - Normal stations are rendered as solid circles matching their line color.
- **Interactive Station Popups**:
  - Tapping any station reveals its name, all assigned station codes, badges for lines served, underground/elevated designation, and quick-action routing buttons (*"From here"* / *"To here"*).
- **Hard License Compliance**: Permanent, unremovable `"© OpenStreetMap contributors"` attribution displayed both in Leaflet tiles and as a persistent Flutter UI overlay badge.
- **Dynamic Route & Walkway Layers**:
  - **Normal Transit**: Solid Emerald Green (`#059669`).
  - **Disrupted Segments**: High-visibility dashed Red/Orange warning (`#dc2626`).
  - **Alternative Reroutes**: Dashed Sky Blue line (`#0284c7`).
  - **Sheltered Walkways**: Renders `CoveredLinkWay` paths for weather-aware routing.

---

### 3. Modern, Sleek, Minimalist UI Architecture
- **Files**: [`lib/features/landing/landing_screen.dart`](lib/features/landing/landing_screen.dart), [`lib/features/home/home_screen.dart`](lib/features/home/home_screen.dart)
- **Landing Screen**:
  - Dark glassmorphic aesthetic with custom high-contrast typography ("Where to NEXT?").
  - Seamless tap-anywhere transition to Home, with keyboard event listener support.
- **Home Screen**:
  - Minimalist `[placeholder [->]]` natural language journey query box with greyed placeholder and single arrow submit action.
  - Elegant white-gradient title typography for "LIVE NOWCAST" and search elements.
  - Real-time weather badge with live dynamic weather emoji and temperature.
  - Clean floating map touch controls positioned conveniently near the bottom action area.

---

### 4. LTA DataMall Integration Service
- **Files**: [`lib/core/services/lta_service.dart`](lib/core/services/lta_service.dart), [`lib/core/models/`](lib/core/models/)
- **`TrainServiceAlerts`**:
  - Parses nested `AffectedSegments`, directions, station codes, and advisory text.
  - Ingests official mitigation data: `FreeMRTShuttle` and `FreePublicBus`.
- **`PCDRealTime` & `PCDForecast`**:
  - Real-time station crowding (10-min interval: low, moderate, high).
  - 30-min-ahead forecast powering proactive advice before commuters leave home.
- **`v2/FacilitiesMaintenance`**:
  - Tracks lift outages down to specific stations and exits (essential for Mdm Lim).
- **`v3/BusArrival`**:
  - Tracks passenger load (`SEA` Seats Available, `SDA` Standing, `LSD` Limited Standing) and `Feature = WAB` (Wheelchair-Accessible Bus).
- **Security**: Zero committed credentials; keys are injected via `--dart-define=LTA_DATAMALL_KEY=...`.

---

### 5. data.gov.sg 2-Hour Weather Nowcast
- **File**: [`lib/core/services/weather_service.dart`](lib/core/services/weather_service.dart)
- Live government weather nowcast API (no API key required).
- Detects rain/thunderstorms for Singapore towns (e.g. Bedok, Outram, Tampines) to proactively reroute Mdm Lim through sheltered walkways.

---

### 6. OneMap Multi-Modal Door-to-Door Routing
- **File**: [`lib/core/services/onemap_service.dart`](lib/core/services/onemap_service.dart)
- Complete door-to-door paths including origin and destination walking legs, not just station-to-station.
- High-fidelity baseline paths for Rachel and Mdm Lim.

---

### 7. Central Transit Routing & Decision Engine
- **File**: [`lib/core/services/transit_routing_engine.dart`](lib/core/services/transit_routing_engine.dart), [`lib/core/services/natural_language_route_service.dart`](lib/core/services/natural_language_route_service.dart)
- **Natural Language Parsing**:
  - Parses queries like *"Take me from Tampines to Raffles Place"* or *"From Bedok to SGH"* across all 182 stations.
- **Automatic Disruption Rerouting**:
  - Automatically incorporates official LTA mitigation services (`FreeMRTShuttle` / `FreePublicBus`) as the suggested route.
  - Explains the change in one concise line.
  - Preserves original delayed route **side-by-side** with the alternative for comparison.
- **Accessibility & Lift Outage Alternative (Mdm Lim)**:
  - Detects broken lifts at destination stations (e.g. Outram Park Exit 7).
  - Recommends direct wheelchair-accessible bus (Bus 197 WAB) with seat availability to avoid stairs.
- **Weather-Aware Sheltered Routing (Mdm Lim)**:
  - If rain is detected in the 2-hour nowcast, shifts walking legs to the `CoveredLinkWay` network.
- **ETA Confidence Bands**:
  - Color-coded (Green / Amber / Red) with plain-English reasons (e.g., *"crowd rising + 1 active alert"*), avoiding fake-precise single numbers.

---

### 8. Dedicated Debug & Simulation Controller (`DebugService` & Konami Code)
- **Files**: [`lib/core/debug/debug_service.dart`](lib/core/debug/debug_service.dart), [`lib/core/debug/konamicode.dart`](lib/core/debug/konamicode.dart)
- **Strict Competition Isolation**:
  - `isDebugMode = false` by default (Strict Live Mode).
  - When Debug Mode is OFF, all simulation flags are completely locked and neutralized. The app strictly hits live endpoints or reports live empty states.
- **Secret Konami Code Activation**:
  - Pressing `↑ ↑ ↓ ↓ ← → ← → B A` instantly activates/deactivates the debug simulation harness with zero UI clutter for normal users.
- **Scenario Replay Controls**:
  * `simulateDisruption`: Injects EWL signalling fault + Free MRT Shuttle.
  * `simulateLiftOutage`: Injects Outram Park Exit 7 lift maintenance + Bus 197 WAB alternative.
  * `simulateRainNowcast`: Injects 2-hour rain nowcast + CoveredLinkWay sheltered walkway.
  * `simulateCrowdSurge`: Injects platform crowding surge + proactive leave-earlier advice.
  * `deadReckoningTimer`: Controls underground elapsed countdown timer.

---

### 9. Comprehensive Automated Testing & Verification
- **Test Files**: 
  - [`test/canonical_line_table_test.dart`](test/canonical_line_table_test.dart)
  - [`test/transit_services_test.dart`](test/transit_services_test.dart)
  - [`test/debug_service_test.dart`](test/debug_service_test.dart)
  - [`test/konami_code_test.dart`](test/konami_code_test.dart)
  - [`test/landing_screen_test.dart`](test/landing_screen_test.dart)
  - [`test/home_screen_test.dart`](test/home_screen_test.dart)
- **31/31 Unit & Widget Tests Passing** verifying data reconciliation, elevation, UI transitions, search box aesthetics, and strict simulation isolation.

---

## 🛠️ Running the Project

### Running in Flutter Web (Development)
```bash
flutter run -d chrome
```

### Passing API Keys via `--dart-define` (Optional)
```bash
flutter run -d chrome \
  --dart-define=LTA_DATAMALL_KEY=your_lta_account_key \
  --dart-define=ONEMAP_KEY=your_onemap_token
```

### Running Unit Tests
```bash
flutter test
```

### Building for Web Production
```bash
flutter build web --release
```

---

## 📋 Pending Features & Roadmap (For Reference)

### 1. Interactive UI & Bottom Sheet
1. **Interactive Pull-Out / Draggable Bottom Sheet**:
   - Add vertical drag gesture physics to the bottom container (currently indicated by the top grab handle pill).
   - Three snap stops: Collapsed (140px peek), Half-screen (450px route overview), and Full-height (85% comprehensive turn-by-turn guidance).
   - Allows commuters to view full transit details or slide down to enjoy an unencumbered view of the live Leaflet map.
2. **Interactive Map Station Popups Wired to Search**:
   - Connect Leaflet popup *"From here"* and *"To here"* buttons back into Flutter state.
   - Automatically populates the natural language search bar (e.g., *"From Tampines to Raffles Place"*) and triggers the route planner directly from map taps.

---

### 2. Dedicated Journey & Navigation Page
3. **Full-Screen Multi-Modal Journey View**:
   - Transition from the quick `RoutePreviewSheet` on Home to a dedicated Journey Page.
   - Step-by-step guidance covering each leg: origin walking with distance, train platform and line badges, step-free transfer instructions, connecting bus/shuttle legs, and destination walking.
4. **Side-by-Side Disruption Comparison Card**:
   - Visual side-by-side comparison card showing the original delayed route (e.g., stalled on EWL, +25 min delay) alongside the suggested mitigation alternative (Free MRT Shuttle or Circle Line).
   - Single-line plain-English explanation of why the reroute was chosen.
5. **Dead-Reckoning Underground Navigation Mode**:
   - When entering underground MRT tunnels (where GPS and cellular connectivity drop), trigger dead-reckoning navigation using canonical transit run-time schedules.
   - Displays station countdown timers and upcoming station prompts so commuters never miss their transfer even while disconnected.

---

### 3. Station Deep-Dive & Real-Time Data Cards
6. **Live Station Inspection Sheet**:
   - Tapping an MRT station marker reveals a rich data card with:
     * **Platform Crowding (`PCDRealTime` & `PCDForecast`)**: Current green/amber/red crowding levels plus the 30-minute predictive trend.
     * **Lift Operational Status (`FacilitiesMaintenance`)**: Live list of station lifts and maintenance outages.
     * **Connecting Bus Arrivals (`BusArrival`)**: Real-time arrival countdowns, passenger load (`SEA`/`SDA`/`LSD`), and wheelchair accessibility (`WAB`).

---

### 4. Persona Quick-Demo Switcher (For Competition Judges)
7. **1-Tap Persona Scenario Selector**:
   - Quick-launch chips on the interface allowing judges to immediately test the two primary personas:
     * **Rachel's Commute**: Tampines $\rightarrow$ Raffles Place (triggers EWL disruption scenario $\rightarrow$ Free Shuttle alternative $\rightarrow$ crowd forecast).
     * **Mdm Lim's Journey**: Bedok $\rightarrow$ SGH Outram Park (triggers step-free wheelchair routing $\rightarrow$ Exit 7 lift outage alert $\rightarrow$ Bus 197 WAB alternative $\rightarrow$ covered walkway for rain).

---

### 5. Assets
8. **Custom Canva Hero Typography Asset**:
   - Replace the current landing page typography component ([`LandingHeroGraphic`](lib/features/landing/widgets/landing_hero_graphic.dart)) with the custom Canva graphic once exported.



