//
//  AppError.swift
//  MediStock
//
//  Created by Ordinateur elena on 21/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

enum AppError: Error, Identifiable {
    var id: String { localizedDescription }

    case noPermission
    case noData
    case serverUnavailable
    case cancelled
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case unknown

    // Message lisible pour l'utilisateur
    var userMessage: String {
        switch self {
        case .noPermission:
            return "You do not have the required permissions."
        case .noData:
            return "No data is available at the moment."
        case .serverUnavailable:
            return "The server is temporarily unavailable. Please try again later."
        case .cancelled:
            return "The connection was interrupted."
        case .emailAlreadyInUse: 
            return "This email is already in use."
        case .userNotFound:
            return "No user found with this email."
        case .wrongPassword:
            return "The password is incorrect."
        case .unknown:
            return "An error occurred. Please try again."
        }
    }
}

// Créer un AppError à partir d'une erreur Firebase pour erreurs de AisleListView
extension AppError {
    static func fromFirestore(_ error: Error) -> AppError {
        let nsError = error as NSError
        switch nsError.code {
        case FirestoreErrorCode.permissionDenied.rawValue:
            return .noPermission
        case FirestoreErrorCode.notFound.rawValue:
            return .noData
        case FirestoreErrorCode.unavailable.rawValue:
            return .serverUnavailable
        case FirestoreErrorCode.cancelled.rawValue:
            return .cancelled
        default:
            return .unknown
        }
    }
}

extension AppError {
        static func fromAuth(_ error: Error) -> AppError {
            let nsError = error as NSError
            switch nsError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return .emailAlreadyInUse
            case AuthErrorCode.userNotFound.rawValue:
                return .userNotFound
            case AuthErrorCode.wrongPassword.rawValue:
                return .wrongPassword
            default:
                return .unknown
            }
        }
    }
