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

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        weatherDesc: "",
        cloudCover: 0,
        moonPhase: "",
        moonrise: "",
        moonset: "",
        dewPoint: 0,
        heatIndex: 0
    })

    function refineData(data) {
        let temp = {};
        temp.uv = parseFloat(data?.current?.uvIndex || 0).toFixed(1);
        temp.humidity = parseInt(data?.current?.humidity || 0) + "%";
        temp.sunrise = data?.astronomy?.sunrise || "--:--";
        temp.sunset = data?.astronomy?.sunset || "--:--";
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName[0]?.value || "City";
        temp.weatherDesc = data?.current?.weatherDesc?.[0]?.value || "Unknown";
        temp.cloudCover = parseInt(data?.current?.cloudcover || 0) + "%";
        temp.moonPhase = data?.astronomy?.moon_phase || "Unknown";
        temp.moonrise = data?.astronomy?.moonrise || "--:--";
        temp.moonset = data?.astronomy?.moonset || "--:--";
        temp.temp = "";
        temp.tempFeelsLike = "";
        temp.dewPoint = "";
        temp.heatIndex = "";
        if (root.useUSCS) {
            temp.wind = parseFloat(data?.current?.windspeedMiles || 0).toFixed(1) + " mph";
            temp.precip = parseFloat(data?.current?.precipInches || 0).toFixed(2) + " in";
            temp.visib = parseFloat(data?.current?.visibilityMiles || 0).toFixed(1) + " mi";
            temp.press = parseFloat(data?.current?.pressureInches || 0).toFixed(2) + " inHg";
            temp.temp += parseFloat(data?.current?.temp_F || 0).toFixed(1);
            temp.tempFeelsLike += parseFloat(data?.current?.FeelsLikeF || 0).toFixed(1);
            temp.dewPoint = parseFloat(data?.current?.DewPointF || 0).toFixed(1) + "°F";
            temp.heatIndex = parseFloat(data?.current?.HeatIndexF || 0).toFixed(1) + "°F";
            temp.temp += "°F";
            temp.tempFeelsLike += "°F";
        } else {
            temp.wind = parseFloat(data?.current?.windspeedKmph || 0).toFixed(1) + " km/h";
            temp.precip = parseFloat(data?.current?.precipMM || 0).toFixed(1) + " mm";
            temp.visib = parseFloat(data?.current?.visibility || 0).toFixed(1) + " km";
            temp.press = parseInt(data?.current?.pressure || 0) + " hPa";
            temp.temp += parseFloat(data?.current?.temp_C || 0).toFixed(1);
            temp.tempFeelsLike += parseFloat(data?.current?.FeelsLikeC || 0).toFixed(1);
            temp.dewPoint = parseFloat(data?.current?.DewPointC || 0).toFixed(1) + "°C";
            temp.heatIndex = parseFloat(data?.current?.HeatIndexC || 0).toFixed(1) + "°C";
            temp.temp += "°C";
            temp.tempFeelsLike += "°C";
        }
        root.data = temp;
    }

    function getData() {
        let command = "curl -s wttr.in";

        if (root.gpsActive && root.location.valid) {
            command += `/${root.location.lat},${root.location.long}`;
        } else {
            command += `/${formatCityName(root.city)}`;
        }

        // format as json
        command += "?format=j1";
        command += " | ";
        // only take the current weather, location, asytronmy data
        command += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                    // console.info(`[ data: ${JSON.stringify(parsedData)}`);
                } catch (e) {
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
                root.location.long = position.coordinate.longitude;
                root.location.valid = true;
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
