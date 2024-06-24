import Foundation
import Logger

func buildCommand(args: [String]) {
  do {
    try FileManager.default.createDirectory(
      atPath: binDir, withIntermediateDirectories: true, attributes: nil)
  } catch {
    fancyLog(
      level: .error,
      message: "Fehler beim Erstellen des '\(binDir)'-Verzeichnisses: \(error.localizedDescription)"
    )
    exit(1)
  }

  var goarch: String = ""
  var goos: String = ""
  var output: String = "default_binary"

  for i in 0..<args.count {
    switch args[i] {
    case "--arm":
      goarch = "arm64"
      goos = "darwin"
      if !output.isEmpty {
        output += "_arm64_darwin"
      }
    case "--amd":
      goarch = "amd64"
      goos = "linux"
      if !output.isEmpty {
        output += "_amd64_linux"
      }
    case "--386":
      goarch = "386"
      goos = "linux"
      if !output.isEmpty {
        output += "_386_linux"
      }
    case "--arm32":
      goarch = "arm"
      goos = "linux"
      if !output.isEmpty {
        output += "_arm_linux"
      }
    case "--windows":
      goarch = "amd64"
      goos = "windows"
      if !output.isEmpty {
        output += "_amd64_windows.exe"
      }
    case "--name":
      if i + 1 < args.count {
        output = args[i + 1]
      } else {
        fancyLog(level: .error, message: "Kein Name für die Binärdatei angegeben.")
        exit(1)
      }
    default:
      continue
    }
  }

  if goarch.isEmpty || goos.isEmpty {
    fancyLog(level: .error, message: "Architektur oder Betriebssystem nicht angegeben.")
    exit(1)
  }

  if !build(goarch: goarch, goos: goos, output: output) {
    fancyLog(level: .error, message: "Fehler beim Build.")
    exit(1)
  }
}

func build(goarch: String, goos: String, output: String) -> Bool {
  fancyLog(level: .info, message: "Baue die Binärdatei für \(goarch)/\(goos)...")
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["go", "build", "-o", "\(binDir)/\(output)", "./cmd/main.go"]
  process.environment = ProcessInfo.processInfo.environment
  process.environment?["GOARCH"] = goarch
  process.environment?["GOOS"] = goos
  process.launch()
  process.waitUntilExit()

  if process.terminationStatus == 0 {
    fancyLog(
      level: .success,
      message:
        "Build für \(goarch)/\(goos) erfolgreich! Die Binärdatei befindet sich im '\(binDir)'-Verzeichnis."
    )
    return true
  } else {
    fancyLog(level: .error, message: "Build für \(goarch)/\(goos) fehlgeschlagen.")
    return false
  }
}
