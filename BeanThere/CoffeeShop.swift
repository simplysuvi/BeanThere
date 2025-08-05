import Foundation
import MapKit

struct CoffeeShop: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem
    var googlePlaceDetails: PlaceDetails?
    var distance: CLLocationDistance?

    static func == (lhs: CoffeeShop, rhs: CoffeeShop) -> Bool {
        lhs.id == rhs.id
    }
}
