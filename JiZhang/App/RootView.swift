import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        Group {
            switch environment.bootstrapState {
            case .idle, .preparing:
                ProgressView("正在准备账本")
            case .failed(let message):
                ContentUnavailableView {
                    Label("初始化失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("重试") {
                        environment.start(force: true)
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .ready:
                MainTabView(environment: environment)
            }
        }
        .task {
            environment.start()
        }
    }
}

private struct MainTabView: View {
    let environment: AppEnvironment
    @State private var selectedTab: MainTab = .bills
    @State private var previousTab: MainTab = .bills
    @State private var isShowingEntry = false
    @State private var billsRefreshToken = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BillsView(
                environment: environment,
                refreshToken: billsRefreshToken
            )
                .tabItem {
                    Label("账单", systemImage: "list.bullet.rectangle")
                }
                .tag(MainTab.bills)

            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityLabel("记一笔")
                }
                .tag(MainTab.add)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
                .tag(MainTab.profile)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            guard newValue == .add else {
                previousTab = newValue
                return
            }

            if oldValue != .add {
                previousTab = oldValue
            }
            isShowingEntry = true
            selectedTab = previousTab
        }
        .fullScreenCover(isPresented: $isShowingEntry) {
            EntryView(environment: environment) {
                billsRefreshToken += 1
            }
        }
    }
}

private enum MainTab: Hashable {
    case bills
    case add
    case profile
}
