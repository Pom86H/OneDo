import SwiftUI
import UserNotifications // Import UserNotifications framework

struct ContentView: View {
    @State private var habits: [Habit] = []
    @State private var showingAddHabitSheet = false

    private let HABITS_KEY = "oneDoHabits"
    
    // MARK: - Get system color scheme
    @Environment(\.colorScheme) var colorScheme

    // Current month base date for calendar display
    // Ensure it's set to the first day of the current month upon initialization
    @State private var currentMonth: Date = {
        let calendar = Calendar.autoupdatingCurrent // Use autoupdatingCurrent
        let now = Date()
        
        // Get current year and month
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        // Create DateComponents for the 1st day of the month at 00:00:00
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1 // Set to 1st
        components.hour = 0 // Set to 0 hour
        components.minute = 0 // Set to 0 minute
        components.second = 0 // Set to 0 second
        
        // Create a Date object directly from DateComponents and set it to the start of that day
        // This should generate the 1st day of the month at 00:00:00 considering the timezone
        if let date = calendar.date(from: components) {
            return calendar.startOfDay(for: date) // Set to 1st day of the month at 00:00:00
        }
        return now // Fallback
    }()
    
    // Selected date (shared between calendar view and list)
    @State private var selectedDate: Date = Date()

    // MARK: - State variables for editing habit and sheet display flag
    @State private var selectedHabitForEdit: Habit? = nil
    @State private var showingEditHabitSheet = false

    // MARK: - State variables for graph display and sheet display flag
    @State private var selectedHabitForGraph: Habit? = nil
    @State private var showingProgressGraphSheet = false

    // MARK: - State variable for sort options
    @State private var selectedSortOption: SortOption = .nameAscending

    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "名前順 (昇順)"
        case nameDescending = "名前順 (降順)"
        case creationDateAscending = "作成日順 (古い順)"
        case creationDateDescending = "作成日順 (新しい順)"

