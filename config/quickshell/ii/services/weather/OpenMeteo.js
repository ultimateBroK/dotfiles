.pragma library

.import "Format.js" as Format
.import "Wmo.js" as Wmo
.import "Warnings.js" as Warnings

function refine(payload, opts) {
    const o = opts || {};
    const useUSCS = !!o.useUSCS;
    const tr = (typeof o.tr === "function") ? o.tr : (s) => s;

    const current = payload?.current || {};
    const hourlyData = payload?.hourly || {};
    const dailyData = payload?.daily || {};

    const out = {};
    out.city = o.displayCityName || o.locationName || o.city || "City";

    const wCode = Number(current.weather_code ?? 0);
    out.weatherCode = wCode;
    // Back-compat for old UI that used `wCode`
    out.wCode = wCode;

    out.isDay = Number(current.is_day ?? 1) === 1;
    out.weatherDesc = Wmo.codeToText(wCode, tr);

    out.temp = Format.formatTemp(Number(current.temperature_2m), useUSCS);
    out.tempFeelsLike = Format.formatTemp(Number(current.apparent_temperature), useUSCS);

    out.humidity = Format.formatPercent(Number(current.relative_humidity_2m));
    out.dewPoint = Format.formatTemp(Number(current.dew_point_2m), useUSCS);
    out.uv = Format.formatUv(Number(current.uv_index));
    out.press = Format.formatPressure(Number(current.pressure_msl));
    out.cloudCover = Format.formatPercent(Number(current.cloud_cover));
    out.visib = Format.formatVisibilityMeters(Number(current.visibility), useUSCS);

    const windDeg = Number(current.wind_direction_10m);
    out.windDir = Format.degToCompass16(windDeg);
    out.wind = Format.formatWind(Number(current.wind_speed_10m), useUSCS);
    out.gust = Format.formatWind(Number(current.wind_gusts_10m), useUSCS);
    out.precip = Format.formatPrecip(Number(current.precipitation), useUSCS);
    out.precipProb = Format.formatPercent(Number(current.precipitation_probability));

    // Daily summary (today min/max, sunrise/sunset)
    const dailyTimes = dailyData?.time || [];
    const dailyMax = dailyData?.temperature_2m_max || [];
    const dailyMin = dailyData?.temperature_2m_min || [];
    const dailySunrise = dailyData?.sunrise || [];
    const dailySunset = dailyData?.sunset || [];
    if (dailyTimes.length > 0) {
        out.tempMax = Format.formatTemp(Number(dailyMax[0]), useUSCS);
        out.tempMin = Format.formatTemp(Number(dailyMin[0]), useUSCS);
        const sr = dailySunrise[0] ? new Date(dailySunrise[0]) : null;
        const ss = dailySunset[0] ? new Date(dailySunset[0]) : null;
        out.sunrise = sr ? Qt.formatTime(sr, "hh:mm") : "--:--";
        out.sunset = ss ? Qt.formatTime(ss, "hh:mm") : "--:--";
    } else {
        out.tempMax = "--";
        out.tempMin = "--";
        out.sunrise = "--:--";
        out.sunset = "--:--";
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
            temp: Format.formatTemp(Number(hTemp[i]), useUSCS),
            code: Number(hCode[i] ?? 0),
            precip: Format.formatPrecip(Number(hPrecip[i]), useUSCS),
            precipProb: Format.formatPercent(Number(hPrecipProb[i])),
            wind: Format.formatWind(Number(hWind[i]), useUSCS),
            gust: Format.formatWind(Number(hGust[i]), useUSCS),
            visibility: Format.formatVisibilityMeters(Number(hVis[i]), useUSCS),
            uv: Format.formatUv(Number(hUv[i])),
            apparentTemp: Format.formatTemp(Number(hApp[i]), useUSCS),
            humidity: Format.formatPercent(Number(hRh[i])),
            dewPoint: Format.formatTemp(Number(hDew[i]), useUSCS),

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
            tempMin: Format.formatTemp(Number(dailyMin[i]), useUSCS),
            tempMax: Format.formatTemp(Number(dailyMax[i]), useUSCS),
            precipSum: Format.formatPrecip(Number(dPrecipSum[i]), useUSCS),
            precipProbMax: Format.formatPercent(Number(dPrecipProbMax[i])),
            gustMax: Format.formatWind(Number(dGustMax[i]), useUSCS),
            uvMax: Format.formatUv(Number(dUvMax[i])),

            precipProbMaxValue: Number(dPrecipProbMax[i])
        });
    }

    const warnings = Warnings.compute(hourlyOut, dailyOut, current, useUSCS);

    return {
        data: out,
        hourly: hourlyOut,
        daily: dailyOut,
        warnings: warnings
    };
}
