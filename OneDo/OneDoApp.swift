import SwiftUI

@main
struct OneDoApp: App {
    // MARK: - 起動画面を表示するかどうかを制御するState変数
    @State private var showLaunchScreen: Bool = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // MARK: - showLaunchScreenの状態に応じてLaunchScreenViewまたはContentViewを表示
                if showLaunchScreen {
                    // LaunchScreenViewにアニメーション完了時のクロージャを渡す
                    LaunchScreenView {
                        self.showLaunchScreen = false // アニメーション完了後、ContentViewに切り替える
                    }
                } else {
                    ContentView()
                }
            }
        }
    }
}
