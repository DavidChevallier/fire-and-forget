//
//  BuilderTests.swift
//
//
//  Created by David Chevallier on 23.06.2024.
//

import Foundation
import XCTest
@testable import Builder
import Logger
import KeychainHelper
import Yams

class BuilderTests: XCTestCase {

    // Teste, ob die Commit-Nachricht korrekt generiert wird
    func testGenerateCommitMessage() {
        let diff = """
        diff --git a/file.swift b/file.swift
        new file mode 100644
        index 0000000..e69de29
        """
        let file = "file.swift"
        let commitMessage = generateCommitMessage(diff: diff, file: file)
        XCTAssertNotNil(commitMessage, "Die Commit-Nachricht sollte nicht nil sein")
    }

    // Teste, ob geänderte Dateien korrekt abgerufen werden
    func testGetChangedFiles() {
        let files = getChangedFiles()
        XCTAssertNotNil(files, "Die Liste der geänderten Dateien sollte nicht nil sein")
    }

    // Teste, ob die Diff-Ausgabe korrekt abgerufen wird
    func testGetDiff() {
        let diff = getDiff(for: "file.swift")
        XCTAssertNotNil(diff, "Die Diff-Ausgabe sollte nicht nil sein")
    }

    // Teste, ob eine Datei korrekt committet wird
    func testCommitFile() {
        let result = commitFile(file: "file.swift", message: "Test commit message")
        XCTAssertTrue(result, "Die Datei sollte erfolgreich committet werden")
    }

    // Teste, ob Änderungen korrekt committet werden
    func testCommitChanges() {
        let result = commitChanges()
        XCTAssertTrue(result, "Die Änderungen sollten erfolgreich committet werden")
    }

    // Teste, ob der API-Schlüssel korrekt aus dem Schlüsselbund abgerufen wird
    func testGetAPIKeyFromKeychain() {
        let apiKey = getAPIKeyFromKeychain()
        XCTAssertNotNil(apiKey, "Der API-Schlüssel sollte nicht nil sein")
    }

    // Teste, ob der API-Schlüssel korrekt im Schlüsselbund gespeichert wird
    func testSetAPIKeyInKeychain() {
        let result = setAPIKeyInKeychain(apiKey: "test_api_key")
        XCTAssertTrue(result, "Der API-Schlüssel sollte erfolgreich im Schlüsselbund gespeichert werden")
    }

    // Teste, ob der Benutzer erfolgreich zur Eingabe des API-Schlüssels aufgefordert wird
    func testPromptForAPIKey() {
        // Dieser Test ist schwer zu automatisieren, da er Benutzereingaben erfordert
        // Du kannst stattdessen eine Mock-Funktion oder einen Stubbing-Mechanismus verwenden
        let apiKey = promptForAPIKey()
        XCTAssertNotNil(apiKey, "Der API-Schlüssel sollte nicht nil sein")
    }

    // Teste, ob die Init-Funktion für den API-Schlüssel korrekt funktioniert
    func testInitAPIKey() {
        // Hier kann eine Mock-Funktion oder ein Stubbing-Mechanismus verwendet werden
        initAPIKey()
        let apiKey = getAPIKeyFromKeychain()
        XCTAssertNotNil(apiKey, "Der API-Schlüssel sollte nach der Initialisierung nicht nil sein")
    }
}
