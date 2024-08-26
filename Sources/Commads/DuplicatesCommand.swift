import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct DuplicatesCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "duplicates",
        abstract: "🔎 List duplicates frameworks in the Xcode project"
    )

    // MARK: - Arguments and Flags
    @Flag(help: "Show detailed information for debugging.")
    var verbose: Bool = false

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    @Flag(help: "Show duplicated frameworks.")
    var duplicates: Bool = false

    // MARK: - Main Function
    func run() throws {
        let projectFilePath = Path(projectPath)

        // Verbose logging
        if verbose {
            print("📂 Provided project path: \(projectFilePath)".cyan)
            print("🔍 Attempting to load the Xcode project...".yellow)
        }

        // Load the Xcode project
        let xcodeproj = try XcodeProj(path: projectFilePath)

        // Verbose logging
        if verbose {
            print("✅ Xcode project loaded successfully.".green)
        }

        // Create a dictionary to track framework occurrences based on framework name only (ignoring path)
        var frameworkOccurrences: [String: Int] = [:]

        // Iterate through all native targets to gather framework references
        for target in xcodeproj.pbxproj.nativeTargets {
            if verbose {
                print("🚀 Processing target: \(target.name)".lightYellow)
            }

            if let frameworksBuildPhase = try target.frameworksBuildPhase() {
                for buildFile in frameworksBuildPhase.files ?? [] {
                    // Extract the framework name by ignoring the path
                    if let fileRef = buildFile.file as? PBXFileReference,
                       let frameworkName = fileRef.name ?? fileRef.path?.components(separatedBy: "/").last {
                        frameworkOccurrences[frameworkName, default: 0] += 1
                    }
                }
            }
        }

        // If duplicates flag is enabled, filter for frameworks with more than one occurrence
        if duplicates {
            let duplicatedFrameworks = frameworkOccurrences.filter { $0.value > 1 }

            if duplicatedFrameworks.isEmpty {
                print("🎉 No duplicated frameworks found.".green)
            } else {
                if verbose {
                    print("🔍 Duplicates detected. Displaying results...".yellow)
                }
                displayFrameworkTable(frameworksInfo: duplicatedFrameworks.map { FrameworkInfo(name: $0.key, count: $0.value) })
            }
        } else {
            // If the duplicates flag is not set, list all frameworks
            if verbose {
                print("📋 Listing all frameworks:".yellow)
            }
            displayFrameworkTable(frameworksInfo: frameworkOccurrences.map { FrameworkInfo(name: $0.key, count: $0.value) })
        }
    }

    // MARK: - Display Framework Table
    func displayFrameworkTable(frameworksInfo: [FrameworkInfo]) {
        let columns = [
            TextTableColumn(header: "Framework".lightBlue),
            TextTableColumn(header: "Occurrences".lightYellow)
        ]

        var table = TextTable(columns: columns)

        table.columnFence = "│"
        table.rowFence = "─"
        table.cornerFence = "┼"

        for frameworkInfo in frameworksInfo {
            table.addRow(values: [
                frameworkInfo.name.lightBlue,
                "\(frameworkInfo.count)".red
            ])
        }

        print(table.render())
    }
}
