import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

// 制限対象アプリの選択を保持するモデル
@MainActor
class ScreenTimeModel: ObservableObject {
    let authorizationCenter = AuthorizationCenter.shared
    let deviceActivityCenter = DeviceActivityCenter.shared
    
    // ユーザーが選択したアプリのトークン
    @Published var selection: FamilyActivitySelection = .init()
    
    init() {
        // 認可状態の変化を監視
        Task {
            for await authorization in authorizationCenter.$authorization {
                if authorization == .approved {
                    // 認可済みならスケジュールを開始
                    await startMonitoring()
                }
            }
        }
    }
    
    // 認可をリクエスト
    func requestAuthorization() async throws {
        try await authorizationCenter.requestAuthorization(for: .individual)
    }
    
    // デバイスアクティビティの監視を開始（1日1時間の制限）
    func startMonitoring() async {
        // すでに同じ名前のスケジュールが動いていたら停止
        deviceActivityCenter.stopMonitoring([.dailyLimit])
        
        // スケジュール定義（例: 毎日0:00〜23:59）
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // アプリの使用時間制限（1時間 = 3600秒）
        let limit: TimeInterval = 3600
        
        // イベント定義（1時間経過したら発火）
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            threshold: DateComponents(second: Int(limit))
        )
        
        do {
            try deviceActivityCenter.startMonitoring(
                .dailyLimit,
                during: schedule,
                events: [.oneHourLimit: event]
            )
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}

// DeviceActivityName（スケジュール識別用）
extension DeviceActivityName {
    static let dailyLimit = Self("dailyLimit")
}

// DeviceActivityEvent.Name（イベント識別用）
extension DeviceActivityEvent.Name {
    static let oneHourLimit = Self("oneHourLimit")
}

// DeviceActivityMonitor（時間超過時にアプリをブロック）
struct AppLimitMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    func intervalDidStart(for activity: DeviceActivityName) {
        // 監視開始時に制限をクリア（新たな日の開始）
        store.shield.applications = nil
    }
    
    func eventDidReachThreshold(_ event: DeviceActivityEvent, activity: DeviceActivityName) {
        // 1時間の使用制限に達したら、選択したアプリをブロック
        store.shield.applications = event.applications
    }
    
    func intervalDidEnd(for activity: DeviceActivityName) {
        // 1日の終わりに制限を解除
        store.shield.applications = nil
    }
}

// SwiftUIビュー
struct ContentView: View {
    @StateObject private var model = ScreenTimeModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("スクリーンタイム制限アプリ")
                .font(.title)
            
            // 認可ボタン
            Button("スクリーンタイムの許可をリクエスト") {
                Task {
                    do {
                        try await model.requestAuthorization()
                    } catch {
                        print("Authorization failed: \(error)")
                    }
                }
            }
            
            // 制限したいアプリを選択するピッカー
            FamilyActivityPicker(selection: $model.selection)
                .frame(height: 300)
            
            Text("選択したアプリは1日1時間までしか使えません")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}