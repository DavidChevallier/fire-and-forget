import Foundation

public enum LogLevel: String {
    case info = "INFO"
    case success = "SUCCESS"
    case error = "ERROR"
}

public func fancyLog(level: LogLevel, message: String) {
    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
    var prefix: String

    switch level {
    case .info:
        prefix = "🔔 \u{001B}[34m[\(timestamp)] \(level.rawValue)\u{001B}[0m"
    case .success:
        prefix = "🚀 \u{001B}[32m[\(timestamp)] \(level.rawValue)\u{001B}[0m"
    case .error:
        prefix = "❌ \u{001B}[31m[\(timestamp)] \(level.rawValue)\u{001B}[0m"
    }

    print("\(prefix) \(message)\n")
}
