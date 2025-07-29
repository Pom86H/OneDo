import SwiftUI

struct LaunchScreenView: View {
    // MARK: - システムのカラーテーマを取得
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - アニメーションの状態を管理するState変数
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.8
    
    // MARK: - アニメーション完了時に親ビューに通知するためのクロージャ
    var onAnimationComplete: () -> Void

    // MARK: - カスタムカラーの定義 (ContentViewと同期)
    var customAccentColor: Color {
        // Light: #4A90E2, Dark: #7FB8F7
        colorScheme == .dark ? Color(red: 0x7F/255.0, green: 0xB8/255.0, blue: 0xF7/255.0) : Color(red: 0x4A/255.0, green: 0x90/255.0, blue: 0xE2/255.0)
    }
    var customBaseColor: Color {
        // Light: #FFFFFF, Dark: #121212
        colorScheme == .dark ? Color(red: 0x12/255.0, green: 0x12/255.0, blue: 0x12/255.0) : Color(red: 0xFF/255.0, green: 0xFF/255.0, blue: 0xFF/255.0)
    }
    var customTextColor: Color {
        // Light: #333333, Dark: #E0E0E0
        colorScheme == .dark ? Color(red: 0xE0/255.0, green: 0xE0/255.0, blue: 0xE0/255.0) : Color(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0)
    }

    var body: some View {
        ZStack {
            // MARK: - 背景色をカスタムベースカラーに設定
            customBaseColor.edgesIgnoringSafeArea(.all)

            VStack {
                // MARK: - アプリアイコン（シンプルなチェックマークの円）
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80)) // アイコンサイズ
                    .foregroundColor(customAccentColor) // アクセントカラーを適用
                    .scaleEffect(scale) // スケールアニメーション
                    .opacity(opacity) // フェードアニメーション
                    .animation(.easeOut(duration: 1.0), value: scale) // スケールアニメーションの速度

                // MARK: - アプリ名テキスト
                Text("OneDo")
                    .font(.largeTitle) // フォントサイズ
                    .fontWeight(.bold) // フォントの太さ
                    .foregroundColor(customTextColor) // テキストカラーを適用
                    .scaleEffect(scale) // スケールアニメーション
                    .opacity(opacity) // フェードアニメーション
                    .animation(.easeOut(duration: 1.0), value: scale) // スケールアニメーションの速度
            }
        }
        // MARK: - ビューが表示されたときにアニメーションと遷移をトリガー
        .onAppear {
            // フェードインとスケールアップのアニメーション
            withAnimation {
                self.opacity = 1.0
                self.scale = 1.0
            }
            // アニメーション表示後、少し待ってからフェードアウトし、親ビューに通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // 1.5秒間表示
                withAnimation {
                    self.opacity = 0.0 // フェードアウト
                    self.scale = 1.2 // フェードアウト時に少し拡大
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // フェードアウトを待つ
                    onAnimationComplete() // アニメーション完了を親ビューに通知
                }
            }
        }
    }
}

// MARK: - プレビュー (コメントアウトして審査エラーを回避)
// #Preview {
//     LaunchScreenView(onAnimationComplete: {})
// }
