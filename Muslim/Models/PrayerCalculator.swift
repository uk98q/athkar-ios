import Foundation

struct PrayerTime: Identifiable, Hashable {
    let id: String
    let name: String
    let date: Date
}

/// Prayer times computed on the device with no network access.
/// Uses Muslim World League angles (Fajr 18°, Isha 17°) and the standard Asr shadow factor (1).
/// Results usually land within about a minute of published local timetables.
enum PrayerCalculator {
    private static let rad = Double.pi / 180

    /// All prayers for the local calendar day of `day`, in chronological order.
    static func times(on day: Date, latitude lat: Double, longitude lon: Double, timeZone: TimeZone = .current) -> [PrayerTime] {
        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = timeZone
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let parts = localCal.dateComponents([.year, .month, .day], from: day)
        guard let midnightUTC = utcCal.date(from: parts) else { return [] }

        let jd0 = midnightUTC.timeIntervalSince1970 / 86400 + 2440587.5
        let sun = solar(jd: jd0 + 0.5)
        // Solar noon in minutes after 00:00 UTC.
        let noon = 720 - 4 * lon - sun.eqTime

        let asrAltitude = atan(1 / (1 + tan(abs(lat * rad - sun.decl)))) / rad

        var result: [PrayerTime] = []
        if let o = offset(altitude: -18, lat: lat, decl: sun.decl) {
            result.append(PrayerTime(id: "fajr", name: "الفجر", date: date(noon - o, base: midnightUTC)))
        }
        if let o = offset(altitude: -0.833, lat: lat, decl: sun.decl) {
            result.append(PrayerTime(id: "sunrise", name: "الشروق", date: date(noon - o, base: midnightUTC)))
        }
        result.append(PrayerTime(id: "dhuhr", name: "الظهر", date: date(noon, base: midnightUTC)))
        if let o = offset(altitude: asrAltitude, lat: lat, decl: sun.decl) {
            result.append(PrayerTime(id: "asr", name: "العصر", date: date(noon + o, base: midnightUTC)))
        }
        if let o = offset(altitude: -0.833, lat: lat, decl: sun.decl) {
            result.append(PrayerTime(id: "maghrib", name: "المغرب", date: date(noon + o, base: midnightUTC)))
        }
        if let o = offset(altitude: -17, lat: lat, decl: sun.decl) {
            result.append(PrayerTime(id: "isha", name: "العشاء", date: date(noon + o, base: midnightUTC)))
        }
        return result
    }

    /// The next prayer after `now`, skipping sunrise. Falls back to tomorrow's Fajr.
    static func next(after now: Date, latitude: Double, longitude: Double) -> PrayerTime? {
        let today = times(on: now, latitude: latitude, longitude: longitude)
        if let upcoming = today.first(where: { $0.id != "sunrise" && $0.date > now }) {
            return upcoming
        }
        let tomorrow = times(on: now.addingTimeInterval(86400), latitude: latitude, longitude: longitude)
        return tomorrow.first(where: { $0.id == "fajr" })
    }

    // MARK: - Helpers

    /// Hour-angle in minutes for a given sun altitude, or nil if the sun never reaches it that day.
    private static func offset(altitude: Double, lat: Double, decl: Double) -> Double? {
        let latR = lat * rad
        let numerator = sin(altitude * rad) - sin(latR) * sin(decl)
        let denominator = cos(latR) * cos(decl)
        let c = numerator / denominator
        guard abs(c) <= 1 else { return nil }
        let degrees = acos(c) / rad
        return degrees * 4
    }

    private static func date(_ minutes: Double, base: Date) -> Date {
        base.addingTimeInterval(minutes.rounded() * 60)
    }

    /// Solar declination (radians) and equation of time (minutes), NOAA style approximation.
    private static func solar(jd: Double) -> (decl: Double, eqTime: Double) {
        let t = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + t * (36000.76983 + 0.0003032 * t)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let mr = m * rad

        let c1 = sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t))
        let c2 = sin(2 * mr) * (0.019993 - 0.000101 * t)
        let c3 = sin(3 * mr) * 0.000289
        let trueLong = l0 + c1 + c2 + c3

        let omega = (125.04 - 1934.136 * t) * rad
        let appLong = (trueLong - 0.00569 - 0.00478 * sin(omega)) * rad

        let meanObl = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let obl = (meanObl + 0.00256 * cos(omega)) * rad
        let decl = asin(sin(obl) * sin(appLong))

        let y = pow(tan(obl / 2), 2)
        let l0r = l0 * rad
        let part1 = y * sin(2 * l0r) - 2 * e * sin(mr)
        let part2 = 4 * e * y * sin(mr) * cos(2 * l0r) - 0.5 * y * y * sin(4 * l0r)
        let part3 = 1.25 * e * e * sin(2 * mr)
        let eq = 4 * (part1 + part2 - part3) / rad
        return (decl, eq)
    }
}
