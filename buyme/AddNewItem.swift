//
//  AddNewItem.swift
//  buyme
//
//  Created by damon musin on 15.04.2026.
//

import SwiftUI

struct AddNewItem: View {
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Priority = .low
    @State private var selectedCategory: ItemCategory = .other
    @State private var showAlert = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    
    enum Currency {
        case RUB, USD
        
        var char: String {
            switch self {
            case .RUB: return "₽"
            case .USD: return "$"
            }
        }
    }
    
    var onAdd: (Item) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Buy some coffee...", text: $title)
                        .autocorrectionDisabled()
                } header: {
                    Text("Title")
                        .listRowSpacing(0)
                }
                .listSectionSpacing(5)
                Section {
                    categorySelector
                } header: {
                    Text("Tags")
                        .listRowSpacing(0)
                }
                .listSectionSpacing(10)
                .listRowBackground(EmptyView())
                Section {
                    prioritySelector
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Enter description...")
                                .foregroundStyle(.quinary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsTightening(false)
                            
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 340)
                            .autocorrectionDisabled()
                    }
                    .listRowSpacing(0)
                } header: {
                    Text("Priority & Details")
                        .listRowSpacing(0)
                }
                .listRowSpacing(0)
                .listSectionSpacing(10)
            }
            .listRowSpacing(0)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Add new item")
                        .font(.title)
                        .frame(minWidth: 270, alignment: .leading)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !(title.isEmpty) {
                            let newItem = Item(
                                id: UUID(), dateCreated: Date(), title: title, details: description, priority: priority, category: selectedCategory
                            )
                            onAdd(newItem)
                            dismiss()
                        } else {
                            showAlert = true
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                        }
                        
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
        .alert("Missing title", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please enter a title before saving.")
        }
    }
    private var prioritySelector: some View {
        GeometryReader { geometry in
            let sliceWidth = geometry.size.width / CGFloat(Priority.allCases.count)
            let activeIndex = CGFloat(Priority.allCases.firstIndex(of: priority) ?? 0)
            let targetOffset = activeIndex * sliceWidth
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.4), lineWidth: 0.5)
                    )
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.15), radius: 6, y: 3)
                    .scaleEffect(x: isDragging ? 1.05 : 1.0, y: isDragging ? 0.95 : 1.0)
                    .frame(width: sliceWidth - 8, height: geometry.size.height - 8)
                    .offset(x: isDragging ? dragOffset + 4 : targetOffset + 4)
                
                HStack(spacing: 0) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        priorityButton(for: p)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let rawX = value.location.x - (sliceWidth / 2)
                        let clampedX = max(min(rawX, geometry.size.width - sliceWidth), 0)
                        
                        isDragging = true
                        dragOffset = clampedX
                        
                        let index = Int(max(0, min(CGFloat(Priority.allCases.count - 1), value.location.x / sliceWidth)))
                        let newPriority = Priority.allCases[index]
                        
                        if priority != newPriority {
                            priority = newPriority
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                            isDragging = false
                        }
                    }
            )
        }
        .frame(height: 64)
    }
    
    @ViewBuilder
    private func priorityButton(for p: Priority) -> some View {
        VStack(spacing: 4) {
            Image(systemName: p.icon)
                .font(.system(size: 18, weight: .medium))
            Text(p.title)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(priority == p ? priority.color : .secondary)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                priority = p
            }
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.icon)
                            Text(category.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selectedCategory == category && selectedCategory != .other {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.blue.opacity(0.1))
                                    .matchedGeometryEffect(id: "activeCategory", in: animation)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .foregroundStyle(selectedCategory == category ? .blue : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets())
        
    }
}

#Preview {
    AddNewItem(onAdd: { _ in })
}
