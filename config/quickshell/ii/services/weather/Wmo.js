.pragma library

function codeToText(code, tr) {
    // WMO Weather interpretation codes used by Open-Meteo
    const t = (typeof tr === "function") ? tr : (s) => s;

    switch (Number(code)) {
    case 0: return t("Clear sky");
    case 1: return t("Mainly clear");
    case 2: return t("Partly cloudy");
    case 3: return t("Overcast");
    case 45: return t("Fog");
    case 48: return t("Rime fog");
    case 51: return t("Light drizzle");
    case 53: return t("Drizzle");
    case 55: return t("Dense drizzle");
    case 56: return t("Freezing drizzle");
    case 57: return t("Dense freezing drizzle");
    case 61: return t("Light rain");
    case 63: return t("Rain");
    case 65: return t("Heavy rain");
    case 66: return t("Freezing rain");
    case 67: return t("Heavy freezing rain");
    case 71: return t("Light snow");
    case 73: return t("Snow");
    case 75: return t("Heavy snow");
    case 77: return t("Snow grains");
    case 80: return t("Rain showers");
    case 81: return t("Heavy rain showers");
    case 82: return t("Violent rain showers");
    case 85: return t("Snow showers");
    case 86: return t("Heavy snow showers");
    case 95: return t("Thunderstorm");
    case 96: return t("Thunderstorm with hail");
    case 99: return t("Thunderstorm with heavy hail");
    default:
        return t("Unknown");
    }
}
