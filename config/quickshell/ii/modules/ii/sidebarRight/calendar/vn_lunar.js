// Vietnamese lunar calendar conversion utilities
// Ported from common public-domain implementations (amlich)
// Works reliably for years ~1900-2100, which is sufficient for UI display.

.pragma library

function INT(d) {
    return Math.floor(d);
}

function jdFromDate(dd, mm, yy) {
    var a = INT((14 - mm) / 12);
    var y = yy + 4800 - a;
    var m = mm + 12 * a - 3;
    var jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - INT(y / 100) + INT(y / 400) - 32045;
    return jd;
}

function jdToDate(jd) {
    var a, b, c, d, e, m;
    if (jd > 2299160) { // After 5/10/1582, Gregorian calendar
        a = jd + 32044;
        b = INT((4 * a + 3) / 146097);
        c = a - INT((b * 146097) / 4);
    } else {
        b = 0;
        c = jd + 32082;
    }
    d = INT((4 * c + 3) / 1461);
    e = c - INT((1461 * d) / 4);
    m = INT((5 * e + 2) / 153);
    var day = e - INT((153 * m + 2) / 5) + 1;
    var month = m + 3 - 12 * INT(m / 10);
    var year = b * 100 + d - 4800 + INT(m / 10);
    return [day, month, year];
}

function getNewMoonDay(k, timeZone) {
    var T = k / 1236.85;
    var T2 = T * T;
    var T3 = T2 * T;
    var dr = Math.PI / 180;
    var Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    Jd1 = Jd1 + 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
    var M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
    var Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
    var F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
    var C1 =
        (0.1734 - 0.000393 * T) * Math.sin(M * dr) +
        0.0021 * Math.sin(2 * dr * M) -
        0.4068 * Math.sin(Mpr * dr) +
        0.0161 * Math.sin(dr * 2 * Mpr) -
        0.0004 * Math.sin(dr * 3 * Mpr) +
        0.0104 * Math.sin(dr * 2 * F) -
        0.0051 * Math.sin(dr * (M + Mpr)) -
        0.0074 * Math.sin(dr * (M - Mpr)) +
        0.0004 * Math.sin(dr * (2 * F + M)) -
        0.0004 * Math.sin(dr * (2 * F - M)) -
        0.0006 * Math.sin(dr * (2 * F + Mpr)) +
        0.0010 * Math.sin(dr * (2 * F - Mpr)) +
        0.0005 * Math.sin(dr * (2 * Mpr + M));
    var deltat;
    if (T < -11) {
        deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3;
    } else {
        deltat = -0.000278 + 0.000265 * T + 0.000262 * T2;
    }
    var JdNew = Jd1 + C1 - deltat;
    return INT(JdNew + 0.5 + timeZone / 24);
}

function getSunLongitude(jdn, timeZone) {
    var T = (jdn - 2451545.5 - timeZone / 24) / 36525;
    var T2 = T * T;
    var dr = Math.PI / 180;
    var M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
    var L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
    var DL =
        (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(dr * M) +
        (0.019993 - 0.000101 * T) * Math.sin(dr * 2 * M) +
        0.000290 * Math.sin(dr * 3 * M);
    var L = L0 + DL;
    L = L * dr;
    L = L - Math.PI * 2 * INT(L / (Math.PI * 2));
    return INT(L / Math.PI * 6);
}

function getLunarMonth11(yy, timeZone) {
    var off = jdFromDate(31, 12, yy) - 2415021;
    var k = INT(off / 29.530588853);
    var nm = getNewMoonDay(k, timeZone);
    var sunLong = getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
        nm = getNewMoonDay(k - 1, timeZone);
    }
    return nm;
}

function getLeapMonthOffset(a11, timeZone) {
    var k = INT(0.5 + (a11 - 2415021.076998695) / 29.530588853);
    var last = 0;
    var i = 1;
    var arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    do {
        last = arc;
        i++;
        arc = getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc !== last && i < 14);
    return i - 1;
}

// Convert solar day dd/mm/yyyy to lunar date [day, month, year, leap]
function solar2lunar(dd, mm, yy, timeZone) {
    timeZone = timeZone || 7; // Vietnam timezone UTC+7
    var dayNumber = jdFromDate(dd, mm, yy);
    var k = INT((dayNumber - 2415021.076998695) / 29.530588853);
    var monthStart = getNewMoonDay(k + 1, timeZone);
    if (monthStart > dayNumber) {
        monthStart = getNewMoonDay(k, timeZone);
    }
    var a11 = getLunarMonth11(yy, timeZone);
    var b11 = a11;
    var lunarYear;
    if (a11 >= monthStart) {
        lunarYear = yy;
        a11 = getLunarMonth11(yy - 1, timeZone);
    } else {
        lunarYear = yy + 1;
        b11 = getLunarMonth11(yy + 1, timeZone);
    }
    var lunarDay = dayNumber - monthStart + 1;
    var diff = INT((monthStart - a11) / 29);
    var lunarMonth = diff + 11;
    var lunarLeap = 0;
    if (b11 - a11 > 365) {
        var leapMonthDiff = getLeapMonthOffset(a11, timeZone);
        if (diff >= leapMonthDiff) {
            lunarMonth = diff + 10;
            if (diff === leapMonthDiff) {
                lunarLeap = 1;
            }
        }
    }
    if (lunarMonth > 12) {
        lunarMonth -= 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
        lunarYear -= 1;
    }
    return {
        day: lunarDay,
        month: lunarMonth,
        year: lunarYear,
        leap: lunarLeap
    };
}


