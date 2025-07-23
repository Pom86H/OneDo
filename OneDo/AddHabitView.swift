import SwiftUI

struct AddHabitView: View {
    @State private var newHabitName: String = ""
    @State private var selectedRepeatSchedule: Habit.RepeatSchedule = .daily // 繰り返し頻度の選択用

    // MARK: - リマインダー関連のState変数
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date() // デフォルトは午前9時
    @State private var reminderDaysOfWeek: Set<Int> = [] // 曜日選択用

    // MARK: - 目標設定関連のState変数を追加
    @State private var selectedGoalType: Habit.GoalType = .none // デフォルトは目標なし
    @State private var targetValueInput: String = "" // 目標値の入力用 (Stringで受け取る)
    @State private var unitInput: String = "" // 単位の入力用

    // MARK: - カスタムアイコンとカラー関連のState変数を追加
    @State private var selectedIconName: String? = "circle.fill" // デフォルトアイコン
    @State private var selectedColor: Color = Color(red: 0x85/255.0, green: 0x9A/255.0, blue: 0x93/255.0) // デフォルトカラー

    @Environment(\.dismiss) var dismiss

    // クロージャの引数にリマインダー、目標設定、アイコン、カラー関連の情報を追加
    var onAddHabit: (String, Habit.RepeatSchedule, Bool, Date?, Set<Int>, Habit.GoalType, Double?, String?, String?, String?) -> Void

    // SF Symbolsのアイコンリスト（例）
    let sfSymbols: [String] = [
        "heart.fill",       // 健康、愛情
        "book.closed.fill", // 学習、読書
        "dumbbell.fill",    // 運動、筋トレ
        "cup.and.saucer.fill", // 休憩、飲食
        "leaf.fill",        // 自然、環境
        "lightbulb.fill",   // アイデア、思考
        "figure.walk"       // 活動、散歩
    ]


    var body: some View {
        NavigationView {
            Form {
                Section("習慣の詳細") {
                    TextField("習慣の名前を入力", text: $newHabitName)

                    Picker("繰り返し", selection: $selectedRepeatSchedule) {
                        ForEach(Habit.RepeatSchedule.allCases, id: \.self) { schedule in
                            Text(schedule.rawValue).tag(schedule)
                        }
                    }
                }

                Section("アイコンとカラー") {
                    // アイコン選択
                    VStack(alignment: .leading) {
                        Text("アイコンを選択")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(sfSymbols, id: \.self) { iconName in
                                // MARK: - ButtonをZStack + onTapGestureに置き換え
                                ZStack {
                                    Image(systemName: iconName)
                                        .font(.title2)
                                        .foregroundColor(selectedIconName == iconName ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIconName == iconName ? selectedColor : Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                                .contentShape(Circle()) // ZStack全体をタップ可能な円形にする
                                .onTapGesture {
                                    selectedIconName = iconName
                                    // MARK: - デバッグ用: アイコンがタップされたか確認
                                    print("DEBUG: AddHabitView - Icon tapped: \(iconName), selectedIconName is now: \(String(describing: selectedIconName))")
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }

                    // カラーピッカー
                    ColorPicker("カラーを選択", selection: $selectedColor)
                        .padding(.vertical, 5)
                }

                Section("リマインダー") {
                    Toggle("リマインダーを有効にする", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker("時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)

                        if selectedRepeatSchedule == .weekly {
                            VStack(alignment: .leading) {
                                Text("曜日を選択")
                                HStack {
                                    ForEach(1...7, id: \.self) { weekday in // 日曜(1)から土曜(7)
                                        // DayOfWeekButtonはHabit.swiftに移動済み
                                        DayOfWeekButton(weekday: weekday, isSelected: reminderDaysOfWeek.contains(weekday)) { selectedWeekday in
                                            if reminderDaysOfWeek.contains(selectedWeekday) {
                                                reminderDaysOfWeek.remove(selectedWeekday)
                                            } else {
                                                reminderDaysOfWeek.insert(selectedWeekday)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: - 目標設定セクションを追加
                Section("目標設定") {
                    Picker("目標タイプ", selection: $selectedGoalType) { // デフォルトは目標なし
                        ForEach(Habit.GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if selectedGoalType != .none {
                        TextField("目標値", text: $targetValueInput)
                            .keyboardType(.decimalPad) // 数値入力に限定

                        TextField("単位 (例: 回, 分)", text: $unitInput)
                    }
                }
            }
            .navigationTitle("新しい習慣を追加")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !newHabitName.isEmpty {
                            // リマインダーが有効な場合のみreminderTimeを渡す
                            let finalReminderTime = reminderEnabled ? reminderTime : nil
                            // 週次リマインダーが有効な場合のみreminderDaysOfWeekを渡す
                            let finalReminderDaysOfWeek = (reminderEnabled && selectedRepeatSchedule == .weekly) ? reminderDaysOfWeek : []

                            // 目標値と単位をDouble?とString?に変換
                            let finalTargetValue = Double(targetValueInput)
                            let finalUnit = unitInput.isEmpty ? nil : unitInput

                            // ColorをHex文字列に変換 (toHex()はHabit.swiftに移動済み)
                            let hexColor = selectedColor.toHex()

                            onAddHabit(
                                newHabitName,
                                selectedRepeatSchedule,
                                reminderEnabled,
                                finalReminderTime,
                                finalReminderDaysOfWeek,
                                selectedGoalType,
                                finalTargetValue,
                                finalUnit,
                                selectedIconName, // 新しい引数
                                hexColor // 新しい引数
                            )
                            dismiss()
                        }
                    }
                    .disabled(newHabitName.isEmpty) // 習慣名が空の場合はボタンを無効化
                }
            }
        }
    }
}
