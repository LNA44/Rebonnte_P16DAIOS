//
//  Extensions.swift
//  MediStock
//
//  Created by Ordinateur elena on 10/11/2025.
//

import Foundation
import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
