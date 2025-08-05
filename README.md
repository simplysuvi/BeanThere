## BeanThere

BeanThere is a SwiftUI-based iOS application designed to help coffee enthusiasts discover the best independent coffee shops nearby. It provides a seamless, map-based interface to explore local coffee spots, view their details, and get directions.

### Features

- **Interactive Map**: Displays nearby coffee shops on a map, with custom annotations and user location tracking.
- **Real-time Search**: Automatically searches for coffee shops as you move or pan to new locations.
- **Location-Aware Sorting**: Lists coffee shops from nearest to farthest, making it easy to find the closest spot.
- **Compass View**: A unique compass that always points toward the nearest coffee shop, guiding you in the right direction.
- **Detailed Information**: Tap on a coffee shop to view its details, including its address and whether it's currently open or closed (powered by Google Places).
- **Custom Location Search**: Manually search for coffee shops in any location, not just your current one.
- **Excludes Major Chains**: Filters out large chains like Starbucks and Dunkin' to help you discover unique, local businesses.

### Getting Started

To get the app up and running on your own device, you'll need to follow these steps:

#### Prerequisites

- Xcode 13 or later
- An Apple Developer account (for running on a physical device)
- A Google Places API key

#### Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/simplysuvi/BeanThere.git
   cd BeanThere
   ```

2. **Configure API Key**:
   The app uses the Google Places API to fetch detailed information about each coffee shop. You'll need to provide your own API key to get this to work.

   - Create a new Swift file in the `BeanThere` directory named `Secrets.swift`.
   - Add the following code to the file, replacing `"YOUR_API_KEY"` with your actual Google Places API key:

   ```swift
   import Foundation

   enum Secrets {
       static let googlePlacesAPIKey = "YOUR_API_KEY"
   }
   ```

3. **Build and Run**:
   Open the `BeanThere.xcodeproj` file in Xcode, select your target device or simulator, and click the "Run" button.

### How It Works

- **SwiftUI and MapKit**: The app is built entirely with SwiftUI and leverages MapKit for all map-related functionality.
- **CoreLocation**: The `LocationManager` class uses CoreLocation to track the user's location and heading in real-time.
- **Google Places API**: The `GooglePlacesService` fetches additional details for each coffee shop, such as its opening hours.
- **MVVM Architecture**: The codebase is organized following the Model-View-ViewModel (MVVM) pattern to ensure a clean separation of concerns.
