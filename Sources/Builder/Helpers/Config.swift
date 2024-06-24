import Foundation
import Yams

struct ServiceConfig: Codable {
    let endpoint: String
    let model: String
}

struct Config: Codable {
    let apiService: String
    let openai: ServiceConfig
    let olama: ServiceConfig
}

let configFilePath = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".david")
    .appendingPathComponent("config.yml")

func loadConfig() -> Config? {
    ensureConfigFileExists()

    do {
        let data = try Data(contentsOf: configFilePath)
        let decoder = YAMLDecoder()
        let config = try decoder.decode(Config.self, from: data)
        return config
    } catch {
        print("Fehler beim Laden der Konfigurationsdatei: \(error)")
        return nil
    }
}

func ensureConfigFileExists() {
    let fileManager = FileManager.default
    let configDir = configFilePath.deletingLastPathComponent()

    if !fileManager.fileExists(atPath: configDir.path) {
        try? fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
    }

    if !fileManager.fileExists(atPath: configFilePath.path) {
        let defaultConfig = """
        apiService: openai
        openai:
          endpoint: https://api.openai.com/v1/chat/completions
          model: gpt-4
        olama:
          endpoint: https://api.olama.com/v1/completions
          model: lama-2
        """
        try? defaultConfig.write(to: configFilePath, atomically: true, encoding: .utf8)
    }
}
