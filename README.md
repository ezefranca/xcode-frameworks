# xcode-frameworks

A command-line tool built on top of [XcodeProj](https://github.com/tuist/XcodeProj) for managing frameworks and xcframeworks in an Xcode project. This tool helps you automate the process of embedding, signing, and managing frameworks, including detecting duplicates and fixing them.

## Motivation

We often work on projects that share frameworks with common dependencies, which need to be integrated manually for various reasons. Due to this, dependencies can sometimes be duplicated, resulting in duplicated symbols and compilation errors. Additionally, some third-party vendor frameworks need to be set to embed and sign, which can lead to crashes if not configured correctly.

This tool was created to automate these tasks and eliminate the need for manual configuration in Xcode.

> [!NOTE]  
> This is a work in progress (WIP). Contributions are welcome!

https://github.com/user-attachments/assets/54fcabaf-1712-4577-a21f-1a2e511a4044

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Subcommands](#subcommands)
  - [list](#list)
  - [duplicates](#duplicates)
  - [fix](#fix)
  - [embed](#embed)
  - [embed-sign](#embed-sign)
- [License](#license)

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/ezefranca/xcode-framework.git
   cd xcode-framework-manager
   ```

2. **Install dependencies**:
   You need to install the required Swift libraries before using this tool.

   ```bash
   swift build
   ```

3. **Build the tool**:

   ```bash
   swift build -c release
   ```

4. **Install**:

   To install the tool globally, use the following command:

   ```bash
   cp .build/release/xcode-frameworks /usr/local/bin/xcode-frameworks
   ```

## Usage

This tool provides several subcommands to help you manage the frameworks in your Xcode projects. You can run the tool using the following syntax:

```bash
xcode-frameworks <subcommand> [options]
```

## Subcommands

### list

📋 **List all embedded frameworks and xcframeworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks list <your-project-path>
```

### duplicates

🔍 **Find and display duplicated frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks duplicates <your-project-path>
```

### fix

🔧 **Fix duplicated frameworks in the Xcode project by keeping only one instance.**

**Usage**:

```bash
xcode-frameworks fix <your-project-path>
```

### embed

🗳️ **Update the embed status without signing the specified frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks embed <your-project-path> --frameworks <yours frameworks>...
```

This subcommand allows you to embed frameworks into your Xcode project without signing them.

### embed-sign

🔒 **Update the embedding status to embed and sign the specified frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks embed-sign <your-project-path> --frameworks <frameworks>...
```

This subcommand allows you to embed frameworks into your Xcode project and sign them.

## License

This project is licensed under the MIT License.
