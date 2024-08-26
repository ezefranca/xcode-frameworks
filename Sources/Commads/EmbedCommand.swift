import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct EmbedCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "embed",
        abstract: "🗳️  Update the embed status without sign of specified frameworks in the Xcode project."
    )

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    @Option(name: [.customLong("frameworks")], parsing: .upToNextOption, help: """
        Specify the frameworks to Embed without Sign.
        You can pass multiple frameworks by separating them with spaces. No need for xcframework or framework extension.
        Example: embed /path/to/YourProject.xcodeproj --frameworks YourFramework
        """)
    var frameworks: [String]

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
        
        for framework in frameworks {
            if verbose { print("🔍 Searching for framework: \(framework)".lightBlue) }

            var foundFramework = false

            for target in pbxproj.nativeTargets {
                if let frameworksBuildPhase = try? target.frameworksBuildPhase() {
                    for buildFile in frameworksBuildPhase.files ?? [] {
                        if let fileName = buildFile.file?.path, fileName.contains(framework) {
                            if verbose { print("✅ Found framework: \(fileName)".green) }

                            // Embed the framework
                            try embedFramework(buildFile: buildFile, forTarget: target, in: pbxproj)

                            updatedFrameworks.append(fileName)
                            foundFramework = true
                            break
                        }
                    }
                }
            }

            if !foundFramework {
                print("⚠️ Warning: Framework \(framework) not found in project.".yellow)
            }
        }

        // Save the project after updating
        try xcodeproj.write(path: projectFilePath)
        
        if !updatedFrameworks.isEmpty {
            print("🔒 Embedding status successfully updated for the specified frameworks.".green)
        } else {
            print("🎉 No frameworks were updated.".green)
        }
    }

    // Helper function to embed and sign the framework
    func embedFramework(buildFile: PBXBuildFile, forTarget target: PBXNativeTarget, in pbxproj: PBXProj) throws {
        // Check if the Embed Frameworks build phase exists
        let embedFrameworksPhase = target.buildPhases.first(where: { $0 is PBXCopyFilesBuildPhase }) as? PBXCopyFilesBuildPhase ?? {
            // Create the Embed Frameworks phase if it doesn't exist
            let newPhase = PBXCopyFilesBuildPhase(dstPath: "", dstSubfolderSpec: .frameworks, name: "Embed Frameworks")
            pbxproj.add(object: newPhase)
            target.buildPhases.append(newPhase)
            if verbose { print("ℹ️ Embed Frameworks phase was missing, created a new one.".yellow) }
            return newPhase
        }()

        // Add the framework to the Embed Frameworks phase if it's not already there
        if !(embedFrameworksPhase.files?.contains(buildFile) ?? false) {
            embedFrameworksPhase.files?.append(buildFile)
            if verbose { print("✅ Framework added to Embed Frameworks phase.".green) }
        }

        // Ensure settings exist and handle nil values
        if buildFile.settings == nil {
            buildFile.settings = [:]
            if verbose { print("ℹ️ Settings were nil, created a new settings dictionary.".yellow) }
        }

        // Add or update the 'CodeSignOnCopy' and 'RemoveHeadersOnCopy' attributes
        if var attributes = buildFile.settings?["ATTRIBUTES"] as? [String] {
            if !attributes.contains("CodeSignOnCopy") {
                attributes.append("CodeSignOnCopy")
            }
            if !attributes.contains("RemoveHeadersOnCopy") {
                attributes.append("RemoveHeadersOnCopy")
            }
            buildFile.settings?["ATTRIBUTES"] = attributes
        } else {
            buildFile.settings?["ATTRIBUTES"] = ["CodeSignOnCopy", "RemoveHeadersOnCopy"]
        }

        if verbose {
            print("🔧 Set CodeSignOnCopy and RemoveHeadersOnCopy attributes for \(buildFile.file?.path ?? "Unknown Framework").".green)
        }
    }
}
