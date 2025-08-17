import SwiftUI
import SwiftUIBloc

// MARK: - Counter State
struct CounterState: Equatable {
    let count: Int
    let isLoading: Bool
    
    init(count: Int = 0, isLoading: Bool = false) {
        self.count = count
        self.isLoading = isLoading
    }
}

// MARK: - Counter Cubit
@MainActor
final class CounterCubit: Cubit<CounterState> {
    
    init() {
        super.init(initialState: CounterState())
    }
    
    // MARK: - Business Logic Methods
    
    /// Increment the counter
    func increment() {
        let currentCount = state.count
        emit(CounterState(count: currentCount + 1))
    }
    
    /// Decrement the counter
    func decrement() {
        let currentCount = state.count
        emit(CounterState(count: currentCount - 1))
    }
    
    /// Reset counter to zero
    func reset() {
        emit(CounterState(count: 0))
    }
    
    /// Simulate async operation
    func incrementAsync() async {
        emit(CounterState(count: state.count, isLoading: true))
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        emit(CounterState(count: state.count + 10, isLoading: false))
    }
    
    /// Override onChange to log state changes
    override func onChange(_ change: Change<CounterState>) {
        print("Counter changed from \(change.currentState.count) to \(change.nextState.count)")
    }
    
    /// Override onError to handle errors
    override func onError(_ error: Error) {
        print("Counter error: \(error)")
        // Reset loading state on error
        emit(CounterState(count: state.count, isLoading: false))
    }
}

// MARK: - Counter View
struct CounterView: View {
    var body: some View {
        BlocProvider(create: { CounterCubit() }) {
            CounterContent()
        }
    }
}

private struct CounterContent: View {
    @EnvironmentObject private var cubit: CounterCubit
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Cubit Counter Example")
                .font(.title)
                .fontWeight(.bold)
            
            BlocBuilder<CounterCubit, CounterState, AnyView> { (state: CounterState) in
                AnyView(VStack(spacing: 36) {
                    // Counter Display
                    Text("\(state.count)")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )
                    
                    // Loading Indicator
                    if state.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    }
                    
                    // Button Controls
                    VStack(spacing: 30) {
                        HStack(spacing: 16) {
                            Button(action: { cubit.decrement() }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .disabled(state.isLoading)
                            
                            Button(action: { cubit.increment() }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            .disabled(state.isLoading)
                        }
                        
                        HStack(spacing: 16) {
                            Button("Reset") {
                                cubit.reset()
                            }
                            .buttonStyle(.bordered)
                            .disabled(state.isLoading)
                            
                            Button("Async +10") {
                                Task {
                                    await cubit.incrementAsync()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(state.isLoading)
                        }
                    }
                })
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    CounterView()
}
