import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapSearchService = MapSearchService()
    @State private var selectedShop: CoffeeShop?
    @State private var manualLocation: CLLocation?
    @State private var showingLocationSearch = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var hasSetInitialPosition = false

    private var currentLocation: CLLocation? {
        manualLocation ?? locationManager.location
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if currentLocation != nil {
                        headerView
                        
                        Map(position: $position) {
                            if manualLocation == nil {
                                UserAnnotation {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 22, height: 22)
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                            
                            if let manualLocation = manualLocation {
                                Annotation("Selected Location", coordinate: manualLocation.coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundColor(Theme.mapPin)
                                        .shadow(radius: 5)
                                }
                            }

                            ForEach(mapSearchService.coffeeShops) { shop in
                                Annotation(shop.name, coordinate: shop.coordinate) {
                                    CoffeeAnnotationView()
                                        .scaleEffect(selectedShop == shop ? 1.2 : 1.0)
                                        .animation(.spring(), value: selectedShop)
                                        .onTapGesture {
                                            selectedShop = shop
                                        }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding()
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .overlay(
                            CompassView(locationManager: locationManager, closestShop: mapSearchService.coffeeShops.first)
                                .padding(),
                            alignment: .topTrailing
                        )
                        
                        List {
                            ForEach(mapSearchService.coffeeShops) { shop in
                                CoffeeRow(shop: shop, userLocation: currentLocation)
                                    .onTapGesture {
                                        selectedShop = shop
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    } else {
                        loadingView
                    }
                }
                .animation(.spring(), value: mapSearchService.coffeeShops)
                .animation(.default, value: currentLocation != nil)
                .navigationBarHidden(true)
                .onAppear {
                    locationManager.requestPermission()
                }
                .onChange(of: locationManager.location) {
                    if !hasSetInitialPosition, manualLocation == nil, let newLocation = locationManager.location {
                        updateMapPosition(to: newLocation)
                        searchAt(location: newLocation)
                        hasSetInitialPosition = true
                    }
                }
                .onChange(of: manualLocation) {
                    if let newLocation = manualLocation {
                        updateMapPosition(to: newLocation)
                        searchAt(location: newLocation)
                    } else if let userLocation = locationManager.location {
                        // When manual location is cleared, go back to user's live location
                        updateMapPosition(to: userLocation)
                        searchAt(location: userLocation)
                    }
                }
                .sheet(item: $selectedShop) { shop in
                    CoffeeDetailSheet(shop: shop, userLocation: currentLocation)
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showingLocationSearch) {
                    NavigationView {
                        LocationSearchView(selectedLocation: $manualLocation)
                    }
                }
            }
        }
    }
    
    private func updateMapPosition(to location: CLLocation) {
        withAnimation(.spring()) {
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    private func searchAt(location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapSearchService.search(for: "coffee", in: region, userLocation: location)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("BeanThere")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Theme.text)
                if manualLocation != nil {
                    Text("Showing results for custom location")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .transition(.opacity)
            
            Spacer()
            
            Button(action: {
                showingLocationSearch = true
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .padding(10)
                    .background(Theme.accentLight)
                    .clipShape(Circle())
            }
            
            if manualLocation != nil {
                Button(action: {
                    withAnimation {
                        manualLocation = nil
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accent)
                        .padding(10)
                        .background(Theme.accentLight)
                        .clipShape(Circle())
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            if locationManager.authorizationStatus == .denied {
                Text("Please enable location services in Settings to find the best coffee spots!")
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(Theme.secondaryText)
            } else {
                ProgressView("Finding your location...")
                    .tint(Theme.accent)
            }
        }
    }
}

struct CoffeeRow: View {
    let shop: CoffeeShop
    let userLocation: CLLocation?

    private var distance: String {
        guard let distanceInMeters = shop.distance else { return "N/A" }
        let distanceInMiles = distanceInMeters * 0.000621371
        return String(format: "%.2f miles", distanceInMiles)
    }

    private var address: String {
        shop.mapItem.placemark.title ?? ""
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title)
                .foregroundColor(Theme.accent)
                .frame(width: 60, height: 60)
                .background(Theme.accentLight)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(shop.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.text)
                
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(1)

                Text(distance)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.accent)
            }
            
            Spacer()
            
            if let isOpen = shop.googlePlaceDetails?.opening_hours?.open_now {
                Text(isOpen ? "OPEN" : "CLOSED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isOpen ? .green : .red)
                    .padding(4)
                    .background((isOpen ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(4)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.secondaryText)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
