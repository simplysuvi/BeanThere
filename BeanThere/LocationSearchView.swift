import SwiftUI
import MapKit

struct LocationSearchView: View {
    @StateObject private var viewModel = LocationSearchViewModel()
    @Binding var selectedLocation: CLLocation?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a location", text: $viewModel.queryFragment)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            List(viewModel.completions) { searchCompletion in
                VStack(alignment: .leading) {
                    Text(searchCompletion.completion.title)
                    Text(searchCompletion.completion.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    getCoordinates(for: searchCompletion.completion)
                }
            }
        }
        .navigationTitle("Search Location")
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
        })
    }

    private func getCoordinates(for completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let coordinate = response?.mapItems.first?.placemark.coordinate {
                self.selectedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                presentationMode.wrappedValue.dismiss()
            } else {
                // Handle error
                print("Error getting coordinates: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
