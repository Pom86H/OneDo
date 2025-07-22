import SwiftUI
import UserNotifications // UserNotificationsフレームワークをインポート

struct ContentView: View {
    @State private var habits: [Habit] = []
    @State private var showingAddHabitSheet = false

    private let HABITS_KEY = "oneDoHabits"
    
    // 現在表示している月の基準となる日付
    @State private var currentMonth: Date = Date()
    // 選択された日付 (カレンダービューとリストで共有)
    @State private var selectedDate: Date = Date()


    var body: some View {
        NavigationView {
            VStack {
                // MARK: - 月選択UI
                HStack {
                    // Buttonの構文を修正
                    Button(action: {
                        // 前月へ移動
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }) { // labelクロージャを直接続ける
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    // 表示中の月と年
                    Text(currentMonth, formatter: monthFormatter)
                        .font(.title2)
                        .fontWeight(.bold)
                        .onTapGesture {
                            // 月をタップしたら今月に戻る
                            currentMonth = Date()
                            selectedDate = Date() // 選択日も今日に戻す
                        }

                    Spacer()

                    // Buttonの構文を修正
                    Button(action: {
                        // 翌月へ移動
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }) { // labelクロージャを直接続ける
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(Color(.systemBackground))

                // MARK: - CalendarViewを埋め込む
                CalendarView(month: currentMonth, habits: habits, selectedDate: $selectedDate)
                    .padding(.bottom, 10) // カレンダーとリストの間に少しスペース

                List {
                    // Today's Habits セクション
                    Section("今日の習慣") {
                        // フィルタリングされた習慣リスト
                        let filteredHabits = habits.indices.filter { habits[$0].repeatSchedule.isDue(on: selectedDate) }

                        if filteredHabits.isEmpty {
                            // 習慣が一つもない場合のメッセージ
                            Text("今日の習慣はありません。\n新しい習慣を追加してみましょう！")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            // ForEachでインデックスを使い、フィルタリングされた要素にアクセス
                            ForEach(filteredHabits, id: \.self) { index in
                                // BindingとしてHabit要素にアクセス
                                let habitBinding = $habits[index]
                                // Habitの実際の値にアクセス
                                let habit = habitBinding.wrappedValue

                                HStack {
                                    // チェックボックスの代わりに、達成状況を示すアイコン
                                    Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(habit.isCompleted(on: selectedDate) ? .green : .gray)

                                    // 習慣名とストリーク表示をVStackで縦に並べる
                                    VStack(alignment: .leading) {
                                        Text(habit.name)
                                            // 達成済みなら取り消し線
                                            .strikethrough(habit.isCompleted(on: selectedDate), color: .secondary)
                                        // ストリーク表示
                                        Text("連続 \(habit.currentStreak) 日")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        toggleCompletion(for: habit, date: selectedDate)
                                    }) {
                                        Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(habit.isCompleted(on: selectedDate) ? .green : .gray)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 5)
                                // 達成済みなら透明度を少し下げる
                                .opacity(habit.isCompleted(on: selectedDate) ? 0.6 : 1.0)
                                // MARK: - スワイプ削除機能の再実装
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let originalIndex = habits.firstIndex(where: { $0.id == habit.id }) {
                                            deleteHabit(at: IndexSet(integer: originalIndex))
                                        }
                                    } label: {
                                        Label("削除", systemImage: "trash.fill")
                                    }
                                }
                            }
                            // MARK: - onDeleteについて (コメントアウトを解除し、swipeActionsに置き換え)
                            // .onDelete(perform: deleteHabit) // この行は削除またはコメントアウトのまま
                        }
                    }
                }
                .navigationTitle("OneDo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Buttonの構文を修正
                        Button(action: {
                            showingAddHabitSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton() // EditButtonはそのまま残します
                    }
                }
                .sheet(isPresented: $showingAddHabitSheet) {
                    AddHabitView { newHabitName, repeatSchedule, reminderEnabled, reminderTime, reminderDaysOfWeek in
                        let newHabit = Habit(
                            name: newHabitName,
                            isCompleted: false,
                            repeatSchedule: repeatSchedule,
                            reminderTime: reminderTime, // 新しい引数を渡す
                            reminderEnabled: reminderEnabled, // 新しい引数を渡す
                            reminderDaysOfWeek: reminderDaysOfWeek // 新しい引数を渡す
                        )
                        habits.append(newHabit)
                        saveHabits()
                        scheduleNotifications() // 新しい習慣が追加されたら通知をスケジュール
                    }
                }
                .onAppear(perform: {
                    loadHabits()
                    requestNotificationAuthorization() // アプリ起動時に通知許可を要求
                })
            }
        }
    }

    // MARK: - DateFormatter for month display
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月" // 例: 2023年7月
        return formatter
    }

    // MARK: - データ永続化メソッド

    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: HABITS_KEY)
            print("習慣データを保存しました: \(habits.count)件")
        } else {
            print("習慣データの保存に失敗しました。")
        }
    }

    private func loadHabits() {
        if let savedHabitsData = UserDefaults.standard.data(forKey: HABITS_KEY) {
            if let decodedHabits = try? JSONDecoder().decode([Habit].self, from: savedHabitsData) {
                habits = decodedHabits
                print("習慣データを読み込みました: \(habits.count)件")
            } else {
                print("習慣データのデコードに失敗しました。")
            }
        } else {
            print("保存された習慣データが見つかりませんでした。")
        }
    }

    // MARK: - タスク削除メソッド
    private func deleteHabit(at offsets: IndexSet) {
        // 削除する通知をキャンセル
        for index in offsets {
            cancelNotification(for: habits[index])
        }
        habits.remove(atOffsets: offsets)
        saveHabits() // 削除後もデータを保存
    }

    // MARK: - 習慣達成状況の切り替えメソッド

    private func toggleCompletion(for habit: Habit, date: Date) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]

            if updatedHabit.isCompleted(on: date) {
                updatedHabit.completionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
            } else {
                updatedHabit.completionDates.append(date)
            }
            
            habits[index] = updatedHabit
            saveHabits() // 変更を保存
            print("\(habit.name) の達成状況が \(updatedHabit.isCompleted(on: date) ? "達成" : "未達成") に変更されました (日付: \(date))")
            
            // 達成状況が変更されたら通知を再スケジュール（特に未達成に戻した場合など）
            scheduleNotifications()
        }
    }

    // MARK: - 通知関連メソッド

    // 通知許可を要求する
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が与えられました。")
                scheduleNotifications() // 許可されたら通知をスケジュール
            } else if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            } else {
                print("通知許可が拒否されました。")
            }
        }
    }

    // すべての習慣の通知をスケジュールする
    private func scheduleNotifications() {
        // 既存のOneDo関連通知をすべて削除
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("既存の通知リクエストをすべて削除しました。")

        for habit in habits {
            guard habit.reminderEnabled, let reminderTime = habit.reminderTime else { continue }

            let content = UNMutableNotificationContent()
            content.title = "OneDo"
            content.body = "\(habit.name) を行う時間です！"
            content.sound = .default

            let calendar = Calendar.current
            var dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

            // 毎日通知する場合
            if habit.repeatSchedule == .daily {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("通知のスケジュールに失敗しました: \(error.localizedDescription)")
                    } else {
                        print("通知をスケジュールしました: \(habit.name) (毎日)")
                    }
                }
            } else {
                // 特定の曜日で通知する場合 (例: weekdays, weekends, weekly)
                // 各曜日に対して通知をスケジュール
                let weekdaysForReminder: [Int]
                switch habit.repeatSchedule {
                case .daily:
                    weekdaysForReminder = [] // dailyは上記で処理済み
                case .weekdays:
                    weekdaysForReminder = [2, 3, 4, 5, 6] // 月〜金
                case .weekends:
                    weekdaysForReminder = [1, 7] // 日、土
                case .weekly:
                    // weeklyの場合は、reminderDaysOfWeekを使用
                    weekdaysForReminder = Array(habit.reminderDaysOfWeek)
                }

                for weekday in weekdaysForReminder {
                    dateComponents.weekday = weekday // 曜日を設定
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let identifier = "\(habit.id.uuidString)-\(weekday)" // 曜日ごとにユニークなID
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("通知のスケジュールに失敗しました: \(error.localizedDescription)")
                        } else {
                            print("通知をスケジュールしました: \(habit.name) (曜日: \(weekday))")
                        }
                    }
                }
            }
        }
    }
    
    // 特定の習慣の通知をキャンセルする
    private func cancelNotification(for habit: Habit) {
        // 習慣IDに関連するすべての通知をキャンセル
        // 曜日ごとの通知IDも考慮して、プレフィックスでキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        // weeklyの場合の曜日ごとの通知もキャンセルできるように、より汎用的なアプローチが必要
        // 現状は、removeAllPendingNotificationRequests()で全て消すのが最も確実
        // または、通知IDを生成する際に、habit.id.uuidStringをプレフィックスとして使うと良い
        print("通知をキャンセルしました: \(habit.name)")
    }
}

// MARK: - Calendarの拡張 (Habit.swiftに移動済みなので、ContentViewからは削除済み)
// #Preview {
//     ContentView()
// }
