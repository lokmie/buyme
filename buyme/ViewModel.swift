//
//  ViewModel.swift
//  buyme
//
//  Created by damon musin on 05.05.2026.
//

import Foundation
import Observation
import WidgetKit

@Observable
class ViewModel {
    var items: [Item] = []
    
    init() {
        loadItems()
        checkWidgetUpdates()
    }
    
    func didUpdateItems() {
            saveItems()
            syncWithWidget()
        }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "items")
        }
    }

    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: "items"),
           let decoded = try? JSONDecoder().decode([Item].self, from: data) {
            self.items = decoded
        }
    }
    
    
    
    func syncWithWidget() {
            guard let sharedDefaults = UserDefaults(suiteName: "group.lokmie.buyme") else { return }
            
            let activeItems = items.filter { !$0.isCompleted }
            let titles = activeItems.map { $0.title }
            let colors = activeItems.map { $0.priority.rawValue }
            
            sharedDefaults.set(titles, forKey: "widgetItems")
            sharedDefaults.set(colors, forKey: "widgetColors")
            sharedDefaults.set(items.count, forKey: "widgetTotal")
            sharedDefaults.set(items.filter { $0.isCompleted }.count, forKey: "widgetDone")
            
            sharedDefaults.set([], forKey: "doneItems")
            
            WidgetCenter.shared.reloadAllTimelines()
        }
    
    
    func checkWidgetUpdates() {
            guard let sharedDefaults = UserDefaults(suiteName: "group.lokmie.buyme") else { return }
            
            let doneInWidget = sharedDefaults.stringArray(forKey: "doneItems") ?? []
            
            if !doneInWidget.isEmpty {
                var updated = false
                for itemName in doneInWidget {
                    if let index = items.firstIndex(where: { $0.title == itemName }) {
                        if !items[index].isCompleted {
                            items[index].isCompleted = true
                            updated = true
                        }
                    }
                }
                
                if updated {
                    saveItems()
                    syncWithWidget()
                }
            }
        }
}
