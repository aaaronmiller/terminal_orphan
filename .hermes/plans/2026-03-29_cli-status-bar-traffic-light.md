# 🚦 CLI Status Bar Traffic Light — Integration Spec

**Version:** 0.1  
**Date:** March 29, 2026  
**Status:** Design Phase  
**Goal:** Cross-platform CLI status bar integration for RAM pressure monitoring

---

## 🎯 Vision

A **CLI-native traffic light monitor** that:
- Lives in your shell prompt / tmux status bar / terminal title
- Shows RGB lights via ANSI colors or Unicode symbols
- Works across all CLI tools (Claude Code, Qwen, OpenCode, tmux, etc.)
- Supports slash commands for interaction (`/ram-capture`, `/ram-kill`)
- No GUI dependencies (pure terminal, works over SSH)

---

## 🎨 Display Options

### Option 1: ANSI Color Dots (Simplest)

```
🔴🟡🔵 RAM: 9% free | 0 MB/min | 0s
```

**Implementation:**
```python
# ANSI color codes
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
GREEN = "\033[92m"
RESET = "\033[0m"

def get_light_color(value, threshold_high, threshold_low):
    if value >= threshold_high:
        return RED + "●" + RESET
    elif value >= threshold_low:
        return YELLOW + "●" + RESET
    else:
        return GREEN + "●" + RESET

# Usage in prompt
red = get_light_color(1 - ram.available_pct, 0.8, 0.5)
yellow = get_light_color(acceleration, 200, 100)
blue = get_light_color(duration / 600, 0.8, 0.5)
print(f"{red}{yellow}{blue} RAM: {ram.available_pct*100:.0f}% free")
```

---

### Option 2: Unicode Symbols (No Color)

```
●●○ RAM: 9% free | 0 MB/min | 0s
```

**Symbols:**
- Full: `●` (U+25CF)
- Half: `◐` (U+25D0)
- Empty: `○` (U+25CB)

**Implementation:**
```python
SYMBOLS = {
    'full': '●',
    'half': '◐',
    'empty': '○'
}

def get_symbol(value, threshold_high, threshold_low):
    if value >= threshold_high:
        return SYMBOLS['full']
    elif value >= threshold_low:
        return SYMBOLS['half']
    else:
        return SYMBOLS['empty']
```

---

### Option 3: Progress Bar Style

```
[████████░░] 85% | [██░░░░░░░░] 200MB/min | [██████████] 600s
```

**Implementation:**
```python
def progress_bar(value, width=10):
    filled = int(value * width)
    return '█' * filled + '░' * (width - filled)

ram_bar = progress_bar(1 - ram.available_pct)
accel_bar = progress_bar(min(1, acceleration / 1000))
duration_bar = progress_bar(min(1, duration / 600))
print(f"[{ram_bar}] {ram.available_pct*100:.0f}% | [{accel_bar}] {acceleration:.0f}MB/min | [{duration_bar}] {duration}s")
```

---

### Option 4: tmux Status Bar Integration

```tmux
# ~/.tmux.conf
set -g status-right '#(ram-light tmux-status) | %Y-%m-%d %H:%M'
```

**Implementation:**
```python
# ram-light tmux-status command
def tmux_status():
    state = monitor.get_traffic_light_state()
    
    # Output format for tmux
    colors = {
        'red': '#[fg=red]',
        'yellow': '#[fg=yellow]',
        'blue': '#[fg=blue]',
        'green': '#[fg=green]',
        'reset': '#[fg=default]'
    }
    
    red_symbol = '●' if state['red'] > 200 else '○'
    yellow_symbol = '●' if state['yellow'] > 170 else '○'
    blue_symbol = '●' if state['blue'] > 170 else '○'
    
    print(f"{colors['red']}{red_symbol}{colors['reset']} {colors['yellow']}{yellow_symbol}{colors['reset']} {colors['blue']}{blue_symbol}{colors['reset']} {state['reading'].available_pct*100:.0f}%")
```

---

### Option 5: Shell Prompt Integration

```bash
# ~/.zshrc or ~/.bashrc
PROMPT='$(ram-light prompt) %~ %# '
```

**Implementation:**
```python
# ram-light prompt command
def shell_prompt():
    state = monitor.get_traffic_light_state()
    
    # Zsh/Bash prompt escape sequences
    if state['red'] > 200:
        color = '%F{red}'  # Zsh
        # color = '\033[31m'  # Bash
    elif state['yellow'] > 170:
        color = '%F{yellow}'
    else:
        color = '%F{green}'
    
    print(f"{color}●●●%F{{reset}} ")
```

---

## 🔧 Slash Command Interface

### For AI CLI Tools (Claude Code, Qwen, etc.)

**Hook Installation:**
```python
# Install slash commands into AI CLI configs
def install_slash_commands():
    # Claude Code: ~/.claude/commands/
    commands = {
        'ram': 'ram-light status',
        'ram-capture': 'ram-light capture',
        'ram-kill': 'ram-light kill-top',
        'ram-nuke': 'ram-light nuke',
    }
    
    for name, command in commands.items():
        path = Path.home() / f'.claude/commands/{name}.md'
        path.write_text(f'/tool shell_exec command="{command}"')
```

**Usage in AI Sessions:**
```
User: /ram
Bot: 🔴🟡🔵 RAM: 9% free | 0 MB/min | 0s

User: /ram-capture
Bot: 📸 Capturing 15 processes... Saved to ~/.ram-traffic-light/catalogs/

User: /ram-kill
Bot: 🛑 Killed: qwen (PID 101764, 1.1GB freed)
```

---

