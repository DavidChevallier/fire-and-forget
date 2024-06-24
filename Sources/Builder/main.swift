import Foundation
import LocalAuthentication
import Security
import Logger
import KeychainHelper

let keychainService: String = "OpenAI"
let keychainAccount: String = "API_KEY"
let binDir: String = "bin"

// Verwenden Sie die definierten Werte aus Compiler-Flags oder Default-Werte
let version: String = BuildInfo.version
let commitSlug: String = BuildInfo.commitSlug
let buildDate: String = BuildInfo.buildDate
let codesigningIdentity: String = BuildInfo.codesigningIdentity
let codesigningInfo: String = BuildInfo.codesigningInfo

var globalProcess: Process?
var processTerminatedBySignal: Bool = false

func main() {
    // Wenn Config und apiKey nicht verwendet werden, kommentieren Sie diese aus
    /*
    guard let config = loadConfig() else {
        fancyLog(level: .error, message: "Konfigurationsdatei konnte nicht geladen werden.")
        exit(1)
    }

    guard let apiKey = getAPIKeyFromKeychain() else {
        fancyLog(level: .error, message: "API-Schlüssel konnte nicht aus dem Schlüsselbund abgerufen werden.")
        exit(1)
    }
    */

    let args: [String] = CommandLine.arguments
    guard args.count > 1 else {
        printHelp()
        return
    }

    let command: Command? = Command(rawValue: args[1])
    let commandArgs: [String] = Array(args.dropFirst(2))

    switch command {
    case .help:
        printHelp()
    case .initKey:
        initAPIKey()
    case .build:
        buildCommand(args: commandArgs)
    case .commit:
        if !commitChanges() {
            fancyLog(level: .error, message: "Fehler beim Comitten der Änderungen.")
            exit(1)
        }
    case .docgen:
        generateDocsCommand(args: commandArgs)
    case .start:
        startCommand(args: commandArgs)
    default:
        printHelp()
    }
}

main()
