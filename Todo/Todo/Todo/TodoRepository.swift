//
//  TodoRepository.swift
//

import Foundation
import Combine

typealias TodoData = Todo

protocol TodoRepository {
    var todosPublisher: AnyPublisher<[Todo], Never> { get }

    func fetchTodos() async throws -> [Todo]
    func fetchTodo(by id: UUID) async throws -> Todo?
    func createTodo(_ todo: Todo) async throws -> Todo
    func updateTodo(_ todo: Todo) async throws -> Todo
    func deleteTodo(by id: UUID) async throws
}

class TodoRepositoryImpl: TodoRepository {
    @Published private(set) var todosDict: [UUID: Todo] = [:]
    var todosPublisher: AnyPublisher<[Todo], Never> {
            $todosDict
            .map { Array($0.values) }
            .eraseToAnyPublisher()
        }

    private let todoService: TodoService

    init(todoService: TodoService) {
        self.todoService = todoService
    }

    private func mapError(_ error: Error) -> TodoError {
        switch error {
        case let networkError as NetworkError:
            return .network(networkError)
        case is DecodingError:
            return .invalidData
        default:
            return .genericError(error.localizedDescription)
        }
    }

    func fetchTodos() async throws -> [Todo] {
        do {
            let todos = try await self.todoService.fetchTodos()
            await MainActor.run {
                self.todosDict = Dictionary(uniqueKeysWithValues: todos.map { ($0.id, $0) })
            }
            return todos
        } catch {
            throw mapError(error)
        }
    }

    func fetchTodo(by id: UUID) async throws -> Todo? {
        if let cachedTodo = todosDict[id] {
            return cachedTodo
        }

        do {
            if let todo = try await todoService.fetchTodo(id) {
                await MainActor.run {
                    self.todosDict[todo.id] = todo
                }
                return todo
            }

            return nil
        } catch {
            throw mapError(error)
        }
    }

    func createTodo(_ todo: Todo) async throws -> Todo {
        let createdTodo = try await todoService.createTodo(todo)
        await MainActor.run {
            self.todosDict[createdTodo.id] = createdTodo
        }
        return createdTodo
    }

    func updateTodo(_ todo: Todo) async throws -> Todo {
        let updatedTodo = try await todoService.updateTodo(todo)
        await MainActor.run {
            self.todosDict[updatedTodo.id] = updatedTodo
        }
        return updatedTodo
    }

    func deleteTodo(by id: UUID) async throws {
        do {
            try await todoService.deleteTodo(id: id)
            await MainActor.run {
                _ = self.todosDict.removeValue(forKey: id)
            }
        } catch {
            throw mapError(error)
        }
    }
}
