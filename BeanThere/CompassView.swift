//
//  CompassView.swift
//  BeanThere
//

import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var locationManager: LocationManager
    let targetShop: CoffeeShop?

    private var bearing: Double {
        guard let userLocation = locationManager.location, let shop = targetShop else { return 0 }
        return userLocation.bearing(to: shop.coordinate)
    }

    private var rotationAngle: Angle {
        guard let heading = locationManager.heading else { return .zero }
        return Angle(degrees: bearing - heading.magneticHeading)
    }

    private var distanceMiles: Double {
        guard let userLocation = locationManager.location, let shop = targetShop else { return 0 }
        let meters = userLocation.distance(from: CLLocation(latitude: shop.coordinate.latitude, longitude: shop.coordinate.longitude))
        return meters * 0.000621371
    }

    var body: some View {
        Group {
            if let shop = targetShop, locationManager.location != nil {
                VStack(spacing: 4) {
                    Image("compass")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .rotationEffect(rotationAngle)
                        .animation(.spring(), value: rotationAngle)

                    Text(shop.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(String(format: "%.2f miles", distanceMiles))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.thinMaterial)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding()
    }
}

private extension CLLocation {
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians

        let lat2 = destination.latitude.degreesToRadians
        let lon2 = destination.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansBearing.radiansToDegrees
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
