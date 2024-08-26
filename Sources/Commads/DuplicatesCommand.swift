import Foundation
import PathKit
import XcodeProj
import ArgumentParser
import SwiftyTextTable
import Rainbow

struct DuplicatesCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "duplicates",
        abstract: "🔍 Find and display duplicated frameworks in the Xcode project."
    )

    @Argument(help: "The path to the Xcode project.")
    var projectPath: String

    func run() throws {
        let projectFilePath = Path(projectPath)
        let xcodeproj = try XcodeProj(path: projectFilePath)

        // Create a dictionary to track framework occurrences
        var frameworkOccurrences: [String: Int] = [:]

        for target in xcodeproj.pbxproj.nativeTargets {
            if let frameworksBuildPhase = try target.frameworksBuildPhase() {
                for buildFile in frameworksBuildPhase.files ?? [] {
                    if let frameworkName = buildFile.file?.path {
                        frameworkOccurrences[frameworkName, default: 0] += 1
                    }
                }
            }
        }

        // Filter duplicated frameworks
        let duplicatedFrameworks = frameworkOccurrences.filter { $0.value > 1 }

        if duplicatedFrameworks.isEmpty {
            print("🎉 No duplicated frameworks found.".green)
        } else {
            let duplicatedFrameworksInfo = duplicatedFrameworks.map { FrameworkInfo(name: $0.key, count: $0.value) }
            displayFrameworkTable(frameworksInfo: duplicatedFrameworksInfo)
        }
    }

    func displayFrameworkTable(frameworksInfo: [FrameworkInfo]) {
        
        let columns = [
            TextTableColumn(header: "Framework".bold.lightBlue),
            TextTableColumn(header: "Duplications".bold.lightYellow)
        ]

        var table = TextTable(columns: columns)

        table.columnFence = "│"
        table.rowFence = "─"
        table.cornerFence = "┼"

        for frameworkInfo in frameworksInfo {
            table.addRow(values: [frameworkInfo.name.lightBlue, "\(frameworkInfo.count)".red])
        }

        print(table.render())
    }
}

