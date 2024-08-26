import ArgumentParser
import Foundation
import XcodeProj
import PathKit
import Rainbow
import SwiftyTextTable

struct ListCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "📋 List all embedded frameworks and xcframeworks in the Xcode project."
    )

    @Flag(help: "Show detailed information for debugging.")
    var verbose: Bool = false

    @Argument(help: "The path to the .xcodeproj file")
    var projectPath: String

    func run() throws {
        let path = Path(projectPath)

        guard path.exists, path.extension == "xcodeproj" else {
            throw ValidationError("❌ The specified path is not a valid .xcodeproj file".red)
        }

        if verbose {
            print("📂 Provided project path: \(path)".lightBlue)
            print("🔍 Attempting to load the Xcode project...".lightBlue)
        }

        let xcodeProj: XcodeProj
        do {
            xcodeProj = try XcodeProj(path: path)
            if verbose {
                print("✅ Xcode project loaded successfully.".green)
            }
        } catch {
            print("❌ Failed to load Xcode project: \(error)".red)
            throw error
        }

        let pbxproj = xcodeProj.pbxproj
        var frameworksInfo: [FrameworkInfo] = []

        for target in pbxproj.nativeTargets {
            if verbose {
                print("🚀 Processing target: \(target.name)".cyan)
            }

            let buildPhases = target.buildPhases

            for phase in buildPhases {
                // Handle regular Frameworks phase
                if let frameworksBuildPhase = phase as? PBXFrameworksBuildPhase {
                    for file in frameworksBuildPhase.files ?? [] {
                        if let filePath = file.file?.path {
                            let frameworkName = URL(fileURLWithPath: filePath).lastPathComponent
                            let type = filePath.hasSuffix(".xcframework") ? "XCFramework" : "Framework"

                            // Default to "Do Not Embed"
                            frameworksInfo.append(FrameworkInfo(name: frameworkName, type: type, isEmbedded: "Do Not Embed"))
                        }
                    }
                }

                // Handle Embed Frameworks phase
                if let embedFrameworksPhase = phase as? PBXCopyFilesBuildPhase, embedFrameworksPhase.name == "Embed Frameworks" {
                    if verbose {
                        print("📦 Found an embed frameworks phase for target: \(target.name)".cyan)
                    }

                    for file in embedFrameworksPhase.files ?? [] {
                        if let filePath = file.file?.path {
                            let frameworkName = URL(fileURLWithPath: filePath).lastPathComponent
                            let type = filePath.hasSuffix(".xcframework") ? "XCFramework" : "Framework"

                            var isEmbedded = "Embed Without Signing"
                            if let settings = file.settings,
                               let attributes = settings["ATTRIBUTES"] as? [String] {
                                if attributes.contains("CodeSignOnCopy") {
                                    isEmbedded = "Embed & Sign"
                                }
                            }

                            if let index = frameworksInfo.firstIndex(where: { $0.name == frameworkName }) {
                                frameworksInfo[index] = FrameworkInfo(name: frameworkName, type: type, isEmbedded: isEmbedded)
                            } else {
                                frameworksInfo.append(FrameworkInfo(name: frameworkName, type: type, isEmbedded: isEmbedded))
                            }

                            if verbose {
                                print("🔧 Found framework: \(frameworkName) - \(type) - \(isEmbedded)".green)
                            }
                        }
                    }
                }
            }
        }

        frameworksInfo.sort { $0.name.lowercased() < $1.name.lowercased() }
        displayFrameworkTable(frameworksInfo: frameworksInfo)
    }
    
    // Display the framework information using SwiftyTextTable
    func displayFrameworkTable(frameworksInfo: [FrameworkInfo]) {
        var table = TextTable(columns: [
            TextTableColumn(header: "Framework Name".cyan),
            TextTableColumn(header: "Type".magenta),
            TextTableColumn(header: "Embedding Status".yellow)
        ])

        // Add rows to the table
        for info in frameworksInfo {
            table.addRow(values: [info.name, info.type, info.isEmbedded])
        }
        
        table.columnFence = "│"
        table.rowFence = "─"
        table.cornerFence = "┼"

        print(table.render())
    }
}
