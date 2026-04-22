import Foundation
import Combine

final class EventBus {
    static let shared = EventBus()
    
    private let eventSubject = PassthroughSubject<AppEvent, Never>()
    
    var events: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    func publish(_ event: AppEvent) {
        eventSubject.send(event)
    }
}
