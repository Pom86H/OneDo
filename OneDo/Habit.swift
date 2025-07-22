import Foundation

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

    // イニシャライザ。idのデフォルト値はUUID()にする
    init(id: UUID = UUID(), name: String, isCompleted: Bool,
         repeatSchedule: RepeatSchedule = .daily,
         completionDates: [Date] = [],
         reminderTime: Date? = nil, // デフォルトはnil (設定なし)
         reminderEnabled: Bool = false, // デフォルトは無効
         reminderDaysOfWeek: Set<Int> = [] // デフォルトは空のセット
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.repeatSchedule = repeatSchedule
        self.completionDates = completionDates
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.reminderDaysOfWeek = reminderDaysOfWeek
    }

    // 特定の日付で達成されたかどうかをチェックするヘルパープロパティ
    func isCompleted(on date: Date) -> Bool {
        // 日付の比較は、日付コンポーネントのみを比較するようにする
        // 時刻を無視して日付だけを比較するためにCalendarを使用
        Calendar.current.isDate(date, containedIn: completionDates)
    }

    // MARK: - 連続達成日数を計算するプロパティを追加
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
}

// MARK: - RepeatScheduleの拡張 (繰り返し頻度に応じた表示ロジック)
// この拡張がHabit.swiftに存在することを確認してください
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
