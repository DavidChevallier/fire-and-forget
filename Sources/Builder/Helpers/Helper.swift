import Foundation

func printHelp() {
  let usageMessage: String = """
    \u{001B}[36mUsage:\u{001B}[0m tool [command] [options]

    \u{001B}[33mCommands:\u{001B}[0m
      \u{1F4BB} \u{001B}[32mbuild\u{001B}[0m [--arm] [--amd] --name <name>             Build the binary
          \u{001B}[35mOptions for build command:\u{001B}[0m
            \u{1F4BB} \u{001B}[32m--arm\u{001B}[0m      Build for arm64 architecture (macOS)
            \u{1F4BB} \u{001B}[32m--amd\u{001B}[0m      Build for amd64 architecture (Linux)
            \u{1F4BB} \u{001B}[32m--386\u{001B}[0m      Build for 386 architecture (Linux)
            \u{1F4BB} \u{001B}[32m--arm32\u{001B}[0m    Build for arm architecture (Linux)
            \u{1F4BB} \u{001B}[32m--windows\u{001B}[0m  Build for amd64 architecture (Windows)
            \u{1F4BB} \u{001B}[32m--name\u{001B}[0m     Specify the name of the binary

      \u{1F4DD} \u{001B}[32mcommit\u{001B}[0m                                          Commit changes with a generated commit message

      \u{1F4DA} \u{001B}[32mdocgen\u{001B}[0m <command> <args>                         Generate documentation (e.g., Swagger)

      \u{1F4BE} \u{001B}[32mstart\u{001B}[0m <binary>                                  Start the binary

      \u{1F4E6} \u{001B}[32minit\u{001B}[0m                                            Initialize the API key in the keychain for OpenAI

      \u{2753} \u{001B}[32mhelp\u{001B}[0m                                             Show this help message

    \u{1F527} \u{001B}[33mMaintainer:\u{001B}[0m David Chevallier
    \u{1F4E6} git: git@git.toolchen.ch:buildtools/go/builder.git
    \u{1F4C4} version: \(version)
    \u{1F4DD} commit: \(commitSlug)
    \u{1F4C5} build date: \(buildDate)
    \u{1F4DD} code signing info: \(codesigningInfo)
    """

  print(usageMessage)
  exit(0)
}

func getCodesigningInfo(for binaryPath: String) -> (String, String) {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
  process.arguments = ["-dvv", binaryPath]

  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = pipe

  do {
    try process.run()
    process.waitUntilExit()
  } catch {
    return ("unknown", "unknown")
  }

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  if let output = String(data: data, encoding: .utf8) {
    let identity = output.lines.first(where: { $0.contains("Authority=") })?.replacingOccurrences(of: "Authority=", with: "") ?? "unknown"
    let info = output.lines.joined(separator: "\n")
    return (identity, info)
  }

  return ("unknown", "unknown")
}

extension String {
  var lines: [String] {
    return self.split(separator: "\n").map { String($0) }
  }
}
