//
//  TodoViewModel.swift
//

import Foundation
import SwiftUI
import Combine
import os.log

struct Todo: Equatable, Identifiable {
    let id: UUID
    let title: String
    let completed: Bool
}

enum TodoAction {
    case fetchTodos
    case todosFetched(Result<[Todo], Error>)
    case addTodo
    case toggleTodo(_ id: UUID)
    case updateTodo(_ todo: Todo)
    case deleteTodo(_ id: UUID)
    case setNewTaskTitle(_ newTitle: String)
    case reorder
}

struct TodoListState: Equatable {
    let todos: [Todo]
    let newTaskTitle: String
    let isLoading: Bool
    let error: TodoError?

    init(
        todos: [Todo] = [],
        newTaskTitle: String = "",
        isLoading: Bool = false,
        error: TodoError? = nil
    ) {
        self.todos = todos
        self.newTaskTitle = newTaskTitle
        self.isLoading = isLoading
        self.error = error
    }
}

@MainActor
final class TodoViewModel: ObservableObject {
    @Published private(set) var state: TodoListState

    private let todoRepository: TodoRepository
    private var cancellables = Set<AnyCancellable>()
    private let newTaskTitleSubject = PassthroughSubject<String, Never>()
    private let logger = Logger(subsystem: "TodoApp", category: "TodoViewModel")

    private(set) lazy var actionHandler: TodoActionHandler = {
        #if DEBUG
        print("actionHandler init")
        #endif
        return TodoActionHandler(viewModel: self)
    }()

    init(
        todoRepository: TodoRepository,
        initialState: TodoListState = .init()
    ) {
        self.state = initialState
        self.todoRepository = todoRepository
        setupBindings()
    }

    private func setupBindings() {
        // Repository updates
        todoRepository.todosPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] todos in
                self?.state = self?.state.copy(todos: todos) ?? TodoListState()
            }
            .store(in: &cancellables)

        // New task title debounce
        newTaskTitleSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] title in
                self?.state = self?.state.copy(newTaskTitle: title) ?? TodoListState()
            }
            .store(in: &cancellables)

        // Error logging
        $state
            .dropFirst()
            .sink { [weak self] state in
                if let error = state.error {
                    self?.logger.error("\(error.errorMessage)")
                }
            }
            .store(in: &cancellables)
    }

    func dispatch(_ action: TodoAction) async {
        switch action {
        case .fetchTodos:
            await fetchTodos()
        case .addTodo:
            await addTodo()
        case .toggleTodo(let id):
            await toggleTodo(id)
        case .updateTodo(let todo):
            await updateTodo(todo)
        case .deleteTodo(let id):
            await deleteTodo(id)
        case .setNewTaskTitle(let title):
            setNewTaskTitle(title)
        case .reorder:
            reorderTodos()
        default:
            break
        }
    }

    private func handleError(_ error: Error) {
        let todoError = (error as? TodoError) ?? .genericError(error.localizedDescription)
        state = state.copy(isLoading: false, error: todoError)

        // Auto-dismiss non-critical errors
        if case .fetchFailed = todoError {
            return
        }

        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                if state.error == todoError {  // Only dismiss if it's still the same error
                    state = state.copy(error: nil)
                }
            }
        }
    }

    // MARK: - CRUD Operations

    func fetchTodos() async {
        state = state.copy(isLoading: true, error: nil)
        do {
            let todos = try await todoRepository.fetchTodos()
            state = state.copy(todos: todos, isLoading: false)
        } catch {
            handleError(error)
        }
    }

    func fetchTodo(_ id: UUID) async {
        state = state.copy(isLoading: true, error: nil)
        do {
            let todo = try await todoRepository.fetchTodo(by: id)
            if let todo = todo {
                state = state.copy(
                    todos: state.todos + [todo],
                    newTaskTitle: ""
                )
            }
        } catch {
            handleError(error)
        }
    }

    func addTodo() async {
        guard !state.newTaskTitle.isEmpty else { return }

        let newTodo = Todo(
            id: UUID(),
            title: state.newTaskTitle,
            completed: false
        )

        do {
            let createdTodo = try await todoRepository.createTodo(newTodo)
            state = state.copy(
                todos: state.todos + [createdTodo],
                newTaskTitle: ""
            )
        } catch {
            handleError(error)
        }
    }

    func toggleTodo(_ id: UUID) async {
        guard let todo = state.todos.first(where: { $0.id == id }) else { return }

        let toggledTodo = Todo(
            id: todo.id,
            title: todo.title,
            completed: !todo.completed
        )

        do {
            let updatedTodo = try await todoRepository.updateTodo(toggledTodo)
            let updatedTodos = state.todos.map { $0.id == id ? updatedTodo : $0 }
            state = state.copy(todos: updatedTodos)
        } catch {
            handleError(error)
        }
    }

    func updateTodo(_ todo: Todo) async {
        do {
            let updatedTodo = try await todoRepository.updateTodo(todo)
            let updatedTodos = state.todos.map { $0.id == todo.id ? updatedTodo : $0 }
            state = state.copy(todos: updatedTodos)
        } catch {
            handleError(error)
        }
    }

    func deleteTodo(_ id: UUID) async {
        do {
            try await todoRepository.deleteTodo(by: id)
            let updatedTodos = state.todos.filter { $0.id != id }
            state = state.copy(todos: updatedTodos)
        } catch {
            handleError(error)
        }
    }

    func reorderTodos() {
        let reversedTodos = Array(state.todos.reversed())
        state = state.copy(todos: reversedTodos)
    }

    func setNewTaskTitle(_ title: String) {
        newTaskTitleSubject.send(title)
    }

    func dismissError() {
        state = state.copy(error: nil)
    }
}

extension TodoListState {
    func copy(
        todos: [Todo]? = nil,
        newTaskTitle: String? = nil,
        isLoading: Bool? = nil,
        error: TodoError? = nil
    ) -> TodoListState {
        TodoListState(
            todos: todos ?? self.todos,
            newTaskTitle: newTaskTitle ?? self.newTaskTitle,
            isLoading: isLoading ?? self.isLoading,
            error: error ?? self.error
        )
    }
}
