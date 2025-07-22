import SwiftUI

struct ProgressGraphView: View {
    let habit: Habit // グラフ表示対象の習慣
    let numberOfDays: Int = 7 // 表示する日数（例: 過去7日間）

    var body: some View {
        VStack(alignment: .leading) {
            Text("過去 \(numberOfDays) 日の進捗")
                .font(.headline)
                .padding(.bottom, 5)

            // 目標が設定されている場合のみグラフを表示
            if habit.goalType != .none, let targetValue = habit.targetValue, targetValue > 0 {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(0..<numberOfDays, id: \.self) { i in
                        let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                        let dailyProgress = calculateDailyProgress(for: date) // その日の進捗を計算
                        
                        // グラフの棒
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(dailyProgress >= targetValue ? Color.green : Color.accentColor.opacity(0.6))
                                .frame(height: CGFloat(min(dailyProgress / targetValue, 1.0) * 100)) // 最大高さ100
                                .cornerRadius(4) // 角丸
                            Text(date, formatter: dateFormatter)
                                .font(.caption2)
                                .rotationEffect(.degrees(-45), anchor: .topLeading) // 日付を斜めに表示
                                .offset(x: 10, y: 10) // 位置調整
                        }
                        .frame(maxWidth: .infinity, maxHeight: 120) // 各棒の最大高さを設定
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20) // 日付表示のための余白

                // 目標値と単位の表示
                Text("目標: \(targetValue, specifier: "%.0f") \(habit.unit ?? "") / 日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)
            } else {
                Text("目標が設定されていません。")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 3)
    }

    // MARK: - ヘルパーメソッド

    // その日の進捗を計算する（現在は達成済みかどうかのみを考慮）
    // 将来的には、目標タイプに応じて実際の値（例: 運動時間、水の量）を記録・計算する
    private func calculateDailyProgress(for date: Date) -> Double {
        // 現時点では、単にその日が達成済みであれば1、そうでなければ0として扱う
        // 目標が回数や時間の場合、ここに実際の記録値を入れるロジックが必要
        if habit.isCompleted(on: date) {
            return habit.targetValue ?? 1.0 // 達成済みなら目標値を満たしたと見なす
        } else {
            return 0.0
        }
    }

    // 日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d" // 例: 7/22
        return formatter
    }
}

// #Preview {
//     struct ProgressGraphViewPreview: View {
//         @State private var sampleHabit: Habit = Habit(
//             name: "水を2リットル飲む",
//             isCompleted: false,
//             repeatSchedule: .daily,
//             completionDates: [
//                 Calendar.current.date(byAdding: .day, value: -1, to: Date())!, // 昨日達成
//                 Calendar.current.date(byAdding: .day, value: -3, to: Date())!  // 3日前達成
//             ],
//             goalType: .count,
//             targetValue: 2.0,
//             unit: "リットル"
//         )
//
//         var body: some View {
//             ProgressGraphView(habit: sampleHabit)
//         }
//     }
//     return ProgressGraphViewPreview()
// }
