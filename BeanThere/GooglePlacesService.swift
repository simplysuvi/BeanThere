import Foundation
import CoreLocation

class GooglePlacesService {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchPlaceDetails(for placeName: String, location: CLLocationCoordinate2D, completion: @escaping (PlaceDetails?) -> Void) {
        guard var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json") else {
            completion(nil)
            return
        }

        components.queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "100"), // Search within 100 meters
            URLQueryItem(name: "keyword", value: placeName),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
                self.fetchFullPlaceDetails(for: response.results.first?.place_id, completion: completion)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    private func fetchFullPlaceDetails(for placeID: String?, completion: @escaping (PlaceDetails?) -> Void) {
        guard let placeID = placeID else {
            completion(nil)
            return
        }

        guard var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json") else {
            completion(nil)
            return
        }

        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeID),
            URLQueryItem(name: "fields", value: "name,opening_hours,formatted_address,website,international_phone_number"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
                completion(response.result)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

struct GooglePlaceDetailsResponse: Codable {
    let result: PlaceDetails
}

// MARK: - Data Models
struct GooglePlacesResponse: Codable {
    let results: [PlaceSearchResult]
}

struct PlaceSearchResult: Codable {
    let place_id: String
}

struct PlaceDetails: Codable {
    let name: String
    let opening_hours: OpeningHours?
    let formatted_address: String?
    let website: String?
    let international_phone_number: String?
}

struct OpeningHours: Codable {
    let open_now: Bool
    let weekday_text: [String]?
}
