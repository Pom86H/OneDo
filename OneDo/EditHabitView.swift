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
        // ここを修正: String(describing:) を使用して明示的に変換
        _targetValueInput = State(initialValue: habit.wrappedValue.targetValue.map { String(describing: $0) } ?? "")
        // ここを修正: unitがnilの場合に空文字列を返すように
        _unitInput = State(initialValue: habit.wrappedValue.unit ?? "")
    }

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

                        onSave() // 保存アクションを呼び出し
                        dismiss()
                    }
                }
            }
        }
    }
}

// DayOfWeekButtonはAddHabitView.swiftに定義済みなので、ここでは定義しません。
// もしエラーが出る場合は、DayOfWeekButtonの定義をHabit.swiftの下か、
// 独立したファイルに移動することを検討してください。

// #Preview {
//     struct EditHabitViewPreview: View {
//         @State private var previewHabit = Habit(
//             name: "毎日水を飲む",
//             isCompleted: false,
//             repeatSchedule: .daily,
//             reminderTime: Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date()),
//             reminderEnabled: true,
//             reminderDaysOfWeek: [],
//             goalType: .count, // プレビュー用に目標設定
//             targetValue: 10,
//             unit: "回"
//         )
//
//         var body: some View {
//             EditHabitView(habit: $previewHabit, onSave: {
//                 print("プレビュー: 習慣が保存されました: \(previewHabit.name)")
//             })
//         }
//     }
//     return EditHabitViewPreview()
// }
