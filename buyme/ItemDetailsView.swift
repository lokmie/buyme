//
//  ItemDetailsView.swift
//  buyme
//
//  Created by damon musin on 05.05.2026.
//

import SwiftUI

extension Binding {
    func unwrapped<T>(defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T> (
            get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 }
        )
    }
}

import SwiftUI

struct ItemDetailsView: View {
    @Binding var item: Item
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @Namespace private var animation
    
    var body: some View {
        List {
            Section {
                TextField("Buy some coffee...", text: $item.title)
                    .autocorrectionDisabled()
            } header: {
                Text("Title")
            }
            
            Section {
                categorySelector
            } header: {
                Text("Tags")
            }
            .listRowBackground(EmptyView())
            
            Section {
                prioritySelector
                
                ZStack(alignment: .topLeading) {
                    if (item.details ?? "").isEmpty {
                        Text("Enter description...")
                            .foregroundStyle(.quinary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsTightening(false)
                    }
                    TextEditor(text: $item.details.unwrapped(defaultValue: ""))
                        .frame(minHeight: 320)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Priority & Details")
            } footer: {
                Text("Created at \(item.dateCreated.formatted(date: .long, time: .omitted))")
            }
        }
        .navigationTitle("Edit details")
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            item.category = category
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
                            if item.category == category && item.category != .other {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.blue.opacity(0.1))
                                    .matchedGeometryEffect(id: "activeCategory", in: animation)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .foregroundStyle(item.category == category ? .blue : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowInsets(EdgeInsets())
    }
    
    private var prioritySelector: some View {
        GeometryReader { geometry in
            let sliceWidth = geometry.size.width / CGFloat(Priority.allCases.count)
            let activeIndex = CGFloat(Priority.allCases.firstIndex(of: item.priority) ?? 0)
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
                        
                        if item.priority != newPriority {
                            item.priority = newPriority
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
        .foregroundStyle(item.priority == p ? p.color : .secondary)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                item.priority = p
            }
        }
    }
}

#Preview {
    ItemDetailsView(item: .constant(Item(id: UUID(), dateCreated: Date(), title: "wat")))
}
