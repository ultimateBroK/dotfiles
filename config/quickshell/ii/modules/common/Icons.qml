pragma Singleton

// From https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell

Singleton {
    id: root

    function getBluetoothDeviceMaterialSymbol(systemIconName: string): string {
        if (systemIconName.includes("headset") || systemIconName.includes("headphones"))
            return "headphones";
        if (systemIconName.includes("audio"))
            return "speaker";
        if (systemIconName.includes("phone"))
            return "smartphone";
        if (systemIconName.includes("mouse"))
            return "mouse";
        if (systemIconName.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    readonly property var weatherIconMap: ({
        // Open-Meteo uses WMO weather interpretation codes
        "0": "clear_day",
        "1": "partly_cloudy_day",
        "2": "partly_cloudy_day",
        "3": "cloud",
        "45": "foggy",
        "48": "foggy",

        "51": "rainy",
        "53": "rainy",
        "55": "rainy",
        "56": "rainy",
        "57": "rainy",

        "61": "rainy",
        "63": "rainy",
        "65": "rainy",
        "66": "rainy",
        "67": "rainy",

        "71": "cloudy_snowing",
        "73": "snowing",
        "75": "snowing_heavy",
        "77": "cloudy_snowing",

        "80": "rainy",
        "81": "rainy",
        "82": "rainy",

        "85": "snowing",
        "86": "snowing_heavy",

        "95": "thunderstorm",
        "96": "thunderstorm",
        "99": "thunderstorm"
    })

    
    function getWeatherIcon(code, isDay = true) {
        const key = String(code)
        if (key === "0") {
            return isDay ? "clear_day" : "clear_night"
        }
        if (key === "1" || key === "2") {
            return isDay ? "partly_cloudy_day" : "partly_cloudy_night"
        }
        if (weatherIconMap.hasOwnProperty(key)) {
            return weatherIconMap[key]
        }
        return isDay ? "cloud" : "cloud"
    }
}
