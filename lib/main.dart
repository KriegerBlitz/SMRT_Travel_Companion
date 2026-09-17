import 'package:flutter/material.dart';
import 'core/canonical_line_codes.dart';
import 'services/geospatial_service.dart';
import 'services/lta_models.dart';
import 'services/lta_service.dart';
import 'services/onemap_service.dart';
import 'services/simulator_service.dart';
import 'services/weather_service.dart';
import 'ui/debug/debug_panel.dart';
import 'ui/journeys/conversational_search_view.dart';
import 'ui/journeys/mdm_lim_journey_view.dart';
import 'ui/journeys/rachel_journey_view.dart';
import 'ui/map/leaflet_map_view.dart';
import 'ui/widgets/simulated_data_badge.dart';

void main() {
  runApp(const MRTCompanionApp());
}

class MRTCompanionApp extends StatelessWidget {
  const MRTCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRT Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF009645),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MRTCompanionHomeScreen(),
    );
  }
}

class MRTCompanionHomeScreen extends StatefulWidget {
  const MRTCompanionHomeScreen({super.key});

  @override
  State<MRTCompanionHomeScreen> createState() => _MRTCompanionHomeScreenState();
}

class _MRTCompanionHomeScreenState extends State<MRTCompanionHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LTAService _ltaService = LTAService();
  final WeatherService _weatherService = WeatherService();
  final SimulatorService _simulator = SimulatorService();

  LeafletController? _mapController;

  int _selectedTabIndex = 0; // 0: Rachel, 1: Mdm Lim, 2: AI Search
  bool _isLargeText = false;
  bool _showRachelAlternative = false;

  TrainServiceAlert _alert = TrainServiceAlert.normal();
  Map<String, StationCrowdInfo> _crowdMap = {};
  Map<String, WeatherNowcast> _weatherMap = {};
  List<BusArrivalInfo> _wabBusArrivals = [];

  @override
  void initState() {
    super.initState();
    _simulator.addListener(_handleSimulatorUpdate);
    _loadInitialData();
  }

  @override
  void dispose() {
    _simulator.removeListener(_handleSimulatorUpdate);
    super.dispose();
  }

  void _handleSimulatorUpdate() {
    setState(() {});
    _syncMapLayers();
  }

  Future<void> _loadInitialData() async {
    final alerts = await _ltaService.getTrainServiceAlerts();
    final crowd = await _ltaService.getCrowdDensity();
    final weather = await _weatherService.getNowcast();
    final busArrivals = await _ltaService.getBusArrivals('06011');

    if (mounted) {
      setState(() {
        if (alerts.isNotEmpty) _alert = alerts.first;
        _crowdMap = crowd;
        _weatherMap = weather;
        _wabBusArrivals = busArrivals;
      });
      _syncMapLayers();
    }
  }

  void _syncMapLayers() {
    final controller = _mapController;
    if (controller == null) return;

    controller.clearAll();

    // Prepare current route based on tab and simulation state
    DoorToDoorRoute route;
    if (_selectedTabIndex == 0) {
      // Rachel
      route = OneMapService.buildRachelRoute(
        isDisrupted: _simulator.forceDisruption,
        crowdSpike: _simulator.forceCrowdForecastSpike,
      );
      if (_showRachelAlternative && _simulator.forceDisruption) {
        final alt = OneMapService.buildRachelRoute(isDisrupted: true);
        controller.drawAlternativeRoute(
          alt.legs[1].pathCoordinates,
          color: '#0284C7',
          label: 'Free MRT Shuttle Bus',
        );
      }
      if (_simulator.forceDisruption) {
        // Highlight affected segment on East-West Line
        final tampines = CanonicalLineCodes.findStationByCode('EW2')!;
        final pasirRis = CanonicalLineCodes.findStationByCode('EW1')!;
        controller.drawAffectedSegment(
          [LatLng(tampines.lat, tampines.lng), LatLng(pasirRis.lat, pasirRis.lng)],
          'EWL Signal Fault (Train Service Delayed)',
        );
      }
    } else if (_selectedTabIndex == 1) {
      // Mdm Lim
      final isRain = _simulator.forceRainNowcast ||
          (_weatherMap['Bukit Merah']?.isRaining ?? false);
      route = OneMapService.buildMdmLimRoute(
        liftDown: _simulator.forceLiftOutage,
        isRaining: isRain,
      );

      // Draw CoveredLinkWay sheltered walkway
      controller.drawShelteredWalkways(
        GeospatialService.coveredWalkways.map((s) => s.coordinates).toList(),
      );

      if (_simulator.forceLiftOutage) {
        // Draw WAB Bus 147 route
        controller.drawAlternativeRoute(
          route.legs[1].pathCoordinates,
          color: '#8B5CF6',
          label: 'Wheelchair-Accessible Bus 147',
        );
      }
    } else {
      // Conversational Route
      route = OneMapService.buildRachelRoute();
    }

    // Draw main route polyline
    controller.drawRoute(
      route.allCoordinates,
      color: _selectedTabIndex == 1 ? '#8B5CF6' : '#009645',
      weight: 6,
    );

    // Station Markers with 3-level crowd indicator dots
    final List<MapStationMarker> markers = [];
    for (final stn in CanonicalLineCodes.stations) {
      // Check crowd level
      String crowdStr = 'low';
      if (_simulator.forcedCrowdLevel == CrowdLevel.high) {
        crowdStr = 'high';
      } else if (_simulator.forcedCrowdLevel == CrowdLevel.moderate) {
        crowdStr = 'moderate';
      } else {
        final info = _crowdMap[stn.code];
        crowdStr = info?.realTime.label.toLowerCase() ?? 'low';
      }

      String? facilityAlert;
      if (stn.code == 'EW16' && _simulator.forceLiftOutage) {
        facilityAlert = 'Lift 2 Out of Service (Under Maintenance)';
      }

      markers.add(MapStationMarker(
        code: stn.code,
        name: stn.name,
        lineName: stn.primaryLine.displayName,
        lineColor: '#${stn.primaryLine.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        lat: stn.lat,
        lng: stn.lng,
        crowd: crowdStr,
        facilityAlert: facilityAlert,
      ));
    }

    controller.setStationMarkers(markers);
    controller.fitBounds(route.allCoordinates);
  }

  @override
  Widget build(BuildContext context) {
    final isDisrupted = _simulator.forceDisruption || _alert.isDisrupted;
    final rachelRoute = OneMapService.buildRachelRoute(
      isDisrupted: isDisrupted,
      crowdSpike: _simulator.forceCrowdForecastSpike,
    );
    final rachelAltRoute = isDisrupted
        ? OneMapService.buildRachelRoute(isDisrupted: true)
        : null;

    final isRain = _simulator.forceRainNowcast ||
        (_weatherMap['Bukit Merah']?.isRaining ?? false);
    final mdmLimRoute = OneMapService.buildMdmLimRoute(
      liftDown: _simulator.forceLiftOutage,
      isRaining: isRain,
    );

    final mdmLimLiftOutage = _simulator.forceLiftOutage
        ? const FacilityMaintenance(
            stationCode: 'EW16',
            stationName: 'Outram Park',
            facilityType: 'Lift',
            locationDescription: 'Lift 2 (Exit 1 to SGH Linkway)',
            isOutOfService: true,
          )
        : null;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DebugPanel(simulator: _simulator),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF009645),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.subway, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MRT Companion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'PS2 Standard · LTA DataMall',
                  style: TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Mandatory Simulation Badge
          Center(
            child: SimulatedDataBadge(
              isSimulated: _simulator.isSimulated,
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.amberAccent),
            tooltip: 'Simulator & Debug Panel',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 850;

          final mapWidget = LeafletMapWidget(
            height: isWide ? constraints.maxHeight : 320,
            onMapReady: (controller) {
              _mapController = controller;
              _syncMapLayers();
            },
          );

          final contentWidget = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persona Switcher Bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueGrey.shade700),
                  ),
                  child: Row(
                    children: [
                      _buildPersonaTab(
                        index: 0,
                        title: 'Rachel',
                        subtitle: 'Commuter',
                        icon: Icons.person,
                        color: const Color(0xFF009645),
                      ),
                      _buildPersonaTab(
                        index: 1,
                        title: 'Mdm Lim',
                        subtitle: 'Accessibility',
                        icon: Icons.accessible,
                        color: Colors.purpleAccent,
                      ),
                      _buildPersonaTab(
                        index: 2,
                        title: 'AI Search',
                        subtitle: 'Natural Lang',
                        icon: Icons.auto_awesome,
                        color: Colors.cyanAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Active View Content
                if (_selectedTabIndex == 0)
                  RachelJourneyView(
                    currentRoute: rachelRoute,
                    alternativeRoute: rachelAltRoute,
                    alert: isDisrupted
                        ? TrainServiceAlert(
                            status: 2,
                            line: 'EWL',
                            direction: 'To Pasir Ris',
                            affectedStations: ['EW1', 'EW2', 'EW3'],
                            freePublicBus: true,
                            freeMrtShuttle: true,
                            message:
                                'Signal fault between Tampines and Pasir Ris. Free MRT Shuttle bus running.',
                            timestamp: DateTime.now(),
                          )
                        : TrainServiceAlert.normal(),
                    crowdInfo: StationCrowdInfo(
                      stationCode: 'EW2',
                      realTime: _simulator.forcedCrowdLevel,
                      forecast30Min: _simulator.forceCrowdForecastSpike
                          ? CrowdLevel.high
                          : CrowdLevel.low,
                    ),
                    showAlternative: _showRachelAlternative,
                    onSelectAlternative: () {
                      setState(() {
                        _showRachelAlternative = !_showRachelAlternative;
                      });
                      _syncMapLayers();
                    },
                  )
                else if (_selectedTabIndex == 1)
                  MdmLimJourneyView(
                    currentRoute: mdmLimRoute,
                    liftMaintenance: mdmLimLiftOutage,
                    weatherNowcast: isRain
                        ? WeatherNowcast.rainy('Outram Park',
                            customText: 'Passing Showers')
                        : WeatherNowcast.fair('Outram Park'),
                    wabBusArrivals: _wabBusArrivals,
                    isLargeText: _isLargeText,
                    onToggleLargeText: (val) => setState(() => _isLargeText = val),
                    deadReckoningSeconds:
                        _simulator.deadReckoningElapsedSeconds,
                    onAdvanceTimer: () => _simulator.advanceDeadReckoningTimer(180),
                    onResetTimer: () => _simulator.resetDeadReckoningTimer(),
                  )
                else
                  ConversationalSearchView(
                    onTripPlanned: (parsed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Parsed Route: ${parsed.fromStation ?? 'Origin'} ➔ ${parsed.toStation ?? 'Destination'} (${parsed.preference})',
                          ),
                          backgroundColor: const Color(0xFF009645),
                        ),
                      );
                      _syncMapLayers();
                    },
                  ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: mapWidget),
                Expanded(flex: 4, child: contentWidget),
              ],
            );
          }

          return Column(
            children: [
              mapWidget,
              Expanded(child: contentWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonaTab({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
          _syncMapLayers();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: isSelected ? color : Colors.white60),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? color : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
