pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    // State
    property bool loading: false
    property string lastError: ""
    property string lastUpdated: ""

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0,
        name: ""
    })

    property var data: ({
        city: "City",
        weatherCode: 0,
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

    // Arrays for UI (hourly + daily)
    // hourly: [{ timeLabel, timeIso, temp, code, precip, precipProb, wind, gust }]
    property var hourly: ([])
    // daily: [{ dateLabel, dateIso, code, tempMin, tempMax, precipSum, precipProbMax, gustMax, uvMax }]
    property var daily: ([])
    // Computed warnings (nearby storm risk heuristics)
    // [{ title, severity, timeRange, details }]
    property var warnings: ([])

    function degToCompass16(deg) {
        if (!Number.isFinite(deg)) return "N";
        const dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        const idx = Math.floor(((deg % 360) + 360) % 360 / 22.5 + 0.5) % 16;
        return dirs[idx];
    }

    function formatTemp(value) {
        if (!Number.isFinite(value)) return "--";
        const unit = root.useUSCS ? "°F" : "°C";
        return `${value.toFixed(1)}${unit}`;
    }

    function formatWind(value) {
        if (!Number.isFinite(value)) return "--";
        const unit = root.useUSCS ? "mph" : "km/h";
        return `${value.toFixed(1)} ${unit}`;
    }

    function formatPrecip(value) {
        if (!Number.isFinite(value)) return "--";
        const unit = root.useUSCS ? "in" : "mm";
        const decimals = root.useUSCS ? 2 : 1;
        return `${value.toFixed(decimals)} ${unit}`;
    }

    function formatPressure(value) {
        if (!Number.isFinite(value)) return "--";
        // Open-Meteo returns hPa for pressure_msl
        return `${Math.round(value)} hPa`;
    }

    function formatVisibilityMeters(meters) {
        if (!Number.isFinite(meters)) return "--";
        if (root.useUSCS) {
            const miles = meters / 1609.344;
            return `${miles.toFixed(1)} mi`;
        }
        const km = meters / 1000.0;
        return `${km.toFixed(1)} km`;
    }

    function formatPercent(value) {
        if (!Number.isFinite(value)) return "--";
        return `${Math.round(value)}%`;
    }

    function formatUv(value) {
        if (!Number.isFinite(value)) return "--";
        return value.toFixed(1);
    }

    function weatherCodeToText(code) {
        // WMO Weather interpretation codes used by Open-Meteo
        switch (Number(code)) {
        case 0: return Translation.tr("Clear sky");
        case 1: return Translation.tr("Mainly clear");
        case 2: return Translation.tr("Partly cloudy");
        case 3: return Translation.tr("Overcast");
        case 45: return Translation.tr("Fog");
        case 48: return Translation.tr("Rime fog");
        case 51: return Translation.tr("Light drizzle");
        case 53: return Translation.tr("Drizzle");
        case 55: return Translation.tr("Dense drizzle");
        case 56: return Translation.tr("Freezing drizzle");
        case 57: return Translation.tr("Dense freezing drizzle");
        case 61: return Translation.tr("Light rain");
        case 63: return Translation.tr("Rain");
        case 65: return Translation.tr("Heavy rain");
        case 66: return Translation.tr("Freezing rain");
        case 67: return Translation.tr("Heavy freezing rain");
        case 71: return Translation.tr("Light snow");
        case 73: return Translation.tr("Snow");
        case 75: return Translation.tr("Heavy snow");
        case 77: return Translation.tr("Snow grains");
        case 80: return Translation.tr("Rain showers");
        case 81: return Translation.tr("Heavy rain showers");
        case 82: return Translation.tr("Violent rain showers");
        case 85: return Translation.tr("Snow showers");
        case 86: return Translation.tr("Heavy snow showers");
        case 95: return Translation.tr("Thunderstorm");
        case 96: return Translation.tr("Thunderstorm with hail");
        case 99: return Translation.tr("Thunderstorm with heavy hail");
        default:
            return Translation.tr("Unknown");
        }
    }

    function computeStormWarnings(hourlyArr, dailyArr) {
        // Heuristic "nearby" storm warnings from Open-Meteo variables (no official CAP feed in Open-Meteo).
        const warnings = [];
        const now = new Date();
        const horizonMs = 24 * 3600 * 1000;

        let maxGust = -1;
        let maxPrecip = -1;
        let thunderFirst = null;
        let thunderLast = null;

        for (let i = 0; i < hourlyArr.length; i++) {
            const t = new Date(hourlyArr[i].timeIso);
            const dt = t - now;
            if (!Number.isFinite(dt) || dt < 0 || dt > horizonMs) continue;

            const code = Number(hourlyArr[i].code);
            const gustVal = Number(hourlyArr[i].gustValue);
            const precipVal = Number(hourlyArr[i].precipValue);

            if (Number.isFinite(gustVal)) maxGust = Math.max(maxGust, gustVal);
            if (Number.isFinite(precipVal)) maxPrecip = Math.max(maxPrecip, precipVal);

            if (code === 95 || code === 96 || code === 99) {
                thunderFirst = thunderFirst ? thunderFirst : t;
                thunderLast = t;
            }
        }

        const gustWarn = root.useUSCS ? 45 : 72;   // ~ strong wind
        const gustDanger = root.useUSCS ? 55 : 88; // ~ storm
        const precipWarn = root.useUSCS ? 0.25 : 6; // mm/h-ish heuristic
        const precipDanger = root.useUSCS ? 0.45 : 12;

        function fmtTime(d) {
            return Qt.formatTime(d, "hh:mm");
        }

        if (thunderFirst) {
            warnings.push({
                title: "Nearby thunderstorm risk",
                severity: "Danger",
                timeRange: `${fmtTime(thunderFirst)}–${fmtTime(thunderLast)}`,
                details: "Thunderstorm signals detected within the next 24 hours."
            });
        }

        if (Number.isFinite(maxGust) && maxGust >= gustWarn) {
            warnings.push({
                title: "Strong wind gusts nearby",
                severity: (maxGust >= gustDanger) ? "Danger" : "Warning",
                timeRange: "Next 24h",
                details: `Peak gust: ${formatWind(maxGust)}`
            });
        }

        if (Number.isFinite(maxPrecip) && maxPrecip >= precipWarn) {
            warnings.push({
                title: "Heavy rain possible",
                severity: (maxPrecip >= precipDanger) ? "Danger" : "Warning",
                timeRange: "Next 24h",
                details: `Max hourly precipitation: ${formatPrecip(maxPrecip)}`
            });
        }

        // Escalate using daily thunderstorm codes if available
        if (dailyArr.length > 0) {
            const today = dailyArr[0];
            const todayCode = Number(today.code);
            const todayProb = Number(today.precipProbMaxValue);
            if ((todayCode === 95 || todayCode === 96 || todayCode === 99) && Number.isFinite(todayProb) && todayProb >= 60) {
                warnings.unshift({
                    title: "Storm risk today",
                    severity: "Warning",
                    timeRange: "Today",
                    details: `Rain chance: ${formatPercent(todayProb)}`
                });
            }
        }

        return warnings;
    }

    function refineOpenMeteo(payload, displayCityName) {
        const current = payload?.current || {};
        const hourlyData = payload?.hourly || {};
        const dailyData = payload?.daily || {};

        const tempOut = {};
        tempOut.city = displayCityName || root.location.name || root.city || "City";
        tempOut.weatherCode = Number(current.weather_code ?? 0);
        tempOut.isDay = Number(current.is_day ?? 1) === 1;
        tempOut.weatherDesc = weatherCodeToText(tempOut.weatherCode);

        tempOut.temp = formatTemp(Number(current.temperature_2m));
        tempOut.tempFeelsLike = formatTemp(Number(current.apparent_temperature));

        tempOut.humidity = formatPercent(Number(current.relative_humidity_2m));
        tempOut.dewPoint = formatTemp(Number(current.dew_point_2m));
        tempOut.uv = formatUv(Number(current.uv_index));
        tempOut.press = formatPressure(Number(current.pressure_msl));
        tempOut.cloudCover = formatPercent(Number(current.cloud_cover));
        tempOut.visib = formatVisibilityMeters(Number(current.visibility));

        const windDeg = Number(current.wind_direction_10m);
        tempOut.windDir = degToCompass16(windDeg);
        tempOut.wind = formatWind(Number(current.wind_speed_10m));
        tempOut.gust = formatWind(Number(current.wind_gusts_10m));
        tempOut.precip = formatPrecip(Number(current.precipitation));
        tempOut.precipProb = formatPercent(Number(current.precipitation_probability));

        // Daily summary (today min/max, sunrise/sunset)
        const dailyTimes = dailyData?.time || [];
        const dailyMax = dailyData?.temperature_2m_max || [];
        const dailyMin = dailyData?.temperature_2m_min || [];
        const dailySunrise = dailyData?.sunrise || [];
        const dailySunset = dailyData?.sunset || [];
        if (dailyTimes.length > 0) {
            tempOut.tempMax = formatTemp(Number(dailyMax[0]));
            tempOut.tempMin = formatTemp(Number(dailyMin[0]));
            const sr = dailySunrise[0] ? new Date(dailySunrise[0]) : null;
            const ss = dailySunset[0] ? new Date(dailySunset[0]) : null;
            tempOut.sunrise = sr ? Qt.formatTime(sr, "hh:mm") : "--:--";
            tempOut.sunset = ss ? Qt.formatTime(ss, "hh:mm") : "--:--";
        }

        // Build hourly array (next 24h)
        const hTimes = hourlyData?.time || [];
        const hTemp = hourlyData?.temperature_2m || [];
        const hCode = hourlyData?.weather_code || [];
        const hPrecip = hourlyData?.precipitation || [];
        const hPrecipProb = hourlyData?.precipitation_probability || [];
        const hWind = hourlyData?.wind_speed_10m || [];
        const hGust = hourlyData?.wind_gusts_10m || [];
        const hourlyOut = [];
        const now = new Date();
        const horizonMs = 24 * 3600 * 1000;

        for (let i = 0; i < hTimes.length; i++) {
            const d = new Date(hTimes[i]);
            const dt = d - now;
            if (!Number.isFinite(dt) || dt < 0 || dt > horizonMs) continue;
            hourlyOut.push({
                timeLabel: Qt.formatTime(d, "hh:mm"),
                timeIso: hTimes[i],
                temp: formatTemp(Number(hTemp[i])),
                code: Number(hCode[i] ?? 0),
                precip: formatPrecip(Number(hPrecip[i])),
                precipProb: formatPercent(Number(hPrecipProb[i])),
                wind: formatWind(Number(hWind[i])),
                gust: formatWind(Number(hGust[i])),

                // raw for warning computations
                precipValue: Number(hPrecip[i]),
                gustValue: Number(hGust[i])
            });
        }

        // Build daily array (7 days)
        const dCode = dailyData?.weather_code || [];
        const dPrecipSum = dailyData?.precipitation_sum || [];
        const dPrecipProbMax = dailyData?.precipitation_probability_max || [];
        const dGustMax = dailyData?.wind_gusts_10m_max || [];
        const dUvMax = dailyData?.uv_index_max || [];
        const dailyOut = [];
        for (let i = 0; i < dailyTimes.length; i++) {
            const d = dailyTimes[i] ? new Date(dailyTimes[i] + "T00:00:00") : null;
            dailyOut.push({
                dateLabel: d ? Qt.formatDate(d, "ddd dd/MM") : (dailyTimes[i] || ""),
                dateIso: dailyTimes[i] || "",
                code: Number(dCode[i] ?? 0),
                tempMin: formatTemp(Number(dailyMin[i])),
                tempMax: formatTemp(Number(dailyMax[i])),
                precipSum: formatPrecip(Number(dPrecipSum[i])),
                precipProbMax: formatPercent(Number(dPrecipProbMax[i])),
                gustMax: formatWind(Number(dGustMax[i])),
                uvMax: formatUv(Number(dUvMax[i])),

                precipProbMaxValue: Number(dPrecipProbMax[i])
            });
        }

        root.data = tempOut;
        root.hourly = hourlyOut;
        root.daily = dailyOut;
        root.warnings = computeStormWarnings(hourlyOut, dailyOut);
    }

    function getData() {
        root.lastError = "";
        root.loading = true;

        if (root.gpsActive && root.location.valid) {
            fetchOpenMeteo(root.location.lat, root.location.lon, root.location.name || Translation.tr("Current location"));
            return;
        }

        geocodeCity(root.city);
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
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
        // Note: Open-Meteo does not provide official CAP warnings; warnings below are computed heuristics.
        const query = [
            `latitude=${lat}`,
            `longitude=${lon}`,
            "timezone=auto",
            "forecast_days=7",

            `temperature_unit=${tempUnit}`,
            `wind_speed_unit=${windUnit}`,
            `precipitation_unit=${precipUnit}`,

            "current=temperature_2m,relative_humidity_2m,apparent_temperature,dew_point_2m,weather_code,is_day,pressure_msl,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,precipitation_probability,uv_index",
            "hourly=temperature_2m,weather_code,precipitation,precipitation_probability,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
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
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
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
