import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct SignCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "sign",
        abstract: "🔒 Update the embedding status of specified frameworks in the Xcode project."
    )

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Specify the frameworks to Embed & Sign.")
    var sign: [String] = []

    @Flag(help: "Show detailed information for debugging.")
    var verbose: Bool = false

    func run() throws {
        let projectFilePath = Path(projectPath)
        
        // Check if the project path is valid
        guard projectFilePath.exists && projectFilePath.extension == "xcodeproj" else {
            throw ValidationError("❌ The specified path is not a valid .xcodeproj file.".red)
        }

        // Load the Xcode project
        if verbose { print("📂 Project Path: \(projectFilePath)".cyan) }
        let xcodeproj = try XcodeProj(path: projectFilePath)
        
        if verbose { print("✅ Successfully loaded Xcode project.".green) }

        let pbxproj = xcodeproj.pbxproj
        var updatedFrameworks: [String] = []
        
        // Process frameworks and update their embedding status to 'Embed & Sign'
        for frameworkName in sign {
            if verbose { print("🔍 Searching for framework: \(frameworkName)".lightBlue) }

            var foundFramework = false

            for target in pbxproj.nativeTargets {
                if let frameworksBuildPhase = try? target.frameworksBuildPhase() {
                    for buildFile in frameworksBuildPhase.files ?? [] {
                        if let fileName = buildFile.file?.path, fileName.contains(frameworkName) {
                            if verbose { print("✅ Found framework: \(fileName)".green) }
                            updateEmbeddingStatus(buildFile: buildFile, newStatus: "Embed & Sign")
                            updatedFrameworks.append(fileName)
                            foundFramework = true
                            break
                        }
                    }
                }
            }

            if !foundFramework {
                print("⚠️ Warning: Framework \(frameworkName) not found in project.".yellow)
            }
        }

        // Save the project after updating
        try xcodeproj.write(path: projectFilePath)
        
        // Display result in a table format
        if !updatedFrameworks.isEmpty {
            var table = TextTable(columns: [
                TextTableColumn(header: "Framework".bold.lightBlue),
                TextTableColumn(header: "Embedding Status".bold.lightYellow)
            ])

            for framework in updatedFrameworks {
                table.addRow(values: [framework.lightBlue, "Embed & Sign".red])
            }

            print(table.render())
            print("🔒 Embedding status successfully updated for the specified frameworks.".green)
        } else {
            print("🎉 No frameworks were updated.".green)
        }
    }

    // Helper function to update the embedding status of a framework
    func updateEmbeddingStatus(buildFile: PBXBuildFile, newStatus: String) {
        // Check if the build file already has an ATTRIBUTES setting
        if buildFile.settings == nil {
            buildFile.settings = [:]
        }
        
        // Add or update the 'CodeSignOnCopy' attribute
        if buildFile.settings?["ATTRIBUTES"] == nil {
            buildFile.settings?["ATTRIBUTES"] = ["CodeSignOnCopy", "RemoveHeadersOnCopy"]
        } else {
            var attributes = buildFile.settings?["ATTRIBUTES"] as? [String] ?? []
            if !attributes.contains("CodeSignOnCopy") {
                attributes.append("CodeSignOnCopy")
            }
            if !attributes.contains("RemoveHeadersOnCopy") {
                attributes.append("RemoveHeadersOnCopy")
            }
            buildFile.settings?["ATTRIBUTES"] = attributes
        }

        if verbose {
            print("🔧 Updated embedding status for \(buildFile.file?.path ?? "Unknown Framework") to '\(newStatus)'.".green)
        }
    }
}

