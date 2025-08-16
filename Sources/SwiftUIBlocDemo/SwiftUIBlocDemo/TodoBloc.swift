import SwiftUI
import SwiftUIBloc

// MARK: - Todo Models

struct Todo: Identifiable, Equatable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let createdAt: Date
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
    
    func copy(title: String? = nil, isCompleted: Bool? = nil) -> Todo {
        Todo(id: self.id, title: title ?? self.title, isCompleted: isCompleted ?? self.isCompleted, createdAt: self.createdAt)
    }
    
    private init(id: UUID, title: String, isCompleted: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

enum TodoFilter: CaseIterable {
    case all
    case active
    case completed
    
    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Todo State

struct TodoState: Equatable {
    let todos: [Todo]
    let filter: TodoFilter
    let isLoading: Bool
    let error: String?
    
    init(todos: [Todo] = [], filter: TodoFilter = .all, isLoading: Bool = false, error: String? = nil) {
        self.todos = todos
        self.filter = filter
        self.isLoading = isLoading
        self.error = error
    }
    
    var filteredTodos: [Todo] {
        switch filter {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.isCompleted }
        case .completed:
            return todos.filter { $0.isCompleted }
        }
    }
    
    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }
    
    var activeCount: Int {
        todos.filter { !$0.isCompleted }.count
    }
}

// MARK: - Todo Events

enum TodoEvent {
    case loadTodos
    case addTodo(title: String)
    case toggleTodo(id: UUID)
    case deleteTodo(id: UUID)
    case editTodo(id: UUID, title: String)
    case clearCompleted
    case toggleAll
    case setFilter(TodoFilter)
}

// MARK: - Todo Bloc

@MainActor
final class TodoBloc: Bloc<TodoEvent, TodoState> {
    
    init() {
        super.init(initialState: TodoState())
        // Load initial todos
        add(event: .loadTodos)
    }
    
