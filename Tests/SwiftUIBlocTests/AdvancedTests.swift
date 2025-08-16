//
//  AdvancedTests.swift
//  SwiftBlocTests
//
//  Created by Cửu Long Hoàng on 15/8/25.
//

import Testing
@preconcurrency import Combine
import Foundation
@testable import SwiftUIBloc

// MARK: - Advanced Test Models

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded([String])
    case error(String)
}

enum DataEvent {
    case load
    case reload
    case clear
    case simulateError
}

class DataBloc: Bloc<DataEvent, LoadingState> {
    init() {
        super.init(initialState: .idle)
    }
    
    override func mapEventToState(event: DataEvent) throws -> LoadingState {
        switch event {
        case .load:
            if case .loading = state {
                return state // Already loading
            }
            return .loading
        case .reload:
            return .loading
        case .clear:
            return .idle
        case .simulateError:
            throw NetworkError.connectionFailed
        }
    }
    
    override func onTransition(_ transition: Transition<DataEvent, LoadingState>) {
        super.onTransition(transition)
        
        // Simulate async loading
        if case .loading = transition.nextState {
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                switch transition.event {
                case .load, .reload:
                    emit(.loaded(["Item 1", "Item 2", "Item 3"]))
                default:
                    break
                }
            }
        }
    }
}

enum NetworkError: Error, Equatable {
    case connectionFailed
    case unauthorized
    case notFound
    case serverError(Int)
}

// MARK: - Complex State Management

struct MultiLayerState: Equatable {
    let user: UserState
    let settings: SettingsState
    let notifications: NotificationState
}

struct UserState: Equatable {
    let id: String?
    let name: String
    let isLoggedIn: Bool
}

struct SettingsState: Equatable {
    let theme: String
    let notifications: Bool
    let language: String
}

struct NotificationState: Equatable {
    let unreadCount: Int
    let lastRead: Date?
}

class AppCubit: Cubit<MultiLayerState> {
    init() {
        let initialState = MultiLayerState(
            user: UserState(id: nil, name: "", isLoggedIn: false),
            settings: SettingsState(theme: "light", notifications: true, language: "en"),
            notifications: NotificationState(unreadCount: 0, lastRead: nil)
        )
        super.init(initialState: initialState)
    }
    
    func login(userId: String, name: String) {
        let newUser = UserState(id: userId, name: name, isLoggedIn: true)
        let newState = MultiLayerState(
            user: newUser,
            settings: state.settings,
            notifications: state.notifications
        )
        emit(newState)
    }
    
    func logout() {
        let newUser = UserState(id: nil, name: "", isLoggedIn: false)
        let newState = MultiLayerState(
            user: newUser,
            settings: state.settings,
            notifications: state.notifications
        )
        emit(newState)
    }
    
    func updateTheme(_ theme: String) {
        let newSettings = SettingsState(
            theme: theme,
            notifications: state.settings.notifications,
            language: state.settings.language
        )
        let newState = MultiLayerState(
            user: state.user,
            settings: newSettings,
            notifications: state.notifications
        )
        emit(newState)
    }
    
    func markNotificationAsRead() {
        let newNotifications = NotificationState(
            unreadCount: max(0, state.notifications.unreadCount - 1),
            lastRead: Date()
        )
        let newState = MultiLayerState(
            user: state.user,
            settings: state.settings,
            notifications: newNotifications
        )
        emit(newState)
    }
}

// MARK: - Advanced Tests

struct AdvancedTests {
    
    // MARK: - Async Data Loading Tests
    
    @Test func testAsyncDataLoading() async throws {
        let bloc = await DataBloc()
        var stateHistory: [LoadingState] = []
        
        let cancellable = await bloc.$state.sink { state in
            stateHistory.append(state)
        }
        
        // Start loading
        await bloc.add(event: .load)
        
        // Wait for loading state
        try await Task.sleep(nanoseconds: 25_000_000)
        #expect(stateHistory.contains(.loading))
        
        // Wait longer for the async loaded state (DataBloc sleeps 50ms + some buffer)
        try await Task.sleep(nanoseconds: 150_000_000)
        
        let loadedStates = stateHistory.compactMap { state in
            if case .loaded(let items) = state {
                return items
            }
            return nil
        }
        
        #expect(!loadedStates.isEmpty)
        #expect(loadedStates.first?.count == 3)
        
        cancellable.cancel()
    }
    
