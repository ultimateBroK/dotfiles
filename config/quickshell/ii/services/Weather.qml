pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

import "weather/OpenMeteo.js" as OpenMeteo

Singleton {
    id: root

    // Config
    // fetchInterval is in ms
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    // State
    property bool loading: false
    property string lastError: ""
    property string lastUpdated: ""

    onUseUSCSChanged: root.getData()
    onCityChanged: root.getData()

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0,
        name: ""
    })

    // Flat object used by widgets/popups
    property var data: ({
        city: "City",

        // New key
        weatherCode: 0,
        // Back-compat for older UI usage (`Weather.data.wCode`)
        wCode: 0,

        isDay: true,
        weatherDesc: "Unknown",

        temp: "--",
        tempFeelsLike: "--",
        tempMax: "--",
        tempMin: "--",

        humidity: "--",
        dewPoint: "--",
        uv: "--",
        press: "--",
        cloudCover: "--",
        visib: "--",

        windDir: "N",
        wind: "--",
        gust: "--",
        precip: "--",
        precipProb: "--",

        sunrise: "--:--",
        sunset: "--:--"
    })

    // Arrays for UI
    // hourly: [{ timeLabel, timeIso, temp, code, precip, precipProb, wind, gust, ...rawValues }]
    property var hourly: ([])
    // daily: [{ dateLabel, dateIso, code, tempMin, tempMax, precipSum, precipProbMax, gustMax, uvMax }]
    property var daily: ([])
    // warnings: [{ title, severity, severityLevel, timeRange, details, icon, isActive }]
    property var warnings: ([])

    // --- Data refinement (pure logic lives in services/weather/*) ---

    function refineOpenMeteo(payload, displayCityName) {
        const refined = OpenMeteo.refine(payload, {
            displayCityName: displayCityName,
            locationName: root.location.name,
            city: root.city,
            useUSCS: root.useUSCS,
            tr: Translation.tr
        });

        root.data = refined.data;
        root.hourly = refined.hourly;
        root.daily = refined.daily;
        root.warnings = refined.warnings;
    }

    // --- Fetch orchestration ---

    function getData() {
        root.lastError = "";
        root.loading = true;

        if (root.gpsActive && root.location.valid) {
            fetchOpenMeteo(root.location.lat, root.location.lon, root.location.name || Translation.tr("Current location"));
            return;
        }

        geocodeCity(root.city);
    }

    function geocodeCity(cityName) {
        const name = (cityName || "").trim();
        if (name.length === 0) {
            root.loading = false;
            root.lastError = Translation.tr("City is empty");
            return;
        }
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(name)}&count=1&language=en&format=json`;
        geocodeFetcher.command[2] = `curl -sL --max-time 10 '${url}'`;
        geocodeFetcher.running = true;
    }

    function fetchOpenMeteo(lat, lon, displayCityName) {
        const base = "https://api.open-meteo.com/v1/forecast";

        const tempUnit = root.useUSCS ? "fahrenheit" : "celsius";
        const windUnit = root.useUSCS ? "mph" : "kmh";
        const precipUnit = root.useUSCS ? "inch" : "mm";

        // Request rich current/hourly/daily variables
        // Note: Open-Meteo does not provide official CAP warnings; warnings are computed heuristics.
        const query = [
            `latitude=${lat}`,
            `longitude=${lon}`,
            "timezone=auto",
            "forecast_days=7",

            `temperature_unit=${tempUnit}`,
            `wind_speed_unit=${windUnit}`,
            `precipitation_unit=${precipUnit}`,

            "current=temperature_2m,relative_humidity_2m,apparent_temperature,dew_point_2m,weather_code,is_day,pressure_msl,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,precipitation_probability,uv_index",
            "hourly=temperature_2m,relative_humidity_2m,dew_point_2m,apparent_temperature,weather_code,precipitation,precipitation_probability,wind_speed_10m,wind_direction_10m,wind_gusts_10m,visibility,uv_index",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,precipitation_probability_max,wind_gusts_10m_max,uv_index_max"
        ].join("&");

        const url = `${base}?${query}`;
        weatherFetcher.command[2] = `curl -sL --max-time 10 '${url}'`;
        weatherFetcherCityName = displayCityName || "";
        weatherFetcher.running = true;
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    // --- Fetchers ---

    Process {
        id: geocodeFetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    const r = parsedData?.results?.[0];
                    if (!r) {
                        root.loading = false;
                        root.lastError = Translation.tr("Cannot geocode city");
                        return;
                    }
                    root.location.lat = Number(r.latitude);
                    root.location.lon = Number(r.longitude);
                    root.location.valid = Number.isFinite(root.location.lat) && Number.isFinite(root.location.lon);
                    const nameBits = [];
                    if (r.name) nameBits.push(r.name);
                    if (r.admin1) nameBits.push(r.admin1);
                    if (r.country) nameBits.push(r.country);
                    root.location.name = nameBits.join(", ") || root.city;
                    fetchOpenMeteo(root.location.lat, root.location.lon, root.location.name);
                } catch (e) {
                    root.loading = false;
                    root.lastError = e.message;
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }

    property string weatherFetcherCityName: ""
    Process {
        id: weatherFetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineOpenMeteo(parsedData, root.weatherFetcherCityName);
                    root.lastUpdated = Qt.formatDateTime(new Date(), "ddd dd/MM hh:mm");
                    root.loading = false;
                } catch (e) {
                    root.loading = false;
                    root.lastError = e.message;
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }

    // --- GPS and polling ---

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude;
                root.location.valid = true;
                root.location.name = Translation.tr("Current location");
                root.getData();
            } else {
                // if can't get initialized with valid location deactivate the GPS
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
