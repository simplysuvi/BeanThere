import Foundation
import MapKit
import Combine

struct SearchCompletion: Identifiable {
    let id = UUID()
    let completion: MKLocalSearchCompletion
}

class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions = [SearchCompletion]()
    private var completer: MKLocalSearchCompleter

    var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results.map(SearchCompletion.init)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error getting search completions: \(error.localizedDescription)")
    }
}