    @Test func testDataBlocReload() async throws {
        let bloc = await DataBloc()
        var loadingStates = 0
        var loadedStates = 0
        
        let cancellable = await bloc.$state.sink { state in
            switch state {
            case .loading:
                loadingStates += 1
            case .loaded:
                loadedStates += 1
            default:
                break
            }
        }
        
        // Load and reload
        await bloc.add(event: .load)
        try await Task.sleep(nanoseconds: 150_000_000)
        
        await bloc.add(event: .reload)
        try await Task.sleep(nanoseconds: 150_000_000)
        
        #expect(loadingStates == 2)
        #expect(loadedStates == 2)
        
        cancellable.cancel()
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testBlocErrorHandling() async throws {
        let _ = await DataBloc()
        
        actor ErrorCapture {
            private(set) var capturedError: Error?
            
            func capture(_ error: Error) {
                capturedError = error
            }
        }
        
        let errorCapture = ErrorCapture()
        
        @MainActor
        class TestDataBloc: DataBloc {
            var errorCallback: ((Error) -> Void)?
            
            override func onError(_ error: Error) {
                errorCallback?(error)
                super.onError(error)
            }
        }
        
        let testBloc = await TestDataBloc()
        await MainActor.run {
            testBloc.errorCallback = { @Sendable error in
                Task {
                    await errorCapture.capture(error)
                }
            }
        }
        
        await testBloc.add(event: .simulateError)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let capturedError = await errorCapture.capturedError
        #expect(capturedError != nil)
        if let networkError = capturedError as? NetworkError {
            #expect(networkError == .connectionFailed)
        }
    }
    
    // MARK: - Complex State Management Tests
    
    @Test func testMultiLayerStateManagement() async throws {
        let appCubit = await AppCubit()
        
        // Initial state checks
        #expect(!(await appCubit.state.user.isLoggedIn))
        #expect(await appCubit.state.settings.theme == "light")
        #expect(await appCubit.state.notifications.unreadCount == 0)
        
        // Login
        await appCubit.login(userId: "123", name: "John Doe")
        #expect(await appCubit.state.user.isLoggedIn)
        #expect(await appCubit.state.user.id == "123")
        #expect(await appCubit.state.user.name == "John Doe")
        
        // Change theme
        await appCubit.updateTheme("dark")
        #expect(await appCubit.state.settings.theme == "dark")
        #expect(await appCubit.state.user.isLoggedIn) // Should remain logged in
        
        // Handle notification
        await appCubit.markNotificationAsRead()
        #expect(await appCubit.state.notifications.lastRead != nil)
        
        // Logout
        await appCubit.logout()
        #expect(!(await appCubit.state.user.isLoggedIn))
        #expect(await appCubit.state.user.id == nil)
        #expect(await appCubit.state.settings.theme == "dark") // Should remain dark
    }
    
    @Test func testComplexStateTransitions() async throws {
        let appCubit = await AppCubit()
        var stateTransitions: [String] = []
        
        let cancellable = await appCubit.$state.sink { state in
            let description = "User: \(state.user.isLoggedIn ? "logged in" : "logged out"), Theme: \(state.settings.theme), Notifications: \(state.notifications.unreadCount)"
            stateTransitions.append(description)
        }
        
        await appCubit.login(userId: "123", name: "John")
        await appCubit.updateTheme("dark")
        await appCubit.markNotificationAsRead()
        await appCubit.logout()
        
        try await Task.sleep(nanoseconds: 50_000_000)
        
        #expect(stateTransitions.count == 5) // initial + 4 changes
        #expect(stateTransitions.first?.contains("logged out") == true)
        #expect(stateTransitions.last?.contains("logged out") == true)
        #expect(stateTransitions.last?.contains("dark") == true)
        
        cancellable.cancel()
    }
    
    // MARK: - Memory Management Tests
    
    @Test func testBlocMemoryCleanup() async throws {
        var bloc: DataBloc? = await DataBloc()
        weak var weakBloc = bloc
        
        #expect(weakBloc != nil)
        
        bloc = nil
        
        // Allow some time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(weakBloc == nil)
    }
    
    @Test func testCubitMemoryCleanup() async throws {
        var cubit: AppCubit? = await AppCubit()
        weak var weakCubit = cubit
        
        #expect(weakCubit != nil)
        
        cubit = nil
        
        // Allow some time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(weakCubit == nil)
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test func testConcurrentAccess() async throws {
        let cubit = await AppCubit()
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent operations
            for i in 0..<10 {
                group.addTask {
                    if i % 2 == 0 {
                        await cubit.updateTheme(i % 3 == 0 ? "dark" : "light")
                    } else {
                        await cubit.markNotificationAsRead()
                    }
                }
            }
        }
        
        // Should not crash and should have consistent final state
        let finalTheme = await cubit.state.settings.theme
        let unreadCount = await cubit.state.notifications.unreadCount
        #expect(finalTheme == "dark" || finalTheme == "light")
        #expect(unreadCount >= 0)
    }
    
    // MARK: - State Consistency Tests
    
    @Test func testStateConsistency() async throws {
        let cubit = await AppCubit()
        var inconsistentStates = 0
        
        let cancellable = await cubit.$state.sink { state in
            // Check that state is always consistent
            if state.user.isLoggedIn && state.user.id == nil {
                inconsistentStates += 1
            }
            if state.notifications.unreadCount < 0 {
                inconsistentStates += 1
            }
        }
        
        // Perform various operations
        await cubit.login(userId: "123", name: "John")
        await cubit.markNotificationAsRead()
        await cubit.markNotificationAsRead()
        await cubit.updateTheme("dark")
        await cubit.logout()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(inconsistentStates == 0)
        
        cancellable.cancel()
    }
    
    // MARK: - Performance Tests
    
    @Test func testPerformanceWithManyStateChanges() async throws {
        let cubit = await CounterCubit()
        let startTime = Date()
        
        for _ in 0..<1000 {
            await cubit.increment()
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(await cubit.state == 1000)
        #expect(duration < 1.0) // Should complete in less than 1 second
    }
}
