// Leaflet JavaScript Bridge for MRT Companion (Flutter Web)
// Provides map initialization, OpenStreetMap tile rendering with strict attribution,
// multi-segment polylines (unaffected vs affected), crowd level indicators, and sheltered walkways.

window.leafletBridge = {
  map: null,
  routeLayerGroup: null,
  markerLayerGroup: null,
  shelteredLayerGroup: null,
  affectedLayerGroup: null,

  initMap: function (elementId, lat, lng, zoom) {
    if (this.map) {
      try {
        this.map.remove();
      } catch (e) {
        console.warn('Error cleaning up previous map:', e);
      }
      this.map = null;
    }

    const container = document.getElementById(elementId);
    if (!container) {
      console.warn('Map container element not found yet:', elementId);
      return false;
    }

    // Initialize Leaflet map
    this.map = L.map(elementId, {
      center: [lat || 1.3521, lng || 103.8198],
      zoom: zoom || 12,
      zoomControl: true,
      attributionControl: true
    });

    // Hard License Requirement: OpenStreetMap attribution must be strictly and always visible!
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
    }).addTo(this.map);

    // Initialize layer groups for clean updates
    this.routeLayerGroup = L.layerGroup().addTo(this.map);
    this.markerLayerGroup = L.layerGroup().addTo(this.map);
    this.shelteredLayerGroup = L.layerGroup().addTo(this.map);
    this.affectedLayerGroup = L.layerGroup().addTo(this.map);

    console.log('Leaflet map initialized successfully on', elementId);
    return true;
  },

  clearAll: function () {
    if (this.routeLayerGroup) this.routeLayerGroup.clearLayers();
    if (this.markerLayerGroup) this.markerLayerGroup.clearLayers();
    if (this.shelteredLayerGroup) this.shelteredLayerGroup.clearLayers();
    if (this.affectedLayerGroup) this.affectedLayerGroup.clearLayers();
  },

  drawRoute: function (coords, color, weight, dashArray, opacity) {
    if (!this.map || !this.routeLayerGroup) return;
    const polyline = L.polyline(coords, {
      color: color || '#009645',
      weight: weight || 6,
      dashArray: dashArray || null,
      opacity: opacity || 0.85
    });
    this.routeLayerGroup.addLayer(polyline);
  },

  drawAffectedSegment: function (coords, warningText) {
    if (!this.map || !this.affectedLayerGroup) return;
    const alertLine = L.polyline(coords, {
      color: '#EF4444',
      weight: 8,
      dashArray: '8, 8',
      opacity: 0.95
    });
    if (warningText) {
      alertLine.bindTooltip(`⚠️ ${warningText}`, {
        permanent: true,
        direction: 'top',
        className: 'disruption-tooltip'
      });
    }
    this.affectedLayerGroup.addLayer(alertLine);
  },

  drawAlternativeRoute: function (coords, color, label) {
    if (!this.map || !this.routeLayerGroup) return;
    const altLine = L.polyline(coords, {
      color: color || '#0284C7',
      weight: 5,
      dashArray: '6, 6',
      opacity: 0.9
    });
    if (label) {
      altLine.bindTooltip(label, { permanent: false, direction: 'center' });
    }
    this.routeLayerGroup.addLayer(altLine);
  },

  drawShelteredWalkways: function (segments) {
    if (!this.map || !this.shelteredLayerGroup) return;
    this.shelteredLayerGroup.clearLayers();
    for (const segment of segments) {
      const path = L.polyline(segment, {
        color: '#3B82F6',
        weight: 4,
        dashArray: '3, 6',
        opacity: 0.85
      });
      path.bindTooltip('☂️ CoveredLinkWay (Sheltered Walkway)', {
        permanent: false,
        direction: 'top'
      });
      this.shelteredLayerGroup.addLayer(path);
    }
  },

  setStationMarkers: function (stations) {
    if (!this.map || !this.markerLayerGroup) return;
    this.markerLayerGroup.clearLayers();

    stations.forEach(function (stn) {
      let crowdColor = '#22C55E';
      if (stn.crowd === 'high') crowdColor = '#EF4444';
      else if (stn.crowd === 'moderate') crowdColor = '#F59E0B';

      const marker = L.circleMarker([stn.lat, stn.lng], {
        radius: 7,
        fillColor: stn.lineColor || '#009645',
        color: '#FFFFFF',
        weight: 2,
        opacity: 1,
        fillOpacity: 0.95
      });

      marker.bindTooltip(`<b>${stn.code}</b> ${stn.name}`, {
        permanent: false,
        direction: 'top',
        offset: [0, -6]
      });

      let popupContent = `
        <div style="font-family: system-ui, sans-serif; min-width: 160px; padding: 2px;">
          <div style="font-size: 13px; font-weight: bold; color: #0F172A; border-bottom: 2px solid ${stn.lineColor || '#009645'}; padding-bottom: 4px; margin-bottom: 6px;">
            ${stn.code} ${stn.name}
          </div>
          <div style="font-size: 11px; color: #475569; margin-bottom: 4px;">
            <b>Line:</b> ${stn.lineName}
          </div>
          <div style="font-size: 11px; color: #475569; display: flex; align-items: center; margin-bottom: 4px;">
            <b style="margin-right: 4px;">Crowd:</b> 
            <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: ${crowdColor}; margin-right: 4px;"></span>
            <span style="font-weight: bold; color: ${crowdColor}; text-transform: uppercase;">${stn.crowd || 'LOW'}</span>
          </div>
          ${stn.facilityAlert ? `<div style="margin-top: 4px; padding: 4px 6px; background: #FEE2E2; border: 1px solid #EF4444; border-radius: 4px; font-size: 10px; color: #991B1B; font-weight: bold;">⚠️ ${stn.facilityAlert}</div>` : ''}
        </div>
      `;
      marker.bindPopup(popupContent);
      window.leafletBridge.markerLayerGroup.addLayer(marker);
    });
  },

  panToStation: function (lat, lng, zoom) {
    if (!this.map) return;
    this.map.setView([lat, lng], zoom || 15, { animate: true });
  },

  fitBounds: function (coords) {
    if (!this.map || !coords || coords.length === 0) return;
    try {
      this.map.fitBounds(coords, { padding: [40, 40] });
    } catch (e) {
      console.warn('Could not fit bounds:', e);
    }
  }
};

window.accessibilityBridge = {
  speak: function (text) {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.92;
      utterance.lang = 'en-SG';
      window.speechSynthesis.speak(utterance);
    }
  },

  vibrate: function (pattern) {
    if ('vibrate' in navigator) {
      navigator.vibrate(pattern);
    }
  }
};
