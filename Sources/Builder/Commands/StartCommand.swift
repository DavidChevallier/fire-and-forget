import Foundation
import Foundation
import Logger

func startCommand(args: [String]) {
    guard args.count > 0 else {
        fancyLog(level: .error, message: "Keine Binärdatei angegeben.")
        exit(1)
    }
    let output = args[0]
    if !startBinary(output: output) {
        fancyLog(level: .error, message: "Fehler beim Ausführen der Binärdatei.")
        exit(1)
    }
}

func startBinary(output: String) -> Bool {
    fancyLog(level: .info, message: "Starte die Binärdatei...")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "./bin/" + output)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    let stdoutHandle = pipe.fileHandleForReading
    stdoutHandle.readabilityHandler = { fileHandle in
        if let line = String(data: fileHandle.availableData, encoding: .utf8) {
            print(line, terminator: "")
        }
    }

    do {
        try process.run()
    } catch {
        fancyLog(level: .error, message: "Fehler beim Ausführen der Binärdatei: \(error.localizedDescription)")
        return false
    }

    globalProcess = process
    setSignalHandler()

    process.waitUntilExit()

    if process.terminationStatus != 0 && !processTerminatedBySignal {
        fancyLog(level: .error, message: "Fehler beim Ausführen der Binärdatei.")
        return false
    }

    return true
}

func setSignalHandler() {
    signal(SIGINT) { _ in
        fancyLog(level: .info, message: "Beende die Binärdatei...")
        processTerminatedBySignal = true
        globalProcess?.terminate()
    }
}
