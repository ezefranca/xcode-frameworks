import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct FixCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "fix",
        abstract: "🔧 Fix duplicated frameworks in the Xcode project by keeping only one instance based on the provided strategy."
    )

    // MARK: - Arguments and Flags

    @Flag(help: "Show detailed information for debugging.")
    var verbose: Bool = false

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    @Option(help: "The strategy to fix duplicates. Options are 'keep-first' or 'keep-last'.")
    var strategy: String = "keep-first"

    // MARK: - Main Function

    func run() throws {
        let projectFilePath = Path(projectPath)

        // Verbose logging
        if verbose {
            print("📂 Project Path: \(projectFilePath)".cyan)
        }

        // Load the Xcode project
        let xcodeproj = try XcodeProj(path: projectFilePath)

        // Verbose logging
        if verbose {
            print("✅ Successfully loaded Xcode project.".green)
        }

        // Step 1: Identify duplicated frameworks
        var frameworkOccurrences: [String: [PBXBuildFile]] = [:]

        // Iterate through all native targets to gather framework references
        for target in xcodeproj.pbxproj.nativeTargets {
            if let frameworksBuildPhase = try target.frameworksBuildPhase() {
                for buildFile in frameworksBuildPhase.files ?? [] {
                    if let frameworkName = buildFile.file?.path {
                        frameworkOccurrences[frameworkName, default: []].append(buildFile)
                    }
                }
            }
        }

        // Step 2: Filter out duplicates
        let duplicatedFrameworks = frameworkOccurrences.filter { $0.value.count > 1 }

        if duplicatedFrameworks.isEmpty {
            print("🎉 No duplicated frameworks found. Nothing to fix.".green)
        } else {
            if verbose {
                print("🔍 Duplicates detected. Applying the '\(strategy)' strategy...".yellow)
            }
            
            // Prepare the table to display the frameworks being fixed
            var table = TextTable(columns: [
                TextTableColumn(header: "Framework"),
                TextTableColumn(header: "Duplications")
            ])

            // Step 3: Apply the fixing strategy
            for (frameworkName, buildFiles) in duplicatedFrameworks {
                // Add to the result table
                table.addRow(values: [frameworkName, "\(buildFiles.count)"])

                // Verbose logging
                if verbose {
                    print("ℹ️  Fixing duplicates for \(frameworkName)...".lightBlue)
                }

                var filesToRemove: [PBXBuildFile]

                switch strategy {
                case "keep-first":
                    // Keep the first and remove the rest
                    filesToRemove = Array(buildFiles.dropFirst())
                case "keep-last":
                    // Keep the last and remove the others
                    filesToRemove = Array(buildFiles.dropLast())
                default:
                    print("❌ Invalid strategy: \(strategy). Choose either 'keep-first' or 'keep-last'.".red)
                    return
                }

                // Remove the duplicate files from the build phases
                for fileToRemove in filesToRemove {
                    for target in xcodeproj.pbxproj.nativeTargets {
                        if let frameworksBuildPhase = try target.frameworksBuildPhase() {
                            frameworksBuildPhase.files?.removeAll(where: { $0 == fileToRemove })
                        }
                    }
                }

                if verbose {
                    print("✅ Fixed duplicates for \(frameworkName). Kept \(strategy == "keep-first" ? "first" : "last") instance.".green)
                }
            }
            
            do {
                try xcodeproj.write(path: projectFilePath)
                print("💾 Project saved with duplicates removed.".blue)
                print(table.render())
            } catch {
                print("❌ \(error.localizedDescription)")
            }
        }
    }
}

