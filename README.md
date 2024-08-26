
# Xcode Framework Manager

A command-line tool for managing frameworks and xcframeworks in an Xcode project. This tool helps you automate the process of embedding, signing, and managing frameworks, including detecting duplicates and fixing them.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Subcommands](#subcommands)
  - [list](#list)
  - [duplicates](#duplicates)
  - [fix](#fix)
  - [embed](#embed)
  - [embed-sign](#embed-sign)
- [Examples](#examples)
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
xcode-frameworks list
```

### duplicates

🔍 **Find and display duplicated frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks duplicates
```

### fix

🔧 **Fix duplicated frameworks in the Xcode project by keeping only one instance.**

**Usage**:

```bash
xcode-frameworks fix
```

### embed

🗳️ **Update the embed status without signing the specified frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks embed <frameworks>...
```

This subcommand allows you to embed frameworks into your Xcode project without signing them.

### embed-sign

🔒 **Update the embedding status to embed and sign the specified frameworks in the Xcode project.**

**Usage**:

```bash
xcode-frameworks embed-sign <frameworks>...
```

This subcommand allows you to embed frameworks into your Xcode project and sign them.

## Examples

- **Listing embedded frameworks**:

  ```bash
  xcode-frameworks list
  ```

- **Finding duplicate frameworks**:

  ```bash
  xcode-frameworks duplicates
  ```

- **Fixing duplicate frameworks**:

  ```bash
  xcode-frameworks fix
  ```

- **Embedding a framework without signing**:

  ```bash
  xcode-frameworks embed MyFramework
  ```

- **Embedding and signing a framework**:

  ```bash
  xcode-frameworks embed-sign MyFramework
  ```

## License

This project is licensed under the MIT License.
