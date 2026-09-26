import Foundation

struct WatchSession: Codable, Identifiable {
    let id: String
    let circleId: String
    let status: String
    let startedAt: String
    let endedAt: String?
    let watcherCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case circleId
        case status
        case startedAt
        case endedAt
        case watcherCount
    }
}
