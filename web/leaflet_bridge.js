// Leaflet Bridge for MRT Companion (Flutter Web)
// Provides bridge between Flutter and Leaflet for OpenStreetMap rendering.

(function () {
  const mapInstances = {};
  const layerGroups = {};

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
        zoomControl: true,
        attributionControl: true,
      });

      // Mandatory OpenStreetMap Attribution (Hard requirement of ODbL licence)
      L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors',
      }).addTo(map);

      // Create a layer group for dynamic overlays
      const layers = L.layerGroup().addTo(map);

      mapInstances[containerId] = map;
      layerGroups[containerId] = layers;

      // Invalidate size once rendered in DOM
      setTimeout(() => {
        map.invalidateSize();
      }, 200);

      return true;
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
     * Clears all dynamic markers and route polylines
     */
    clearLayers: function (containerId) {
      const layers = layerGroups[containerId];
      if (layers) {
        layers.clearLayers();
      }
    },

    /**
     * Renders a primary route, visually distinguishing affected segments.
     * @param {string} containerId
     * @param {Array<[number, number]>} unaffectedCoords - [[lat, lng], ...]
     * @param {Array<[number, number]>} affectedCoords - [[lat, lng], ...]
     * @param {Array<[number, number]>} alternativeCoords - [[lat, lng], ...]
     */
    renderRoute: function (containerId, unaffectedCoords, affectedCoords, alternativeCoords) {
      const map = mapInstances[containerId];
      const layers = layerGroups[containerId];
      if (!map || !layers) return;

      layers.clearLayers();
      const allBounds = [];

      // 1. Alternative Route (Shown alongside original, dashed cyan/blue)
      if (alternativeCoords && alternativeCoords.length > 1) {
        const altPolyline = L.polyline(alternativeCoords, {
          color: "#0284c7", // Sky blue
          weight: 4,
          dashArray: "6, 8",
          opacity: 0.85,
        }).addTo(layers);
        altPolyline.bindPopup("<b>Alternative Route (Rerouted)</b>");
        allBounds.push(...alternativeCoords);
      }

      // 2. Unaffected Route Segment (Solid MRT emerald green)
      if (unaffectedCoords && unaffectedCoords.length > 1) {
        const normPolyline = L.polyline(unaffectedCoords, {
          color: "#059669", // Emerald green
          weight: 6,
          opacity: 0.9,
        }).addTo(layers);
        normPolyline.bindPopup("<b>MRT Route (Normal Operation)</b>");
        allBounds.push(...unaffectedCoords);
      }

      // 3. Affected Route Segment (Visually distinct warning color: Red/Orange dashed)
      if (affectedCoords && affectedCoords.length > 1) {
        const affPolyline = L.polyline(affectedCoords, {
          color: "#dc2626", // Red alert
          weight: 6,
          dashArray: "8, 6",
          opacity: 0.95,
        }).addTo(layers);
        affPolyline.bindPopup("<b>Disrupted / Delayed Segment</b><br>Mitigation in effect.");
        allBounds.push(...affectedCoords);
      }

      if (allBounds.length > 1) {
        map.fitBounds(allBounds, { padding: [40, 40] });
      }
    },

    /**
     * Renders station markers with crowd level indicators (Low/Moderate/High)
     * @param {string} containerId
     * @param {Array<Object>} stations - [{name, code, lat, lon, crowd, groundLevel, alert}]
     */
    renderStations: function (containerId, stations) {
      const map = mapInstances[containerId];
      const layers = layerGroups[containerId];
      if (!map || !layers || !stations) return;

      stations.forEach((stn) => {
        let crowdColor = "#10b981"; // Low (Green)
        let crowdText = "Low Crowding";
        if (stn.crowd === "m" || stn.crowd === "moderate") {
          crowdColor = "#f59e0b"; // Moderate (Amber)
          crowdText = "Moderate Crowding";
        } else if (stn.crowd === "h" || stn.crowd === "high") {
          crowdColor = "#ef4444"; // High (Red)
          crowdText = "High Crowding";
        }

        const markerHtml = `
          <div style="
            background: #ffffff;
            border: 3px solid ${crowdColor};
            box-shadow: 0 2px 6px rgba(0,0,0,0.35);
            border-radius: 50%;
            width: 22px;
            height: 22px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: bold;
            color: #1f2937;
          ">
            <div style="width: 8px; height: 8px; border-radius: 50%; background: ${crowdColor};"></div>
          </div>
        `;

        const icon = L.divIcon({
          className: "mrt-station-icon",
          html: markerHtml,
          iconSize: [22, 22],
          iconAnchor: [11, 11],
        });

        const popupContent = `
          <div style="font-family: sans-serif; font-size: 13px; min-width: 140px;">
            <b style="font-size: 14px;">${stn.name}</b> (${stn.code})<br/>
            <span style="color: ${crowdColor}; font-weight: bold;">● ${crowdText}</span><br/>
            <span style="color: #6b7280; font-size: 12px;">Ground: ${stn.groundLevel || "N/A"}</span>
            ${stn.alert ? `<div style="margin-top:4px; color:#b91c1c; font-size:12px;">⚠️ ${stn.alert}</div>` : ""}
          </div>
        `;

        L.marker([stn.lat, stn.lon], { icon: icon })
          .bindPopup(popupContent)
          .addTo(layers);
      });
    },

    /**
     * Renders sheltered walkway / CoveredLinkWay segments for accessibility routing (Mdm Lim)
     */
    renderShelteredWalkway: function (containerId, coords) {
      const layers = layerGroups[containerId];
      if (!layers || !coords) return;

      L.polyline(coords, {
        color: "#0d9488", // Teal sheltered walkway
        weight: 5,
        opacity: 0.8,
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
