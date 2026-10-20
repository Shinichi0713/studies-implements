import SwiftUI
import SwiftData

struct SyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \HealthRecord.date, order: .reverse) private var records: [HealthRecord]

    @State private var syncStatus: SyncStatus = .idle
    @State private var lastSyncResult: String = ""
    @State private var showCloudKitInfo = false

    enum SyncStatus: Equatable {
        case idle
        case syncingToServer
        case syncingFromServer
        case success(String)
        case failure(String)

        var isLoading: Bool {
            self == .syncingToServer || self == .syncingFromServer
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: CloudKit (iCloud) 自動同期セクション
                Section {
                    HStack {
                        Image(systemName: "icloud")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud同期 (CloudKit)")
                                .font(.headline)
                            Text("自動的に全デイスに同期")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }

                    Button {
                        showCloudKitInfo = true
                    } label: {
                        Label("iCloud同期について", systemImage: "info.circle")
                    }
                } header: {
                    Text("自動同期")
                } footer: {
                    Text("Apple IDでサインインし、iCloud Driveが有効な場合、記録は自動的に同期されます。")
                }

                // MARK: 外部サーバーDB 手動同期セクション
                Section {
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("外部サーバー同期")
                                .font(.headline)
                            Text("自分のサーバーDBと手動同期")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // サーバーへアップロード
                    Button {
                        Task { await syncToServer() }
                    } label: {
                        HStack {
                            Label("サーバーにアップロード", systemImage: "arrow.up.circle")
                            if syncStatus == .syncingToServer {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(syncStatus.isLoading)

                    // サーバーからダウンロド
                    Button {
                        Task { await syncFromServer() }
                    } label: {
                        HStack {
                            Label("サーバーからダウンロード", systemImage: "arrow.down.circle")
                            if syncStatus == .syncingFromServer {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(syncStatus.isLoading)

                } header: {
                    Text("手動同期")
                } footer: {
                    Text("REST API経由で自分のバックエンドサーバーと同期します。サーバーURLは HealthAPIService.swift で設定してください。")
                }

                // MARK: 同期結果表示
                if !lastSyncResult.isEmpty {
                    Section("最終同期結果") {
                        Text(lastSyncResult)
                            .font(.subheadline)
                    }
                }

                // MARK: ローカル記録の統計
                Section("ローカル記録") {
                    LabeledContent("総記録数", value: "\(records.count) 件")
                    LabeledContent("未同期", value: "\(records.filter { $0.lastSyncedAt == nil }.count) 件")
                }
            }
            .navigationTitle("同期設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .alert("iCloud同期", isPresented: $showCloudKitInfo) {
                Button("OK") {}
            } message: {
                Text("このアプリはSwiftData + CloudKitを使用しています。iCloudにサインインしている場合、記録は自動的に同期されます。設定アプリ > [あなたの名前] > iCloud > iCloud Drive がオンになっていることを確認してください。")
            }
        }
    }

    // MARK: - サーバーへアップロード
    private func syncToServer() async {
        syncStatus = .syncingToServer
        lastSyncResult = ""

        let unsynced = records.filter { $0.lastSyncedAt == nil }
        if unsynced.isEmpty {
            syncStatus = .success("未同期の記録はありません")
            lastSyncResult = "未同期の記録はありません"
            return
        }

        do {
            let result = try await HealthAPIService.shared.syncToServer(records: unsynced)
            // 成功した記録の lastSyncedAt を更新
            for record in unsynced {
                record.lastSyncedAt = Date()
            }
            syncStatus = .success("\(result.uploaded) 件アップロード完了")
            lastSyncResult = "アップロード: \(result.uploaded) 件成功 / \(result.failed) 件失敗"
        } catch {
            syncStatus = .failure(error.localizedDescription)
            lastSyncResult = "エラー: \(error.localizedDescription)"
        }
    }

    // MARK: - サーバーからダウンロード
    private func syncFromServer() async {
        syncStatus = .syncingFromServer
        lastSyncResult = ""

        do {
            let dtos = try await HealthAPIService.shared.fetchAllRecords()
            var addedCount = 0

            for dto in dtos {
                // 既存のIDがない場合のみ追加（簡易重複防）
                if !records.contains(where: { $0.id == dto.id }) {
                    let newRecord = HealthRecord(
                        id: dto.id ?? UUID(),
                        date: dto.date,
                        bodyTemperature: dto.bodyTemperature,
                        weight: dto.weight,
                        systolicBloodPressure: dto.systolicBloodPressure,
                        diastolicBloodPressure: dto.diastolicBloodPressure,
                        heartRate: dto.heartRate,
                        memo: dto.memo,
                        lastSyncedAt: Date()
                    )
                    modelContext.insert(newRecord)
                    addedCount += 1
                }
            }

            syncStatus = .success("\(addedCount) 件ダウンロード完了")
            lastSyncResult = "ダウンロード: \(addedCount) 件追加 / サーバー総数 \(dtos.count) 件"
        } catch {
            syncStatus = .failure(error.localizedDescription)
            lastSyncResult = "エラー: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SyncSettingsView()
        .modelContainer(for: HealthRecord.self, inMemory: true)
}
