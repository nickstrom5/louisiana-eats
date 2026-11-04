import CoreLocation
import Observation
import UIKit

/// "Near me" sorting. Asks for when-in-use permission only when a list is sorted by distance or "My location" is tapped; the location never leaves the device.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var location: CLLocation?
    private(set) var status: CLAuthorizationStatus = .notDetermined
    /// no fix within 12 seconds, or Core Location reported an error
    private(set) var failed = false
    private var timeout: Task<Void, Never>?
    /// when the current request started: a fix from before it is a cached one (from launch, or before a drive) and doesn't count
    private var askedAt = Date.distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        status = manager.authorizationStatus
    }

    var isDenied: Bool { status == .denied || status == .restricted }

    /// Every place is in Louisiana, so a reader elsewhere (an App Reviewer in California, say) gets told rather than an empty map.
    /// A coarse outline of the state (Idaho's lesson: a bounding box would count Natchez, Beaumont and Gulfport), drawn a little outside
    /// the line so Grand Isle, Venice and Cameron count as inside, plus a ring for the Chandeleur Islands.
    var isOutsideLouisiana: Bool {
        guard let c = location?.coordinate else { return false }
        return !LouisianaOutline.contains(c)
    }

    /// Once location is off for the app, iOS won't ask again; the app's page in Settings is the only way back.
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: locate()
        default: break
        }
    }

    private func locate() {
        failed = false
        let asked = Date()
        askedAt = asked
        manager.requestLocation()
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, !Task.isCancelled else { return }
            if (self.location?.timestamp ?? .distantPast) < asked { self.failed = true }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        Task { @MainActor in
            self.status = s
            if s == .authorizedWhenInUse || s == .authorizedAlways { self.locate() }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        Task { @MainActor in
            // "My location" needs a fresh fix on every tap: a cached one from before the request would put you back where you were
            guard l.timestamp >= self.askedAt.addingTimeInterval(-2) else { return }
            self.location = l; self.failed = false; self.timeout?.cancel()
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in if self.location == nil { self.failed = true } }
    }
}

extension CLLocation {
    /// "0.4 mi", "12 mi", "1,012 mi" (an App Reviewer in California is a thousand miles out)
    func milesText(to other: CLLocation) -> String {
        let mi = distance(from: other) / 1609.344
        return (mi < 10 ? mi.formatted(.number.precision(.fractionLength(1))) : Int(mi.rounded()).formatted()) + " mi"
    }
}

/// A coarse Louisiana outline (longitude, latitude): the mainland (56 points) and the Chandeleur Islands (4), about 4 km outside the
/// Overture land outline (buffer 0.04°, simplify 0.06°). New Orleans, Grand Isle, Cameron, Shreveport and Monroe are inside; Natchez,
/// Gulfport, Beaumont and Texarkana are not (Vicksburg's riverfront falls in the margin).
enum LouisianaOutline {
    static let rings: [[(Double, Double)]] = [
        [(-94.08, 31.99), (-94.05, 33.06), (-91.08, 33.02), (-91.02, 32.90), (-91.12, 32.79), (-91.02, 32.74), (-90.86, 32.31), (-91.23, 31.73),
         (-91.36, 31.69), (-91.58, 31.13), (-91.52, 31.04), (-89.70, 31.04), (-89.80, 30.68), (-89.49, 30.19), (-89.68, 30.04), (-89.69, 29.91),
         (-89.46, 30.18), (-89.38, 30.16), (-89.41, 30.09), (-89.16, 30.18), (-89.21, 29.81), (-89.51, 29.50), (-89.16, 29.37), (-89.03, 29.09),
         (-89.13, 28.96), (-89.26, 29.02), (-89.42, 28.89), (-89.35, 29.10), (-89.65, 29.26), (-89.88, 29.27), (-90.33, 29.02), (-90.55, 29.27),
         (-90.60, 29.18), (-90.81, 29.17), (-90.74, 29.09), (-90.43, 29.10), (-90.42, 29.03), (-90.93, 29.01), (-90.96, 29.14), (-91.45, 29.32),
         (-91.41, 29.44), (-91.68, 29.61), (-91.66, 29.71), (-91.84, 29.67), (-91.67, 29.57), (-91.82, 29.44), (-93.24, 29.74), (-93.86, 29.66),
         (-93.97, 29.81), (-93.75, 30.13), (-93.78, 30.55), (-93.61, 30.83), (-93.59, 31.13), (-93.87, 31.57), (-93.88, 31.77)],
        [(-88.87, 29.73), (-88.91, 30.05), (-88.86, 30.08), (-88.79, 29.88)]]

    static func contains(_ c: CLLocationCoordinate2D) -> Bool { rings.contains { contains(c, ring: $0) } }

    /// Ray casting: a point is inside when a ray east of it crosses the outline an odd number of times.
    static func contains(_ c: CLLocationCoordinate2D, ring: [(Double, Double)]) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let (xi, yi) = ring[i], (xj, yj) = ring[j]
            if (yi > c.latitude) != (yj > c.latitude) && c.longitude < (xj - xi) * (c.latitude - yi) / (yj - yi) + xi { inside.toggle() }
            j = i
        }
        return inside
    }
}
