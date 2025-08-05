import Foundation
import Combine
import CoreLocation

class CoffeeDetailViewModel: ObservableObject {
    @Published var coffeeShop: CoffeeShop
    private let googlePlacesService: GooglePlacesService

    init(coffeeShop: CoffeeShop) {
        self.coffeeShop = coffeeShop
        self.googlePlacesService = GooglePlacesService(apiKey: Secrets.googlePlacesAPIKey)
        fetchGooglePlacesDetails()
    }

    private func fetchGooglePlacesDetails() {
        googlePlacesService.fetchPlaceDetails(for: coffeeShop.name, location: coffeeShop.coordinate) { [weak self] details in
            DispatchQueue.main.async {
                self?.coffeeShop.googlePlaceDetails = details
            }
        }
    }
}
