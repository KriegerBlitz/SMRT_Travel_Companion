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
    STL: "#748477",
    PTL: "#748477",
  };

  const LINE_META = {
    EWL: { name: "East-West Line", color: "#009645" },
    CGL: { name: "Changi Airport Branch", color: "#009645" },
    NSL: { name: "North-South Line", color: "#D42E12" },
    NEL: { name: "North East Line", color: "#7F2889" },
    CCL: { name: "Circle Line", color: "#FA9E0D" },
    CEL: { name: "Circle Line Extension", color: "#FA9E0D" },
    DTL: { name: "Downtown Line", color: "#005EC4" },
    TEL: { name: "Thomson-East Coast Line", color: "#9D5B25" },
    BPL: { name: "Bukit Panjang LRT", color: "#748477" },
    SLRT: { name: "Sengkang LRT", color: "#748477" },
    PLRT: { name: "Punggol LRT", color: "#748477" },
  };

  // Fallback subset if external data is not yet loaded
  const MRT_STATIONS_FALLBACK = [
    { code: "EW24", name: "Jurong East", lat: 1.3332, lon: 103.7423, lines: ["EWL", "NSL"], codes: ["EW24", "NS1"], ground: "aboveground" },
    { code: "EW16", name: "Outram Park", lat: 1.2803, lon: 103.8395, lines: ["EWL", "NEL", "TEL"], codes: ["EW16", "NE3", "TE17"], ground: "underground" },
    { code: "EW14", name: "Raffles Place", lat: 1.2830, lon: 103.8513, lines: ["EWL", "NSL"], codes: ["EW14", "NS26"], ground: "underground" },
    { code: "EW13", name: "City Hall", lat: 1.2931, lon: 103.8522, lines: ["EWL", "NSL"], codes: ["EW13", "NS25"], ground: "underground" },
    { code: "EW12", name: "Bugis", lat: 1.3005, lon: 103.8558, lines: ["EWL", "DTL"], codes: ["EW12", "DT14"], ground: "underground" },
    { code: "EW2", name: "Tampines", lat: 1.3533, lon: 103.9452, lines: ["EWL", "DTL"], codes: ["EW2", "DT32"], ground: "aboveground" },
    { code: "NS24", name: "Dhoby Ghaut", lat: 1.2989, lon: 103.8459, lines: ["NSL", "NEL", "CCL"], codes: ["NS24", "NE6", "CC1"], ground: "underground" },
    { code: "NS27", name: "Marina Bay", lat: 1.2764, lon: 103.8546, lines: ["NSL", "CEL", "TEL"], codes: ["NS27", "CE2", "TE20"], ground: "underground" },
    { code: "NE1", name: "HarbourFront", lat: 1.2654, lon: 103.8222, lines: ["NEL", "CCL"], codes: ["NE1", "CC29"], ground: "underground" },
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
    const isInterchange = stn.lines && stn.lines.length > 1;
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

    const lineBadges = (stn.lines || []).map((l) => {
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
   * Uses real curved railway track alignments and the complete station database.
   */
  function renderTransitNetwork(containerId) {
    const layer = transitNetworkLayers[containerId];
    if (!layer) return;

    layer.clearLayers();

    const stationsList = (window.MRT_ALL_STATIONS && window.MRT_ALL_STATIONS.length > 0)
      ? window.MRT_ALL_STATIONS
      : MRT_STATIONS_FALLBACK;

    const trackGeometries = window.MRT_TRACK_GEOMETRIES || {};

    // 1. Draw Real Curved Metro Lines from OpenStreetMap Track Geometries
    Object.keys(LINE_META).forEach((lineId) => {
      const meta = LINE_META[lineId];
      const segments = trackGeometries[lineId];

      if (segments && segments.length > 0) {
        // Dark outer halo casing for sharp contrast and track definition
        L.polyline(segments, {
          color: "#0a0f1d",
          weight: 5.5,
          opacity: 0.85,
          lineCap: "round",
          lineJoin: "round",
        }).addTo(layer);

        // Core colored curved transit line
        const poly = L.polyline(segments, {
          color: meta.color,
          weight: 3.6,
          opacity: 0.95,
          lineCap: "round",
          lineJoin: "round",
        }).addTo(layer);

        poly.bindTooltip(`<b>${meta.name} (${lineId})</b>`, {
          sticky: true,
          opacity: 0.92,
        });
      }
    });

    // 2. Draw ALL Stations (Solid circle for normal stations, pie chart multicolor for interchanges)
    stationsList.forEach((stn) => {
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
     * Renders station crowd indicators (Green/Amber/Red rings) on stations
     */
    renderStationCrowds: function (containerId, crowdsMap) {
      const map = mapInstances[containerId];
      const layers = routeLayers[containerId];
      if (!map || !layers || !crowdsMap) return;

      const stationsList = (window.MRT_ALL_STATIONS && window.MRT_ALL_STATIONS.length > 0)
        ? window.MRT_ALL_STATIONS
        : MRT_STATIONS_FALLBACK;

      stationsList.forEach((stn) => {
        const rawLvl = crowdsMap[stn.code] || (stn.codes && stn.codes.find(c => crowdsMap[c])) ? (crowdsMap[stn.code] || crowdsMap[stn.codes.find(c => crowdsMap[c])]) : null;
        if (!rawLvl || rawLvl === 'na' || rawLvl === 'NA') return;

        let color = '#10b981'; // green
        let label = 'Low Crowd';
        if (rawLvl === 'm' || rawLvl === 'moderate') {
          color = '#f59e0b'; // amber
          label = 'Moderate Crowd';
        } else if (rawLvl === 'h' || rawLvl === 'high') {
          color = '#ef4444'; // red
          label = 'High Platform Surge';
        }

        const crowdMarker = L.circleMarker([stn.lat, stn.lon], {
          radius: 12,
          color: color,
          weight: 3,
          fillColor: color,
          fillOpacity: 0.25,
        }).addTo(layers);

        crowdMarker.bindTooltip(`<b>${stn.name}</b><br><span style="color:${color}; font-weight:bold;">${label}</span>`, {
          sticky: true,
          opacity: 0.95,
        });
      });
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
