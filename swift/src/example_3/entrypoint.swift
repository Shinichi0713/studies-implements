import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        let app = try await Application.make(.detect())

        // ルーティング設定
        try routes(app)

        // サーバー起動（ポート8080）
        try await app.startup()
        try await app.running?.get()

        // 終了時のクリーンアップ
        try await app.asyncShutdown()
    }
}
