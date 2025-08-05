import SwiftUI
import MapKit

struct CoffeeDetailSheet: View {
    @StateObject private var viewModel: CoffeeDetailViewModel
    let userLocation: CLLocation?

    init(shop: CoffeeShop, userLocation: CLLocation?) {
        _viewModel = StateObject(wrappedValue: CoffeeDetailViewModel(coffeeShop: shop))
        self.userLocation = userLocation
    }

    private var shop: CoffeeShop {
        viewModel.coffeeShop
    }

    private var distance: String {
        guard let userLocation = userLocation else { return "N/A" }
        let shopLocation = CLLocation(latitude: shop.coordinate.latitude, longitude: shop.coordinate.longitude)
        let distanceInMeters = userLocation.distance(from: shopLocation)
        let distanceInMiles = distanceInMeters * 0.000621371
        return String(format: "%.2f miles", distanceInMiles)
    }

    private var address: String {
        let placemark = shop.mapItem.placemark
        return placemark.title ?? "No address available"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(shop.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.text)
                    Spacer()
                    if let isOpen = shop.googlePlaceDetails?.opening_hours?.open_now {
                        Text(isOpen ? "OPEN" : "CLOSED")
                            .font(.headline)
                            .foregroundColor(isOpen ? .green : .red)
                            .fontWeight(.bold)
                    }
                }

                Text("Distance: \(distance)")
                    .font(.headline)
                    .foregroundColor(Theme.secondaryText)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "mappin.and.ellipse", text: shop.googlePlaceDetails?.formatted_address ?? address)
                    
                    if let phone = shop.googlePlaceDetails?.international_phone_number {
                        InfoRow(icon: "phone.fill", text: phone, isLink: "tel:\(phone.filter { $0.isNumber })")
                    }
                    
                    if let urlString = shop.googlePlaceDetails?.website {
                        InfoRow(icon: "safari.fill", text: urlString, isLink: urlString)
                    }
                }

                if let hours = shop.googlePlaceDetails?.opening_hours?.weekday_text {
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Opening Hours")
                            .font(.headline)
                            .foregroundColor(Theme.text)
                        ForEach(hours, id: \.self) { hour in
                            Text(hour)
                                .font(.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    shop.mapItem.openInMaps()
                }) {
                    Text("Open in Apple Maps")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Theme.accent)
                .foregroundColor(Theme.background)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Theme.cardBackground)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    var isLink: String? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
            if let link = isLink, let url = URL(string: link) {
                Link(text, destination: url)
                    .font(.body)
                    .foregroundColor(Theme.accent)
            } else {
                Text(text)
                    .font(.body)
                    .foregroundColor(Theme.text)
            }
        }
    }
}
