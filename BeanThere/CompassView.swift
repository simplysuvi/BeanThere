import SwiftUI
import CoreLocation

struct CompassView: View {
    @ObservedObject var locationManager: LocationManager
    let closestShop: CoffeeShop?

    private var bearing: Double {
        guard let userLocation = locationManager.location, let shopLocation = closestShop else { return 0 }
        return userLocation.bearing(to: shopLocation.coordinate)
    }

    private var rotationAngle: Angle {
        guard let heading = locationManager.heading else { return .zero }
        let magneticHeading = heading.magneticHeading
        return Angle(degrees: bearing - magneticHeading)
    }

    private var distance: Double {
        guard let userLocation = locationManager.location, let shopLocation = closestShop else { return 0 }
        return userLocation.distance(from: CLLocation(latitude: shopLocation.coordinate.latitude, longitude: shopLocation.coordinate.longitude))
    }

    var body: some View {
        Group {
            if let shop = closestShop, locationManager.location != nil {
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
                    
                    Text(String(format: "%.2f miles", distance * 0.000621371))
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

extension CLLocation {
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

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}
