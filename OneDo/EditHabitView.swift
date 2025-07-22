import SwiftUI

struct EditHabitView: View {
    // 編集対象のHabitをBindingで受け取る
    @Binding var habit: Habit
    // シートを閉じるための環境変数
    @Environment(\.dismiss) var dismiss

    // リマインダー設定の内部状態（変更があったか追跡するため）
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var reminderDaysOfWeek: Set<Int>

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
//             reminderDaysOfWeek: []
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
