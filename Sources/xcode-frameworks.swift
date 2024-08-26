import ArgumentParser

@main
struct XcodeFrameworks: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "xcode-frameworks".lightRed.bold,
        abstract: "A tool for managing frameworks and xcframeworks in an Xcode project.".cyan,
        subcommands: [ListCommand.self, DuplicatesCommand.self, FixCommand.self, SignCommand.self]
    )
}

