# Terminal Orphan Killer

A powerful bash script to aggressively terminate orphaned development server processes that consume system resources.

## Description

Terminal Orphan Killer is an enhanced process killer designed specifically for developers. It aggressively hunts down and terminates runaway development servers, extension hosts, language servers, and other dev-related processes that often get left running and drain your system's resources.

## Features

- **Aggressive Process Detection**: Catches ALL dev processes with broad pattern matching
- **Multi-Language Support**: Handles Node.js, Python, Ruby, Go, Rust, PHP, and more
- **VSCode Integration**: Targets extension hosts and language servers
- **Port Scanning**: Identifies processes listening on common dev ports
- **History Management**: Saves and reuses custom targets
- **Nuke Mode**: Processes all historical targets at once
- **Dry Run Mode**: Preview kills without executing
- **Port Information**: Display detailed port usage
- **Parent Process Discovery**: Finds and kills parent processes
- **Colorful Output**: Enhanced terminal experience with ASCII art

## Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/yourusername/terminal-orphan-killer.git
   cd terminal-orphan-killer
   ```

2. Make the script executable:
   ```bash
   chmod +x terminal-orphan.sh
   ```

3. (Optional) Add to your PATH for global access:
   ```bash
   sudo ln -s $(pwd)/terminal-orphan.sh /usr/local/bin/tok
   ```

## Usage

### Basic Usage

Kill all dev processes:
```bash
./terminal-orphan.sh
```

### Command Line Options

- `-n, --dry-run`: Preview processes that would be killed without terminating them
- `-p, --ports`: Show detailed port usage information
- `-t 'pattern', --target 'pattern'`: Kill processes matching a custom pattern
- `-H, --history`: Browse and select from previously used custom targets
- `--nuke`: Process all historical targets sequentially
- `-h, --help`: Display help information

### Examples

**Dry run to see what would be killed:**
```bash
./terminal-orphan.sh --dry-run
```

**Kill processes on specific ports:**
```bash
./terminal-orphan.sh --ports
```

**Kill custom target:**
```bash
./terminal-orphan.sh --target "my-app"
```

**Browse history:**
```bash
./terminal-orphan.sh --history
# Interactive selection from saved targets
```

**Nuke all historical targets:**
```bash
./terminal-orphan.sh --nuke
```

**Combined usage:**
```bash
./terminal-orphan.sh --dry-run --ports
```

## History File Behavior

The script maintains a history file `terminal_orphan_targets.txt` in the same directory as the script. This file:

- Stores custom targets with timestamps
- Is automatically created when using custom targets
- Can be browsed interactively with `--history`
- All entries can be processed at once with `--nuke`
- Format: `YYYY-MM-DD HH:MM:SS pattern`

Example history file content:
```
2023-10-01 14:30:15 my-react-app
2023-10-02 09:15:22 python-server
2023-10-02 16:45:33 vite-dev
```

## Requirements

- **Bash**: Version 4.0 or higher
- **pgrep**: Process grep utility (usually pre-installed on Unix systems)
- **lsof**: List open files utility (install with `brew install lsof` on macOS)
- **ps**: Process status utility (standard on Unix systems)

### Supported Platforms

- macOS
- Linux
- WSL (Windows Subsystem for Linux)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2023 Terminal Orphan Killer Contributors

## Disclaimer

Use this tool responsibly. While designed for development environments, it can terminate important processes. Always use `--dry-run` first to verify targets. The authors are not responsible for any unintended process termination or system issues.