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

    function computeStormWarnings(hourlyArr, dailyArr, current) {
        // Global hazard heuristics based on Open-Meteo variables (no official CAP alerts in Open-Meteo).
        // Designed to be useful when traveling to other countries/climates.
        const warnings = [];
        const seen = {};
        const now = new Date();
        const horizonMs = 24 * 3600 * 1000;

        function addOrUpgradeWarning(id, obj) {
            // Prefer "active now" and higher severity.
            if (!seen[id]) {
                seen[id] = warnings.length;
                warnings.push(obj);
                return;
            }
            const idx = seen[id];
            const old = warnings[idx];
            const oldActive = !!old.isActive;
            const newActive = !!obj.isActive;
            const oldSev = Number(old.severityLevel ?? 0);
            const newSev = Number(obj.severityLevel ?? 0);
            if ((newActive && !oldActive) || (newSev > oldSev)) {
                warnings[idx] = obj;
            }
        }

        function fmtTime(d) {
            return Qt.formatTime(d, "hh:mm");
        }

        function dayLabel(d) {
            // Local day labels
            const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            const startOfThat = new Date(d.getFullYear(), d.getMonth(), d.getDate());
            const diffDays = Math.round((startOfThat - startOfToday) / (24 * 3600 * 1000));
            if (diffDays === 0) return "Today";
            if (diffDays === 1) return "Tomorrow";
            return Qt.formatDate(d, "ddd dd/MM");
        }

        function relativeFromNow(d) {
            const diffMs = d - now;
            const absMin = Math.round(Math.abs(diffMs) / 60000);
            if (absMin <= 10) return "Now";
            if (diffMs > 0) {
                const h = Math.floor(absMin / 60);
                const m = absMin % 60;
                if (h > 0 && m > 0) return `In ${h}h ${m}m`;
                if (h > 0) return `In ${h}h`;
                return `In ${m}m`;
            } else {
                const h = Math.floor(absMin / 60);
                const m = absMin % 60;
                if (h > 0 && m > 0) return `Started ${h}h ${m}m ago`;
                if (h > 0) return `Started ${h}h ago`;
                return `Started ${m}m ago`;
            }
        }

        function describeWhen(first, last, isActive) {
            if (!first) return "Next 24h";
            const end = last ? last : first;
            const sameHour = Math.abs(end - first) < 45 * 60000;
            const startTxt = `${dayLabel(first)} ${fmtTime(first)}`;
            const endTxt = `${fmtTime(end)}`;
            if (isActive) {
                // show end time if we have it
                return sameHour ? `Now • ${startTxt}` : `Now • until ${dayLabel(end)} ${endTxt}`;
            }
            if (sameHour) {
                return `${relativeFromNow(first)} • ${startTxt}`;
            }
            return `${relativeFromNow(first)} • ${startTxt}–${endTxt}`;
        }

        // Thresholds (units follow API settings)
        const gustWarn = root.useUSCS ? 45 : 72;   // mph / km/h
        const gustDanger = root.useUSCS ? 55 : 88;
        const precipWarn = root.useUSCS ? 0.25 : 6; // in/h-ish / mm/h-ish (Open-Meteo hourly precip)
        const precipDanger = root.useUSCS ? 0.45 : 12;

        const heatWarn = root.useUSCS ? 95 : 35;    // °F / °C (apparent temperature)
        const heatDanger = root.useUSCS ? 104 : 40;
        const coldWarn = root.useUSCS ? 32 : 0;
        const coldDanger = root.useUSCS ? 23 : -5;

        const visWarn = 1000;   // meters
        const visDanger = 300;  // meters

        const uvWarn = 8;
        const uvDanger = 11;

        // Heat index / wind chill (explicit, travel-friendly)
        const heatIndexWarn = root.useUSCS ? 90 : 32;     // °F / °C
        const heatIndexDanger = root.useUSCS ? 104 : 40;
        const windChillWarn = root.useUSCS ? 32 : 0;      // °F / °C
        const windChillDanger = root.useUSCS ? 14 : -10;

        // Humidity / dew point comfort hazards (travel-friendly)
        const dewWarn = root.useUSCS ? 75 : 24;     // °F / °C
        const dewDanger = root.useUSCS ? 79 : 26;
        const dryWarn = 15;   // %
        const dryDanger = 10; // %

        // Ice risk near freezing with precipitation
        const iceTempHigh = root.useUSCS ? 34 : 1;   // °F / °C
        const iceTempLow = root.useUSCS ? 28 : -2;
        const icePrecip = root.useUSCS ? 0.02 : 0.4; // inch / mm per hour

        function heatIndex(temp, rh) {
            // Returns heat index in the same temperature unit as inputs (F if useUSCS, else C).
            if (!Number.isFinite(temp) || !Number.isFinite(rh)) return NaN;
            const RH = Math.max(0, Math.min(100, rh));
            // Heat index formula is defined for warmer temps; below that it's not meaningful.
            const tF = root.useUSCS ? temp : (temp * 9 / 5 + 32);
            if (tF < 80 || RH < 40) return NaN;

            // Rothfusz regression (NOAA)
            let hiF =
                -42.379 +
                2.04901523 * tF +
                10.14333127 * RH +
                -0.22475541 * tF * RH +
                -0.00683783 * tF * tF +
                -0.05481717 * RH * RH +
                0.00122874 * tF * tF * RH +
                0.00085282 * tF * RH * RH +
                -0.00000199 * tF * tF * RH * RH;

            // Simple adjustments (optional but improves realism on edges)
            if (RH < 13 && tF >= 80 && tF <= 112) {
                hiF -= ((13 - RH) / 4) * Math.sqrt((17 - Math.abs(tF - 95)) / 17);
            } else if (RH > 85 && tF >= 80 && tF <= 87) {
                hiF += ((RH - 85) / 10) * ((87 - tF) / 5);
            }

            return root.useUSCS ? hiF : ((hiF - 32) * 5 / 9);
        }

        function windChill(temp, wind) {
            // Returns wind chill in same temperature unit as inputs.
            if (!Number.isFinite(temp) || !Number.isFinite(wind)) return NaN;
            if (root.useUSCS) {
                const tF = temp;
                const v = wind; // mph
                if (tF > 50 || v <= 3) return NaN;
                const wcF = 35.74 + 0.6215 * tF - 35.75 * Math.pow(v, 0.16) + 0.4275 * tF * Math.pow(v, 0.16);
                return wcF;
        } else {
                const tC = temp;
                const v = wind; // km/h
                if (tC > 10 || v <= 4.8) return NaN;
                const wcC = 13.12 + 0.6215 * tC - 11.37 * Math.pow(v, 0.16) + 0.3965 * tC * Math.pow(v, 0.16);
                return wcC;
            }
        }

        // Aggregates
        let maxGust = -1;
        let maxPrecip = -1;
        let minVis = Number.POSITIVE_INFINITY;
        let minFogVis = Number.POSITIVE_INFINITY;
        let maxUv = -1;
        let maxAppTemp = -1e9;
        let minAppTemp = 1e9;
        let maxHeatIndex = -1e9;
        let minWindChill = 1e9;

        let thunderFirst = null, thunderLast = null;
        let freezingFirst = null, freezingLast = null;
        let fogFirst = null, fogLast = null;
        let snowFirst = null, snowLast = null;
        let heatFirst = null, heatLast = null;
        let coldFirst = null, coldLast = null;
        let uvFirst = null, uvLast = null;
        let humidFirst = null, humidLast = null;
        let dryFirst = null, dryLast = null;
        let iceFirst = null, iceLast = null;
        let heatStressFirst = null, heatStressLast = null;
        let windChillFirst = null, windChillLast = null;

        let hasHeavySnow = false;
        let hasHail = false;

        const includePastMs = 55 * 60 * 1000; // include current hour window for "now" feel
        for (let i = 0; i < hourlyArr.length; i++) {
            const t = new Date(hourlyArr[i].timeIso);
            const dt = t - now;
            if (!Number.isFinite(dt) || dt < -includePastMs || dt > horizonMs) continue;

            const code = Number(hourlyArr[i].code);
            const gustVal = Number(hourlyArr[i].gustValue);
            const precipVal = Number(hourlyArr[i].precipValue);
            const visVal = Number(hourlyArr[i].visibilityValue);
            const uvVal = Number(hourlyArr[i].uvValue);
            const appVal = Number(hourlyArr[i].apparentTempValue);
            const rhVal = Number(hourlyArr[i].humidityValue);
            const dewVal = Number(hourlyArr[i].dewPointValue);
            const tempVal = Number(hourlyArr[i].tempValue);
            const windVal = Number(hourlyArr[i].windSpeedValue);

            if (Number.isFinite(gustVal)) maxGust = Math.max(maxGust, gustVal);
            if (Number.isFinite(precipVal)) maxPrecip = Math.max(maxPrecip, precipVal);
            if (Number.isFinite(visVal)) minVis = Math.min(minVis, visVal);
            if (Number.isFinite(uvVal)) maxUv = Math.max(maxUv, uvVal);
            if (Number.isFinite(appVal)) {
                maxAppTemp = Math.max(maxAppTemp, appVal);
                minAppTemp = Math.min(minAppTemp, appVal);
            }

            const hiVal = heatIndex(tempVal, rhVal);
            if (Number.isFinite(hiVal)) {
                maxHeatIndex = Math.max(maxHeatIndex, hiVal);
                if (hiVal >= heatIndexWarn) {
                    heatStressFirst = heatStressFirst ? heatStressFirst : t;
                    heatStressLast = t;
                }
            }

            const wcVal = windChill(tempVal, windVal);
            if (Number.isFinite(wcVal)) {
                minWindChill = Math.min(minWindChill, wcVal);
                if (wcVal <= windChillWarn) {
                    windChillFirst = windChillFirst ? windChillFirst : t;
                    windChillLast = t;
                }
            }

            // Thunderstorm
            if (code === 95 || code === 96 || code === 99) {
                thunderFirst = thunderFirst ? thunderFirst : t;
                thunderLast = t;
                if (code === 96 || code === 99) hasHail = true;
            }

            // Freezing rain / drizzle
            if (code === 56 || code === 57 || code === 66 || code === 67) {
                freezingFirst = freezingFirst ? freezingFirst : t;
                freezingLast = t;
            }

            // Snow / ice risk
            if ((code >= 71 && code <= 77) || code === 85 || code === 86) {
                snowFirst = snowFirst ? snowFirst : t;
                snowLast = t;
                if (code === 75 || code === 86) hasHeavySnow = true;
            }

            // Fog / low visibility
            const fogByCode = (code === 45 || code === 48);
            const fogByVis = Number.isFinite(visVal) && visVal <= visWarn;
            if (fogByCode || fogByVis) {
                fogFirst = fogFirst ? fogFirst : t;
                fogLast = t;
                if (Number.isFinite(visVal)) minFogVis = Math.min(minFogVis, visVal);
            }

            // Heat/cold (apparent temperature)
            if (Number.isFinite(appVal) && appVal >= heatWarn) {
                heatFirst = heatFirst ? heatFirst : t;
                heatLast = t;
            }
            if (Number.isFinite(appVal) && appVal <= coldWarn) {
                coldFirst = coldFirst ? coldFirst : t;
                coldLast = t;
            }

            // UV
            if (Number.isFinite(uvVal) && uvVal >= uvWarn) {
                uvFirst = uvFirst ? uvFirst : t;
                uvLast = t;
            }

            // Oppressive humidity (dew point) and very dry air
            if (Number.isFinite(dewVal) && dewVal >= dewWarn) {
                humidFirst = humidFirst ? humidFirst : t;
                humidLast = t;
            }
            if (Number.isFinite(rhVal) && rhVal <= dryWarn) {
                dryFirst = dryFirst ? dryFirst : t;
                dryLast = t;
            }

            // Black ice / slippery risk near freezing with precipitation
            if (Number.isFinite(appVal) && Number.isFinite(precipVal) && precipVal >= icePrecip && appVal <= iceTempHigh && appVal >= iceTempLow) {
                iceFirst = iceFirst ? iceFirst : t;
                iceLast = t;
            }
        }

        // "Active now" checks using current snapshot (more real-time)
        const curCode = Number(current?.weather_code);
        const curGust = Number(current?.wind_gusts_10m);
        const curPrecip = Number(current?.precipitation);
        const curVis = Number(current?.visibility);
        const curUv = Number(current?.uv_index);
        const curApp = Number(current?.apparent_temperature);
        const curRh = Number(current?.relative_humidity_2m);
        const curDew = Number(current?.dew_point_2m);
        const curTemp = Number(current?.temperature_2m);
        const curWind = Number(current?.wind_speed_10m);

        const currentThunder = (curCode === 95 || curCode === 96 || curCode === 99);
        const currentHail = (curCode === 96 || curCode === 99);
        const currentFreezing = (curCode === 56 || curCode === 57 || curCode === 66 || curCode === 67);
        const currentSnow = ((curCode >= 71 && curCode <= 77) || curCode === 85 || curCode === 86);
        const currentFog = (curCode === 45 || curCode === 48) || (Number.isFinite(curVis) && curVis <= visWarn);

        // Build warnings (ordered by typical severity)
        if (currentThunder) {
            addOrUpgradeWarning("thunder", {
                kind: "thunder",
                icon: "thunderstorm",
                severityLevel: 2,
                isActive: true,
                title: currentHail ? "Thunderstorm now (hail possible)" : "Thunderstorm now",
                severity: "Danger",
                timeRange: "Now",
                details: "Storm conditions detected right now."
            });
        }
        if (currentFreezing) {
            addOrUpgradeWarning("freezing", {
                kind: "freezing",
                icon: "severe_cold",
                severityLevel: 2,
                isActive: true,
                title: "Freezing rain / ice now",
                severity: "Danger",
                timeRange: "Now",
                details: "Icy conditions detected right now."
            });
        }
        if (currentSnow) {
            addOrUpgradeWarning("snow", {
                kind: "snow",
                icon: "ac_unit",
                severityLevel: 1,
                isActive: true,
                title: "Snow / icy conditions now",
                severity: "Warning",
                timeRange: "Now",
                details: "Snow/ice conditions detected right now."
            });
        }
        if (currentFog) {
            const sev = (Number.isFinite(curVis) && curVis <= visDanger) ? 2 : 1;
            const detail = Number.isFinite(curVis) ? `Visibility: ${formatVisibilityMeters(curVis)}` : "Low visibility possible.";
            addOrUpgradeWarning("fog", {
                kind: "fog",
                icon: "foggy",
                severityLevel: sev,
                isActive: true,
                title: "Fog / low visibility now",
                severity: sev >= 2 ? "Danger" : "Warning",
                timeRange: "Now",
                details: detail
            });
        }
        if (Number.isFinite(curGust) && curGust >= gustWarn) {
            addOrUpgradeWarning("wind", {
                kind: "wind",
                icon: "air",
                severityLevel: (curGust >= gustDanger) ? 2 : 1,
                isActive: true,
                title: "Strong wind gusts now",
                severity: (curGust >= gustDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Gust: ${formatWind(curGust)}`
            });
        }
        if (Number.isFinite(curPrecip) && curPrecip >= precipWarn) {
            addOrUpgradeWarning("rain", {
                kind: "rain",
                icon: "rainy",
                severityLevel: (curPrecip >= precipDanger) ? 2 : 1,
                isActive: true,
                title: "Heavy rain now",
                severity: (curPrecip >= precipDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Precipitation: ${formatPrecip(curPrecip)}`
            });
        }
        const curHi = heatIndex(curTemp, curRh);
        if (Number.isFinite(curHi) && curHi >= heatIndexWarn) {
            addOrUpgradeWarning("heat", {
                kind: "heat_stress",
                icon: "whatshot",
                severityLevel: (curHi >= heatIndexDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Heat stress now",
                severity: (curHi >= heatIndexDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Heat index: ${formatTemp(curHi)} (Temp: ${formatTemp(curTemp)} • Humidity: ${Math.round(curRh)}%)`
            });
        } else if (Number.isFinite(curApp) && curApp >= heatWarn) {
            addOrUpgradeWarning("heat", {
                kind: "heat",
                icon: "device_thermostat",
                severityLevel: (curApp >= heatDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Heat risk now",
                severity: (curApp >= heatDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Apparent temperature: ${formatTemp(curApp)}`
            });
        }

        const curWc = windChill(curTemp, curWind);
        if (Number.isFinite(curWc) && curWc <= windChillWarn) {
            addOrUpgradeWarning("cold", {
                kind: "wind_chill",
                icon: "air",
                severityLevel: (curWc <= windChillDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Wind chill now",
                severity: (curWc <= windChillDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Wind chill: ${formatTemp(curWc)} (Temp: ${formatTemp(curTemp)} • Wind: ${formatWind(curWind)})`
            });
        } else if (Number.isFinite(curApp) && curApp <= coldWarn) {
            addOrUpgradeWarning("cold", {
                kind: "cold",
                icon: "ac_unit",
                severityLevel: (curApp <= coldDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Cold / frost risk now",
                severity: (curApp <= coldDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Apparent temperature: ${formatTemp(curApp)}`
            });
        }
        if (Number.isFinite(curUv) && curUv >= uvWarn) {
            addOrUpgradeWarning("uv", {
                kind: "uv",
                icon: "wb_sunny",
                severityLevel: (curUv >= uvDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "High UV exposure now",
                severity: (curUv >= uvDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `UV index: ${curUv.toFixed(1)}`
            });
        }

        if (Number.isFinite(curDew) && curDew >= dewWarn) {
            addOrUpgradeWarning("humidity", {
                kind: "humidity",
                icon: "humidity_high",
                severityLevel: (curDew >= dewDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Oppressive humidity now",
                severity: (curDew >= dewDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Dew point: ${formatTemp(curDew)}`
            });
        }

        if (Number.isFinite(curRh) && curRh <= dryWarn) {
            addOrUpgradeWarning("dry", {
                kind: "dry",
                icon: "airwave",
                severityLevel: (curRh <= dryDanger) ? 2 : 1,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Very dry air now",
                severity: (curRh <= dryDanger) ? "Danger" : "Warning",
                timeRange: "Now",
                details: `Humidity: ${Math.round(curRh)}%`
            });
        }

        if (Number.isFinite(curApp) && Number.isFinite(curPrecip) && curPrecip >= icePrecip && curApp <= iceTempHigh && curApp >= iceTempLow) {
            addOrUpgradeWarning("ice", {
                kind: "ice",
                icon: "sledding",
                severityLevel: 2,
                isActive: true,
                startTimeMs: now.getTime(),
                title: "Black ice / slippery risk now",
                severity: "Danger",
                timeRange: "Now",
                details: `Near-freezing with precipitation (${formatTemp(curApp)} • ${formatPrecip(curPrecip)})`
            });
        }

        // Build warnings (ordered by typical severity)
        if (thunderFirst) {
            addOrUpgradeWarning("thunder", {
                kind: "thunder",
                icon: "thunderstorm",
                severityLevel: 2,
                isActive: false,
                startTimeMs: thunderFirst.getTime(),
                title: hasHail ? "Thunderstorm risk (hail possible)" : "Nearby thunderstorm risk",
                severity: "Danger",
                timeRange: describeWhen(thunderFirst, thunderLast, false),
                details: "Thunderstorm signals detected within the next 24 hours."
            });
        }

        if (freezingFirst) {
            addOrUpgradeWarning("freezing", {
                kind: "freezing",
                icon: "severe_cold",
                severityLevel: 2,
                isActive: false,
                startTimeMs: freezingFirst.getTime(),
                title: "Freezing rain / ice risk",
                severity: "Danger",
                timeRange: describeWhen(freezingFirst, freezingLast, false),
                details: "Icy conditions possible (slippery roads/sidewalks)."
            });
        }

        if (snowFirst) {
            addOrUpgradeWarning("snow", {
                kind: "snow",
                icon: "ac_unit",
                severityLevel: hasHeavySnow ? 2 : 1,
                isActive: false,
                startTimeMs: snowFirst.getTime(),
                title: hasHeavySnow ? "Heavy snow risk" : "Snow / icy conditions possible",
                severity: hasHeavySnow ? "Danger" : "Warning",
                timeRange: describeWhen(snowFirst, snowLast, false),
                details: "Reduced visibility and slippery surfaces may occur."
            });
        }

        if (fogFirst) {
            const sev = (Number.isFinite(minVis) && minVis <= visDanger) ? "Danger" : "Warning";
            const fogSevLevel = (Number.isFinite(minFogVis) && minFogVis <= visDanger) ? 2 : 1;
            const detail = Number.isFinite(minFogVis) && minFogVis !== Number.POSITIVE_INFINITY && minFogVis <= 5000
                ? `Lowest visibility: ${formatVisibilityMeters(minFogVis)}`
                : "Forecast indicates fog / reduced visibility.";
            addOrUpgradeWarning("fog", {
                kind: "fog",
                icon: "foggy",
                severityLevel: fogSevLevel,
                isActive: false,
                startTimeMs: fogFirst.getTime(),
                title: "Fog / low visibility",
                severity: fogSevLevel >= 2 ? "Danger" : "Warning",
                timeRange: describeWhen(fogFirst, fogLast, false),
                details: detail
            });
        }

        if (Number.isFinite(maxGust) && maxGust >= gustWarn) {
            addOrUpgradeWarning("wind", {
                kind: "wind",
                icon: "air",
                severityLevel: (maxGust >= gustDanger) ? 2 : 1,
                isActive: false,
                startTimeMs: now.getTime(),
                title: "Strong wind gusts nearby",
                severity: (maxGust >= gustDanger) ? "Danger" : "Warning",
                timeRange: "Next 24h",
                details: `Peak gust: ${formatWind(maxGust)}`
            });
        }

        if (Number.isFinite(maxPrecip) && maxPrecip >= precipWarn) {
            addOrUpgradeWarning("rain", {
                kind: "rain",
                icon: "rainy",
                severityLevel: (maxPrecip >= precipDanger) ? 2 : 1,
                isActive: false,
                startTimeMs: now.getTime(),
                title: "Heavy rain possible",
                severity: (maxPrecip >= precipDanger) ? "Danger" : "Warning",
                timeRange: "Next 24h",
                details: `Max hourly precipitation: ${formatPrecip(maxPrecip)}`
            });
        }

        if (heatStressFirst) {
            const sevLevel = Number.isFinite(maxHeatIndex) && maxHeatIndex >= heatIndexDanger ? 2 : 1;
            addOrUpgradeWarning("heat", {
                kind: "heat_stress",
                icon: "whatshot",
                severityLevel: sevLevel,
                isActive: false,
                startTimeMs: heatStressFirst.getTime(),
                title: "Heat stress risk",
                severity: sevLevel >= 2 ? "Danger" : "Warning",
                timeRange: describeWhen(heatStressFirst, heatStressLast, false),
                details: Number.isFinite(maxHeatIndex) ? `Peak heat index: ${formatTemp(maxHeatIndex)}` : "Heat stress possible."
            });
        } else if (heatFirst) {
            const sev = Number.isFinite(maxAppTemp) && maxAppTemp >= heatDanger ? "Danger" : "Warning";
            const detail = Number.isFinite(maxAppTemp) ? `Peak apparent temperature: ${formatTemp(maxAppTemp)}` : "";
            addOrUpgradeWarning("heat", {
                kind: "heat",
                icon: "device_thermostat",
                severityLevel: Number.isFinite(maxAppTemp) && maxAppTemp >= heatDanger ? 2 : 1,
                isActive: false,
                startTimeMs: heatFirst.getTime(),
                title: "Heat risk",
                severity: sev,
                timeRange: describeWhen(heatFirst, heatLast, false),
                details: detail
            });
        }

        if (windChillFirst) {
            const sevLevel = Number.isFinite(minWindChill) && minWindChill <= windChillDanger ? 2 : 1;
            addOrUpgradeWarning("cold", {
                kind: "wind_chill",
                icon: "air",
                severityLevel: sevLevel,
                isActive: false,
                startTimeMs: windChillFirst.getTime(),
                title: "Wind chill risk",
                severity: sevLevel >= 2 ? "Danger" : "Warning",
                timeRange: describeWhen(windChillFirst, windChillLast, false),
                details: Number.isFinite(minWindChill) ? `Lowest wind chill: ${formatTemp(minWindChill)}` : "Wind chill possible."
            });
        } else if (coldFirst) {
            const sev = Number.isFinite(minAppTemp) && minAppTemp <= coldDanger ? "Danger" : "Warning";
            const detail = Number.isFinite(minAppTemp) ? `Lowest apparent temperature: ${formatTemp(minAppTemp)}` : "";
            addOrUpgradeWarning("cold", {
                kind: "cold",
                icon: "ac_unit",
                severityLevel: Number.isFinite(minAppTemp) && minAppTemp <= coldDanger ? 2 : 1,
                isActive: false,
                startTimeMs: coldFirst.getTime(),
                title: "Cold / frost risk",
                severity: sev,
                timeRange: describeWhen(coldFirst, coldLast, false),
                details: detail
            });
        }

        if (uvFirst) {
            const sev = Number.isFinite(maxUv) && maxUv >= uvDanger ? "Danger" : "Warning";
            const detail = Number.isFinite(maxUv) ? `Peak UV index: ${maxUv.toFixed(1)}` : "";
            addOrUpgradeWarning("uv", {
                kind: "uv",
                icon: "wb_sunny",
                severityLevel: Number.isFinite(maxUv) && maxUv >= uvDanger ? 2 : 1,
                isActive: false,
                startTimeMs: uvFirst.getTime(),
                title: "High UV exposure",
                severity: sev,
                timeRange: describeWhen(uvFirst, uvLast, false),
                details: detail
            });
        }

        if (humidFirst) {
            // determine severity from peak dewpoint if available
            let peakDew = Number.NEGATIVE_INFINITY;
            for (let i = 0; i < hourlyArr.length; i++) {
                const d = Number(hourlyArr[i].dewPointValue);
                const t = new Date(hourlyArr[i].timeIso);
                const dt = t - now;
                if (!Number.isFinite(dt) || dt < -includePastMs || dt > horizonMs) continue;
                if (Number.isFinite(d)) peakDew = Math.max(peakDew, d);
            }
            const sevLevel = (Number.isFinite(peakDew) && peakDew >= dewDanger) ? 2 : 1;
            addOrUpgradeWarning("humidity", {
                kind: "humidity",
                icon: "humidity_high",
                severityLevel: sevLevel,
                isActive: false,
                startTimeMs: humidFirst.getTime(),
                title: "Oppressive humidity",
                severity: sevLevel >= 2 ? "Danger" : "Warning",
                timeRange: describeWhen(humidFirst, humidLast, false),
                details: Number.isFinite(peakDew) ? `Peak dew point: ${formatTemp(peakDew)}` : "High humidity expected."
            });
        }

        if (dryFirst) {
            let minRh = Number.POSITIVE_INFINITY;
            for (let i = 0; i < hourlyArr.length; i++) {
                const h = Number(hourlyArr[i].humidityValue);
                const t = new Date(hourlyArr[i].timeIso);
                const dt = t - now;
                if (!Number.isFinite(dt) || dt < -includePastMs || dt > horizonMs) continue;
                if (Number.isFinite(h)) minRh = Math.min(minRh, h);
            }
            const sevLevel = (Number.isFinite(minRh) && minRh <= dryDanger) ? 2 : 1;
            addOrUpgradeWarning("dry", {
                kind: "dry",
                icon: "airwave",
                severityLevel: sevLevel,
                isActive: false,
                startTimeMs: dryFirst.getTime(),
                title: "Very dry air",
                severity: sevLevel >= 2 ? "Danger" : "Warning",
                timeRange: describeWhen(dryFirst, dryLast, false),
                details: Number.isFinite(minRh) ? `Lowest humidity: ${Math.round(minRh)}%` : "Very dry air expected."
            });
        }

        if (iceFirst) {
            addOrUpgradeWarning("ice", {
                kind: "ice",
                icon: "sledding",
                severityLevel: 2,
                isActive: false,
                startTimeMs: iceFirst.getTime(),
                title: "Black ice / slippery risk",
                severity: "Danger",
                timeRange: describeWhen(iceFirst, iceLast, false),
                details: "Near-freezing temperatures with precipitation may create slippery surfaces."
            });
        }

        // Escalate using today's daily thunderstorm code if available (helps when hourly is sparse)
        if (dailyArr.length > 0) {
            const today = dailyArr[0];
            const todayCode = Number(today.code);
            const todayProb = Number(today.precipProbMaxValue);
            if ((todayCode === 95 || todayCode === 96 || todayCode === 99) && Number.isFinite(todayProb) && todayProb >= 60) {
                addOrUpgradeWarning("storm_today", {
                    kind: "storm_today",
                    icon: "thunderstorm",
                    severityLevel: 1,
                    isActive: false,
                    startTimeMs: now.getTime(),
                    title: "Storm risk today",
                    severity: "Warning",
                    timeRange: "Today",
                    details: `Rain chance: ${formatPercent(todayProb)}`
                });
            }
        }

        // Sort: active first, then severity, then soonest
        warnings.sort((a, b) => {
            const aa = a.isActive ? 1 : 0;
            const bb = b.isActive ? 1 : 0;
            if (aa !== bb) return bb - aa;
            const as = Number(a.severityLevel ?? 0);
            const bs = Number(b.severityLevel ?? 0);
            if (as !== bs) return bs - as;
            const at = Number(a.startTimeMs ?? Number.POSITIVE_INFINITY);
            const bt = Number(b.startTimeMs ?? Number.POSITIVE_INFINITY);
            if (at !== bt) return at - bt;
            return String(a.title || "").localeCompare(String(b.title || ""));
        });

        // Cap to keep UI readable
        return warnings.slice(0, 6);
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
        const hVis = hourlyData?.visibility || [];
        const hUv = hourlyData?.uv_index || [];
        const hApp = hourlyData?.apparent_temperature || [];
        const hRh = hourlyData?.relative_humidity_2m || [];
        const hDew = hourlyData?.dew_point_2m || [];
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
                visibility: formatVisibilityMeters(Number(hVis[i])),
                uv: formatUv(Number(hUv[i])),
                apparentTemp: formatTemp(Number(hApp[i])),
                humidity: formatPercent(Number(hRh[i])),
                dewPoint: formatTemp(Number(hDew[i])),

                // raw for warning computations
                tempValue: Number(hTemp[i]),
                windSpeedValue: Number(hWind[i]),
                precipValue: Number(hPrecip[i]),
                gustValue: Number(hGust[i]),
                visibilityValue: Number(hVis[i]),
                uvValue: Number(hUv[i]),
                apparentTempValue: Number(hApp[i]),
                humidityValue: Number(hRh[i]),
                dewPointValue: Number(hDew[i])
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
        root.warnings = computeStormWarnings(hourlyOut, dailyOut, current);
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
