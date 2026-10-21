import Foundation
import SwiftData

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodeError(String)
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URLが無効です"
        case .invalidResponse: return "サーバーからの応答が無効です"
        case .decodeError(let msg): return "デコードエラー: \(msg)"
        case .serverError(let code): return "サーバーエラー (\(code))"
        case .networkError(let error): return "通信エラー: \(error.localizedDescription)"
        }
    }
}

class HealthAPIService {
    static let shared = HealthAPIService()
    private let baseURL: URL

    private init() {
        if let url = URL(string: "http://localhost:8080") {
            self.baseURL = url
        } else {
            fatalError("Invalid base URL")
        }
    }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func fetchAllRecords() async throws -> [HealthRecord.DTO] {
        let url = baseURL.appendingPathComponent("healthrecords")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([HealthRecord.DTO].self, from: data)
        } catch {
            throw APIError.decodeError(error.localizedDescription)
        }
    }

    func createRecord(_ dto: HealthRecord.DTO) async throws -> HealthRecord.DTO {
        let url = baseURL.appendingPathComponent("healthrecords")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(dto)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HealthRecord.DTO.self, from: data)
    }

    func updateRecord(id: UUID, dto: HealthRecord.DTO) async throws -> HealthRecord.DTO {
        let url = baseURL.appendingPathComponent("healthrecords/\(id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(dto)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HealthRecord.DTO.self, from: data)
    }

    func deleteRecord(id: UUID) async throws {
        let url = baseURL.appendingPathComponent("healthrecords/\(id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    func syncToServer(records: [HealthRecord]) async throws -> (uploaded: Int, failed: Int) {
        var uploaded = 0
        var failed = 0

        for record in records {
            do {
                let dto = record.toDTO()
                _ = try await createRecord(dto)
                uploaded += 1
            } catch {
                failed += 1
            }
        }
        return (uploaded, failed)
    }
}
