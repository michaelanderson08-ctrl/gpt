//
//  ContentView.swift
//  gpt
//
//  Created by 64004552 on 2/26/26.
//
import SwiftUI
import UserNotifications

// =====================================================
// MAIN VIEW (MODE SWITCHER)
// =====================================================

struct ContentView: View {

    @State private var selectedMode = 0

    var body: some View {
        VStack {

            Picker("Mode", selection: $selectedMode) {
                Text("Clock is here").tag(0)
                Text("Stopwatch").tag(1)
                Text("World").tag(2)
                Text("Alarms").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedMode {
            case 0: ClockView()
            case 1: StopwatchView()
            case 2: WorldClockView()
            default: AlarmView()
            }
        }
    }
}

/////////////////////////////////////////////////////////
// CLOCK
/////////////////////////////////////////////////////////

struct ClockView: View {
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(now, style: .time)
            .font(.system(size: 60, weight: .bold, design: .monospaced))
            .onReceive(timer) { input in
                now = input
            }
    }
}

/////////////////////////////////////////////////////////
// STOPWATCH
/////////////////////////////////////////////////////////

struct StopwatchView: View {

    @State private var timeElapsed: Double = 0
    @State private var running = false
    @State private var timer: Timer?
    @State private var laps: [String] = []

    var body: some View {
        VStack(spacing: 40) {

            Text(formatTime(timeElapsed))
                .font(.system(size: 60, weight: .bold, design: .monospaced))

            HStack(spacing: 40) {

                Button(running ? "Lap" : "Reset") {
                    running ? addLap() : reset()
                }
                .frame(width: 100, height: 100)
                .background(.gray.opacity(0.2))
                .clipShape(Circle())

                Button(running ? "Pause" : "Start") {
                    running ? pause() : start()
                }
                .frame(width: 100, height: 100)
                .background(running ? .red : .green)
                .foregroundColor(.white)
                .clipShape(Circle())
            }

            List(laps.indices.reversed(), id:\.self) { i in
                HStack {
                    Text("Lap \(laps.count - i)")
                    Spacer()
                    Text(laps[i])
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
    }

    func start() {
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            timeElapsed += 0.01
        }
    }

    func pause() {
        running = false
        timer?.invalidate()
    }

    func reset() {
        timer?.invalidate()
        running = false
        timeElapsed = 0
        laps.removeAll()
    }

    func addLap() {
        laps.append(formatTime(timeElapsed))
    }

    func formatTime(_ t: Double) -> String {
        let m = Int(t)/60
        let s = Int(t)%60
        let h = Int((t*100).truncatingRemainder(dividingBy:100))
        return String(format:"%02d:%02d.%02d",m,s,h)
    }
}

/////////////////////////////////////////////////////////
// WORLD CLOCK
/////////////////////////////////////////////////////////

struct WorldClockView: View {

    let cities = [
        ("New York", "America/New_York"),
        ("London", "Europe/London"),
        ("Tokyo", "Asia/Tokyo"),
        ("Sydney", "Australia/Sydney"),
        ("Los Angeles", "America/Los_Angeles")
    ]

    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        List(cities, id:\.0) { city in
            HStack {
                Text(city.0)
                Spacer()
                Text(timeString(zone: city.1))
                    .font(.system(.body, design: .monospaced))
            }
        }
        .onReceive(timer) { input in
            now = input
        }
    }

    func timeString(zone: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: zone)
        formatter.timeStyle = .medium
        return formatter.string(from: now)
    }
}

/////////////////////////////////////////////////////////
// ALARMS
/////////////////////////////////////////////////////////

struct Alarm: Identifiable {
    let id = UUID()
    var time: Date
    var enabled: Bool
}

struct AlarmView: View {

    @State private var alarms: [Alarm] = []
    @State private var newTime = Date()

    var body: some View {
        VStack {

            DatePicker("New Alarm",
                       selection: $newTime,
                       displayedComponents: .hourAndMinute)
                .padding()

            Button("Add Alarm") {
                addAlarm()
            }

            List {
                ForEach($alarms) { $alarm in
                    HStack {
                        Text(alarm.time, style: .time)
                        Spacer()
                        Toggle("", isOn: $alarm.enabled)
                            .onChange(of: alarm.enabled) {
                                scheduleNotification(alarm)
                            }
                    }
                }
            }
        }
        .onAppear {
            requestPermission()
        }
    }

    func addAlarm() {
        let alarm = Alarm(time: newTime, enabled: true)
        alarms.append(alarm)
        scheduleNotification(alarm)
    }

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert,.sound]) { _,_ in }
    }

    func scheduleNotification(_ alarm: Alarm) {

        guard alarm.enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "Time is up!"
        content.sound = .default

        let comps = Calendar.current.dateComponents([.hour,.minute],
                                                    from: alarm.time)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    ContentView()
}
