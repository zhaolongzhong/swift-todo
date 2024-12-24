//
//  TodoApp.swift
//

import SwiftUI

private struct TodoRepositoryKey: EnvironmentKey {
    static let defaultValue: TodoRepository = TodoRepositoryImpl(todoService: TodoServiceImpl())
}

extension EnvironmentValues {
    var todoRepository: TodoRepository {
        get { self[TodoRepositoryKey.self] }
        set { self[TodoRepositoryKey.self] = newValue }
    }
}

@main
struct TodoApp: App {
    @Environment(\.todoRepository) private var todoRepository

    var body: some Scene {
        WindowGroup {
            TodoListView()
                .environmentObject(TodoViewModel(todoRepository: todoRepository))
        }
    }
}
