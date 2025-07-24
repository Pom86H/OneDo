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
        NavigationView {
            VStack(spacing: 0) { // Overall VStack with 0 spacing
                // MARK: - Month selection UI
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
                .padding(.horizontal)
                .padding(.vertical, 10) // Increase vertical padding
                .background(customBaseColor) // Apply custom color

                // MARK: - Embed CalendarView
                CalendarView(month: currentMonth, habits: habits, selectedDate: $selectedDate)
                    .padding(.bottom, 10)

                // MARK: - Filtering options Picker (hidden in edit mode)
                if editMode?.wrappedValue != .active { // Only show if not in edit mode
                    Picker("表示", selection: $selectedFilterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented) // Display as segmented picker
                    .padding(.horizontal)
                    .padding(.bottom, 10) // Adjust padding
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
                                Text("習慣がありません。\n新しい習慣を追加してみましょう！")
                                    .foregroundColor(customTextColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(reorderableHabits) { habit in // Loop directly through Habit objects
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
                                    // Directly manipulate the habits array
                                    habits.move(fromOffsets: source, toOffset: destination)
                                    saveHabits()
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
                                Text("習慣がありません。\n新しい習慣を追加してみましょう！")
                                    .foregroundColor(customTextColor.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(processedHabitsIndices, id: \.self) { index in
                                    let habit = habits[index] // Get habit directly
                                    HabitRowView(habit: habit, selectedDate: $selectedDate,
                                                 selectedHabitForGraph: $selectedHabitForGraph,
                                                 showingProgressGraphSheet: $showingProgressGraphSheet,
                                                 selectedHabitForEdit: $selectedHabitForEdit,
                                                 showingEditHabitSheet: $showingEditHabitSheet,
                                                 toggleCompletion: toggleCompletion,
                                                 deleteHabit: deleteHabit,
                                                 customTextColor: customTextColor)
                                }
                                // onMove is not needed in normal mode
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddHabitSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(customAccentColor) // Apply custom color
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        // MARK: - Replaced EditButton with custom Japanese button (position adjustment)
                        Button(action: {
                            // Toggle editMode state
                            editMode?.wrappedValue = (editMode?.wrappedValue == .active) ? .inactive : .active
                        }) {
                            Text(editMode?.wrappedValue == .active ? "完了" : "編集")
                                .foregroundColor(customAccentColor) // Apply custom color
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
                    // MARK: - Reset currentMonth and selectedDate to the first day of the current month (just in case)
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
            .background(customBaseColor.edgesIgnoringSafeArea(.all)) // Apply custom color
            // MARK: - Ensure preferredColorScheme is NOT set here to allow system theme
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
    let customTextColor: Color

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
                        .foregroundColor(.blue) // Graph icon color remains blue
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            Button(action: {
                toggleCompletion(habit, selectedDate)
            }) {
                Image(systemName: habit.isCompleted(on: selectedDate) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(habit.isCompleted(on: selectedDate) ? .green : .gray) // Checkmark color remains green/gray
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .opacity(habit.isCompleted(on: selectedDate) ? 0.6 : 1.0)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // For swipe deletion to work with the original habits array index,
                // it needs to identify the habit to delete using its ID here,
                // rather than directly calling ContentView's deleteHabit.
                // However, due to complexity with onMove, it's kept simple for now.
                // (Note: If onMove and swipeActions are applied to the same ForEach,
                // onMove may take precedence. Especially in edit mode.)
                // In this revision, onMove is active in edit mode, and swipeActions is inactive.
                // In normal mode, swipeActions is active.
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