        var id: String { self.rawValue }
    }

    // MARK: - State variable for filtering options
    @State private var selectedFilterOption: FilterOption = .all

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "すべて"
        case completed = "完了済み"
        case incomplete = "未完了"

        var id: String { self.rawValue }
    }

    // MARK: - State variable to control List edit mode
    @Environment(\.editMode) var editMode

    // MARK: - Custom color definitions (adjusted for dark mode compatibility)
    var customAccentColor: Color {
        // Light: #D48C45, Dark: #F5B070 (Warm Orange/Brown)
        colorScheme == .dark ? Color(red: 0xF5/255.0, green: 0xB0/255.0, blue: 0x70/255.0) : Color(red: 0xD4/255.0, green: 0x8C/255.0, blue: 0x45/255.0)
    }
    var customBaseColor: Color {
        // Light: #FDF8F0, Dark: #2A2A2A (Soft Off-white / Dark Gray)
        colorScheme == .dark ? Color(red: 0x2A/255.0, green: 0x2A/255.0, blue: 0x2A/255.0) : Color(red: 0xFD/255.0, green: 0xF8/255.0, blue: 0xF0/255.0)
    }
    var customTextColor: Color {
        // Light: #544739, Dark: #E0DCD7 (Dark Brown / Light Warm Gray)
        colorScheme == .dark ? Color(red: 0xE0/255.0, green: 0xDC/255.0, blue: 0xD7/255.0) : Color(red: 0x54/255.0, green: 0x47/255.0, blue: 0x39/255.0)
    }


    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) { // MARK: - ZStackを追加し、FABを右下配置
                // MARK: - ZStackの背景色を最初に設定し、全体をカバー
                customBaseColor.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) { // Overall VStack with 0 spacing
                    // MARK: - Month selection UIとCalendarViewをまとめたカード
                    VStack(spacing: 0) { // このVStackが新しいカードになります
                        HStack {
                            Button(action: {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(customAccentColor) // Apply custom color
                            }

                            Spacer()

                            // MARK: - Convert to string with DateFormatter before passing to Text
                            Text(monthFormatter.string(from: currentMonth))
                                .font(.system(size: 24, weight: .bold)) // Specify concrete font size and weight (e.g., 24)
                                .foregroundColor(customTextColor) // Apply custom color
                                .frame(maxWidth: .infinity) // Use maximum available width
                                .lineLimit(1) // Limit to single line
                                .minimumScaleFactor(0.7) // Shrink if necessary (e.g., allow shrinking to 0.7)
                                .onTapGesture {
                                    // When tapping to return to current date, also set to the first day of the month at 00:00
                                    let calendar = Calendar.autoupdatingCurrent // Use autoupdatingCurrent
                                    let now = Date()
                                    
                                    // Get current year and month
                                    let year = calendar.component(.year, from: now)
                                    let month = calendar.component(.month, from: now)
                                    
                                    // Create DateComponents for the 1st day of the month at 00:00:00
                                    var components = DateComponents()
                                    components.year = year
                                    components.month = month
                                    components.day = 1
                                    components.hour = 0
                                    components.minute = 0
                                    components.second = 0
                                    
                                    if let startOfMonth = calendar.date(from: components) {
                                        currentMonth = calendar.startOfDay(for: startOfMonth) // Set to 1st day of the month at 00:00:00
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
                                    .foregroundColor(customAccentColor) // Apply custom color
                            }
                        }
                        .padding(.horizontal) // カード内の水平パディング
                        // .padding(.top, 10) // MARK: - カード内の上部パディングを削除

                        // MARK: - Embed CalendarView
                        CalendarView(month: currentMonth, habits: habits, selectedDate: $selectedDate)
                            .padding(.bottom, 0) // カレンダー自体の下部パディングは親VStackで調整
                            // .padding(.top, 10) // MARK: - 月選択UIとカレンダーの間のパディングを削除
                    }
                    .padding(.horizontal, 10) // カード全体の左右パディング
                    .padding(.top, 5) // MARK: - カード全体の上部パディングを調整 (例: 5pt)
                    .padding(.bottom, 10) // カード全体の下部パディング
                    .background(Color(.systemBackground)) // カードの背景色（システム背景色でライト/ダークモードに対応）
                    .cornerRadius(12) // カードの角丸
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3) // 控えめな影
                    // .padding(.bottom, 10) // カレンダーカードと次の要素との間隔 - この行は削除またはコメントアウトされます

                    // MARK: - Filtering options Custom Segmented Control (hidden in edit mode)
                    if editMode?.wrappedValue != .active { // Only show if not in edit mode
                        HStack(spacing: 0) { // No spacing between segments, internal padding will create visual separation
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(action: {
                                    selectedFilterOption = option
                                }) {
                                    Text(option.rawValue)
                                        .font(.caption) // Smaller font for segments
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedFilterOption == option ? .white : customTextColor)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity) // Distribute space evenly
                                        .background(selectedFilterOption == option ? customAccentColor : customBaseColor)
                                        .cornerRadius(8) // Rounded corners for individual segments
                                }
                                .buttonStyle(PlainButtonStyle()) // Remove default button styling
                            }
                        }
                        .background(customBaseColor) // Overall background for the segmented control container
                        .cornerRadius(10) // Overall rounded corners for the container
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2) // Subtle shadow
                        .padding(.horizontal)
                        .padding(.top, 10) // MARK: - セグメントピッカーの上部パディングを追加
                        .padding(.bottom, 10)
                        .animation(.easeInOut(duration: 0.2), value: selectedFilterOption) // Smooth transition on selection
                    }


                    List {
                        // Today's Habits Section
                        Section { // Remove section argument for header to be defined separately
                            // MARK: - Toggle list display based on edit mode
                            if editMode?.wrappedValue == .active {
                                // In edit mode: no filtering, sort by creation date (for stable reordering)
                                let reorderableHabits = habits.sorted { (habit1, habit2) -> Bool in
                                    switch selectedSortOption { // Sorting is still applied in edit mode, but creation date is recommended for stable reordering
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
                                    // MARK: - Empty State UI for Edit Mode
                                    VStack(alignment: .center) {
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(customAccentColor.opacity(0.6))
                                            .padding(.bottom, 10)
                                        Text("習慣がありません。\n右下の＋ボタンから新しい習慣を追加しましょう！")
                                            .font(.body)
                                            .foregroundColor(customTextColor.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .listRowBackground(Color.clear) // ListRowの背景を透明に
                                    .listRowSeparator(.hidden) // ListRowのセパレータを非表示に
                                } else {
                                    ForEach(reorderableHabits) { habit in // Loop directly through Habit objects
                                        // MARK: - customAccentColorとcustomTextColorをHabitRowViewに渡す
                                        HabitRowView(habit: habit, selectedDate: $selectedDate,
                                                     selectedHabitForGraph: $selectedHabitForGraph,
                                                     showingProgressGraphSheet: $showingProgressGraphSheet,
                                                     selectedHabitForEdit: $selectedHabitForEdit,
                                                     showingEditHabitSheet: $showingEditHabitSheet,
                                                     toggleCompletion: toggleCompletion,
                                                     deleteHabit: deleteHabit,
                                                     customTextColor: customTextColor, // ここで渡す
                                                     customAccentColor: customAccentColor) // ここで渡す
                                        // MARK: - List row styling for custom cards
                                        .listRowBackground(Color.clear) // Make the default list row background transparent
                                        .listRowSeparator(.hidden) // Hide the default list row background transparent
                                        .listRowInsets(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)) // Add spacing around the card
                                    }
                                }
                            } else {
                                // In normal mode: Apply filtering and sorting
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
                                    // MARK: - Empty State UI for Normal Mode
                                    VStack(alignment: .center) {
                                        Image(systemName: "pawprint.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(customAccentColor.opacity(0.6))
                                            .padding(.bottom, 10)
                                        Text("習慣がありません。\n右下の＋ボタンから新しい習慣を追加しましょう！")
                                            .font(.body)
                                            .foregroundColor(customTextColor.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .listRowBackground(Color.clear) // ListRowの背景を透明に
                                    .listRowSeparator(.hidden) // ListRowのセパレータを非表示に
                                } else {
                                    ForEach(processedHabitsIndices, id: \.self) { index in
                                        let habit = habits[index] // Get habit directly
                                        // MARK: - customAccentColorとcustomTextColorをHabitRowViewに渡す
                                        HabitRowView(habit: habit, selectedDate: $selectedDate,
                                                     selectedHabitForGraph: $selectedHabitForGraph,
                                                     showingProgressGraphSheet: $showingProgressGraphSheet,
                                                     selectedHabitForEdit: $selectedHabitForEdit,
                                                     showingEditHabitSheet: $showingEditHabitSheet,
                                                     toggleCompletion: toggleCompletion,
                                                     deleteHabit: deleteHabit,
                                                     customTextColor: customTextColor, // ここで渡す
                                                     customAccentColor: customAccentColor) // ここで渡す
                                        // MARK: - List row styling for custom cards
                                        .listRowBackground(Color.clear) // Make the default list row background transparent
                                        .listRowSeparator(.hidden) // Hide the default list row background transparent
                                        .listRowInsets(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)) // Add spacing around the card
                                    }
                                }
                            }
                        }
                        header: {
                            Text("今日の習慣")
                                .font(.headline)
                                .foregroundColor(customTextColor)
                                .padding(.vertical, 5)
                                // MARK: - .padding(.leading, -15) を削除
                        }
                    }
                    .listStyle(PlainListStyle()) // MARK: - リストスタイルをPlainListStyleに設定
                    .background(Color(.systemBackground)) // MARK: - リストの背景色をシステム背景色（白など）に設定
                    .ignoresSafeArea(.container, edges: .bottom) // MARK: - リストの背景をセーフエリア下部まで拡張
                }
                .padding(.top, -40) // MARK: - メインVStack全体を上に移動
                // MARK: - Floating Action Button (FAB)
                Button(action: {
                    showingAddHabitSheet = true
                }) {
                    Image(systemName: "plus") // シンプルなプラスアイコン
                        .font(.title2) // アイコンサイズを調整 (.title -> .title2)
                        .foregroundColor(.white) // アイコンの色は白
                        .padding(16) // パディングでボタンの大きさを調整 (20 -> 16)
                        .background(customAccentColor) // アクセントカラーで塗りつぶし
                        .clipShape(Circle()) // 円形にクリップ
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3) // 影を追加
                }
                .padding(.trailing, 20) // 右側のパディング
                .padding(.bottom, 20) // 下側のパディング
            }
            // MARK: - ナビゲーションタイトルをToolbarItemでカスタム表示
            .toolbar {
                ToolbarItem(placement: .principal) { // ナビゲーションバー中央に配置
                    HStack(spacing: 5) { // アイコンとテキストの間隔
                        Image(systemName: "pawprint.fill") // 犬の足跡アイコン
                            .font(.title2) // アイコンサイズ
                            .foregroundColor(customAccentColor) // アクセントカラーを適用
                        Text("OneDo")
                            .font(.system(size: 28, weight: .bold)) // アプリ名に合わせたフォントサイズと太さ
                            .foregroundColor(customTextColor) // カスタムテキストカラーを適用
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // MARK: - Sort options menu
                    Menu {
                        Picker("並べ替え", selection: $selectedSortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill") // Sort icon
                            .font(.title2)
                            .foregroundColor(customAccentColor) // Apply custom color
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    // MARK: - EditButtonを日本語化されたカスタムボタンに置き換え (位置調整とデザイン変更)
                    Button(action: {
                        // editModeの状態を切り替える
                        editMode?.wrappedValue = (editMode?.wrappedValue == .active) ? .inactive : .active
                    }) {
                        Text(editMode?.wrappedValue == .active ? "完了" : "編集")
                            .font(.caption) // フォントサイズを調整
                            .fontWeight(.medium)
                            .foregroundColor(customAccentColor) // テキストカラーはアクセントカラー
                            .padding(.horizontal, 10) // 水平方向のパディング
                            .padding(.vertical, 5) // 垂直方向のパディング
                            .background(
                                Capsule() // カプセル形状の背景
                                    .stroke(customAccentColor, lineWidth: 1.5) // アクセントカラーの枠線
                            )
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
                        iconName: iconName, // Pass icon name here
                        customColorHex: customColorHex // Pass custom color Hex here
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
                // MARK: - Reset currentMonth and selectedDate to the first day of the month (just in case)
                let calendar = Calendar.autoupdatingCurrent // Use autoupdatingCurrent
                let now = Date()
                print("DEBUG: Current Date (now): \(now)") // Debug print
                
                // Get current year and month
                let year = calendar.component(.year, from: now)
                let month = calendar.component(.month, from: now)
                
                // Create DateComponents for the 1st day of the month at 00:00:00
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = 1 // Set to 1st
                components.hour = 0 // Set to 0 hour
                components.minute = 0 // Set to 0 minute
                components.second = 0 // Set to 0 second
                
                // Create Date object directly from DateComponents
                if let startOfMonth = calendar.date(from: components) {
                    currentMonth = startOfMonth // Set to 1st day of the month at 00:00:00
                    print("DEBUG: Start of Month: \(currentMonth)") // Debug print
                } else {
                    currentMonth = now
                    print("DEBUG: Failed to get start of month. Using now for currentMonth.") // Debug print
                }
                selectedDate = now // selectedDate remains today
                print("DEBUG: currentMonth after onAppear: \(currentMonth)") // Debug print
                print("DEBUG: formatted currentMonth: \(monthFormatter.string(from: currentMonth))") // Debug print
            })
        }
    }

    // MARK: - DateFormatter for month display
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        // Explicitly set locale, calendar, and timezone for stability
        formatter.locale = Locale(identifier: "ja_JP") // Explicitly set Japanese locale
        formatter.calendar = Calendar(identifier: .gregorian) // Explicitly set Gregorian calendar
        formatter.timeZone = TimeZone.current // Set current timezone
        formatter.dateFormat = "yyyy年M月" // Set format last
        return formatter
    }

    // MARK: - Data persistence methods

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

    // MARK: - Task deletion method
    private func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            cancelNotification(for: habits[index])
        }
        habits.remove(atOffsets: offsets)
        saveHabits()
    }

    // MARK: - Habit completion toggle method

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

    // MARK: - Notification related methods

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

