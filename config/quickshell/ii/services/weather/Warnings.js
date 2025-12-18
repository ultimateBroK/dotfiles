.pragma library

.import "Format.js" as Format

function compute(hourlyArr, dailyArr, current, useUSCS) {
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
    const gustWarn = useUSCS ? 45 : 72;   // mph / km/h
    const gustDanger = useUSCS ? 55 : 88;
    const precipWarn = useUSCS ? 0.25 : 6; // in/h-ish / mm/h-ish (Open-Meteo hourly precip)
    const precipDanger = useUSCS ? 0.45 : 12;

    const heatWarn = useUSCS ? 95 : 35;    // °F / °C (apparent temperature)
    const heatDanger = useUSCS ? 104 : 40;
    const coldWarn = useUSCS ? 32 : 0;
    const coldDanger = useUSCS ? 23 : -5;

    const visWarn = 1000;   // meters
    const visDanger = 300;  // meters

    const uvWarn = 8;
    const uvDanger = 11;

    // Heat index / wind chill (explicit, travel-friendly)
    const heatIndexWarn = useUSCS ? 90 : 32;     // °F / °C
    const heatIndexDanger = useUSCS ? 104 : 40;
    const windChillWarn = useUSCS ? 32 : 0;      // °F / °C
    const windChillDanger = useUSCS ? 14 : -10;

    // Humidity / dew point comfort hazards (travel-friendly)
    const dewWarn = useUSCS ? 75 : 24;     // °F / °C
    const dewDanger = useUSCS ? 79 : 26;
    const dryWarn = 15;   // %
    const dryDanger = 10; // %

    // Ice risk near freezing with precipitation
    const iceTempHigh = useUSCS ? 34 : 1;   // °F / °C
    const iceTempLow = useUSCS ? 28 : -2;
    const icePrecip = useUSCS ? 0.02 : 0.4; // inch / mm per hour

    function heatIndex(temp, rh) {
        // Returns heat index in the same temperature unit as inputs (F if useUSCS, else C).
        if (!Number.isFinite(temp) || !Number.isFinite(rh)) return NaN;
        const RH = Math.max(0, Math.min(100, rh));
        // Heat index formula is defined for warmer temps; below that it's not meaningful.
        const tF = useUSCS ? temp : (temp * 9 / 5 + 32);
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

        return useUSCS ? hiF : ((hiF - 32) * 5 / 9);
    }

    function windChill(temp, wind) {
        // Returns wind chill in same temperature unit as inputs.
        if (!Number.isFinite(temp) || !Number.isFinite(wind)) return NaN;
        if (useUSCS) {
            const tF = temp;
            const v = wind; // mph
            if (tF > 50 || v <= 3) return NaN;
            const wcF = 35.74 + 0.6215 * tF - 35.75 * Math.pow(v, 0.16) + 0.4275 * tF * Math.pow(v, 0.16);
            return wcF;
        }

        const tC = temp;
        const v = wind; // km/h
        if (tC > 10 || v <= 4.8) return NaN;
        const wcC = 13.12 + 0.6215 * tC - 11.37 * Math.pow(v, 0.16) + 0.3965 * tC * Math.pow(v, 0.16);
        return wcC;
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
        const detail = Number.isFinite(curVis) ? `Visibility: ${Format.formatVisibilityMeters(curVis, useUSCS)}` : "Low visibility possible.";
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
            details: `Gust: ${Format.formatWind(curGust, useUSCS)}`
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
            details: `Precipitation: ${Format.formatPrecip(curPrecip, useUSCS)}`
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
            details: `Heat index: ${Format.formatTemp(curHi, useUSCS)} (Temp: ${Format.formatTemp(curTemp, useUSCS)} • Humidity: ${Math.round(curRh)}%)`
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
            details: `Apparent temperature: ${Format.formatTemp(curApp, useUSCS)}`
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
            details: `Wind chill: ${Format.formatTemp(curWc, useUSCS)} (Temp: ${Format.formatTemp(curTemp, useUSCS)} • Wind: ${Format.formatWind(curWind, useUSCS)})`
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
            details: `Apparent temperature: ${Format.formatTemp(curApp, useUSCS)}`
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
            details: `Dew point: ${Format.formatTemp(curDew, useUSCS)}`
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
            details: `Near-freezing with precipitation (${Format.formatTemp(curApp, useUSCS)} • ${Format.formatPrecip(curPrecip, useUSCS)})`
        });
    }

    // Build warnings (forecast)
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
        const fogSevLevel = (Number.isFinite(minFogVis) && minFogVis <= visDanger) ? 2 : 1;
        const detail = Number.isFinite(minFogVis) && minFogVis !== Number.POSITIVE_INFINITY && minFogVis <= 5000
            ? `Lowest visibility: ${Format.formatVisibilityMeters(minFogVis, useUSCS)}`
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
            details: `Peak gust: ${Format.formatWind(maxGust, useUSCS)}`
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
            details: `Max hourly precipitation: ${Format.formatPrecip(maxPrecip, useUSCS)}`
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
            details: Number.isFinite(maxHeatIndex) ? `Peak heat index: ${Format.formatTemp(maxHeatIndex, useUSCS)}` : "Heat stress possible."
        });
    } else if (heatFirst) {
        const detail = Number.isFinite(maxAppTemp) ? `Peak apparent temperature: ${Format.formatTemp(maxAppTemp, useUSCS)}` : "";
        addOrUpgradeWarning("heat", {
            kind: "heat",
            icon: "device_thermostat",
            severityLevel: Number.isFinite(maxAppTemp) && maxAppTemp >= heatDanger ? 2 : 1,
            isActive: false,
            startTimeMs: heatFirst.getTime(),
            title: "Heat risk",
            severity: Number.isFinite(maxAppTemp) && maxAppTemp >= heatDanger ? "Danger" : "Warning",
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
            details: Number.isFinite(minWindChill) ? `Lowest wind chill: ${Format.formatTemp(minWindChill, useUSCS)}` : "Wind chill possible."
        });
    } else if (coldFirst) {
        const detail = Number.isFinite(minAppTemp) ? `Lowest apparent temperature: ${Format.formatTemp(minAppTemp, useUSCS)}` : "";
        addOrUpgradeWarning("cold", {
            kind: "cold",
            icon: "ac_unit",
            severityLevel: Number.isFinite(minAppTemp) && minAppTemp <= coldDanger ? 2 : 1,
            isActive: false,
            startTimeMs: coldFirst.getTime(),
            title: "Cold / frost risk",
            severity: Number.isFinite(minAppTemp) && minAppTemp <= coldDanger ? "Danger" : "Warning",
            timeRange: describeWhen(coldFirst, coldLast, false),
            details: detail
        });
    }

    if (uvFirst) {
        addOrUpgradeWarning("uv", {
            kind: "uv",
            icon: "wb_sunny",
            severityLevel: Number.isFinite(maxUv) && maxUv >= uvDanger ? 2 : 1,
            isActive: false,
            startTimeMs: uvFirst.getTime(),
            title: "High UV exposure",
            severity: Number.isFinite(maxUv) && maxUv >= uvDanger ? "Danger" : "Warning",
            timeRange: describeWhen(uvFirst, uvLast, false),
            details: Number.isFinite(maxUv) ? `Peak UV index: ${maxUv.toFixed(1)}` : ""
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
            details: Number.isFinite(peakDew) ? `Peak dew point: ${Format.formatTemp(peakDew, useUSCS)}` : "High humidity expected."
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
                details: `Rain chance: ${Format.formatPercent(todayProb)}`
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
