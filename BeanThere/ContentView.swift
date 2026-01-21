//
//  ContentView.swift
//  BeanThere
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapSearchService = MapSearchService()

    @State private var selectedShopForDetails: CoffeeShop?
    @State private var showMap: Bool = false

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var hasSearchedOnce = false

    private var userLocation: CLLocation? {
        locationManager.location
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    header

                    if let userLocation = userLocation {
                        recommendationCard(userLocation: userLocation)

                        if showMap {
                            mapView(userLocation: userLocation)
                                .frame(height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                                .overlay(
                                    CompassView(locationManager: locationManager, targetShop: mapSearchService.recommendedShop),
                                    alignment: .topTrailing
                                )
                        }

                        Spacer(minLength: 0)
                    } else {
                        loadingView
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
            .onAppear {
                locationManager.requestPermission()
            }
            .onChange(of: locationManager.location) {
                guard let userLocation = locationManager.location else { return }

                if !hasSearchedOnce {
                    hasSearchedOnce = true
                    Task {
                        await mapSearchService.searchNearbyCoffee(userLocation: userLocation)
                        mapSearchService.updateRecommendation(
                            userLocation: userLocation,
                            heading: locationManager.heading,
                            movement: locationManager.movementState
                        )
                        updateMapPosition(to: userLocation)
                    }
                } else {
                    // If location changes later, just recompute recommendation from current ranked list
                    mapSearchService.updateRecommendation(
                        userLocation: userLocation,
                        heading: locationManager.heading,
                        movement: locationManager.movementState
                    )
                }
            }
            .onChange(of: locationManager.heading) {
                guard let userLocation = userLocation else { return }
                mapSearchService.updateRecommendation(
                    userLocation: userLocation,
                    heading: locationManager.heading,
                    movement: locationManager.movementState
                )
            }
            .sheet(item: $selectedShopForDetails) { shop in
                CoffeeDetailSheet(shop: shop, userLocation: userLocation)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - UI

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BeanThere")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Theme.text)

                Text("One good pick. Right now.")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            Button {
                withAnimation(.spring()) {
                    showMap.toggle()
                }
            } label: {
                Image(systemName: showMap ? "map.fill" : "map")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .padding(10)
                    .background(Theme.accentLight)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }

    private func recommendationCard(userLocation: CLLocation) -> some View {
        let shop = mapSearchService.recommendedShop

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accentLight)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(shop?.name ?? "Finding a good option…")
                        .font(.headline)
                        .foregroundColor(Theme.text)
                        .lineLimit(1)

                    Text(subtitleText(shop: shop, userLocation: userLocation))
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    if let shop = shop {
                        shop.mapItem.openInMaps()
                    }
                } label: {
                    Text("Go")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .foregroundColor(Theme.background)
                        .cornerRadius(12)
                }
                .disabled(shop == nil)

                Button {
                    mapSearchService.pickNextRecommendation()
                } label: {
                    Text("Not this")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accentLight)
                        .foregroundColor(Theme.accent)
                        .cornerRadius(12)
                }
                .disabled(shop == nil)

                Button {
                    if let shop = shop {
                        selectedShopForDetails = shop
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(Theme.accent)
                        .frame(width: 44, height: 44)
                        .background(Theme.accentLight)
                        .cornerRadius(12)
                }
                .disabled(shop == nil)
            }

            if shop == nil {
                Text("Tip: if you don’t see anything, try again in a minute or move a bit.")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)
        .padding(.horizontal)
    }

    private func subtitleText(shop: CoffeeShop?, userLocation: CLLocation) -> String {
        guard let shop = shop else {
            return "Searching nearby…"
        }
        let meters = shop.distanceMeters ?? userLocation.distance(from: CLLocation(latitude: shop.coordinate.latitude, longitude: shop.coordinate.longitude))
        let miles = meters * 0.000621371

        // Simple time estimate (walking-ish) for readability
        let etaMinutes = Int(round((meters / 1.4) / 60.0))
        return String(format: "%.2f mi • ~%d min", miles, max(1, etaMinutes))
    }

    private func mapView(userLocation: CLLocation) -> some View {
        Map(position: $position) {
            UserAnnotation()

            if let shop = mapSearchService.recommendedShop {
                Annotation(shop.name, coordinate: shop.coordinate) {
                    CoffeeAnnotationView()
                        .scaleEffect(1.15)
                }
            }

            // Show a few alternates lightly (optional)
            ForEach(mapSearchService.rankedShops.prefix(6)) { shop in
                if shop.id != mapSearchService.recommendedShop?.id {
                    Annotation(shop.name, coordinate: shop.coordinate) {
                        CoffeeAnnotationView()
                            .opacity(0.55)
                            .scaleEffect(0.9)
                    }
                }
            }
        }
        .onAppear {
            updateMapPosition(to: userLocation)
        }
    }

    private func updateMapPosition(to location: CLLocation) {
        withAnimation(.spring()) {
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            if locationManager.authorizationStatus == .denied {
                Text("Please enable location services in Settings.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(Theme.secondaryText)
            } else {
                ProgressView("Getting your location…")
                    .tint(Theme.accent)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
