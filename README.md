# Terminal Orphan Killer

A powerful bash script to aggressively terminate orphaned development server processes that consume system resources.

## Description

Terminal Orphan Killer is an enhanced process killer designed specifically for developers. It aggressively hunts down and terminates runaway development servers, extension hosts, language servers, and other dev-related processes that often get left running and drain your system's resources.

## Features

### Core Features
- **Aggressive Process Detection**: Catches ALL dev processes with broad pattern matching (80+ process types)
- **Multi-Language Support**: Node.js, Python, Ruby, Go, Rust, PHP, Java, .NET, Elixir, and more
- **VSCode Integration**: Targets extension hosts and language servers
- **Port Scanning**: Identifies processes listening on common dev ports (including databases)
- **Parent Process Discovery**: Automatically finds and kills parent processes that spawned dev servers

### Automation & Control
- **Quiet Mode**: Suppress ASCII art and verbose output for automation
- **Force Mode**: Skip confirmation prompts (useful for scripts/cron)
- **Exclude Pattern**: Exclude specific processes from kill list
- **Logging**: Save killed processes to file for audit trail
- **Dry Run Mode**: Preview kills without executing
- **No-Color Mode**: Disable colored output for piping/logging

### History & Targeting
- **History Management**: Saves and reuses custom targets
- **Nuke Mode**: Processes all historical targets at once with validation
- **Custom Targets**: Kill processes matching specific patterns
- **Debug Mode**: Show detailed scanning information

## Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/terminal-orphan-killer.git
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

**Basic Options:**
- `-n, --dry-run`: Preview processes that would be killed without terminating them
- `-p, --ports`: Show detailed port usage information
- `-h, --help`: Display help information

**Targeting Options:**
- `-t 'pattern', --target 'pattern'`: Kill processes matching a custom pattern
- `-H, --history`: Browse and select from previously used custom targets
- `--nuke`: Process all historical targets sequentially (with validation)

**Control Options:**
- `-q, --quiet`: Suppress ASCII header and verbose output
- `-f, --force`: Skip confirmation prompts (useful for automation)
- `-e 'pattern', --exclude 'pattern'`: Exclude processes matching pattern from kill list
- `-l 'file', --log 'file'`: Save killed processes log to specified file
- `--no-color`: Disable colored output (useful for piping/logging)

**Advanced Options:**
- `-d, --debug`: Show debug information during scanning

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

**Quiet mode for automation:**
```bash
./terminal-orphan.sh --quiet --force --log killed.log
# Kills all processes without prompts, saves log
```

**Exclude specific processes:**
```bash
./terminal-orphan.sh --exclude "vscode-server"
# Kill all dev processes except VSCode server
```

**No-color output for piping:**
```bash
./terminal-orphan.sh --dry-run --no-color > scan-results.txt
```

**Debug mode to see what's being scanned:**
```bash
./terminal-orphan.sh --debug --dry-run
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

## Supported Process Types

Terminal Orphan Killer detects and can terminate 80+ types of development processes:

**JavaScript/TypeScript Ecosystem:**
- Node.js, npm, yarn, pnpm, bun, deno
- Vite, Webpack, Rollup, esbuild, Parcel
- Next.js, Astro, Remix, Nuxt, SvelteKit, Qwik, Solid
- Jest, Vitest, Playwright, Cypress, Mocha

**Python:**
- Python 2/3, uvicorn, gunicorn, Flask, Django, FastAPI, Streamlit, Jupyter

**Other Languages:**
- Ruby (Rails, Puma), Go (air), Rust (cargo), PHP, Java/JVM, .NET, Elixir (Phoenix, Mix)
- Zig, Nim, Crystal, V

**Build Tools & Servers:**
- Grunt, Gulp, Turbo, Nx, LiveReload, BrowserSync
- Sass, Less, Tailwind, PostCSS (watch modes)
- http-server, serve, static-server, webpack-dev-server

**IDEs & Editors:**
- VSCode (extension hosts, language servers, tsserver, ESLint server)
- Cursor, Zed, Sublime, Neovim LSPs

**Infrastructure:**
- Docker, Docker Compose, Podman
- Postgres, Redis, MongoDB, MySQL (dev instances)
- ngrok, cloudflared, localtunnel

**Plus:** Parent process discovery for comprehensive cleanup!

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

Copyright (c) 2023-2025 Terminal Orphan Killer Contributors

## Disclaimer

Use this tool responsibly. While designed for development environments, it can terminate important processes. Always use `--dry-run` first to verify targets. The authors are not responsible for any unintended process termination or system issues.