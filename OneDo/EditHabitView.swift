import SwiftUI

struct EditHabitView: View {
    // 編集対象のHabitをBindingで受け取る
    @Binding var habit: Habit
    // シートを閉じるための環境変数
    @Environment(\.dismiss) var dismiss

    // リマインダー設定の内部状態
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var reminderDaysOfWeek: Set<Int>

    // MARK: - 目標設定の内部状態を追加
    @State private var selectedGoalType: Habit.GoalType
    @State private var targetValueInput: String
    @State private var unitInput: String

    // MARK: - カスタムアイコンとカラー関連のState変数を追加
    @State private var selectedIconName: String?
    @State private var selectedColor: Color

    // 変更が保存された際に呼び出すクロージャ
    var onSave: () -> Void

    // イニシャライザでBindingからStateの初期値を設定
    init(habit: Binding<Habit>, onSave: @escaping () -> Void) {
        self._habit = habit // Bindingを直接代入
        self.onSave = onSave

        // Habitの現在の値からStateの初期値を設定
        _reminderEnabled = State(initialValue: habit.wrappedValue.reminderEnabled)
        _reminderTime = State(initialValue: habit.wrappedValue.reminderTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        _reminderDaysOfWeek = State(initialValue: habit.wrappedValue.reminderDaysOfWeek)

        // MARK: - 目標設定関連のState初期化
        _selectedGoalType = State(initialValue: habit.wrappedValue.goalType)
        _targetValueInput = State(initialValue: habit.wrappedValue.targetValue.map { String(describing: $0) } ?? "")
        _unitInput = State(initialValue: habit.wrappedValue.unit ?? "")

        // MARK: - アイコンとカラー関連のState初期化
        _selectedIconName = State(initialValue: habit.wrappedValue.iconName ?? "circle.fill") // デフォルトアイコンを設定
        _selectedColor = State(initialValue: habit.wrappedValue.customColorHex?.toColor() ?? Color(red: 0x85/255.0, green: 0x9A/255.0, blue: 0x93/255.0)) // デフォルトカラーを設定
    }

    // SF Symbolsのアイコンリスト（約7種類に絞り込みました）
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
                    TextField("習慣の名前", text: $habit.name) // Bindingを使って直接編集

                    Picker("繰り返し", selection: $habit.repeatSchedule) { // Bindingを使って直接編集
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
                                    print("DEBUG: EditHabitView - Icon tapped: \(iconName), selectedIconName is now: \(String(describing: selectedIconName))")
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
                    Toggle("リマインダーを有効にする", isOn: $reminderEnabled) // 内部State

                    if reminderEnabled {
                        DatePicker("時間", selection: $reminderTime, displayedComponents: .hourAndMinute) // 内部State
                            .datePickerStyle(.compact)

                        if habit.repeatSchedule == .weekly { // habit.repeatScheduleで表示を制御
                            VStack(alignment: .leading) {
                                Text("曜日を選択")
                                HStack {
                                    ForEach(1...7, id: \.self) { weekday in
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
                    Picker("目標タイプ", selection: $selectedGoalType) { // 内部State
                        ForEach(Habit.GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if selectedGoalType != .none {
                        TextField("目標値", text: $targetValueInput) // 内部State
                            .keyboardType(.decimalPad)

                        TextField("単位 (例: 回, 分)", text: $unitInput) // 内部State
                    }
                }
            }
            .navigationTitle("習慣を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss() // 変更を破棄して閉じる
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // 内部Stateの値をBindingに反映
                        habit.reminderEnabled = reminderEnabled
                        habit.reminderTime = reminderEnabled ? reminderTime : nil
                        habit.reminderDaysOfWeek = (reminderEnabled && habit.repeatSchedule == .weekly) ? reminderDaysOfWeek : []

                        // MARK: - 目標設定関連の値をBindingに反映
                        habit.goalType = selectedGoalType
                        habit.targetValue = Double(targetValueInput) // StringをDouble?に変換
                        habit.unit = unitInput.isEmpty ? nil : unitInput // 空文字列ならnil

                        // MARK: - アイコンとカラーの値をBindingに反映
                        habit.iconName = selectedIconName
                        habit.customColorHex = selectedColor.toHex() // ColorをHex文字列に変換 (toHex()はHabit.swiftに移動済み)

                        onSave() // 保存アクションを呼び出し
                        dismiss()
                    }
                }
            }
        }
    }
}
