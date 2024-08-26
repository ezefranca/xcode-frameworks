import ArgumentParser

@main
struct EmbeddedFrameworks: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A tool for managing embedded frameworks and xcframeworks in an Xcode project.",
        subcommands: [ListCommand.self, DuplicatesCommand.self, FixCommand.self]
    )
}
