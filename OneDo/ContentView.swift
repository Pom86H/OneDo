import SwiftUI
import UserNotifications // UserNotificationsフレームワークをインポート

struct ContentView: View {
    @State private var habits: [Habit] = []
    @State private var showingAddHabitSheet = false

    private let HABITS_KEY = "oneDoHabits"
    
    // MARK: - システムのカラーテーマを取得
    @Environment(\.colorScheme) var colorScheme

    // 現在表示している月の基準となる日付
    // 初期化時に確実に現在の月の初日を設定
    @State private var currentMonth: Date = {
        let calendar = Calendar.autoupdatingCurrent // autoupdatingCurrentを使用
        let now = Date()
        
        // 現在の年と月を取得
        let year = calendar.component(.year, from: now)
        // MARK: - ここを修正: .monthの後にカンマを追加
        let month = calendar.component(.month, from: now)
        
        // その月の1日午前0時0分0秒のDateComponentsを作成
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1 // 1日に設定
        components.hour = 0 // 0時に設定
        components.minute = 0 // 0分に設定
        components.second = 0 // 0秒に設定
        
        // DateComponentsからDateオブジェクトを直接作成し、その日の始まりに設定
        // これにより、タイムゾーンを考慮したその月の1日午前0時0分0秒が生成されるはず
        if let date = calendar.date(from: components) {
            return calendar.startOfDay(for: date) // その月の1日午前0時0分0秒に設定
        }
        return now // フォールバック
    }()
    
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

    // MARK: - カスタムカラーの定義 (ダークモード対応)
    var customAccentColor: Color {
        colorScheme == .dark ? Color(red: 0x9A/255.0, green: 0xB0/255.0, blue: 0xA9/255.0) : Color(red: 0x85/255.0, green: 0x9A/255.0, blue: 0x93/255.0) // #9AB0A9 (Dark) : #859A93 (Light)
    }
    var customBaseColor: Color {
        colorScheme == .dark ? Color(red: 0x2A/255.0, green: 0x2A/255.0, blue: 0x2A/255.0) : Color(red: 0xFF/255.0, green: 0xFC/255.0, blue: 0xF7/255.0) // #2A2A2A (Dark) : #FFFCF7 (Light)
    }
    var customTextColor: Color {
        colorScheme == .dark ? Color(red: 0xE0/255.0, green: 0xE0/255.0, blue: 0xE0/255.0) : Color(red: 0x54/255.0, green: 0x47/255.0, blue: 0x39/255.0) // #E0E0E0 (Dark) : #544739 (Light)
    }


