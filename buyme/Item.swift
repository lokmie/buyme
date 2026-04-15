//
//  Item.swift
//  buyme
//
//  Created by damon musin on 15.04.2026.
//

import Foundation
import SwiftUI

extension Priority {
    var icon: String {
        switch self {
        case .low: return "gauge.with.dots.needle.bottom.0percent"
        case .medium: return "gauge.with.dots.needle.bottom.50percent"
        case .high: return "gauge.with.dots.needle.bottom.100percent"
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

enum ItemCategory: String, Codable, CaseIterable {
    case other, grocery, subscription, entertainment, health, house, food, clothes, beauty, pets, tech
    
    var icon: String {
        switch self {
        case .other:
            return ""
        case .grocery:
            return "🍏"
        case .subscription:
            return "💸"
        case .entertainment:
            return "🎮"
        case .health:
            return "💊"
        case .house:
            return "🏡"
        case .food:
            return "🍕"
        case .clothes:
            return "👕"
        case .beauty:
            return "🧼"
        case .pets:
            return "🐾"
        case .tech:
            return "💻"
        }
    }
    var title: String {
        return self.rawValue.capitalized
    }
}

struct Item: Identifiable, Hashable, Codable, Equatable {
    let id: UUID
    let dateCreated: Date
    
    var title: String
    var isCompleted: Bool = false
    var details: String?
    var priority: Priority = .low
    var price: Double?
    var category: ItemCategory = .other
}


