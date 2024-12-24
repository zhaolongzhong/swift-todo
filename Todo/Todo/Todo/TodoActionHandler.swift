//
//  TodoActionHandler.swift
//

import Foundation

final class TodoActionHandler {
    private weak var viewModel: TodoViewModel?

    init(viewModel: TodoViewModel) {
        self.viewModel = viewModel
    }

    func toggleTodo(_ id: UUID) {
        Task { await viewModel?.toggleTodo(id) }
    }

    func deleteTodo(_ id: UUID) {
        Task { await viewModel?.deleteTodo(id) }
    }

    func fetchTodos() {
        Task { await viewModel?.fetchTodos() }
    }

    func fetchTodo(_ id: UUID) {
        Task { await viewModel?.fetchTodo(id) }
    }

    func addTodo() {
        Task { await viewModel?.addTodo() }
    }
}
