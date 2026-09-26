import Foundation

class APIService {
    static let shared = APIService()

    // Replace this with the IP address you just got
    private let baseURL = "http://10.66.32.205:3000"

    func fetchIncidents() async throws -> [Incident] {
        guard let url = URL(string: "\(baseURL)/api/incidents?circleId=roommates-demo") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Incident].self, from: data)
    }
    
    func submitReport(
        report: String,
        latitude: Double,
        longitude: Double
    ) async throws -> Incident {

        guard let url = URL(string: "\(baseURL)/api/incidents/analyze") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "report": report,
            "latitude": latitude,
            "longitude": longitude,
            "circleId": "roommates-demo"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Incident.self, from: data)
    }
}
