// Leaflet Bridge for MRT Companion (Flutter Web)
// Provides bridge between Flutter and Leaflet for OpenStreetMap rendering,
// full Singapore MRT transit network (lines + stations), and route visualization.

(function () {
  const mapInstances = {};
  const transitNetworkLayers = {};
  const routeLayers = {};

  const LINE_COLORS = {
    EWL: "#009645",
    CGL: "#009645",
    NSL: "#D42E12",
    NEL: "#7F2889",
    CCL: "#FA9E0D",
    CEL: "#FA9E0D",
    DTL: "#005EC4",
    TEL: "#9D5B25",
    BPL: "#748477",
    SLRT: "#748477",
    PLRT: "#748477",
  };

  const MRT_STATIONS = [
    // East-West Line
    { code: "EW24", name: "Jurong East", lat: 1.3332, lon: 103.7423, lines: ["EWL", "NSL"], codes: ["EW24", "NS1"], ground: "aboveground" },
    { code: "EW23", name: "Clementi", lat: 1.3151, lon: 103.7652, lines: ["EWL"], codes: ["EW23"], ground: "aboveground" },
    { code: "EW21", name: "Buona Vista", lat: 1.3073, lon: 103.7900, lines: ["EWL", "CCL"], codes: ["EW21", "CC22"], ground: "aboveground" },
    { code: "EW19", name: "Queenstown", lat: 1.2945, lon: 103.8060, lines: ["EWL"], codes: ["EW19"], ground: "aboveground" },
    { code: "EW18", name: "Redhill", lat: 1.2896, lon: 103.8168, lines: ["EWL"], codes: ["EW18"], ground: "aboveground" },
    { code: "EW17", name: "Tiong Bahru", lat: 1.2861, lon: 103.8269, lines: ["EWL"], codes: ["EW17"], ground: "underground" },
    { code: "EW16", name: "Outram Park", lat: 1.2803, lon: 103.8395, lines: ["EWL", "NEL", "TEL"], codes: ["EW16", "NE3", "TE17"], ground: "underground" },
    { code: "EW15", name: "Tanjong Pagar", lat: 1.2764, lon: 103.8458, lines: ["EWL"], codes: ["EW15"], ground: "underground" },
    { code: "EW14", name: "Raffles Place", lat: 1.2830, lon: 103.8513, lines: ["EWL", "NSL"], codes: ["EW14", "NS26"], ground: "underground" },
    { code: "EW13", name: "City Hall", lat: 1.2931, lon: 103.8522, lines: ["EWL", "NSL"], codes: ["EW13", "NS25"], ground: "underground" },
    { code: "EW12", name: "Bugis", lat: 1.3005, lon: 103.8558, lines: ["EWL", "DTL"], codes: ["EW12", "DT14"], ground: "underground" },
    { code: "EW11", name: "Lavender", lat: 1.3074, lon: 103.8596, lines: ["EWL"], codes: ["EW11"], ground: "underground" },
    { code: "EW10", name: "Kallang", lat: 1.3115, lon: 103.8714, lines: ["EWL"], codes: ["EW10"], ground: "aboveground" },
    { code: "EW9", name: "Aljunied", lat: 1.3164, lon: 103.8829, lines: ["EWL"], codes: ["EW9"], ground: "aboveground" },
    { code: "EW8", name: "Paya Lebar", lat: 1.3181, lon: 103.8931, lines: ["EWL", "CCL"], codes: ["EW8", "CC9"], ground: "aboveground" },
    { code: "EW7", name: "Eunos", lat: 1.3197, lon: 103.9031, lines: ["EWL"], codes: ["EW7"], ground: "aboveground" },
    { code: "EW6", name: "Kembangan", lat: 1.3210, lon: 103.9129, lines: ["EWL"], codes: ["EW6"], ground: "aboveground" },
    { code: "EW5", name: "Bedok", lat: 1.3240, lon: 103.9300, lines: ["EWL"], codes: ["EW5"], ground: "aboveground" },
    { code: "EW4", name: "Tanah Merah", lat: 1.3273, lon: 103.9463, lines: ["EWL", "CGL"], codes: ["EW4"], ground: "aboveground" },
    { code: "EW3", name: "Simei", lat: 1.3432, lon: 103.9533, lines: ["EWL"], codes: ["EW3"], ground: "aboveground" },
    { code: "EW2", name: "Tampines", lat: 1.3533, lon: 103.9452, lines: ["EWL", "DTL"], codes: ["EW2", "DT32"], ground: "aboveground" },

    // Changi Airport Branch
    { code: "CG1", name: "Expo", lat: 1.3353, lon: 103.9616, lines: ["CGL", "DTL"], codes: ["CG1", "DT35"], ground: "aboveground" },
    { code: "CG2", name: "Changi Airport", lat: 1.3574, lon: 103.9885, lines: ["CGL"], codes: ["CG2"], ground: "underground" },

    // North-South Line
    { code: "NS4", name: "Choa Chu Kang", lat: 1.3854, lon: 103.7444, lines: ["NSL", "BPL"], codes: ["NS4", "BP1"], ground: "aboveground" },
    { code: "NS9", name: "Woodlands", lat: 1.4361, lon: 103.7865, lines: ["NSL", "TEL"], codes: ["NS9", "TE2"], ground: "underground" },
    { code: "NS13", name: "Yishun", lat: 1.4294, lon: 103.8350, lines: ["NSL"], codes: ["NS13"], ground: "aboveground" },
    { code: "NS16", name: "Ang Mo Kio", lat: 1.3699, lon: 103.8496, lines: ["NSL"], codes: ["NS16"], ground: "aboveground" },
    { code: "NS17", name: "Bishan", lat: 1.3508, lon: 103.8481, lines: ["NSL", "CCL"], codes: ["NS17", "CC15"], ground: "aboveground" },
    { code: "NS19", name: "Toa Payoh", lat: 1.3327, lon: 103.8475, lines: ["NSL"], codes: ["NS19"], ground: "underground" },
    { code: "NS20", name: "Novena", lat: 1.3204, lon: 103.8438, lines: ["NSL"], codes: ["NS20"], ground: "underground" },
    { code: "NS21", name: "Newton", lat: 1.3129, lon: 103.8380, lines: ["NSL", "DTL"], codes: ["NS21", "DT11"], ground: "underground" },
    { code: "NS22", name: "Orchard", lat: 1.3040, lon: 103.8318, lines: ["NSL", "TEL"], codes: ["NS22", "TE14"], ground: "underground" },
    { code: "NS23", name: "Somerset", lat: 1.3003, lon: 103.8390, lines: ["NSL"], codes: ["NS23"], ground: "underground" },
    { code: "NS24", name: "Dhoby Ghaut", lat: 1.2989, lon: 103.8459, lines: ["NSL", "NEL", "CCL"], codes: ["NS24", "NE6", "CC1"], ground: "underground" },
    { code: "NS27", name: "Marina Bay", lat: 1.2764, lon: 103.8546, lines: ["NSL", "CEL", "TEL"], codes: ["NS27", "CE2", "TE20"], ground: "underground" },

    // North East Line
    { code: "NE1", name: "HarbourFront", lat: 1.2654, lon: 103.8222, lines: ["NEL", "CCL"], codes: ["NE1", "CC29"], ground: "underground" },
    { code: "NE4", name: "Chinatown", lat: 1.2845, lon: 103.8440, lines: ["NEL", "DTL"], codes: ["NE4", "DT19"], ground: "underground" },
    { code: "NE5", name: "Clarke Quay", lat: 1.2884, lon: 103.8466, lines: ["NEL"], codes: ["NE5"], ground: "underground" },
    { code: "NE7", name: "Little India", lat: 1.3068, lon: 103.8492, lines: ["NEL", "DTL"], codes: ["NE7", "DT12"], ground: "underground" },
    { code: "NE8", name: "Farrer Park", lat: 1.3123, lon: 103.8540, lines: ["NEL"], codes: ["NE8"], ground: "underground" },
    { code: "NE9", name: "Boon Keng", lat: 1.3194, lon: 103.8617, lines: ["NEL"], codes: ["NE9"], ground: "underground" },
    { code: "NE10", name: "Potong Pasir", lat: 1.3314, lon: 103.8691, lines: ["NEL"], codes: ["NE10"], ground: "underground" },
    { code: "NE12", name: "Serangoon", lat: 1.3497, lon: 103.8737, lines: ["NEL", "CCL"], codes: ["NE12", "CC13"], ground: "underground" },
    { code: "NE16", name: "Sengkang", lat: 1.3917, lon: 103.8955, lines: ["NEL", "SLRT"], codes: ["NE16", "STC"], ground: "aboveground" },
    { code: "NE17", name: "Punggol", lat: 1.4049, lon: 103.9023, lines: ["NEL", "PLRT"], codes: ["NE17", "PTC"], ground: "aboveground" },

    // Circle Line & Extensions
    { code: "CC4", name: "Promenade", lat: 1.2940, lon: 103.8603, lines: ["CCL", "DTL"], codes: ["CC4", "DT15"], ground: "underground" },
    { code: "CC10", name: "MacPherson", lat: 1.3262, lon: 103.8899, lines: ["CCL", "DTL"], codes: ["CC10", "DT26"], ground: "underground" },
    { code: "CC19", name: "Botanic Gardens", lat: 1.3223, lon: 103.8153, lines: ["CCL", "DTL"], codes: ["CC19", "DT9"], ground: "underground" },
    { code: "CE1", name: "Bayfront", lat: 1.2818, lon: 103.8591, lines: ["CEL", "DTL"], codes: ["CE1", "DT16"], ground: "underground" },

    // Downtown Line
    { code: "DT17", name: "Downtown", lat: 1.2794, lon: 103.8528, lines: ["DTL"], codes: ["DT17"], ground: "underground" },
    { code: "DT18", name: "Telok Ayer", lat: 1.2822, lon: 103.8486, lines: ["DTL"], codes: ["DT18"], ground: "underground" },

    // Thomson-East Coast Line
    { code: "TE18", name: "Maxwell", lat: 1.2806, lon: 103.8440, lines: ["TEL"], codes: ["TE18"], ground: "underground" },
    { code: "TE19", name: "Shenton Way", lat: 1.2778, lon: 103.8505, lines: ["TEL"], codes: ["TE19"], ground: "underground" },
    { code: "TE22", name: "Gardens by the Bay", lat: 1.2783, lon: 103.8672, lines: ["TEL"], codes: ["TE22"], ground: "underground" },
  ];

  const MRT_LINES = [
    {
      id: "EWL",
      name: "East-West Line",
      color: "#009645",
      stations: ["EW24", "EW23", "EW21", "EW19", "EW18", "EW17", "EW16", "EW15", "EW14", "EW13", "EW12", "EW11", "EW10", "EW9", "EW8", "EW7", "EW6", "EW5", "EW4", "EW3", "EW2"]
    },
    {
      id: "CGL",
      name: "Changi Airport Branch",
      color: "#009645",
      stations: ["EW4", "CG1", "CG2"]
    },
    {
      id: "NSL",
      name: "North-South Line",
      color: "#D42E12",
      stations: ["EW24", "NS4", "NS9", "NS13", "NS16", "NS17", "NS19", "NS20", "NS21", "NS22", "NS23", "NS24", "EW13", "EW14", "NS27"]
    },
    {
      id: "NEL",
      name: "North East Line",
      color: "#7F2889",
      stations: ["NE1", "EW16", "NE4", "NE5", "NS24", "NE7", "NE8", "NE9", "NE10", "NE12", "NE16", "NE17"]
    },
    {
      id: "CCL",
      name: "Circle Line",
      color: "#FA9E0D",
      stations: ["NS24", "CC4", "EW8", "CC10", "NE12", "NS17", "CC19", "EW21", "NE1"]
    },
    {
      id: "CEL",
      name: "Circle Line Extension",
      color: "#FA9E0D",
      stations: ["CC4", "CE1", "NS27"]
    },
    {
      id: "DTL",
      name: "Downtown Line",
      color: "#005EC4",
      stations: ["CC19", "NS21", "NE7", "EW12", "CC4", "CE1", "DT17", "DT18", "NE4", "CC10", "EW2", "CG1"]
    },
    {
      id: "TEL",
      name: "Thomson-East Coast Line",
      color: "#9D5B25",
      stations: ["NS9", "NS22", "EW16", "TE18", "TE19", "NS27", "TE22"]
    }
  ];

  /**
   * Computes background CSS for station marker:
   * - Normal station (1 line): solid color circle
   * - Interchange (2+ lines): multicolor pie chart using conic-gradient!
   */
  function getStationBackground(lines) {
    if (!lines || lines.length === 0) return "#64748b";
    if (lines.length === 1) {
      return LINE_COLORS[lines[0]] || "#009645";
    }
    const slice = 360 / lines.length;
    const stops = [];
    lines.forEach((line, i) => {
      const color = LINE_COLORS[line] || "#64748b";
      const start = (i * slice).toFixed(1);
      const end = ((i + 1) * slice).toFixed(1);
      stops.push(`${color} ${start}deg ${end}deg`);
    });
    return `conic-gradient(${stops.join(", ")})`;
  }

  /**
   * Creates an interactive Leaflet marker for a station
   */
  function createStationMarker(stn) {
    const isInterchange = stn.lines.length > 1;
    const size = isInterchange ? 18 : 13;
    const bg = getStationBackground(stn.lines);
    const border = isInterchange ? "2.5px solid #ffffff" : "2px solid #ffffff";
    const shadow = isInterchange
      ? "0 2px 6px rgba(0,0,0,0.55)"
      : "0 1px 4px rgba(0,0,0,0.45)";

    const markerHtml = `
      <div style="
        width: ${size}px;
        height: ${size}px;
        border-radius: 50%;
        background: ${bg};
        border: ${border};
        box-shadow: ${shadow};
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
      ">
        ${isInterchange ? '<div style="width: 5px; height: 5px; border-radius: 50%; background: #ffffff; box-shadow: 0 1px 2px rgba(0,0,0,0.4);"></div>' : ""}
      </div>
    `;

    const icon = L.divIcon({
      className: isInterchange ? "mrt-interchange-icon" : "mrt-station-icon",
      html: markerHtml,
      iconSize: [size, size],
      iconAnchor: [size / 2, size / 2],
    });

    const marker = L.marker([stn.lat, stn.lon], { icon: icon, zIndexOffset: isInterchange ? 100 : 50 });

    const lineBadges = stn.lines.map((l) => {
      const col = LINE_COLORS[l] || "#64748b";
      return `<span style="background: ${col}; color: #ffffff; padding: 2px 6px; border-radius: 4px; font-weight: 800; font-size: 10px; margin-right: 4px;">${l}</span>`;
    }).join("");

    const displayCodes = (stn.codes && stn.codes.length > 0) ? stn.codes.join(" · ") : stn.code;

    const popupHtml = `
      <div style="font-family: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif; min-width: 175px; color: #0f172a; padding: 4px 2px;">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px;">
          <b style="font-size: 14px; color: #0f172a;">${stn.name}</b>
          <span style="font-size: 10px; font-weight: 700; color: #64748b; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">${displayCodes}</span>
        </div>
        <div style="margin-bottom: 8px;">
          ${lineBadges}
        </div>
        <div style="font-size: 11px; color: #64748b; margin-bottom: 10px;">
          ${stn.ground === "underground" ? "🚇 Underground Station" : "🚊 Elevated / Above Ground"}
        </div>
        <div style="display: flex; gap: 6px; border-top: 1px solid #e2e8f0; padding-top: 8px;">
          <button onclick="window.MRTLeafletBridge.selectStation('${stn.name}', 'origin')" style="flex: 1; padding: 6px 4px; background: #0f172a; color: #ffffff; border: none; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer;">From here</button>
          <button onclick="window.MRTLeafletBridge.selectStation('${stn.name}', 'destination')" style="flex: 1; padding: 6px 4px; background: #f1f5f9; color: #0f172a; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer;">To here</button>
        </div>
      </div>
    `;

    marker.bindPopup(popupHtml, { maxWidth: 260 });
    return marker;
  }

  /**
   * Renders the permanent Singapore MRT lines and station markers
   */
  function renderTransitNetwork(containerId) {
    const layer = transitNetworkLayers[containerId];
    if (!layer) return;

    layer.clearLayers();

    // Map stations by code for line construction
    const stnByCode = {};
    MRT_STATIONS.forEach((stn) => {
      stnByCode[stn.code] = stn;
      if (stn.codes) {
        stn.codes.forEach((c) => {
          stnByCode[c] = stn;
        });
      }
    });

    // 1. Draw Metro Lines (Casing + Core Polyline)
    MRT_LINES.forEach((line) => {
      const coords = [];
      line.stations.forEach((code) => {
        const s = stnByCode[code];
        if (s) {
          coords.push([s.lat, s.lon]);
        }
      });

      if (coords.length > 1) {
        // Dark outer halo for contrast against OpenStreetMap
        L.polyline(coords, {
          color: "#0a0f1d",
          weight: 6,
          opacity: 0.75,
          lineCap: "round",
          lineJoin: "round",
        }).addTo(layer);

        // Core colored transit line
        const poly = L.polyline(coords, {
          color: line.color,
          weight: 3.8,
          opacity: 0.95,
          lineCap: "round",
          lineJoin: "round",
        }).addTo(layer);

        poly.bindTooltip(`<b>${line.name} (${line.id})</b>`, {
          sticky: true,
          opacity: 0.92,
        });
      }
    });

    // 2. Draw Stations (Solid circle for normal stations, pie chart multicolor for interchanges)
    MRT_STATIONS.forEach((stn) => {
      const marker = createStationMarker(stn);
      marker.addTo(layer);
    });
  }

  window.MRTLeafletBridge = {
    /**
     * Initializes a Leaflet map inside the container.
     */
    initMap: function (containerId, lat, lng, zoom) {
      if (mapInstances[containerId]) {
        mapInstances[containerId].remove();
        delete mapInstances[containerId];
      }

      const container = document.getElementById(containerId);
      if (!container) {
        console.warn("[MRTLeafletBridge] Container not found:", containerId);
        return false;
      }

      const defaultLat = lat || 1.3521;
      const defaultLng = lng || 103.8198;
      const defaultZoom = zoom || 12;

      const map = L.map(containerId, {
        center: [defaultLat, defaultLng],
        zoom: defaultZoom,
        zoomControl: false, // Disabled: using custom sleek Flutter MapTouchControls
        attributionControl: true,
      });

      // Mandatory OpenStreetMap Attribution (Hard requirement of ODbL licence)
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
      }).addTo(map);

      // Separate layer groups for base transit network and dynamic route overlays
      const networkLayer = L.layerGroup().addTo(map);
      const routeLayer = L.layerGroup().addTo(map);

      mapInstances[containerId] = map;
      transitNetworkLayers[containerId] = networkLayer;
      routeLayers[containerId] = routeLayer;

      // Render the complete Singapore MRT lines and stations immediately
      renderTransitNetwork(containerId);

      // Invalidate size once rendered in DOM
      setTimeout(() => {
        map.invalidateSize();
      }, 200);

      return true;
    },

    onStationSelect: null,

    /**
     * Callback when a station popup button is clicked (From here / To here)
     */
    selectStation: function (name, role) {
      if (typeof window.MRTLeafletBridge.onStationSelect === "function") {
        window.MRTLeafletBridge.onStationSelect(name, role);
      }
      window.dispatchEvent(
        new CustomEvent("mrt-station-select", {
          detail: { name: name, role: role },
        })
      );
    },

    /**
     * Centers map on a specific coordinate
     */
    setView: function (containerId, lat, lng, zoom) {
      const map = mapInstances[containerId];
      if (map) {
        map.setView([lat, lng], zoom || 14, { animate: true });
      }
    },

    /**
     * Zooms the map in by 1 level
     */
    zoomIn: function (containerId) {
      const map = mapInstances[containerId];
      if (map) {
        map.zoomIn();
      }
    },

    /**
     * Zooms the map out by 1 level
     */
    zoomOut: function (containerId) {
      const map = mapInstances[containerId];
      if (map) {
        map.zoomOut();
      }
    },

    /**
     * Toggles CSS blur effect on the map container
     */
    setBlurred: function (containerId, blurred) {
      const container = document.getElementById(containerId);
      if (container) {
        if (blurred) {
          container.style.filter = "blur(8px)";
          container.style.transform = "scale(1.06)";
          container.style.transition = "filter 0.5s ease, transform 0.5s ease";
        } else {
          container.style.filter = "none";
          container.style.transform = "none";
          container.style.transition = "filter 0.5s ease, transform 0.5s ease";
        }
      }
    },

    /**
     * Clears route overlays without removing base transit lines/stations
     */
    clearLayers: function (containerId) {
      const layers = routeLayers[containerId];
      if (layers) {
        layers.clearLayers();
      }
    },

    /**
     * Renders a primary route, visually distinguishing affected segments.
     */
    renderRoute: function (containerId, unaffectedCoords, affectedCoords, alternativeCoords) {
      const map = mapInstances[containerId];
      const layers = routeLayers[containerId];
      if (!map || !layers) return;

      layers.clearLayers();
      const allBounds = [];

      // 1. Alternative Route (Dashed cyan/blue)
      if (alternativeCoords && alternativeCoords.length > 1) {
        const altPolyline = L.polyline(alternativeCoords, {
          color: "#0284c7",
          weight: 5,
          dashArray: "6, 8",
          opacity: 0.9,
        }).addTo(layers);
        altPolyline.bindPopup("<b>Alternative Route (Rerouted)</b>");
        allBounds.push(...alternativeCoords);
      }

      // 2. Unaffected Route Segment (Solid bright emerald green)
      if (unaffectedCoords && unaffectedCoords.length > 1) {
        const normPolyline = L.polyline(unaffectedCoords, {
          color: "#10b981",
          weight: 6,
          opacity: 0.95,
        }).addTo(layers);
        normPolyline.bindPopup("<b>MRT Route (Normal Operation)</b>");
        allBounds.push(...unaffectedCoords);
      }

      // 3. Affected Route Segment (Red alert dashed)
      if (affectedCoords && affectedCoords.length > 1) {
        const affPolyline = L.polyline(affectedCoords, {
          color: "#dc2626",
          weight: 6,
          dashArray: "8, 6",
          opacity: 0.95,
        }).addTo(layers);
        affPolyline.bindPopup("<b>Disrupted / Delayed Segment</b><br>Mitigation in effect.");
        allBounds.push(...affectedCoords);
      }

      if (allBounds.length > 1) {
        map.fitBounds(allBounds, { padding: [50, 50] });
      }
    },

    /**
     * Renders sheltered walkway / CoveredLinkWay segments for accessibility routing
     */
    renderShelteredWalkway: function (containerId, coords) {
      const layers = routeLayers[containerId];
      if (!layers || !coords) return;

      L.polyline(coords, {
        color: "#0d9488",
        weight: 5,
        opacity: 0.85,
        dashArray: "4, 4",
      }).bindPopup("<b>Covered Walkway (Sheltered)</b>").addTo(layers);
    },

    /**
     * Triggers map resize update
     */
    invalidateSize: function (containerId) {
      const map = mapInstances[containerId];
      if (map) {
        map.invalidateSize();
      }
    },
  };
})();
