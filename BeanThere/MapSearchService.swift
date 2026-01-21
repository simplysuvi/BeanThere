//
//  MapSearchService.swift
//  BeanThere
//

import Foundation
import MapKit
import Combine
import CoreLocation

@MainActor
final class MapSearchService: ObservableObject {
    @Published private(set) var rankedShops: [CoffeeShop] = []
    @Published private(set) var recommendedShop: CoffeeShop?

    private let excludedChains = [
        "starbucks", "dunkin", "mcdonald's", "tim hortons", "peet's", "caribou", "costa"
    ]

    // MARK: - Skip persistence (no SwiftUI dependency)

    private let skippedKey = "skipped_place_ids"

    private var skippedPlaceIDs: Set<String> {
        get {
            let csv = UserDefaults.standard.string(forKey: skippedKey) ?? ""
            return Set(csv.split(separator: "|").map(String.init))
        }
        set {
            let csv = newValue.joined(separator: "|")
            UserDefaults.standard.set(csv, forKey: skippedKey)
        }
    }

    // MARK: - Search

    func searchNearbyCoffee(
        userLocation: CLLocation,
        radiusMeters: CLLocationDistance = 2500
    ) async {
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: radiusMeters,
            longitudinalMeters: radiusMeters
        )

        let request = MKLocalPointsOfInterestRequest(
            center: userLocation.coordinate,
            radius: radiusMeters
        )

        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: [
                .cafe,
                .bakery
            ]
        )

        do {
            let response = try await MKLocalSearch(request: request).start()

            var shops: [CoffeeShop] = response.mapItems.compactMap { item in
                guard let name = item.name else { return nil }
                guard !excludedChains.contains(where: { name.lowercased().contains($0) }) else {
                    return nil
                }

                let coord = item.placemark.coordinate
                let shopLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let dist = userLocation.distance(from: shopLoc)

                return CoffeeShop(
                    name: name,
                    coordinate: coord,
                    mapItem: item,
                    distanceMeters: dist
                )
            }

            shops.sort { ($0.distanceMeters ?? 0) < ($1.distanceMeters ?? 0) }

            rankedShops = shops
            recommendedShop = nil

        } catch {
            rankedShops = []
            recommendedShop = nil
            print("MKLocalSearch error: \(error)")
        }
    }

    // MARK: - Recommendation

    func updateRecommendation(
        userLocation: CLLocation,
        heading: CLHeading?,
        movement: LocationManager.MovementState
    ) {
        guard !rankedShops.isEmpty else {
            recommendedShop = nil
            return
        }

        let scored = rankedShops
            .filter { !skippedPlaceIDs.contains($0.id) }
            .map { shop in
                (
                    shop: shop,
                    score: score(
                        shop: shop,
                        userLocation: userLocation,
                        heading: heading,
                        movement: movement
                    )
                )
            }
            .sorted { $0.score > $1.score }

        recommendedShop = scored.first?.shop
        rankedShops = scored.map { $0.shop }
    }

    func pickNextRecommendation() {
        guard let current = recommendedShop else { return }

        var skipped = skippedPlaceIDs
        skipped.insert(current.id)
        skippedPlaceIDs = skipped

        recommendedShop = rankedShops.first { !skipped.contains($0.id) }
    }

    func resetSkips() {
        skippedPlaceIDs = []
    }

    // MARK: - Scoring

    private func score(
        shop: CoffeeShop,
        userLocation: CLLocation,
        heading: CLHeading?,
        movement: LocationManager.MovementState
    ) -> Double {
        let dist = shop.distanceMeters ?? 9_999_999

        let speed: Double = {
            switch movement {
            case .stationary, .walking: return 1.4
            case .driving: return 13.9
            }
        }()

        let etaSeconds = dist / speed
        let etaNorm = max(0.0, 1.0 - (etaSeconds / (20.0 * 60.0)))

        let headingNorm: Double = {
            guard let heading = heading else { return 0.5 }

            let bearingToShop = userLocation.bearing(to: shop.coordinate)
            let current = heading.magneticHeading
            let delta = smallestAngleDeltaDegrees(a: current, b: bearingToShop)

            if delta <= 60 { return 1.0 }
            if delta >= 150 { return 0.0 }
            return max(0.0, 1.0 - ((delta - 60.0) / 90.0))
        }()

        let distanceNorm = max(0.0, 1.0 - (dist / 2500.0))

        return (0.65 * etaNorm) + (0.25 * headingNorm) + (0.10 * distanceNorm)
    }

    private func smallestAngleDeltaDegrees(a: Double, b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }
}

// MARK: - Helpers (LOCAL, not fileprivate elsewhere)

private extension CLLocation {
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = coordinate.latitude.degreesToRadians
        let lon1 = coordinate.longitude.degreesToRadians
        let lat2 = destination.latitude.degreesToRadians
        let lon2 = destination.longitude.degreesToRadians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2)
            - sin(lat1) * cos(lat2) * cos(dLon)

        let radiansBearing = atan2(y, x)
        return radiansBearing.radiansToDegrees
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
