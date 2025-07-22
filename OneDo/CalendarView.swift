import SwiftUI

struct CalendarView: View {
    // 表示する月のDate
    let month: Date
    // 習慣のデータ（達成履歴を含む）
    let habits: [Habit]
    // 選択された日付のBinding (ContentViewと同期させるため)
    @Binding var selectedDate: Date

    // カレンダーの表示に使うCalendarインスタンス
    private let calendar = Calendar.current

    var body: some View {
        VStack {
            // MARK: - 曜日ヘッダー
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekdaySymbol in
                    Text(weekdaySymbol)
                        .font(.caption)
                        .fontWeight(.medium) // フォントの太さを調整
                        .foregroundColor(.secondary) // 色をセカンダリカラーに
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8) // パディングを調整

            // MARK: - 日付グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(daysInMonth(for: month), id: \.self) { date in
                    // 月内の日付かどうかをチェック
                    if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                        // 月内の日付
                        DayCell(date: date, habits: habits, selectedDate: $selectedDate)
                    } else {
                        // 月外の日付（空白セル）
                        Color.clear
                            .frame(height: 40) // セルの高さを合わせる
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - ヘルパーメソッド

    // 指定された月のすべての日（前月・翌月の日を含む）を生成
    private func daysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = monthInterval.end // 月の最終日も必要

        // 月の最初の曜日を取得 (例: 月曜日が週の始まりなら、日曜日の分だけ空白が必要)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // 週の始まりが月曜の場合、日曜日は7、月曜日は1として計算する
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var dates: [Date] = []
        // 前月の空白日を追加
        for i in 0..<offsetDays {
            if let prevDate = calendar.date(byAdding: .day, value: -offsetDays + i, to: firstDayOfMonth) {
                dates.append(prevDate)
            }
        }

        // 今月の日を追加 (月の最初の日から最終日までをループ)
        var currentDate = firstDayOfMonth
        while currentDate <= lastDayOfMonth { // 最終日を含むように条件を修正
            dates.append(currentDate)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
        
        // 翌月の空白日を追加 (合計42日になるまで)
        let totalCells = 42 // 6週間 x 7日 = 42日
        let remainingDays = totalCells - dates.count
        if remainingDays > 0 {
            if let lastDateInGrid = dates.last {
                for i in 1...remainingDays {
                    if let nextDate = calendar.date(byAdding: .day, value: i, to: lastDateInGrid) {
                        dates.append(nextDate)
                    }
                }
            }
        }

        return dates
    }
}

// MARK: - DayCell: 各日のセルビュー
// このビューはCalendarView.swift内に定義します。
struct DayCell: View {
    let date: Date
    let habits: [Habit]
    @Binding var selectedDate: Date

    private let calendar = Calendar.current

    // その日が今日かどうか
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    // その日が選択された日付かどうか
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    // その日に達成された習慣があるかどうか
    private var hasCompletedHabit: Bool {
        habits.contains { habit in
            habit.repeatSchedule.isDue(on: date) && habit.isCompleted(on: date)
        }
    }

    var body: some View {
        Text("\(calendar.component(.day, from: date))") // 日付の数字を表示
            .font(.callout) // フォントサイズを調整
            .frame(width: 38, height: 38) // セルのサイズを調整
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Circle()) // 円形にクリップ
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2) // 選択された日付に枠線
            )
            .onTapGesture {
                selectedDate = date // タップされた日付を選択
            }
    }

    // セルの背景色を計算
    private var backgroundColor: Color {
        if isSelected {
            return .accentColor // 選択された日付はアクセントカラー
        } else if isToday {
            return .blue.opacity(0.3) // 今日は薄い青
        } else if hasCompletedHabit {
            return .green.opacity(0.4) // 達成済み習慣があれば薄い緑を濃く
        } else {
            return Color(.systemGray5) // デフォルトはシステムグレー5
        }
    }

    // セルの文字色を計算
    private var foregroundColor: Color {
        if isSelected {
            return .white // 選択された日付は白文字
        } else if isToday || hasCompletedHabit {
            return .primary // 今日か達成済みならプライマリカラー
        } else {
            return .secondary // それ以外はセカンダリカラー
        }
    }
}