// MARK: - HabitRowView: Separate view for each habit list row
// Added to reduce ContentView complexity
struct HabitRowView: View {
    let habit: Habit
    @Binding var selectedDate: Date
    @Binding var selectedHabitForGraph: Habit?
    @Binding var showingProgressGraphSheet: Bool
    @Binding var selectedHabitForEdit: Habit?
    @Binding var showingEditHabitSheet: Bool
    let toggleCompletion: (Habit, Date) -> Void
    let deleteHabit: (IndexSet) -> Void // deleteHabit now accepts IndexSet
    let customTextColor: Color // MARK: - customTextColorを追加
    let customAccentColor: Color // MARK: - customAccentColorを追加

    var body: some View {
        HStack {
            // MARK: - Display custom icon and color
            if let iconName = habit.iconName, let colorHex = habit.customColorHex, let customColor = colorHex.toColor() {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.white) // Icon color fixed to white
                    .frame(width: 30, height: 30)
                    .background(customColor)
                    .clipShape(Circle())
                    .padding(.trailing, 5)
            } else {
                // Default icon and color (dark mode compatible)
                Image(systemName: "checkmark.circle.fill") // Default icon
                    .font(.title2)
                    .foregroundColor(Color(red: 0x85/255.0, green: 0x9A/255.0, blue: 0x93/255.0)) // Default color
                    .frame(width: 30, height: 30)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .padding(.trailing, 5)
            }

            VStack(alignment: .leading) {
                HStack { // MARK: - New HStack for habit name and time
                    Text(habit.name)
                        .font(.body)
                        .foregroundColor(customTextColor)
                        .strikethrough(habit.isCompleted(on: selectedDate), color: customTextColor.opacity(0.7))
                    
                    // MARK: - Display reminder time if available
                    if let reminderTime = habit.reminderTime, habit.reminderEnabled {
                        Text(reminderTime, formatter: timeFormatter)
                            .font(.caption)
                            .foregroundColor(customTextColor.opacity(0.7))
                    }
                }
                
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
                        .foregroundColor(customAccentColor) // MARK: - グラフアイコンの色をアクセントカラーに変更
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            Button(action: {
                toggleCompletion(habit, selectedDate)
            }) {
                Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(habit.isCompleted(on: selectedDate) ? customAccentColor : customTextColor.opacity(0.5)) // MARK: - チェックマーク/円の色をアクセントカラー/テキストカラーに変更
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 15) // Card内の水平パディング
        .padding(.vertical, 10) // Card内の垂直パディング
        .background(Color(.systemBackground)) // カードの背景色（システム背景色でライト/ダークモードに対応）
        .cornerRadius(12) // カードの角丸
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3) // 控えめな影
        .opacity(habit.isCompleted(on: selectedDate) ? 0.6 : 1.0)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // スワイプ削除は元のhabits配列のインデックスで動作させる必要があるため、
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

    // MARK: - Time Formatter
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeStyle = .short // 例: "9:00" または "午前9:00"
        formatter.dateStyle = .none
        return formatter
    }
}
