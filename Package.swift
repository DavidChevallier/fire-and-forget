// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "Builder",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.2")
  ],
  targets: [
    .target(
      name: "Logger",
      path: "Sources/Builder/Helpers",
      sources: ["Logger.swift"]
    ),
    .target(
      name: "KeychainHelper",
      dependencies: ["Logger"],
      path: "Sources/Builder/Keychain",
      sources: ["KeychainHelper.swift"]
    ),
    .executableTarget(
      name: "Builder",
      dependencies: [
        "Yams",
        "Logger",
        "KeychainHelper",
      ],
      path: "Sources/Builder",
      exclude: ["Tests"],
      sources: [
        "Commands/BuildCommand.swift",
        "Commands/CommitCommand.swift",
        "Commands/DocgenCommand.swift",
        "Commands/StartCommand.swift",
        "Helpers/BuildInfo.swift",
        "Helpers/Command.swift",
        "Helpers/Config.swift",
        "Helpers/Helper.swift",
        "main.swift",
      ],
      resources: [
        // Deklariere ungenutzte Dateien explizit als Ressourcen
        .process("Keychain/KeychainHelper.swift"),
        .process("Helpers/Logger.swift"),
      ]
    ),
    .testTarget(
      name: "BuilderTests",
      dependencies: ["Builder"],
      path: "Sources/Tests/BuilderTests",
      sources: ["BuilderTests.swift"]
    ),
  ]
)
