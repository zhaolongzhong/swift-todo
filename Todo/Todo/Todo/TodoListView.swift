//
//  TodoListView.swift
//

import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var todoViewModel: TodoViewModel

    var body: some View {
        ZStack {
            VStack {
                TodoListContentView(
                    todos: todoViewModel.state.todos,
                    toggleTodo: todoViewModel.actionHandler.toggleTodo,
                    deleteTodo: todoViewModel.actionHandler.deleteTodo,
                    fetchTodo: todoViewModel.actionHandler.fetchTodo
                )

                ControlView(
                    fetchTodos: todoViewModel.actionHandler.fetchTodos,
                    reorderTasks: todoViewModel.reorderTodos
                )

                TaskInputView(
                    newTaskTitle: todoViewModel.state.newTaskTitle,
                    onTitleChange: todoViewModel.setNewTaskTitle,
                    addTask: todoViewModel.actionHandler.addTodo
                )
            }

            if todoViewModel.state.isLoading {
                LoadingView()
            }

            if let error = todoViewModel.state.error {
                ErrorAlert(
                    error: error,
                    onDismiss: { todoViewModel.dismissError() }
                )
            }
        }
        .onAppear {
            Task {
                await todoViewModel.dispatch(TodoAction.fetchTodos)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ProgressView("Loading...")
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}

struct ErrorAlert: View {
    let error: TodoError
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: 0.5)
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 12) {
                Text(error.errorMessage)
                    .font(.system(.body))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Divider()

                Button(action: onDismiss) {
                    Text("OK")
                        .font(.system(.body, design: .default))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            #if os(iOS)
            .background(Color(UIColor.systemBackground))
            #else
            .background(Color(NSColor.windowBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 40)
            .frame(maxWidth: 300)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity)
        .zIndex(2)
    }
}

struct TodoListContentView: View {
    let todos: [Todo]
    let toggleTodo: (_ id: UUID) -> Void
    let deleteTodo: (_ id: UUID) -> Void
    let fetchTodo: (_ id: UUID) -> Void

    var body: some View {
        #if DEBUG
        print("TodoListContentView draw")
        #endif
        return List {
            ForEach(todos) { todo in
                TaskRowView(
                    todo: todo,
                    toggleTodo: toggleTodo,
                    deleteTodo: deleteTodo,
                    fetchTodo: fetchTodo
                )
            }
        }
    }
}

struct ControlView: View {
    let fetchTodos: () -> Void
    let reorderTasks: () -> Void

    var body: some View {
        #if DEBUG
        print("ControlView draw")
        #endif
        return HStack {
            Button("Fetch") {
                fetchTodos()
            }
            Button("Reorder") {
                reorderTasks()
            }
        }
    }
}

struct TaskRowView: View {
    let todo: Todo
    let toggleTodo: (_ id: UUID) -> Void
    let deleteTodo: (_ id: UUID) -> Void
    let fetchTodo: (_ id: UUID) -> Void

    var body: some View {
        #if DEBUG
        print("TaskRowView draw: \(todo.id)")
        #endif
        return HStack {
            Text(todo.title)
            Spacer()
            Toggle("", isOn: Binding(
                get: { todo.completed },
                set: { _ in toggleTodo(todo.id) }
            ))
            Button("Delete") {
                deleteTodo(todo.id)
            }
            Button("Fetch") {
                fetchTodo(todo.id)
            }
        }
    }
}

struct TaskInputView: View {
    let newTaskTitle: String
    let onTitleChange: (String) -> Void
    let addTask: () -> Void

    var body: some View {
        #if DEBUG
        print("TaskInputView draw")
        #endif
        return HStack {
            TextField("Type a task name", text: Binding(
                get: { newTaskTitle },
                set: { onTitleChange($0) }
            ))
            Button("Add") {
                addTask()
            }
            .disabled(newTaskTitle.isEmpty)
        }
        .padding()
    }
}
