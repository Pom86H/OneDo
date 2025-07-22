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

    // MARK: - 編集中の習慣を保持するState変数とシート表示フラグ
    @State private var selectedHabitForEdit: Habit? = nil
    @State private var showingEditHabitSheet = false

    // MARK: - グラフ表示用のState変数とシート表示フラグ
    @State private var selectedHabitForGraph: Habit? = nil
    @State private var showingProgressGraphSheet = false

    // MARK: - ソートオプション用のState変数
    @State private var selectedSortOption: SortOption = .nameAscending

    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "名前順 (昇順)"
        case nameDescending = "名前順 (降順)"
        case creationDateAscending = "作成日順 (古い順)"
        case creationDateDescending = "作成日順 (新しい順)"

        var id: String { self.rawValue }
    }

    // MARK: - フィルタリングオプション用のState変数
    @State private var selectedFilterOption: FilterOption = .all

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "すべて"
        case completed = "完了済み"
        case incomplete = "未完了"

        var id: String { self.rawValue }
    }

    // MARK: - Listの編集モードを制御するState変数
    @Environment(\.editMode) var editMode


    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // 全体のVStackのスペーシングを0に
                // MARK: - 月選択UI
                HStack {
                    Button(action: {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2) // 少し小さく
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    Text(currentMonth, formatter: monthFormatter)
                        .font(.title) // 少し大きく
                        .fontWeight(.bold)
                        .onTapGesture {
                            currentMonth = Date()
                            selectedDate = Date()
                        }

                    Spacer()

                    Button(action: {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2) // 少し小さく
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10) // 縦のパディングを増やす
                .background(Color(.systemBackground)) // 背景色をシステム背景色に

                // MARK: - CalendarViewを埋め込む
                CalendarView(month: currentMonth, habits: habits, selectedDate: $selectedDate)
                    .padding(.bottom, 10)

                // MARK: - フィルタリングオプションのPicker
                Picker("表示", selection: $selectedFilterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented) // セグメントピッカーで表示
                .padding(.horizontal)
                .padding(.bottom, 10) // パディングを調整

                List {
                    // Today's Habits セクション
                    Section { // ヘッダーは別に定義するため、Sectionの引数を削除
                        // フィルタリングとソートを適用した習慣リスト
                        let processedHabitsIndices = habits.indices
                            .filter { index in
                                let habit = habits[index]
                                // 繰り返しスケジュールとフィルタリングオプションの両方を考慮
                                let isDueToday = habit.repeatSchedule.isDue(on: selectedDate)
                                
                                switch selectedFilterOption {
                                case .all:
                                    return isDueToday
                                case .completed:
                                    return isDueToday && habit.isCompleted(on: selectedDate)
                                case .incomplete:
                                    return isDueToday && !habit.isCompleted(on: selectedDate)
                                }
                            }
                            .sorted { (index1, index2) -> Bool in
                                let habit1 = habits[index1]
                                let habit2 = habits[index2]
                                switch selectedSortOption {
                                case .nameAscending:
                                    return habit1.name < habit2.name
                                case .nameDescending:
                                    return habit1.name > habit2.name
                                case .creationDateAscending:
                                    return habit1.id.uuidString < habit2.id.uuidString
                                case .creationDateDescending:
                                    return habit1.id.uuidString > habit2.id.uuidString
                                }
                            }

                        if processedHabitsIndices.isEmpty {
                            Text("今日の習慣はありません。\n新しい習慣を追加してみましょう！")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20) // 縦のパディングを追加
                                .frame(maxWidth: .infinity) // 中央寄せのために幅を最大に
                        } else {
                            ForEach(processedHabitsIndices, id: \.self) { index in
                                let habitBinding = $habits[index]
                                let habit = habitBinding.wrappedValue

                                HStack {
                                    // 習慣名とストリーク表示をVStackで縦に並べる
                                    VStack(alignment: .leading) {
                                        Text(habit.name)
                                            .font(.body) // フォントサイズを明示
                                            .strikethrough(habit.isCompleted(on: selectedDate), color: .secondary)
                                        Text("連続 \(habit.currentStreak) 日")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // MARK: - 進捗グラフ表示ボタン
                                    if habit.goalType != .none {
                                        Button(action: {
                                            selectedHabitForGraph = habit
                                            showingProgressGraphSheet = true
                                        }) {
                                            Image(systemName: "chart.bar.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }

                                    // MARK: - 右側のチェックマークボタン
                                    Button(action: {
                                        toggleCompletion(for: habit, date: selectedDate)
                                    }) {
                                        Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(habit.isCompleted(on: selectedDate) ? .green : .gray)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 8) // 各行の縦パディングを調整
                                .opacity(habit.isCompleted(on: selectedDate) ? 0.6 : 1.0)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if let originalIndex = habits.firstIndex(where: { $0.id == habit.id }) {
                                            deleteHabit(at: IndexSet(integer: originalIndex))
                                        }
                                    } label: {
                                        Label("削除", systemImage: "trash.fill")
                                    }
                                }
                                .onTapGesture {
                                    selectedHabitForEdit = habit
                                    showingEditHabitSheet = true
                                }
                            }
                            // MARK: - 並べ替え機能 (onMoveはフィルタリングされたリストでは複雑になるため、今回はソート機能で対応)
                            // onMoveはフィルタリングされたリストのインデックスを元のリストのインデックスに変換
                            .onMove { source, destination in
                                var movedHabits: [Habit] = []
                                for offset in source {
                                    movedHabits.append(habits[processedHabitsIndices[offset]])
                                }
                                
                                var newHabits = habits
                                for offset in source.sorted().reversed() { // 逆順に削除しないとインデックスがずれる
                                    newHabits.remove(at: processedHabitsIndices[offset])
                                }
                                
                                let actualDestinationIndex: Int
                                if destination < processedHabitsIndices.count {
                                    actualDestinationIndex = processedHabitsIndices[destination]
                                } else {
                                    actualDestinationIndex = newHabits.count
                                }
                                
                                newHabits.insert(contentsOf: movedHabits, at: actualDestinationIndex)
                                
                                habits = newHabits
                                saveHabits()
                            }
                        }
                    } header: { // Sectionのヘッダーを明示的に定義
                        Text("今日の習慣")
                            .font(.headline) // ヘッダーのフォントを調整
                            .foregroundColor(.primary)
                            .padding(.vertical, 5)
                            .padding(.leading, -15) // リストのデフォルトパディングを打ち消す
                    }
                }
                .navigationTitle("OneDo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // MARK: - ソートオプションのメニュー
                        Menu {
                            Picker("並べ替え", selection: $selectedSortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill") // ソートアイコン
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddHabitSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2) // 少し小さく
                                .foregroundColor(.accentColor)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        // MARK: - EditButtonを日本語化されたカスタムボタンに置き換え
                        Button(action: {
                            // editModeの状態を切り替える
                            editMode?.wrappedValue = (editMode?.wrappedValue == .active) ? .inactive : .active
                        }) {
                            Text(editMode?.wrappedValue == .active ? "完了" : "編集")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .sheet(isPresented: $showingAddHabitSheet) {
                    AddHabitView { newHabitName, repeatSchedule, reminderEnabled, reminderTime, reminderDaysOfWeek, goalType, targetValue, unit in
                        let newHabit = Habit(
                            name: newHabitName,
                            isCompleted: false,
                            repeatSchedule: repeatSchedule,
                            reminderTime: reminderTime,
                            reminderEnabled: reminderEnabled,
                            reminderDaysOfWeek: reminderDaysOfWeek,
                            goalType: goalType,
                            targetValue: targetValue,
                            unit: unit
                        )
                        habits.append(newHabit)
                        saveHabits()
                        scheduleNotifications()
                    }
                }
                .sheet(item: $selectedHabitForEdit) { habitToEdit in
                    if let index = habits.firstIndex(where: { $0.id == habitToEdit.id }) {
                        EditHabitView(habit: $habits[index]) {
                            saveHabits()
                            scheduleNotifications()
                        }
                    }
                }
                .sheet(item: $selectedHabitForGraph) { habitForGraph in
                    ProgressGraphView(habit: habitForGraph)
                }
                .onAppear(perform: {
                    loadHabits()
                    requestNotificationAuthorization()
                })
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)) // 全体の背景色
        }
    }

    // MARK: - DateFormatter for month display
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
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
        for index in offsets {
            cancelNotification(for: habits[index])
        }
        habits.remove(atOffsets: offsets)
        saveHabits()
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
            saveHabits()
            print("\(habit.name) の達成状況が \(updatedHabit.isCompleted(on: date) ? "達成" : "未達成") に変更されました (日付: \(date))")
            
            scheduleNotifications()
        }
    }

    // MARK: - 通知関連メソッド

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知許可が与えられました。")
                scheduleNotifications()
            } else if let error = error {
                print("通知許可エラー: \(error.localizedDescription)")
            } else {
                print("通知許可が拒否されました。")
            }
        }
    }

    private func scheduleNotifications() {
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
                let weekdaysForReminder: [Int]
                switch habit.repeatSchedule {
                case .daily:
                    weekdaysForReminder = []
                case .weekdays:
                    weekdaysForReminder = [2, 3, 4, 5, 6]
                case .weekends:
                    weekdaysForReminder = [1, 7]
                case .weekly:
                    weekdaysForReminder = Array(habit.reminderDaysOfWeek)
                }

                for weekday in weekdaysForReminder {
                    dateComponents.weekday = weekday
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let identifier = "\(habit.id.uuidString)-\(weekday)"
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
    
    private func cancelNotification(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
        print("通知をキャンセルしました: \(habit.name)")
    }
}