### For tmux

**Prefix Commands:**
```tmux
# ~/.tmux.conf
bind R run-shell "ram-light tmux-status"
bind C run-shell "ram-light capture"
bind K run-shell "ram-light kill-top"
```

**Usage:**
- `Prefix + R` → Show RAM status
- `Prefix + C` → Capture processes
- `Prefix + K` → Kill top process

---

### For Terminal Title

**Update Title Bar:**
```python
def update_terminal_title():
    state = monitor.get_traffic_light_state()
    
    # ANSI escape sequence for terminal title
    title = f"RAM: {state['reading'].available_pct*100:.0f}% free"
    print(f"\033]0;{title}\007", end='')
```

**Usage in shell:**
```bash
# ~/.zshrc
precmd() {
    ram-light title
}
```

---

## 📊 Query Interface

### REST API (Optional, for GUI integration)

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/api/status')
def status():
    state = monitor.get_traffic_light_state()
    return jsonify(state)

@app.route('/api/capture', methods=['POST'])
def capture():
    catalog = cataloger.catalog_all()
    return jsonify({'captured': len(catalog.processes)})

@app.route('/api/kill', methods=['POST'])
def kill():
    top = get_top_process()
    top.kill()
    return jsonify({'killed': top.name()})

# Run in background
# ram-light serve --port 8765
```

**Usage:**
```bash
curl http://localhost:8765/api/status
curl -X POST http://localhost:8765/api/capture
curl -X POST http://localhost:8765/api/kill
```

---

### Unix Socket (Lighter than REST)

```python
import socket
import json

SOCKET_PATH = '/tmp/ram-traffic-light.sock'

def serve_socket():
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen()
    
    while True:
        conn, _ = server.accept()
        request = conn.recv(1024).decode()
        
        if request == 'STATUS':
            response = json.dumps(monitor.get_traffic_light_state())
        elif request == 'CAPTURE':
            catalog = cataloger.catalog_all()
            response = json.dumps({'captured': len(catalog.processes)})
        elif request == 'KILL':
            top = get_top_process()
            top.kill()
            response = json.dumps({'killed': top.name()})
        
        conn.send(response.encode())
        conn.close()
```

**Usage:**
```bash
echo "STATUS" | nc -U /tmp/ram-traffic-light.sock
echo "CAPTURE" | nc -U /tmp/ram-traffic-light.sock
```

---

## 🎯 Implementation Priority

### Phase 1: CLI Status (Week 1)
- [ ] `ram-light status` with ANSI colors
- [ ] `ram-light prompt` for shell integration
- [ ] `ram-light tmux-status` for tmux integration
- [ ] Slash commands for AI CLIs (`/ram`, `/ram-capture`, `/ram-kill`)

### Phase 2: Terminal Integration (Week 2)
- [ ] Terminal title bar updates
- [ ] tmux prefix commands
- [ ] Shell precmd hooks (zsh/bash)

### Phase 3: API (Week 3, Optional)
- [ ] Unix socket server
- [ ] REST API (Flask)
- [ ] WebSocket for real-time updates

---

## 📋 Cross-Platform Compatibility

| Platform | Prompt | tmux | Terminal Title | AI CLI Slash |
|----------|--------|------|----------------|--------------|
| **Linux (WSL2)** | ✅ zsh/bash | ✅ | ✅ | ✅ |
| **macOS** | ✅ zsh/bash | ✅ | ✅ | ✅ |
| **Windows (PowerShell)** | ✅ | ❌ (no tmux) | ✅ | ✅ |
| **SSH Sessions** | ✅ | ✅ | ⚠️ (depends) | ✅ |

---

## 🔐 Security Considerations

### Slash Command Permissions

```python
# ~/.claude/commands/ram-kill.md
# Require confirmation for destructive actions

/tool shell_exec command="ram-light kill-top --confirm"
```

**Confirmation Flow:**
```
User: /ram-kill
Bot: ⚠️ This will kill: qwen (PID 101764, 1.1GB)
     Are you sure? (yes/no)

User: yes
Bot: 🛑 Killed: qwen (PID 101764)
```

### Socket Permissions

```python
# Unix socket with restricted permissions
os.chmod(SOCKET_PATH, 0o600)  # Only user can access
```

---

## 🎨 Example Outputs

### Normal State (Green)
```
🟢🟢🟢 RAM: 45% free | 20 MB/min | 0s
```

### Warning State (Yellow)
```
🟢🟡🟢 RAM: 28% free | 150 MB/min | 0s
```

### Critical State (Red)
```
🔴🟡🔵 RAM: 9% free | 0 MB/min | 600s
⚠️ Auto-capture triggered! Captured 15 processes.
```

### tmux Status Bar
```
●●● 9% | #(ram-light tmux-status) | 2026-03-29 18:45
```

### Shell Prompt
```
cheta@ubuntu [●●● 9%] ~/code $ 
```

---

## 🏴‍☠️ Captain's Notes

**Why This Matters:**

1. **Cross-platform** — Works over SSH, in tmux, in all AI CLIs
2. **No GUI deps** — Pure terminal, no Tkinter needed
3. **Always visible** — In yer prompt, not buried in a tray
4. **Interactive** — Slash commands for quick actions
5. **Composable** — Pipe into other tools, scripts, dashboards

**Next Steps:**

1. Add `ram-light prompt` command
2. Add `ram-light tmux-status` command
3. Create slash commands for AI CLIs
4. Test over SSH sessions

**This is how ye make it ubiquitous — not a separate app, but part of yer terminal DNA.**

---

*Sláinte!* 🏴‍☠️