    override func mapEventToState(event: TodoEvent) throws -> TodoState {
        switch event {
        case .loadTodos:
            return handleLoadTodos()
            
        case .addTodo(let title):
            return handleAddTodo(title: title)
            
        case .toggleTodo(let id):
            return handleToggleTodo(id: id)
            
        case .deleteTodo(let id):
            return handleDeleteTodo(id: id)
            
        case .editTodo(let id, let title):
            return handleEditTodo(id: id, title: title)
            
        case .clearCompleted:
            return handleClearCompleted()
            
        case .toggleAll:
            return handleToggleAll()
            
        case .setFilter(let filter):
            return handleSetFilter(filter: filter)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleLoadTodos() -> TodoState {
        // Simulate loading some initial todos
        let initialTodos = [
            Todo(title: "Learn SwiftUI"),
            Todo(title: "Implement BLoC pattern"),
            Todo(title: "Build awesome apps", isCompleted: true)
        ]
        
        return TodoState(todos: initialTodos)
    }
    
    private func handleAddTodo(title: String) -> TodoState {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TodoState(todos: state.todos, filter: state.filter, error: "Todo title cannot be empty")
        }
        
        let newTodo = Todo(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        let updatedTodos = state.todos + [newTodo]
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleToggleTodo(id: UUID) -> TodoState {
        let updatedTodos = state.todos.map { todo in
            todo.id == id ? todo.copy(isCompleted: !todo.isCompleted) : todo
        }
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleDeleteTodo(id: UUID) -> TodoState {
        let updatedTodos = state.todos.filter { $0.id != id }
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleEditTodo(id: UUID, title: String) -> TodoState {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TodoState(todos: state.todos, filter: state.filter, error: "Todo title cannot be empty")
        }
        
        let updatedTodos = state.todos.map { todo in
            todo.id == id ? todo.copy(title: title.trimmingCharacters(in: .whitespacesAndNewlines)) : todo
        }
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleClearCompleted() -> TodoState {
        let updatedTodos = state.todos.filter { !$0.isCompleted }
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleToggleAll() -> TodoState {
        let hasIncomplete = state.todos.contains { !$0.isCompleted }
        let updatedTodos = state.todos.map { todo in
            todo.copy(isCompleted: hasIncomplete)
        }
        
        return TodoState(todos: updatedTodos, filter: state.filter)
    }
    
    private func handleSetFilter(filter: TodoFilter) -> TodoState {
        return TodoState(todos: state.todos, filter: filter)
    }
    
    // MARK: - Bloc Overrides
    override func onTransition(_ transition: Transition<TodoEvent, TodoState>) {
        print("Todo Transition: \(transition.event) -> \(transition.nextState.todos.count) todos")
    }
    
    override func onError(_ error: Error) {
        print("Todo error: \(error)")
        emit(TodoState(todos: state.todos, filter: state.filter, error: error.localizedDescription))
    }
}

// MARK: - Todo View

struct TodoView: View {
    var body: some View {
        BlocProvider(create: { TodoBloc() }) {
            TodoContent()
        }
    }
}

private struct TodoContent: View {
    @EnvironmentObject private var bloc: TodoBloc
    @State private var newTodoText: String = ""
    @State private var editingTodo: Todo?
    @State private var editText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                BlocBuilder<TodoBloc, TodoState> { state in
                    VStack(spacing: 16) {
                        // Header Stats
                        VStack(spacing: 8) {
                            Text("Bloc Todo Example")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack(spacing: 16) {
                                Label("\(state.activeCount)", systemImage: "circle")
                                    .foregroundColor(.blue)
                                
                                Label("\(state.completedCount)", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .font(.caption)
                        }
                        .padding()
                        
                        // Add Todo Input
                        HStack {
                            TextField("Add a new todo...", text: $newTodoText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    addTodo()
                                }
                            
                            Button("Add") {
                                addTodo()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newTodoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.horizontal)
                        
                        // Filter Tabs
                        Picker("Filter", selection: Binding(
                            get: { state.filter },
                            set: { bloc.add(event: .setFilter($0)) }
                        )) {
                            ForEach(TodoFilter.allCases, id: \.self) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Error Display
                        if let error = state.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Todo List
                        List {
                            ForEach(state.filteredTodos) { todo in
                                TodoRow(
                                    todo: todo,
                                    isEditing: editingTodo?.id == todo.id,
                                    editText: $editText,
                                    onToggle: { bloc.add(event: .toggleTodo(id: todo.id)) },
                                    onDelete: { bloc.add(event: .deleteTodo(id: todo.id)) },
                                    onEdit: { startEditing(todo: todo) },
                                    onSaveEdit: { saveEdit(todo: todo) },
                                    onCancelEdit: { cancelEdit() }
                                )
                            }
                        }
                        .listStyle(PlainListStyle())
                        
                        // Bulk Actions
                        if !state.todos.isEmpty {
                            HStack {
                                Button("Toggle All") {
                                    bloc.add(event: .toggleAll)
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                if state.completedCount > 0 {
                                    Button("Clear Completed") {
                                        bloc.add(event: .clearCompleted)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func addTodo() {
        bloc.add(event: .addTodo(title: newTodoText))
        newTodoText = ""
    }
    
    private func startEditing(todo: Todo) {
        editingTodo = todo
        editText = todo.title
    }
    
    private func saveEdit(todo: Todo) {
        bloc.add(event: .editTodo(id: todo.id, title: editText))
        cancelEdit()
    }
    
    private func cancelEdit() {
        editingTodo = nil
        editText = ""
    }
}

// MARK: - Todo Row Component

private struct TodoRow: View {
    let todo: Todo
    let isEditing: Bool
    @Binding var editText: String
    
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    
    var body: some View {
        HStack {
            // Toggle Button
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Title or Edit Field
            if isEditing {
                TextField("Edit todo", text: $editText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onSaveEdit()
                    }
                
                Button("Save") {
                    onSaveEdit()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("Cancel") {
                    onCancelEdit()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .strikethrough(todo.isCompleted)
                        .foregroundColor(todo.isCompleted ? .gray : .primary)
                    
                    Text(todo.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Edit Button
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Delete Button
            if !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TodoView()
}
