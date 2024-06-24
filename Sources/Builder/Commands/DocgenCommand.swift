import Foundation
import Logger

func generateDocsCommand(args: [String]) {
  guard args.count > 0 else {
    fancyLog(level: .error, message: "Kein Dokumentationsgenerator angegeben.")
    exit(1)
  }
  let docCommand = args[0]
  let docArgs = Array(args.dropFirst())
  if !generateDocs(command: docCommand, args: docArgs) {
    fancyLog(level: .error, message: "Fehler beim Generieren der Dokumentation.")
    exit(1)
  }
}

func generateDocs(command: String, args: [String]) -> Bool {
  let fileManager = FileManager.default
  fileManager.changeCurrentDirectoryPath("cmd")
  fancyLog(level: .info, message: "Generiere Dokumentation mit \(command)...")

  let process = Process()
  guard fileManager.fileExists(atPath: command) else {
    fancyLog(level: .error, message: "Die ausführbare Datei '\(command)' wurde nicht gefunden.")
    return false
  }

  process.executableURL = URL(fileURLWithPath: command)
  process.arguments = args
  process.launch()
  process.waitUntilExit()

  if process.terminationStatus != 0 {
    fancyLog(level: .error, message: "Fehler beim Generieren der Dokumentation.")
    return false
  }

  fileManager.changeCurrentDirectoryPath("..")
  return true
}
