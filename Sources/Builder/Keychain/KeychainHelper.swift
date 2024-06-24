import Foundation
import LocalAuthentication
import Security
import Logger

let keychainService = "OpenAI"
let keychainAccount = "API_KEY"
var cachedAPIKey: String?
var cacheExpiryDate: Date?

public func getAPIKeyFromKeychain() -> String? {
    if let cachedKey = cachedAPIKey, let expiryDate = cacheExpiryDate, expiryDate > Date() {
        return cachedKey
    }

    let context = LAContext()
    context.localizedReason = "Authentifizieren Sie sich, um auf das Schlüsselbund-Element zuzugreifen"

    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        print("Touch ID/Face ID nicht verfügbar: \(String(describing: error?.localizedDescription))")
        return nil
    }

    let reason = "Authentifizieren Sie sich, um auf das Schlüsselbund-Element zuzugreifen"
    var apiKey: String?

    let semaphore = DispatchSemaphore(value: 0)
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
        if success {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecReturnData as String: true,
                kSecUseAuthenticationContext as String: context
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            if status == errSecSuccess {
                if let data = item as? Data, let passwordString = String(data: data, encoding: .utf8) {
                    apiKey = passwordString
                    cachedAPIKey = passwordString
                    cacheExpiryDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) // Setzt Cache-Ablauf auf 10 Minuten
                }
            } else {
                print("Fehler beim Abrufen des Schlüssels: \(status)")
            }
        } else {
            print("Authentifizierung fehlgeschlagen: \(String(describing: authenticationError?.localizedDescription))")
        }
        semaphore.signal()
    }

    _ = semaphore.wait(timeout: .distantFuture)
    return apiKey
}

public func setAPIKeyInKeychain(apiKey: String) -> Bool {
    guard let accessControl = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        .userPresence,
        nil
    ) else {
        print("Fehler beim Erstellen der Zugriffskontrolle")
        return false
    }

    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService,
        kSecAttrAccount as String: keychainAccount,
    ]

    let attributes: [String: Any] = [
        kSecValueData as String: apiKey.data(using: .utf8)!,
        kSecAttrAccessControl as String: accessControl as Any,
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    if status == errSecSuccess {
        cachedAPIKey = apiKey
        cacheExpiryDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())
        return true
    } else if status == errSecItemNotFound {
        var newItem = query
        newItem[kSecValueData as String] = apiKey.data(using: .utf8)
        newItem[kSecAttrAccessControl as String] = accessControl

        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        if addStatus == errSecSuccess {
            cachedAPIKey = apiKey
            cacheExpiryDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())
            return true
        } else {
            print("Fehler beim Speichern des Schlüssels: \(addStatus)")
            return false
        }
    } else {
        print("Fehler beim Speichern des Schlüssels: \(status)")
        return false
    }
}

public func deleteAPIKeyFromKeychain() -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService,
        kSecAttrAccount as String: keychainAccount
    ]

    let status = SecItemDelete(query as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound {
        cachedAPIKey = nil
        cacheExpiryDate = nil
        print("API-Schlüssel erfolgreich aus dem Schlüsselbund gelöscht.")
        return true
    } else {
        print("Fehler beim Löschen des Schlüssels: \(status)")
        return false
    }
}

public func promptForAPIKey() -> String? {
    print("Bitte geben Sie Ihren OpenAI API-Schlüssel ein:")
    if let apiKey = readLine(), !apiKey.isEmpty {
        return apiKey
    } else {
        print("Ungültiger API-Schlüssel eingegeben.")
        return nil
    }
}

public func initAPIKey() {
    guard let apiKey = promptForAPIKey() else {
        fancyLog(level: .error, message: "Fehler beim Abrufen des API-Schlüssels.")
        exit(1)
    }

    if !setAPIKeyInKeychain(apiKey: apiKey) {
        fancyLog(level: .error, message: "Fehler beim Speichern des API-Schlüssels im Schlüsselbund.")
        exit(1)
    }

    fancyLog(level: .success, message: "API-Schlüssel erfolgreich im Schlüsselbund gespeichert!")
}
