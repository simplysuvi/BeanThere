import Foundation
import MapKit
import Combine

class MapSearchService: ObservableObject {
    @Published var coffeeShops = [CoffeeShop]()
    private let excludedChains = ["starbucks", "dunkin", "mcdonald's", "tim hortons", "peet's", "caribou", "costa"]
    private let googlePlacesService = GooglePlacesService(apiKey: Secrets.googlePlacesAPIKey)

    func search(for query: String, in region: MKCoordinateRegion, userLocation: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        let search = MKLocalSearch(request: request)

        search.start { [weak self] (response, error) in
            guard let self = self, let response = response, error == nil else {
                return
            }
            
            var initialShops = response.mapItems.compactMap { mapItem -> CoffeeShop? in
                guard let name = mapItem.name, !self.excludedChains.contains(where: name.lowercased().contains) else {
                    return nil
                }
                let shopLocation = CLLocation(latitude: mapItem.placemark.coordinate.latitude, longitude: mapItem.placemark.coordinate.longitude)
                let distance = userLocation.distance(from: shopLocation)
                return CoffeeShop(name: name, coordinate: mapItem.placemark.coordinate, mapItem: mapItem, distance: distance)
            }
            
            initialShops.sort { $0.distance ?? 0 < $1.distance ?? 0 }
            
            DispatchQueue.main.async {
                self.coffeeShops = initialShops
                self.fetchDetailsForAllShops()
            }
        }
    }
    
    private func fetchDetailsForAllShops() {
        for (index, shop) in coffeeShops.enumerated() {
            googlePlacesService.fetchPlaceDetails(for: shop.name, location: shop.coordinate) { [weak self] details in
                DispatchQueue.main.async {
                    self?.coffeeShops[index].googlePlaceDetails = details
                }
            }
        }
    }
}
