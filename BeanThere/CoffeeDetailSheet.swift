//
//  CoffeeDetailSheet.swift
//  BeanThere
//

import SwiftUI
import MapKit
import CoreLocation

struct CoffeeDetailSheet: View {
    let shop: CoffeeShop
    let userLocation: CLLocation?

    private var distanceText: String {
        guard
            let userLocation = userLocation
        else { return "N/A" }

        let shopLoc = CLLocation(latitude: shop.coordinate.latitude, longitude: shop.coordinate.longitude)
        let meters = userLocation.distance(from: shopLoc)
        let miles = meters * 0.000621371
        return String(format: "%.2f miles", miles)
    }

    private var addressText: String {
        shop.mapItem.placemark.title ?? "No address available"
    }

    private var phoneText: String? {
        shop.mapItem.phoneNumber
    }

    private var urlText: String? {
        shop.mapItem.url?.absoluteString
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(shop.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.text)

                    Spacer()

                    Button {
                        shop.mapItem.openInMaps()
                    } label: {
                        Text("Go")
                            .font(.headline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.accent)
                            .foregroundColor(Theme.background)
                            .cornerRadius(12)
                    }
                }

                Text("Distance: \(distanceText)")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)

                Divider()

                InfoRow(icon: "mappin.and.ellipse", text: addressText)

                if let phone = phoneText {
                    let digits = phone.filter { $0.isNumber }
                    InfoRow(icon: "phone.fill", text: phone, isLink: "tel:\(digits)")
                }

                if let url = urlText {
                    InfoRow(icon: "safari.fill", text: url, isLink: url)
                }
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 20)

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
