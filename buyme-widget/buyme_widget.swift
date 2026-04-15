//
//  buyme_widget.swift
//  buyme-widget
//
//  Created by damon musin on 06.05.2026.
//

import WidgetKit
import SwiftUI
import AppIntents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [String]
    let itemColors: [String]
    let totalCount: Int
    let doneCount: Int
    let doneItems: [String]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: ["Apples", "Bread", "Grape"], itemColors: ["low", "high", "medium"], totalCount: 3, doneCount: 1, doneItems: ["Grape"])
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date(), items: ["Milk", "Cheese"], itemColors: ["low", "high"], totalCount: 2, doneCount: 1, doneItems: ["Cheese"])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<SimpleEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: "group.lokmie.buyme")
        
        let savedTitles = sharedDefaults?.stringArray(forKey: "widgetItems") ?? []
        let savedColors = sharedDefaults?.stringArray(forKey: "widgetColors") ?? []
        let savedDoneItems = sharedDefaults?.stringArray(forKey: "doneItems") ?? []
        let total = sharedDefaults?.integer(forKey: "widgetTotal") ?? 0
        let done = sharedDefaults?.integer(forKey: "widgetDone") ?? 0

        let entry = SimpleEntry(
            date: Date(),
            items: savedTitles,
            itemColors: savedColors,
            totalCount: total,
            doneCount: done,
            doneItems: savedDoneItems
        )

        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct buyme_widgetEntryView : View {
    @Environment(\.colorScheme) var colorScheme
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .center) {
                let progress = entry.totalCount > 0 ? (CGFloat(entry.doneCount) / CGFloat(entry.totalCount)) * 0.5 : 0
                
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(180))
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .orange, .red]),
                                center: .center,
                                startAngle: .degrees(180),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(180))
                        .animation(.spring, value: progress)
                        
                    VStack(spacing: 0) {
                        Spacer()
                        Text("\(entry.doneCount) / \(entry.totalCount)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("done")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 50, height: 60)
                .padding(.leading, 15)
            }
            
            Spacer(minLength: 20)
            
            VStack(alignment: .leading, spacing: 6) {
                let allDisplayItems = entry.items + entry.doneItems
                
                if allDisplayItems.isEmpty {
                    Text("You did all purchases!")
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                } else {
                    Text(entry.items.isEmpty ? "All done!" : "To buy:")
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .padding(.bottom, 5)
                }
                
                ForEach(allDisplayItems.prefix(3), id: \.self) { name in
                    let isDone = entry.doneItems.contains(name)
                    
                    Button(intent: ToggleItemIntent(itemName: name)) {
                        HStack(spacing: 8) {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(isDone ? .green : colorName(getItemColor(for: name)))
                                .contentTransition(.symbolEffect(.replace))
                            
                            Text(name)
                                .lineLimit(1)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .strikethrough(isDone)
                                .foregroundStyle(isDone ? .secondary : .primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .invalidatableContent()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .padding(.horizontal, 30)
    }

    func getItemColor(for name: String) -> String? {
        if let index = entry.items.firstIndex(of: name) {
            return entry.itemColors[safe: index]
        }
        return "low"
    }

    func colorName(_ name: String?) -> Color {
        switch name {
        case "high": return .red
        case "medium": return .orange
        default: return .green
        }
    }
}

struct ToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark as Done"

    @Parameter(title: "Item Name")
    var itemName: String

    init() {}
    init(itemName: String) {
        self.itemName = itemName
    }

    func perform() async throws -> some IntentResult {
        guard let sharedDefaults = UserDefaults(suiteName: "group.lokmie.buyme") else { return .result() }
        
        var items = sharedDefaults.stringArray(forKey: "widgetItems") ?? []
        var doneItems = sharedDefaults.stringArray(forKey: "doneItems") ?? []
        var doneCount = sharedDefaults.integer(forKey: "widgetDone")
        
        if let index = items.firstIndex(of: itemName) {
            let item = items.remove(at: index)
            doneItems.append(item)
            doneCount += 1
        } else if let index = doneItems.firstIndex(of: itemName) {
            let item = doneItems.remove(at: index)
            items.insert(item, at: 0)
            doneCount -= 1
        }
        
        sharedDefaults.set(items, forKey: "widgetItems")
        sharedDefaults.set(doneItems, forKey: "doneItems")
        sharedDefaults.set(doneCount, forKey: "widgetDone")
        
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct buyme_widget: Widget {
    let kind: String = "buyme_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            buyme_widgetEntryView(entry: entry)
        }
        .configurationDisplayName("BuyMe")
        .description("Your shopping list at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    buyme_widget()
} timeline: {
    SimpleEntry(date: .now, items: ["Coffee", "Bread"], itemColors: ["high", "medium"], totalCount: 3, doneCount: 1, doneItems: ["Milk"])
}
