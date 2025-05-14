//
//  Observable.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 14.05.2025.
//

final class Observable<T> {
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    private var listener: ((T) -> Void)?
    
    init(_ value: T) {
        self.value = value
    }
    
    func bind(_ listener: @escaping (T) -> Void) {
        self.listener = listener
        listener(value)
    }
    
}
