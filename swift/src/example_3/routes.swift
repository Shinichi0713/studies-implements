import Vapor

// 商品モデル
struct Item: Content {
    let id: Int
    let name: String
    let price: Int
}

// エコー用のリクエスト/レスポンスモデル
struct EchoRequest: Content {
    let message: String
}

struct EchoResponse: Content {
    let echoed: String
    let timestamp: String
}

func routes(_ app: Application) throws {
    // GET / → Hello, World!
    app.get { req in
        "Hello, World!"
    }

    // GET /hello/:name → パラメータを使った挨拶
    app.get("hello", ":name") { req -> String in
        let name = req.parameters.get("name") ?? "Stranger"
        return "Hello, \\(name)!"
    }

    // GET /items → JSONで商品リストを返す
    app.get("items") { req -> [Item] in
        return [
            Item(id: 1, name: "MacBook Pro", price: 240000),
            Item(id: 2, name: "iPhone 15", price: 120000),
            Item(id: 3, name: "AirPods Pro", price: 35000),
        ]
    }

    // POST /echo → 送ったJSONをそのまま返す
    app.post("echo") { req -> EchoResponse in
        let body = try req.content.decode(EchoRequest.self)
        let now = ISO8601DateFormatter().string(from: Date())
        return EchoResponse(echoed: body.message, timestamp: now)
    }
}
