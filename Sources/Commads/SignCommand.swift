//import Foundation
//import PathKit
//import XcodeProj
//import ArgumentParser
//
//struct SignCommand: ParsableCommand {
//    static var configuration = CommandConfiguration(
//        commandName: "sign",
//        abstract: "Sign and embed the specified frameworks in the Xcode project"
//    )
//
//    @Argument(help: "The path to the Xcode project.")
//    var projectPath: String
//
//    @Argument(help: "The names of the frameworks to embed and sign.")
//    var frameworkNames: [String]
//
//    func run() throws {
//        // 1. Load the Xcode project
//        let projectFilePath = Path(projectPath)
//        let xcodeproj = try XcodeProj(path: projectFilePath)
//
//        // 2. Get the main application target (the one that produces an app)
//        guard let mainTarget = xcodeproj.pbxproj.targets.first(where: { $0.productType == .application }) as? PBXNativeTarget else {
//            throw ValidationError("No main application target found in the project.")
//        }
//
//        // 3. Get the Frameworks build phase (or create one if it doesn't exist)
//        let frameworksBuildPhase = mainTarget.frameworksBuildPhase() ?? PBXFrameworksBuildPhase()
//
//        if mainTarget.buildPhases.contains(where: { $0 == frameworksBuildPhase }) == false {
//            mainTarget.buildPhases.append(frameworksBuildPhase)
//        }
//
//        // 4. Get the Embed Frameworks phase (or create one if it doesn't exist)
//        let embedFrameworksPhase = mainTarget.embedFrameworksBuildPhase() ?? PBXCopyFilesBuildPhase(dstPath: "", dstSubfolderSpec: .frameworks)
//
//        if mainTarget.buildPhases.contains(where: { $0 == embedFrameworksPhase }) == false {
//            mainTarget.buildPhases.append(embedFrameworksPhase)
//        }
//
//        // 5. Process each framework
//        for frameworkName in frameworkNames {
//            // Framework reference
//            let frameworkFilePath = "Frameworks/\(frameworkName).xcframework"
//            let frameworkFileReference = PBXFileReference(sourceTree: .group, lastKnownFileType: "wrapper.xcframework", path: frameworkFilePath)
//
//            // Check if framework already exists in the Frameworks build phase
//            let frameworkExists = frameworksBuildPhase.files?.contains(where: { $0.file?.path == frameworkFilePath }) ?? false
//
//            if frameworkExists {
//                print("Framework \(frameworkName) already exists in the project, updating signing settings.")
//                // Update settings for existing framework
//                frameworksBuildPhase.files?.forEach { buildFile in
//                    if buildFile.file?.path == frameworkFilePath {
//                        buildFile.settings?["ATTRIBUTES"] = ["CodeSignOnCopy", "RemoveHeadersOnCopy"]
//                    }
//                }
//            } else {
//                print("Adding framework \(frameworkName) to the project.")
//                // Create new build file for the framework
//                let buildFile = PBXBuildFile(file: frameworkFileReference)
//                frameworksBuildPhase.files?.append(buildFile)
//
//                // Add the framework to the Embed Frameworks phase
//                embedFrameworksPhase.files?.append(buildFile)
//
//                // Set the embedding and signing attributes
//                buildFile.settings = ["ATTRIBUTES": ["CodeSignOnCopy", "RemoveHeadersOnCopy"]]
//
//                // Add the framework reference to the project (if needed)
//                if let mainGroup = xcodeproj.pbxproj.mainGroup {
//                    mainGroup.children.append(frameworkFileReference)
//                }
//            }
//        }
//
//        // 6. Save changes
//        try xcodeproj.write(path: projectFilePath)
//        print("Successfully embedded and signed the frameworks.")
//    }
//}

