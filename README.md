# MRT Companion — Smart Commuter Companion (PS2)

> Built strictly against Problem Statement 2 (Smart Commuter Companion) using designated public Singapore data sources.  
> **Target Stack**: Flutter Web (`flutter build web`)  
> **Personas**: **Rachel** (Fixed-schedule commuter) & **Mdm Lim** (Accessibility-constrained commuter)

---

## 🚀 Currently Working Features (Logic & Architecture)

### 1. Canonical Transit Network & Line-Code Reconciliation Table
- **File**: [`lib/core/transit/canonical_line_table.dart`](lib/core/transit/canonical_line_table.dart)
- **Problem Solved**: Reconciles DataMall line code mismatches before joining data:
  | Transit Line | TrainServiceAlerts Code | Station Crowd Density (PCD) Code | Canonical Code |
  | :--- | :---: | :---: | :---: |
  | **Sengkang LRT** | `STL` | `SLRT` | `SLRT` |
  | **Punggol LRT** | `PTL` | `PLRT` | `PLRT` |
  | **Circle Line Extension** | `CCL` *(folded)* | `CEL` *(separate)* | `CEL` |
  | **Changi Airport Branch** | `EWL` *(folded)* | `CGL` *(separate)* | `CGL` |
- **`GroundLevel` Enum**:
  - Matches official LTA Master Plan categories: `underground` and `aboveGround`.
  - Flexible normalizer parses `'at-grade'`, `'at_grade'`, `'elevated'`, `'underground'`, and `'subsurface'` seamlessly.
  - `isUnderground` property powers dead-reckoning offline logic when GPS/cellular signals degrade underground.
- **Singapore Transit Database**:
  - Accurate lat/lon coordinates, station codes, lines, exits, and elevation for Rachel (`Tampines`, `Raffles Place`), Mdm Lim (`Bedok`, `Outram Park` for SGH), and key transfer hubs.

---

### 2. OpenStreetMap Geospatial Base (Leaflet in Flutter Web)
- **Files**: [`web/leaflet_bridge.js`](web/leaflet_bridge.js), [`lib/core/map/leaflet_map_view.dart`](lib/core/map/leaflet_map_view.dart), [`lib/core/map/leaflet_web_impl.dart`](lib/core/map/leaflet_web_impl.dart)
- **Leaflet Integration**: Embedded in Flutter Web via `HtmlElementView` and `dart:ui_web`.
- **Hard License Compliance**: Permanent, unremovable `"© OpenStreetMap contributors"` attribution displayed both in Leaflet tiles and as a persistent Flutter UI overlay badge.
- **Multi-Colored Segment Polylines**:
  - **Normal Operation**: Solid Emerald Green (`#059669`).
  - **Disrupted Segments**: High-visibility dashed Red/Orange warning (`#dc2626`).
  - **Alternative Reroutes**: Dashed Sky Blue line (`#0284c7`).
- **Station Crowding Dots**: 3-level color indicators directly on station markers (Low = Green, Moderate = Amber, High = Red).
- **Sheltered Walkways**: Renders `CoveredLinkWay` paths for weather-aware routing.
- **Compilation Verified**: Builds cleanly with `flutter build web` in 11.5s.

---

### 3. LTA DataMall Integration Service
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

### 4. data.gov.sg 2-Hour Weather Nowcast
- **File**: [`lib/core/services/weather_service.dart`](lib/core/services/weather_service.dart)
- Live government weather nowcast API (no API key required).
- Detects rain/thunderstorms for Singapore towns (e.g. Bedok, Outram, Tampines) to proactively reroute Mdm Lim through sheltered walkways.

---

### 5. OneMap Multi-Modal Door-to-Door Routing
- **File**: [`lib/core/services/onemap_service.dart`](lib/core/services/onemap_service.dart)
- Complete door-to-door paths including origin and destination walking legs, not just station-to-station.
- High-fidelity baseline paths for Rachel and Mdm Lim.

---

### 6. Central Transit Routing & Decision Engine
- **File**: [`lib/core/services/transit_routing_engine.dart`](lib/core/services/transit_routing_engine.dart)
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

### 7. Dedicated Debug & Simulation Controller (`DebugService`)
- **File**: [`lib/core/debug/debug_service.dart`](lib/core/debug/debug_service.dart)
- **Strict Competition Isolation**:
  - `isDebugMode = false` by default (Strict Live Mode).
  - When Debug Mode is OFF, all simulation flags are completely locked and neutralized. The app strictly hits live endpoints or reports live empty states.
  - When Debug Mode is explicitly activated, the judge/developer can toggle specific scenario replays:
    * `simulateDisruption`: Injects EWL signalling fault + Free MRT Shuttle.
    * `simulateLiftOutage`: Injects Outram Park Exit 7 lift maintenance + Bus 197 WAB alternative.
    * `simulateRainNowcast`: Injects 2-hour rain nowcast + CoveredLinkWay sheltered walkway.
    * `simulateCrowdSurge`: Injects platform crowding surge + proactive leave-earlier advice.
    * `deadReckoningTimer`: Controls underground elapsed countdown timer.
  - Every simulated response automatically sets `isSimulated = true` with active scenario audit tags.

---

### 8. Automated Testing & Verification
- **Test Files**: [`test/canonical_line_table_test.dart`](test/canonical_line_table_test.dart), [`test/transit_services_test.dart`](test/transit_services_test.dart)
- **14/14 Unit Tests Passing** including strict competition isolation validation.
- **Static Analysis**: `flutter analyze` reports **0 issues**.

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
flutter build web
```