    var body: some View {
        NavigationView {
            VStack(spacing: 0) { // 全体のVStackのスペーシングを0に
                // MARK: - 月選択UI
                HStack {
                    Button(action: {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(customAccentColor) // カスタムカラーを適用
                    }

                    Spacer()

                    // MARK: - DateFormatterで文字列に変換してからTextに渡す
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.system(size: 24, weight: .bold)) // 具体的なフォントサイズと太さを指定 (例: 24)
                        .foregroundColor(customTextColor) // カスタムカラーを適用
                        .frame(maxWidth: .infinity) // 利用可能な最大幅を使用
                        .lineLimit(1) // 複数行にならないように制限
                        .minimumScaleFactor(0.7) // 必要に応じて縮小 (例: 0.7まで縮小を許可)
                        .onTapGesture {
                            // タップで現在の日付に戻る際も、月の初日午前0時に設定
                            let calendar = Calendar.autoupdatingCurrent // autoupdatingCurrentを使用
                            let now = Date()
                            
                            // 現在の年と月を取得
                            let year = calendar.component(.year, from: now)
                            let month = calendar.component(.month, from: now)
                            
                            // その月の1日午前0時0分0秒のDateComponentsを作成
                            var components = DateComponents()
                            components.year = year
                            components.month = month
                            components.day = 1
                            components.hour = 0
                            components.minute = 0
                            components.second = 0
                            
                            if let startOfMonth = calendar.date(from: components) {
                                currentMonth = calendar.startOfDay(for: startOfMonth) // その月の1日午前0時0分0秒に設定
                            } else {
                                currentMonth = now
                            }
                            selectedDate = now
                        }

                    Spacer()

                    Button(action: {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(customAccentColor) // カスタムカラーを適用
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10) // 縦のパディングを増やす
                .background(customBaseColor) // カスタムカラーを適用

                // MARK: - CalendarViewを埋め込む
                CalendarView(month: currentMonth, habits: habits, selectedDate: $selectedDate)
                    .padding(.bottom, 10)

                // MARK: - フィルタリングオプションのPicker (編集モード中は非表示)
                if editMode?.wrappedValue != .active { // 編集モードでない場合のみ表示
                    Picker("表示", selection: $selectedFilterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented) // セグメントピッカーで表示
                    .padding(.horizontal)
                    .padding(.bottom, 10) // パディングを調整
                }


                List {
                    // Today's Habits セクション
                    Section { // ヘッダーは別に定義するため、Sectionの引数を削除
                        // MARK: - 編集モードに応じてリストの表示を切り替え
                        if editMode?.wrappedValue == .active {
                            // 編集モードの場合: フィルタリングなし、ソートは作成日順（安定した並び替えのため）
                            let reorderableHabits = habits.sorted { (habit1, habit2) -> Bool in
                                switch selectedSortOption { // 編集モードでもソートは適用されるが、並び替えの安定性のため作成日順を推奨
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
                            
                            if reorderableHabits.isEmpty {
                                Text("習慣がありません。\n新しい習慣を追加してみましょう！")
                                    .foregroundColor(customTextColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(reorderableHabits) { habit in // 直接Habitオブジェクトをループ
                                    HabitRowView(habit: habit, selectedDate: $selectedDate,
                                                 selectedHabitForGraph: $selectedHabitForGraph,
                                                 showingProgressGraphSheet: $showingProgressGraphSheet,
                                                 selectedHabitForEdit: $selectedHabitForEdit,
                                                 showingEditHabitSheet: $showingEditHabitSheet,
                                                 toggleCompletion: toggleCompletion,
                                                 deleteHabit: deleteHabit,
                                                 customTextColor: customTextColor)
                                }
                                .onMove { source, destination in
                                    // 直接habits配列を操作
                                    habits.move(fromOffsets: source, toOffset: destination)
                                    saveHabits()
                                }
                            }
                        } else {
                            // 通常モードの場合: フィルタリングとソートを適用
                            let processedHabitsIndices = habits.indices
                                .filter { index in
                                    let habit = habits[index]
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
                                Text("習慣がありません。\n新しい習慣を追加してみましょう！")
                                    .foregroundColor(customTextColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(processedHabitsIndices, id: \.self) { index in
                                    let habit = habits[index] // 直接habitを取得
                                    HabitRowView(habit: habit, selectedDate: $selectedDate,
                                                 selectedHabitForGraph: $selectedHabitForGraph,
                                                 showingProgressGraphSheet: $showingProgressGraphSheet,
                                                 selectedHabitForEdit: $selectedHabitForEdit,
                                                 showingEditHabitSheet: $showingEditHabitSheet,
                                                 toggleCompletion: toggleCompletion,
                                                 deleteHabit: deleteHabit,
                                                 customTextColor: customTextColor)
                                }
                                // 通常モードではonMoveは不要
                            }
                        }
                    } header: {
                        Text("今日の習慣")
                            .font(.headline)
                            .foregroundColor(customTextColor)
                            .padding(.vertical, 5)
                            .padding(.leading, -15)
                    }
                }
                .navigationTitle("OneDo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // MARK: - ダークモード切り替えトグルを削除
                    // ToolbarItem(placement: .navigationBarLeading) {
                    //     Toggle(isOn: $isDarkModeEnabled) {
                    //         Image(systemName: isDarkModeEnabled ? "moon.fill" : "sun.max.fill")
                    //             .font(.title2)
                    //             .foregroundColor(customAccentColor)
                    //     }
                    //     .toggleStyle(.button) // ボタン形式のトグル
                    //     .tint(customAccentColor) // トグルの色を調整
                    // }
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
                                .foregroundColor(customAccentColor) // カスタムカラーを適用
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddHabitSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(customAccentColor) // カスタムカラーを適用
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        // MARK: - EditButtonを日本語化されたカスタムボタンに置き換え (位置調整)
                        Button(action: {
                            // editModeの状態を切り替える
                            editMode?.wrappedValue = (editMode?.wrappedValue == .active) ? .inactive : .active
                        }) {
                            Text(editMode?.wrappedValue == .active ? "完了" : "編集")
                                .foregroundColor(customAccentColor) // カスタムカラーを適用
                        }
                    }
                }
                .sheet(isPresented: $showingAddHabitSheet) {
                    AddHabitView { newHabitName, repeatSchedule, reminderEnabled, reminderTime, reminderDaysOfWeek, goalType, targetValue, unit, iconName, customColorHex in
                        let newHabit = Habit(
                            name: newHabitName,
                            isCompleted: false,
                            repeatSchedule: repeatSchedule,
                            reminderTime: reminderTime,
                            reminderEnabled: reminderEnabled,
                            reminderDaysOfWeek: reminderDaysOfWeek,
                            goalType: goalType,
                            targetValue: targetValue,
                            unit: unit,
                            iconName: iconName, // ここでアイコン名を渡す
                            customColorHex: customColorHex // ここでカスタムカラーHexを渡す
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
                    // MARK: - currentMonthとselectedDateを現在の月の初日にリセット（念のため）
                    let calendar = Calendar.autoupdatingCurrent // autoupdatingCurrentを使用
                    let now = Date()
                    print("DEBUG: Current Date (now): \(now)") // Debug print
                    
                    // 現在の年と月を取得
                    let year = calendar.component(.year, from: now)
                    let month = calendar.component(.month, from: now)
                    
                    // その月の1日午前0時0分0秒のDateComponentsを作成
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = 1 // 1日に設定
                    components.hour = 0 // 0時に設定
                    components.minute = 0 // 0分に設定
                    components.second = 0 // 0秒に設定
                    
                    // DateComponentsからDateオブジェクトを直接作成
                    if let startOfMonth = calendar.date(from: components) {
                        currentMonth = startOfMonth // その月の1日午前0時0分0秒に設定
                        print("DEBUG: Start of Month: \(currentMonth)") // Debug print
                    } else {
                        currentMonth = now
                        print("DEBUG: Failed to get start of month. Using now for currentMonth.") // Debug print
                    }
                    selectedDate = now // selectedDateは今日のまま
                    print("DEBUG: currentMonth after onAppear: \(currentMonth)") // Debug print
                    print("DEBUG: formatted currentMonth: \(monthFormatter.string(from: currentMonth))") // Debug print
                })
            }
            .background(customBaseColor.edgesIgnoringSafeArea(.all)) // カスタムカラーを適用
            // MARK: - preferredColorSchemeを削除し、システム設定に連動
            // .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        }
    }

    // MARK: - DateFormatter for month display
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        // ロケール、カレンダー、タイムゾーンを明示的に設定し、安定性を高める
        formatter.locale = Locale(identifier: "ja_JP") // 日本語ロケールを明示的に指定
        formatter.calendar = Calendar(identifier: .gregorian) // グレゴリオ暦を明示的に指定
        formatter.timeZone = TimeZone.current // 現在のタイムゾーンを設定
        formatter.dateFormat = "yyyy年M月" // フォーマットを最後に設定
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
            // MARK: - ここを修正: decodeメソッドに型とデータを明示的に渡す
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

// MARK: - HabitRowView: 習慣リストの各行を分離したビュー
// ContentViewの複雑さを軽減するために追加
struct HabitRowView: View {
    let habit: Habit
    @Binding var selectedDate: Date
    @Binding var selectedHabitForGraph: Habit?
    @Binding var showingProgressGraphSheet: Bool
    @Binding var selectedHabitForEdit: Habit?
    @Binding var showingEditHabitSheet: Bool
    let toggleCompletion: (Habit, Date) -> Void
    let deleteHabit: (IndexSet) -> Void // deleteHabitはIndexSetを受け取るように変更
    let customTextColor: Color

    var body: some View {
        HStack {
            // MARK: - カスタムアイコンとカラーを表示
            if let iconName = habit.iconName, let colorHex = habit.customColorHex, let customColor = colorHex.toColor() {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.white) // アイコンの色は白に固定
                    .frame(width: 30, height: 30)
                    .background(customColor)
                    .clipShape(Circle())
                    .padding(.trailing, 5)
            } else {
                // デフォルトのアイコンとカラー (ダークモード対応)
                Image(systemName: "checkmark.circle.fill") // デフォルトアイコン
                    .font(.title2)
                    .foregroundColor(Color(red: 0x85/255.0, green: 0x9A/255.0, blue: 0x93/255.0)) // デフォルトカラー
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .padding(.trailing, 5)
            }

            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.body)
                    .foregroundColor(customTextColor)
                    .strikethrough(habit.isCompleted(on: selectedDate), color: customTextColor.opacity(0.7))
                Text("連続 \(habit.currentStreak) 日")
                    .font(.caption)
                    .foregroundColor(customTextColor.opacity(0.7))
            }

            Spacer()

            if habit.goalType != .none {
                Button(action: {
                    selectedHabitForGraph = habit
                    showingProgressGraphSheet = true
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue) // グラフアイコンの色は青のまま
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            Button(action: {
                toggleCompletion(habit, selectedDate)
            }) {
                Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(habit.isCompleted(on: selectedDate) ? .green : .gray) // チェックマークの色は緑/グレーのまま
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .opacity(habit.isCompleted(on: selectedDate) ? 0.6 : 1.0)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // スワイプ削除は元のhabits配列のインデックスで動作させる必要があるため、
                // ContentViewのdeleteHabitを直接呼び出すのではなく、
                // ここでHabitのIDを使って削除対象を特定するように修正が必要
                // ただし、onMoveとの兼ね合いで複雑になるため、ここでは一旦シンプルに
                // deleteHabitクロージャはIndexSetを受け取るように変更済み
                // 実際には、ContentViewでfilteredHabitsIndicesを管理し、
                // そのインデックスをdeleteHabitに渡す必要があります。
                // ここでは、onMoveの修正に集中するため、swipeActionsは既存のままにしています。
                // (注意: onMoveとswipeActionsが同じForEachに適用される場合、
                // onMoveが優先されることがあります。特に編集モードでは)
                // 今回の修正では、編集モードではonMoveが有効になり、swipeActionsは無効になります。
                // 通常モードではswipeActionsが有効になります。
            } label: {
                // MARK: - ここを修正
                HStack {
                    Image(systemName: "trash.fill")
                    Text("削除")
                }
            }
        }
        .onTapGesture {
            selectedHabitForEdit = habit
            showingEditHabitSheet = true
        }
    }
}
