import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct EmbedSignCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "embed-sign",
        abstract: "🔒 Update the embedding status to embed and sign of specified frameworks in the Xcode project."
    )

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    @Option(name: [.customLong("frameworks")], parsing: .upToNextOption, help: """
        Specify the frameworks to Embed & Sign.
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

                            // Embed and sign the framework
                            try embedAndSignFramework(buildFile: buildFile, forTarget: target, in: pbxproj)

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
    func embedAndSignFramework(buildFile: PBXBuildFile, forTarget target: PBXNativeTarget, in pbxproj: PBXProj) throws {
        // Create a new PBXBuildFile for the Embed Frameworks phase
        let embedBuildFile = PBXBuildFile(file: buildFile.file)
        
        // Add the 'CodeSignOnCopy' attribute to the new build file
        embedBuildFile.settings = ["ATTRIBUTES": ["CodeSignOnCopy"]]

        // Find or create the Embed Frameworks build phase
        let embedFrameworksPhase = target.buildPhases.first(where: { $0 is PBXCopyFilesBuildPhase }) as? PBXCopyFilesBuildPhase ?? {
            let newPhase = PBXCopyFilesBuildPhase(dstPath: "", dstSubfolderSpec: .frameworks, name: "Embed Frameworks")
            pbxproj.add(object: newPhase)
            target.buildPhases.append(newPhase)
            if verbose { print("ℹ️  Embed Frameworks phase was missing, created a new one.".yellow) }
            return newPhase
        }()

        // Add the new build file to the Embed Frameworks phase
        if !(embedFrameworksPhase.files?.contains(embedBuildFile) ?? false) {
            pbxproj.add(object: embedBuildFile)
            embedFrameworksPhase.files?.append(embedBuildFile)
            if verbose { print("✅ Framework added to Embed Frameworks phase with CodeSignOnCopy.".green) }
        }
    }
}
