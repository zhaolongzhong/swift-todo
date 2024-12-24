//
//  TodoService.swift
//

import Foundation

protocol TodoService {
    func fetchTodos() async throws -> [TodoData]
    func fetchTodo(_ id: UUID) async throws -> TodoData?
    func createTodo(_ todo: Todo) async throws -> TodoData
    func updateTodo(_ todo: Todo) async throws -> TodoData
    func deleteTodo(id: UUID) async throws
}

class TodoServiceImpl: TodoService {
    init() {

    }

    func fetchTodos() async throws -> [TodoData] {
        let todos = [
            Todo(id: UUID(), title: "task 1", completed: false),
            Todo(id: UUID(), title: "task 2", completed: false),
            Todo(id: UUID(), title: "task 3", completed: false)
        ]
        return todos
    }

    func fetchTodo(_ id: UUID) async throws -> TodoData? {
        return TodoData(id: id, title: "Todo \(id.uuidString.prefix(8))", completed: false)
    }

    func createTodo(_ todo: Todo) async throws -> TodoData {
        return TodoData(id: UUID(), title: todo.title, completed: false)
    }

    func updateTodo(_ todo: Todo) async throws -> TodoData {
        return todo
    }

    func deleteTodo(id: UUID) async throws {

    }
}
