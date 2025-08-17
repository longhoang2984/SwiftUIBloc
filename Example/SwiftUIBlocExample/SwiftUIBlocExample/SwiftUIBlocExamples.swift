import SwiftUI
import SwiftUIBloc

// MARK: - Main Examples View

/// Main entry point showcasing both Cubit and Bloc examples
public struct SwiftUIBlocExamples: View {
    public init() {}
    
    public var body: some View {
        NavigationView {
            ExamplesList()
        }
    }
}

private struct ExamplesList: View {
    var body: some View {
        List {
            Section {
                Text("SwiftUIBloc provides two main approaches for state management:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("About")
            }
            
            Section {
                NavigationLink(destination: CounterView()) {
                    ExampleRow(
                        title: "Counter (Cubit)",
                        description: "Simple function-based state management",
                        icon: "plus.slash.minus",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: TodoView()) {
                    ExampleRow(
                        title: "Todo List (Bloc)",
                        description: "Event-driven architecture with complex state",
                        icon: "checklist",
                        color: .green
                    )
                }
            } header: {
                Text("Examples")
            }
            
            Section {
                ExampleFeature(
                    title: "Cubit Features",
                    features: [
                        "Simple emit() function",
                        "Direct state updates",
                        "Perfect for simple state",
                        "Less boilerplate"
                    ]
                )
                
                ExampleFeature(
                    title: "Bloc Features",
                    features: [
                        "Event-driven architecture",
                        "Complex business logic",
                        "State transitions",
                        "Better for complex flows"
                    ]
                )
            } header: {
                Text("Comparison")
            }
            
            Section {
                Link("SwiftUIBloc Documentation", destination: URL(string: "https://github.com/your-repo/SwiftUIBloc")!)
                    .foregroundColor(.blue)
                
                Link("Flutter BLoC Pattern", destination: URL(string: "https://bloclibrary.dev/")!)
                    .foregroundColor(.blue)
            } header: {
                Text("Resources")
            }
        }
        .navigationTitle("SwiftUIBloc Examples")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Example Row Component

private struct ExampleRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Example Feature Component

private struct ExampleFeature: View {
    let title: String
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(feature)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Example Usage Documentation

/// # SwiftUIBloc Examples
///
/// This module demonstrates the usage of SwiftUIBloc library with practical examples.
///
/// ## Getting Started
///
/// ```swift
/// import SwiftUI
/// import SwiftUIBloc
///
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             SwiftUIBlocExamples()
///         }
///     }
/// }
/// ```
///
/// ## Cubit Example - Counter
///
/// The Counter example shows how to use a Cubit for simple state management:
///
/// ```swift
/// // Define your state
/// struct CounterState: Equatable {
///     let count: Int
/// }
///
/// // Create your Cubit
/// class CounterCubit: Cubit<CounterState> {
///     init() {
///         super.init(initialState: CounterState(count: 0))
///     }
///
///     func increment() {
///         emit(CounterState(count: state.count + 1))
///     }
/// }
///
/// // Use in SwiftUI
/// struct CounterView: View {
///     var body: some View {
///         BlocProvider(create: { CounterCubit() }) {
///             BlocBuilder<CounterCubit, CounterState> { state in
///                 Text("\(state.count)")
///             }
///         }
///     }
/// }
/// ```
///
/// ## Bloc Example - Todo List
///
/// The Todo example demonstrates event-driven architecture:
///
/// ```swift
/// // Define your events
/// enum TodoEvent {
///     case addTodo(String)
///     case toggleTodo(UUID)
/// }
///
/// // Define your state
/// struct TodoState: Equatable {
///     let todos: [Todo]
/// }
///
/// // Create your Bloc
/// class TodoBloc: Bloc<TodoEvent, TodoState> {
///     override func mapEventToState(event: TodoEvent) throws -> TodoState {
///         switch event {
///         case .addTodo(let title):
///             let newTodo = Todo(title: title)
///             return TodoState(todos: state.todos + [newTodo])
///         // ... handle other events
///         }
///     }
/// }
/// ```
///
/// ## Key Concepts
///
/// - **BlocProvider**: Provides Bloc/Cubit instances to the widget tree
/// - **BlocBuilder**: Rebuilds UI when state changes
/// - **BlocListener**: Performs side effects when state changes
/// - **BlocConsumer**: Combines BlocBuilder and BlocListener
///
/// ## When to Use What
///
/// ### Use Cubit When:
/// - Simple state management
/// - Direct state updates
/// - Limited business logic
/// - Rapid prototyping
///
/// ### Use Bloc When:
/// - Complex business logic
/// - Event-driven architecture
/// - Need to track state transitions
/// - Multiple ways to update state

// MARK: - Preview

#Preview {
    SwiftUIBlocExamples()
}
