import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var isExpanded = false
    @State private var currentMonth: Date = Date()

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }()

    private let weekdaySymbols = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        DLGlassCard(tint: Color.dlLavender) {
            VStack(spacing: Spacing.sm) {
                headerRow
                weekdayLabels
                if isExpanded {
                    monthGrid
                } else {
                    weekRow
                }
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var headerRow: some View {
        HStack {
            if isExpanded {
                Button(action: { withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { goToPrevMonth() } }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.glass)
            }

            Text(monthYearString)
                .font(.headline)
                .foregroundStyle(Color.dlTextPrimary)
                .frame(maxWidth: .infinity, alignment: isExpanded ? .center : .leading)

            Button(action: { withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { isExpanded.toggle() } }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.glass)

            if isExpanded {
                Button(action: { withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { goToNextMonth() } }) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.glass)
            }
        }
    }

    private var weekdayLabels: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(Color.dlTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var weekRow: some View {
        let days = currentWeekDays()
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private var monthGrid: some View {
        let days = currentMonthDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 36)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)

        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                selectedDate = date
            }
        }) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.weight(isToday || isSelected ? .bold : .regular))
                .foregroundStyle(
                    isSelected ? Color.white :
                    isToday ? Color.dlCoin :
                    isCurrentMonth ? Color.dlTextPrimary : Color.dlTextPrimary.opacity(0.3)
                )
                .frame(width: 36, height: 36)
                .background {
                    if isSelected {
                        Circle()
                            .glassEffect(.regular.tint(Color.dlLavender), in: .circle)
                    } else if isToday {
                        Circle()
                            .glassEffect(.regular.tint(Color.dlCoin.opacity(0.38)), in: .circle)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func currentWeekDays() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -offset, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func currentMonthDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let totalCells = leadingBlanks + daysInMonth

        return (0..<totalCells).map { index in
            if index < leadingBlanks { return nil }
            return calendar.date(byAdding: .day, value: index - leadingBlanks, to: monthInterval.start)
        }
    }

    private func goToPrevMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func goToNextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: isExpanded ? currentMonth : selectedDate)
    }
}
