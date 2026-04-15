//
//  ContentView.swift
//  buyme
//
//  Created by damon musin on 15.04.2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var list = ""
    @State public var addMenu: Bool = false
    @State private var viewModel = ViewModel()
    @State private var selectedSort: SortOption = .priority
    
    enum SortOption {
        case priority, alphabet, date, low, medium, high
    }
    
    var filteredItems: [Item] {
        var result = viewModel.items
        
        switch selectedSort {
        case .low: result = result.filter { $0.priority == .low }
        case .medium: result = result.filter { $0.priority == .medium }
        case .high: result = result.filter { $0.priority == .high }
        default: break
        }
        
        return result.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            switch selectedSort {
            case .alphabet:
                return lhs.title < rhs.title
            case .date:
                return lhs.dateCreated < rhs.dateCreated
            default:
                let weights: [Priority: Int] = [.high: 2, .medium: 1, .low: 0]
                return (weights[lhs.priority] ?? 0) > (weights[rhs.priority] ?? 0)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                List {
                    Section {
                        if (viewModel.items.isEmpty || filteredItems.isEmpty) {
                            ContentUnavailableView {
                                    Label("No Items", systemImage: "pencil.and.list.clipboard")
                                    .foregroundStyle(.secondary)
                                } description: {
                                    Text("Tap the plus button to add item!")
                                }
                            .listRowSeparator(.hidden)
                            .fontDesign(.rounded)
                            .padding(.top, 200)
                        }
                        
                        ForEach(filteredItems) { item in
                            if let index = viewModel.items.firstIndex(where:  { $0.id == item.id }) {
                                HStack {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            viewModel.items[index].isCompleted.toggle()
                                        }
                                        viewModel.didUpdateItems()
                                        if viewModel.items[index].isCompleted {
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                        } else {
                                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                        }
                                        
                                    } label: {
                                        Image(systemName: viewModel.items[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(viewModel.items[index].priority.color)
                                    }
                                    .buttonStyle(.borderless)
                                    ZStack(alignment: .leading) {
                                        NavigationLink(destination: ItemDetailsView(item: $viewModel.items[index])) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                        HStack {
                                            Text(item.title)
                                                .animation(.spring, value: viewModel.items[index].isCompleted)
                                                .strikethrough(viewModel.items[index].isCompleted)
                                                .foregroundStyle(viewModel.items[index].isCompleted ? .secondary : .primary)
                                            Spacer()
                                            Text(item.category.icon)
                                                
                                        }
                                        .padding(.leading, 10)
                                    }
                                    
                                }
                                .listRowSeparator(.hidden)
                                .contextMenu {
                                    Section("Info") {
                                        Label("Created: \(item.dateCreated.formatted(date: .long, time: .omitted))", systemImage: "calendar")
                                        Label("Priority: \(item.priority.rawValue.capitalized)", systemImage: "star.fill")
                                        Label("Tag: \(item.category.rawValue.capitalized)", systemImage: "tag.fill")
                                    }
                                    Divider()
                                    Button {
                                        UIPasteboard.general.string = item.title
                                    } label: {
                                        Label("Copy Title", systemImage: "doc.on.doc")
                                    }
                                    Button(role: .destructive) {
                                        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.items.remove(at: index)
                                            viewModel.didUpdateItems()
                                        }
                                    } label: {
                                        Label("Delete Item", systemImage: "trash")
                                    }
                                }
                            }
                            
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let id = filteredItems[index].id
                                viewModel.items.removeAll(where: {$0.id == id})
                                viewModel.didUpdateItems()
                            }
                        }
                    } header: {
                        Text("To buy:")
                            .font(.system(size: 40))
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    viewModel.checkWidgetUpdates()
                }
                .padding(.vertical, 40)
                .padding(.horizontal)
                .ignoresSafeArea()
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listSectionSpacing(0)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .sheet(isPresented: $addMenu) {
                    AddNewItem(onAdd: { item in
                        viewModel.items.append(item)
                        viewModel.didUpdateItems()
                    })
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(selection: $selectedSort, label: Text("Sort by")) {
                            Label("Priority", systemImage: "arrow.up.circle")
                                .tag(SortOption.priority)
                            Label("Alphabet", systemImage: "character.circle")
                                .tag(SortOption.alphabet)
                            Label("Date", systemImage: "calendar.circle")
                                .tag(SortOption.date)
                        }
                        .pickerStyle(.inline)
                        
                        Picker(selection: $selectedSort, label: Text("Filter by")) {
                            Label("Low only", systemImage: "gauge.with.dots.needle.bottom.0percent")
                                .tag(SortOption.low)
                            Label("Medium only", systemImage: "gauge.with.dots.needle.bottom.50percent")
                                .tag(SortOption.medium)
                            Label("High only", systemImage: "gauge.with.dots.needle.bottom.100percent")
                                .tag(SortOption.high)
                        }
                        .pickerStyle(.inline)
                    } label: {
                        if selectedSort == .priority {
                            Image(systemName: "line.3.horizontal.decrease")
                        } else {
                            Image(systemName: "line.3.horizontal.decrease").foregroundStyle(.tint).symbolVariant(.fill)
                        }
                    }
                    .sensoryFeedback(.selection, trigger: selectedSort)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        addMenu.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
