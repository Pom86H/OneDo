import Foundation
import SwiftUI // Colorを扱うために必要になる可能性があるのでインポート

// 習慣タスクのデータを定義する構造体
struct Habit: Identifiable, Codable {
    let id: UUID // 各Habitを一意に識別するためのID
    var name: String // 習慣の名前
    var isCompleted: Bool // その日の達成状況

    var repeatSchedule: RepeatSchedule // 習慣の繰り返し頻度
    var completionDates: [Date] // 習慣が達成された日付のリスト

    // MARK: - リマインダー関連のプロパティ
    var reminderTime: Date? // リマインダーの時間 (Optional)
    var reminderEnabled: Bool // リマインダーが有効かどうか
    var reminderDaysOfWeek: Set<Int> // リマインダーを鳴らす曜日 (1=日曜, 2=月曜...7=土曜)

    // MARK: - 目標設定関連のプロパティを追加
    var goalType: GoalType // 目標のタイプ (例: 回数、時間)
    var targetValue: Double? // 目標値 (例: 10回、30分)
    var unit: String? // 単位 (例: "回", "分")

    // MARK: - カスタムアイコンとカラーのプロパティを追加
    var iconName: String? // SF Symbolsの名前 (例: "heart.fill")
    var customColorHex: String? // カラーの16進数コード (例: "#FF0000")


    // イニシャライザ。idのデフォルト値はUUID()にする
    init(id: UUID = UUID(), name: String, isCompleted: Bool,
         repeatSchedule: RepeatSchedule = .daily,
         completionDates: [Date] = [],
         reminderTime: Date? = nil, // デフォルトはnil (設定なし)
         reminderEnabled: Bool = false, // デフォルトは無効
         reminderDaysOfWeek: Set<Int> = [], // デフォルトは空のセット
         goalType: GoalType = .none, // デフォルトは目標なし
         targetValue: Double? = nil, // デフォルトはnil
         unit: String? = nil, // デフォルトはnil
         iconName: String? = nil, // 新しい引数: デフォルトはnil
         customColorHex: String? = nil // 新しい引数: デフォルトはnil
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.repeatSchedule = repeatSchedule
        self.completionDates = completionDates
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.reminderDaysOfWeek = reminderDaysOfWeek
        self.goalType = goalType
        self.targetValue = targetValue
        self.unit = unit
        self.iconName = iconName
        self.customColorHex = customColorHex
    }

    // 特定の日付で達成されたかどうかをチェックするヘルパープロパティ
    func isCompleted(on date: Date) -> Bool {
        // 日付の比較は、日付コンポーネントのみを比較するようにする
        // 時刻を無視して日付だけを比較するためにCalendarを使用
        Calendar.current.isDate(date, containedIn: completionDates)
    }

    // MARK: - 連続達成日数を計算するプロパティ
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date() // 今日から開始

        // 今日が達成済みでなければ、ストリークは0
        guard isCompleted(on: currentDate) else { return 0 }
        
        // 今日が達成済みなので、まず1日としてカウント
        streak = 1

        // 昨日から遡って達成状況を確認
        while let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
            // その日が習慣の対象日で、かつ達成済みであればストリークを増やす
            if repeatSchedule.isDue(on: previousDay) && isCompleted(on: previousDay) {
                streak += 1
                currentDate = previousDay // 日付を遡る
            } else if repeatSchedule.isDue(on: previousDay) && !isCompleted(on: previousDay) {
                // 対象日だが未達成ならストリークは途切れる
                break
            } else {
                // 対象日ではない場合、ストリークは途切れないがカウントも増えない
                currentDate = previousDay // 日付を遡る
            }
        }
        return streak
    }


    // MARK: - 繰り返しスケジュールを定義するEnum

    enum RepeatSchedule: String, Codable, CaseIterable {
        case daily = "毎日"
        case weekdays = "平日" // 月〜金
        case weekends = "週末" // 土日
        case weekly = "毎週" // 任意の曜日を選択（別途設定が必要になるが、ここではシンプルに）
    }

    // MARK: - 目標のタイプを定義するEnumを追加
    enum GoalType: String, Codable, CaseIterable, Identifiable {
        case none = "目標なし"
        case count = "回数"
        case duration = "時間"

        var id: String { self.rawValue } // Identifiableに準拠
    }
}

// MARK: - RepeatScheduleの拡張 (繰り返し頻度に応じた表示ロジック)
extension Habit.RepeatSchedule {
    func isDue(on date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 日曜が1、土曜が7

        switch self {
        case .daily:
            return true // 毎日
        case .weekdays:
            // 平日 (月曜=2, 火曜=3, 水曜=4, 木曜=5, 金曜=6)
            return weekday >= 2 && weekday <= 6
        case .weekends:
            // 週末 (土曜=7, 日曜=1)
            return weekday == 1 || weekday == 7
        case .weekly:
            // 週次（現時点では全てtrueにしているが、将来的には特定の曜日選択に対応）
            return true
        }
    }
}

// MARK: - Dateの拡張：特定の日付が他の日付の配列に含まれているかを確認
// 時刻を考慮せずに日付のみを比較するためのヘルパー
extension Calendar {
    func isDate(_ date: Date, containedIn dates: [Date]) -> Bool {
        dates.contains { self.isDate($0, inSameDayAs: date) }
    }
}

// MARK: - Stringの拡張：HexカラーコードからColorを生成するヘルパー
extension String {
    func toColor() -> Color? {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}

// MARK: - Colorの拡張：ColorをHex文字列に変換するヘルパー (AddHabitViewから移動)
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = components.count >= 4 ? Float(components[3]) : 1.0 // Alpha
        
        // Convert to 0-255 range
        let r255 = Int(r * 255.0)
        let g255 = Int(g * 255.0)
        let b255 = Int(b * 255.0)
        
        // Format as hex string
        return String(format: "#%02X%02X%02X", r255, g255, b255)
    }
}

// MARK: - DayOfWeekButton: 曜日選択ボタンのカスタムビュー (AddHabitViewから移動)
struct DayOfWeekButton: View {
    let weekday: Int // 1 (日曜) ... 7 (土曜)
    let isSelected: Bool
    let action: (Int) -> Void

    private var daySymbol: String {
        let calendar = Calendar.current
        return calendar.veryShortWeekdaySymbols[weekday - 1] // 日曜が0番目
    }

    var body: some View {
        Button(action: {
            action(weekday)
        }) {
            Text(daySymbol)
                .font(.caption)
                .frame(width: 28, height: 28)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}
