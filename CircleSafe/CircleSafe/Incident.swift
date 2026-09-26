import Foundation
import CoreLocation

struct Incident: Codable, Identifiable {
    let id: String
    let title: String
    let summary: String
    let severity: String
    let source: String
    let location: IncidentLocation
    let locationContext: LocationContext?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case summary
        case severity
        case source
        case location
        case locationContext
    }
}

struct IncidentLocation: Codable {
    let type: String
    let coordinates: [Double]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinates[1],
            longitude: coordinates[0]
        )
    }
}

struct LocationContext: Codable {
    let areaType: String
    let context: String
}
