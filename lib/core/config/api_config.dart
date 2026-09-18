/// Central API configuration and endpoints for MRT Companion (PS2).
///
/// All external keys can be passed at build/run time via:
/// flutter run -d chrome --dart-define=LTA_DATAMALL_KEY=your_key --dart-define=ONEMAP_KEY=your_key
class ApiConfig {
  ApiConfig._();

  // ---------------------------------------------------------------------------
  // API Keys (Injected via --dart-define or environment, never hardcoded)
  // ---------------------------------------------------------------------------
  static const String ltaAccountKey = String.fromEnvironment('LTA_DATAMALL_KEY', defaultValue: '');
  static const String oneMapAuthToken = String.fromEnvironment('ONEMAP_KEY', defaultValue: '');

  // ---------------------------------------------------------------------------
  // LTA DataMall (https://datamall2.mytransport.sg/ltaodataservice/)
  // ---------------------------------------------------------------------------
  static const String ltaBaseUrl = 'https://datamall2.mytransport.sg/ltaodataservice';

  /// Train disruption status & mitigation actions (FreePublicBus, FreeMRTShuttle)
  static const String ltaTrainServiceAlerts = '$ltaBaseUrl/TrainServiceAlerts';

  /// Station crowd density - Real-time (10-min interval: l, m, h)
  static const String ltaPcdRealTime = '$ltaBaseUrl/PCDRealTime';

  /// Station crowd density - 30-min forecast
  static const String ltaPcdForecast = '$ltaBaseUrl/PCDForecast';

  /// Lift maintenance at stations/exits (Crucial for Mdm Lim)
  static const String ltaFacilitiesMaintenance = '$ltaBaseUrl/v2/FacilitiesMaintenance';

  /// Bus arrival, occupancy (Load: SEA/SDA/LSD), and wheelchair accessibility (Feature: WAB)
  static const String ltaBusArrival = '$ltaBaseUrl/v3/BusArrival';

  /// Geospatial layers (CoveredLinkWay, TrainStationExit, Footpath)
  static const String ltaGeospatial = '$ltaBaseUrl/GeospatialWholeIsland';

  static Map<String, String> get ltaHeaders => {
    'AccountKey': ltaAccountKey,
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // OneMap (Singapore's official mapping & routing service)
  // ---------------------------------------------------------------------------
  static const String oneMapBaseUrl = 'https://www.onemap.gov.sg/api';
  static const String oneMapRoutePublicTransport = '$oneMapBaseUrl/public/routingsvc/route';
  static const String oneMapGeocode = '$oneMapBaseUrl/common/elastic/search';

  static Map<String, String> get oneMapHeaders => {
    if (oneMapAuthToken.isNotEmpty) 'Authorization': oneMapAuthToken,
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // data.gov.sg Real-Time Weather (No API key needed)
  // ---------------------------------------------------------------------------
  static const String dataGovBaseUrl = 'https://api-open.data.gov.sg/v2/real-time/api';
  
  /// 2-hour nowcast for weather-aware routing (Mdm Lim sheltered alternative)
  static const String weatherTwoHourForecast = '$dataGovBaseUrl/two-hr-forecast';

  // ---------------------------------------------------------------------------
  // OpenStreetMap Geospatial Base
  // ---------------------------------------------------------------------------
  /// Hard license requirement: OSM attribution must always be displayed
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String osmTileUrlPattern = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String overpassApiUrl = 'https://overpass-api.de/api/interpreter';
}
