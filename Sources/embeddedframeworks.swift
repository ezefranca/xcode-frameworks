import ArgumentParser
import Foundation
import XcodeProj
import PathKit

struct FrameworkInfo {
    let name: String
    let type: String
    let isEmbedded: String
}

@main
struct EmbeddedFrameworks: ParsableCommand {

    @Flag(help: "List all embedded frameworks and xcframeworks in the project.")
    var list: Bool = false

    @Flag(help: "Show detailed information for debugging.")
    var verbose: Bool = false

    @Argument(help: "The path to the .xcodeproj file")
    var projectPath: String

    func run() throws {
        let path = Path(projectPath)

        guard path.exists, path.extension == "xcodeproj" else {
            throw ValidationError("The specified path is not a valid .xcodeproj file")
        }

        if verbose {
            print("Provided project path: \(path)")
            print("Attempting to load the Xcode project...")
        }

        let xcodeProj: XcodeProj
        do {
            xcodeProj = try XcodeProj(path: path)
            if verbose {
                print("Xcode project loaded successfully.")
            }
        } catch {
            print("Failed to load Xcode project: \(error)")
            throw error
        }

        let pbxproj = xcodeProj.pbxproj
        var frameworksInfo: [FrameworkInfo] = []

        for target in pbxproj.nativeTargets {
            if verbose {
                print("Processing target: \(target.name)")
            }

            let buildPhases = target.buildPhases

            // Check both the regular frameworks and embed frameworks phases
            for phase in buildPhases {
                // Handle regular Frameworks phase
                if let frameworksBuildPhase = phase as? PBXFrameworksBuildPhase {
                    for file in frameworksBuildPhase.files ?? [] {
                        if let filePath = file.file?.path {
                            let frameworkName = URL(fileURLWithPath: filePath).lastPathComponent
                            let type = filePath.hasSuffix(".xcframework") ? "XCFramework" : "Framework"

                            // Default to "Do Not Embed"
                            var isEmbedded = "Do Not Embed"
                            frameworksInfo.append(FrameworkInfo(name: frameworkName, type: type, isEmbedded: isEmbedded))
                        }
                    }
                }

                // Handle Embed Frameworks phase
                if let embedFrameworksPhase = phase as? PBXCopyFilesBuildPhase, embedFrameworksPhase.name == "Embed Frameworks" {
                    if verbose {
                        print("Found an embed frameworks phase for target: \(target.name)")
                    }

                    for file in embedFrameworksPhase.files ?? [] {
                        if let filePath = file.file?.path {
                            var isEmbedded = "Do Not Embed"  // Default to "Do Not Embed"

                            // Check for embedding settings
                            if let settings = file.settings as? [String: Any],
                               let attributes = settings["ATTRIBUTES"] as? [String] {
                                if attributes.contains("CodeSignOnCopy") {
                                    isEmbedded = "Embed & Sign"
                                } else if attributes.contains("RemoveHeadersOnCopy") {
                                    isEmbedded = "Embed Without Signing"
                                }
                            }

                            let frameworkName = URL(fileURLWithPath: filePath).lastPathComponent
                            let type = filePath.hasSuffix(".xcframework") ? "XCFramework" : "Framework"

                            // Update the existing framework info if already present
                            if let index = frameworksInfo.firstIndex(where: { $0.name == frameworkName }) {
                                frameworksInfo[index] = FrameworkInfo(name: frameworkName, type: type, isEmbedded: isEmbedded)
                            } else {
                                frameworksInfo.append(FrameworkInfo(name: frameworkName, type: type, isEmbedded: isEmbedded))
                            }

                            if verbose {
                                print("Found framework: \(frameworkName) - \(type) - \(isEmbedded)")
                            }
                        }
                    }
                }
            }
        }

        // Sort the frameworks alphabetically by name
        frameworksInfo.sort { $0.name.lowercased() < $1.name.lowercased() }

        if list {
            displayFrameworkTable(frameworksInfo: frameworksInfo)
        }
    }

    func displayFrameworkTable(frameworksInfo: [FrameworkInfo]) {
        // Dynamically calculate the width of each column
        let nameColumnWidth = max("Framework Name".count, frameworksInfo.map { $0.name.count }.max() ?? 0)
        let typeColumnWidth = max("Type".count, frameworksInfo.map { $0.type.count }.max() ?? 0)
        let embeddingColumnWidth = max("Embedding Status".count, frameworksInfo.map { $0.isEmbedded.count }.max() ?? 0)

        // Build the table borders based on column widths
        let topBorder = "┌" + String(repeating: "─", count: nameColumnWidth + 2) + "┬" +
                        String(repeating: "─", count: typeColumnWidth + 2) + "┬" +
                        String(repeating: "─", count: embeddingColumnWidth + 2) + "┐"
        let headerSeparator = "├" + String(repeating: "─", count: nameColumnWidth + 2) + "┼" +
                              String(repeating: "─", count: typeColumnWidth + 2) + "┼" +
                              String(repeating: "─", count: embeddingColumnWidth + 2) + "┤"
        let bottomBorder = "└" + String(repeating: "─", count: nameColumnWidth + 2) + "┴" +
                           String(repeating: "─", count: typeColumnWidth + 2) + "┴" +
                           String(repeating: "─", count: embeddingColumnWidth + 2) + "┘"

        // Print the table header
        print(topBorder)
        print("│ \(String("Framework Name").padding(toLength: nameColumnWidth, withPad: " ", startingAt: 0)) │ " +
              "\(String("Type").padding(toLength: typeColumnWidth, withPad: " ", startingAt: 0)) │ " +
              "\(String("Embedding Status").padding(toLength: embeddingColumnWidth, withPad: " ", startingAt: 0)) │")
        print(headerSeparator)

        // Print each row
        for info in frameworksInfo {
            let paddedName = info.name.padding(toLength: nameColumnWidth, withPad: " ", startingAt: 0)
            let paddedType = info.type.padding(toLength: typeColumnWidth, withPad: " ", startingAt: 0)
            let paddedEmbedding = info.isEmbedded.padding(toLength: embeddingColumnWidth, withPad: " ", startingAt: 0)

            print("│ \(paddedName) │ \(paddedType) │ \(paddedEmbedding) │")
        }

        // Print the bottom border of the table
        print(bottomBorder)
    }
}
