.pragma library

function degToCompass16(deg) {
    if (!Number.isFinite(deg)) return "N";
    const dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
    const norm = ((deg % 360) + 360) % 360;
    const idx = Math.floor(norm / 22.5 + 0.5) % 16;
    return dirs[idx];
}

function formatTemp(value, useUSCS) {
    if (!Number.isFinite(value)) return "--";
    const unit = useUSCS ? "°F" : "°C";
    return `${value.toFixed(1)}${unit}`;
}

function formatWind(value, useUSCS) {
    if (!Number.isFinite(value)) return "--";
    const unit = useUSCS ? "mph" : "km/h";
    return `${value.toFixed(1)} ${unit}`;
}

function formatPrecip(value, useUSCS) {
    if (!Number.isFinite(value)) return "--";
    const unit = useUSCS ? "in" : "mm";
    const decimals = useUSCS ? 2 : 1;
    return `${value.toFixed(decimals)} ${unit}`;
}

function formatPressure(value) {
    if (!Number.isFinite(value)) return "--";
    // Open-Meteo returns hPa for pressure_msl
    return `${Math.round(value)} hPa`;
}

function formatVisibilityMeters(meters, useUSCS) {
    if (!Number.isFinite(meters)) return "--";
    if (useUSCS) {
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
