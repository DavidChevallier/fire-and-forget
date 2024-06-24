import Foundation
import Yams
import Logger
import KeychainHelper

public func commitChanges() -> Bool {
    fancyLog(level: .info, message: "Führe 'git add --all' aus...")
    let processAdd = Process()
    processAdd.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    processAdd.arguments = ["git", "add", "--all"]
    processAdd.launch()
    processAdd.waitUntilExit()

    if processAdd.terminationStatus != 0 {
        fancyLog(level: .error, message: "Fehler beim Ausführen von 'git add --all'.")
        return false
    }

    fancyLog(level: .info, message: "Ermittle geänderte Dateien...")
    let changedFiles = getChangedFiles()
    guard !changedFiles.isEmpty else {
        fancyLog(level: .error, message: "Keine geänderten Dateien gefunden.")
        return false
    }

    var logEntries: [(String, String, String)] = [] // (Datei, Status, Nachricht)

    for file in changedFiles {
        fancyLog(level: .info, message: "Generiere Commit-Nachricht für \(file)...")
        var commitMessage: String?
        for attempt in 1...2 {
            commitMessage = generateCommitMessage(diff: getDiff(for: file), file: file)
            if commitMessage != nil && !commitMessage!.isEmpty {
                break
            }
            if attempt == 2 {
                fancyLog(level: .error, message: "Fehler beim Generieren der Commit-Nachricht nach 2 Versuchen")
                logEntries.append((file, "Fehlgeschlagen", "Fehler beim Generieren der Commit-Nachricht nach 2 Versuchen"))
                continue
            }
            fancyLog(level: .info, message: "Leere Commit-Nachricht erhalten. Versuche erneut...")
        }

        if let commitMessage = commitMessage {
            fancyLog(level: .info, message: "Führe 'git commit' für \(file) aus...")
            if !commitFile(file: file, message: commitMessage) {
                logEntries.append((file, "Fehlgeschlagen", "Fehler beim Ausführen von 'git commit'"))
                continue
            }

            logEntries.append((file, "Erfolgreich", "Änderungen erfolgreich committet"))
        }
    }

    return logEntries.allSatisfy { $0.1 == "Erfolgreich" }
}

func getChangedFiles() -> [String] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "diff", "--cached", "--name-only"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    let files = output.split(separator: "\n").map { String($0) }
    return files
}

func getDiff(for file: String) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "diff", "--cached", file]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

func commitFile(file: String, message: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git", "commit", "-m", message]
    process.launch()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        fancyLog(level: .error, message: "Fehler beim Ausführen von 'git commit' für \(file).")
        return false
    }

    return true
}

func generateCommitMessage(diff: String, file: String) -> String? {
    guard let config = loadConfig() else {
        fancyLog(level: .error, message: "Konfigurationsdatei konnte nicht geladen werden.")
        return nil
    }

    let serviceConfig: ServiceConfig
    switch config.apiService {
    case "openai":
        serviceConfig = config.openai
    case "olama":
        serviceConfig = config.olama
    default:
        fancyLog(level: .error, message: "Ungültiger API-Dienst in der Konfigurationsdatei.")
        return nil
    }

    guard let apiKey = getAPIKeyFromKeychain() else {
        fancyLog(level: .error, message: "API-Schlüssel konnte nicht aus dem Schlüsselbund abgerufen werden.")
        return nil
    }

    let openAIEndpoint = serviceConfig.endpoint
    var commitMessage = ""
    let maxTokens = 150
    let diffChunks = diff.chunked(into: maxTokens * 3) // Schätzungsweise 3 Zeichen pro Token

    for chunk in diffChunks {
        var request = URLRequest(url: URL(string: openAIEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        Generate a detailed and multi-line commit message based on the following git diff for the file \(file):
        \(chunk)

        The commit message should include:
        - A summary line describing the changes
        - Detailed bullet points explaining what was changed and why
        - Any relevant references to issues or documentation
        - Ensure the message is well-structured and easy to read
        """
        let requestBody: [String: Any] = [
            "model": serviceConfig.model,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt],
            ],
            "max_tokens": maxTokens,
            "temperature": 0.7,
            "n": 1,
            "stop": ["\n\n"],
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                fancyLog(level: .error, message: "Fehler beim Abrufen der Commit-Nachricht: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                fancyLog(level: .error, message: "Keine Daten von der API erhalten.")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                        fancyLog(level: .error, message: "API-Fehler: \(message)")
                        return
                    }

                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let text = message["content"] as? String
                    {
                        commitMessage += text.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n"
                    } else {
                        fancyLog(level: .error, message: "Unerwartete API-Antwortstruktur.")
                    }
                }
            } catch {
                fancyLog(level: .error, message: "Fehler beim Parsen der API-Antwort: \(error.localizedDescription)")
            }
        }

        task.resume()
        semaphore.wait()
    }

    if !commitMessage.isEmpty {
        return commitMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        fancyLog(level: .error, message: "Leere Commit-Nachricht erhalten.")
        return nil
    }
}

extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var index = startIndex

        while index < endIndex {
            let endIndex = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            let chunk = self[index..<endIndex]
            chunks.append(String(chunk))
            index = endIndex
        }

        return chunks
    }
}
