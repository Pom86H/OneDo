import SwiftUI

struct AddHabitView: View {
    @State private var newHabitName: String = ""
    @State private var selectedRepeatSchedule: Habit.RepeatSchedule = .daily // 繰り返し頻度の選択用

    // MARK: - リマインダー関連のState変数を追加
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date() // デフォルトは午前9時
    @State private var reminderDaysOfWeek: Set<Int> = [] // 曜日選択用

    @Environment(\.dismiss) var dismiss

    // クロージャの引数にリマインダー関連の情報を追加
    var onAddHabit: (String, Habit.RepeatSchedule, Bool, Date?, Set<Int>) -> Void

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

                // MARK: - リマインダー設定セクションを追加
                Section("リマインダー") {
                    Toggle("リマインダーを有効にする", isOn: $reminderEnabled)

                    if reminderEnabled {
                        DatePicker("時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact) // コンパクトなスタイル

                        // 週次リマインダーの場合のみ曜日選択を表示
                        if selectedRepeatSchedule == .weekly {
                            VStack(alignment: .leading) {
                                Text("曜日を選択")
                                HStack {
                                    ForEach(1...7, id: \.self) { weekday in // 日曜(1)から土曜(7)
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

                            onAddHabit(newHabitName, selectedRepeatSchedule, reminderEnabled, finalReminderTime, finalReminderDaysOfWeek)
                            dismiss()
                        }
                    }
                    .disabled(newHabitName.isEmpty) // 習慣名が空の場合はボタンを無効化
                }
            }
        }
    }
}

// MARK: - DayOfWeekButton: 曜日選択ボタンのカスタムビュー

struct DayOfWeekButton: View {
    let weekday: Int // 1 (日曜) ... 7 (土曜)
    let isSelected: Bool
    let action: (Int) -> Void

    private var daySymbol: String {
        let calendar = Calendar.current
        return calendar.veryShortWeekdaySymbols[weekday - 1] // 日曜が0番目
    }

    var body: some View {
        Button(action: {
            action(weekday)
        }) {
            Text(daySymbol)
                .font(.caption)
                .frame(width: 28, height: 28)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

// #Preview {
//     AddHabitView(onAddHabit: { name, schedule, enabled, time, days in
//         print("プレビュー: 新しい習慣: \(name), 繰り返し: \(schedule.rawValue), リマインダー有効: \(enabled), 時間: \(String(describing: time)), 曜日: \(days)")
//     })
// }
