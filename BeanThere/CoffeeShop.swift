//
//  CoffeeShop.swift
//  BeanThere
//

import Foundation
import MapKit
import CoreLocation

struct CoffeeShop: Identifiable, Equatable {
    let id: String            // stable key (not UUID)
    let name: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem

    // Derived at search-time
    var distanceMeters: CLLocationDistance?

    init(name: String, coordinate: CLLocationCoordinate2D, mapItem: MKMapItem, distanceMeters: CLLocationDistance?) {
        self.name = name
        self.coordinate = coordinate
        self.mapItem = mapItem
        self.distanceMeters = distanceMeters

        // Stable ID so “skip this” works across refreshes
        self.id = CoffeeShop.makeID(name: name, coordinate: coordinate)
    }

    static func makeID(name: String, coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.5f", coordinate.latitude)
        let lon = String(format: "%.5f", coordinate.longitude)
        return "\(name.lowercased())|\(lat),\(lon)"
    }

    static func == (lhs: CoffeeShop, rhs: CoffeeShop) -> Bool {
        lhs.id == rhs.id
    }
}
