import Foundation

struct WatchSession: Codable, Identifiable {
    let id: String
    let circleId: String
    let status: String
    let startedAt: String
    let endedAt: String?
    let watcherCount: Int
    let latitude: Double?
    let longitude: Double?
    let locationUpdatedAt: String?
    let deviceId: String?
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case circleId
        case status
        case startedAt
        case endedAt
        case watcherCount
        case latitude
        case longitude
        case locationUpdatedAt
        case deviceId
    }
}
