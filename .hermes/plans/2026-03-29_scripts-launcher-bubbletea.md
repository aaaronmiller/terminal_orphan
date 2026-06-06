# Scripts Launcher - Bubble Tea TUI

**Created:** 2026-03-29  
**Priority:** High (user requested)  
**Status:** Ready to implement

---

## Goal

Build a **Charm.sh Bubble Tea TUI launcher** for curated scripts that:
1. Shows useful scripts with descriptions
2. Displays usage examples and arguments
3. Allows quick execution with argument input
4. Uses portable paths (`$HOME` not hardcoded usernames)
5. Filters by platform (Linux/macOS/Both)

---

## Tech Stack

| Component | Library |
|-----------|---------|
| TUI Framework | `github.com/charmbracelet/bubbletea` |
| Styling | `github.com/charmbracelet/lipgloss` |
| Components | `github.com/charmbracelet/bubbles` |
| Table | `github.com/charmbracelet/bubbles/table` |
| Fuzzy Search | `github.com/sahilm/fuzzy` |
| Config | `gopkg.in/yaml.v3` |

---

## Project Structure

```
scripts-launcher/
├── cmd/
│   └── launcher/
│       └── main.go           # Entry point
├── internal/
│   ├── catalog/
│   │   ├── catalog.go        # Load/parse script metadata
│   │   └── categories.go     # Category definitions
│   ├── ui/
│   │   ├── model.go          # Main TUI model
│   │   ├── list.go           # Script list with fuzzy search
│   │   ├── detail.go         # Script detail panel
│   │   ├── args.go           # Argument input modal
│   │   └── styles.go         # Lip gloss styles
│   ├── runner/
│   │   ├── executor.go       # Run scripts
│   │   └── pathfix.go        # Normalize $HOME paths
│   └── config/
│       └── config.go         # User config (favorites, etc)
├── scripts/
│   └── curated.yaml          # Curated script definitions
├── go.mod
├── go.sum
└── README.md
```

---

## Curated Script Schema

```yaml
# scripts/curated.yaml
scripts:
  findit:
    path: "$HOME/code/scripts/findit.sh"
    category: "utils"
    description: "Advanced fuzzy file search with cascading engines (mdfind, fd, git)"
    usage: "findit [query] [-t type] [-s size] [-m mtime]"
    examples:
      - "findit report.pdf"
      - "findit -t py test"
      - "findit -s +1M large"
    args:
      - flag: "-t"
        name: "type"
        desc: "File type preset (py, js, md, pdf, etc)"
      - flag: "-s"
        name: "size"
        desc: "Size filter (+1M, -100k)"
      - flag: "-m"
        name: "mtime"
        desc: "Modified time (-7d, -1w)"
    platform: ["linux", "macos"]
    priority: high

  macdrive:
    path: "$HOME/code/scripts/macdrive.sh"
    category: "macos"
    description: "USB/APFS volume manager for WSL2 - connect macOS drives"
    usage: "macdrive [status|mount|unmount|<busid>]"
    examples:
      - "macdrive"
      - "macdrive status"
      - "macdrive 5-1"
    platform: ["linux"]  # WSL2 only
    priority: high

  cchooks:
    path: "$HOME/code/scripts/cchooks.sh"
    category: "ai"
    description: "Claude Code hooks manager - install/manage CC hooks"
    usage: "cchooks [install|list|remove|<hook>]"
    platform: ["linux", "macos"]
    priority: high
```

---

## TUI Layout

```
┌─ Scripts Launcher ─────────────────────────────────────────────────────┐
│ 🔍 [fuzzy search: type to filter...]                                   │
├────────────────┬───────────────────────────────────────────────────────┤
│ CATEGORIES     │ 📄 findit.sh                                          │
│                │                                                       │
│ ⭐ Favorites   │    Advanced fuzzy file search with cascading engines  │
│ 📁 utils (12)  │    (mdfind, fd, git). Supports file type presets and  │
│ 📁 security (5)│    size/mtime filters.                                │
│ 📁 ai (8)      │                                                       │
│ 📁 macos (10)  │    USAGE: findit [query] [-t type] [-s size] [-m time]│
│ 📁 dev (6)     │                                                       │
│ 📁 all (45)    │    ARGS:                                              │
│                │      -t <type>   File type preset (py,js,md,pdf...)   │
│ ─────────────  │      -s <size>   Size filter (+1M, -100k)             │
│                │      -m <mtime>  Modified time (-7d, -1w)             │
│ [⭐ findit ▼]  │                                                       │
│   macdrive     │    EXAMPLES:                                          │
│   cchooks      │      $ findit report.pdf                              │
│   new-project  │      $ findit -t py test                              │
│   obsidian-..  │      $ findit -s +1M large                            │
│                │                                                       │
├────────────────┴───────────────────────────────────────────────────────┤
│ [R] Run  [E] Edit  [F] Favorite  [S] Search  [Q] Quit                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Setup (Day 1)
- [ ] Install Go (`apt install golang-go`)
- [ ] Initialize module: `go mod init scripts-launcher`
- [ ] Add dependencies
- [ ] Create `scripts/curated.yaml` with ~10 high-priority scripts

### Phase 2: Catalog (Day 2)
- [ ] Build `catalog.go` - load YAML, parse metadata
- [ ] Auto-extract descriptions from script comments
- [ ] Add path normalization (`$HOME` fixer)

### Phase 3: Core TUI (Day 3-4)
- [ ] Main model with tea.Program
- [ ] Script list with fuzzy filtering
- [ ] Category sidebar
- [ ] Detail panel (description, usage, args, examples)

### Phase 4: Execution (Day 5)
- [ ] Argument input modal
- [ ] Script executor with output capture
- [ ] Live output viewport

### Phase 5: Polish (Day 6)
- [ ] Favorites system
- [ ] Help panel
- [ ] Install to PATH
- [ ] Add `sl` alias to `.zshrc`

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts-launcher/go.mod` | Go module |
| `scripts-launcher/cmd/launcher/main.go` | Entry point |
| `scripts-launcher/internal/catalog/catalog.go` | Script catalog |
| `scripts-launcher/internal/catalog/categories.go` | Categories |
| `scripts-launcher/internal/ui/model.go` | TUI model |
| `scripts-launcher/internal/ui/list.go` | Script list |
| `scripts-launcher/internal/ui/detail.go` | Detail panel |
| `scripts-launcher/internal/ui/args.go` | Arg input |
| `scripts-launcher/internal/ui/styles.go` | Lip gloss |
| `scripts-launcher/internal/runner/executor.go` | Run scripts |
| `scripts-launcher/internal/runner/pathfix.go` | Path fix |
| `scripts-launcher/internal/config/config.go` | Config |
| `scripts-launcher/scripts/curated.yaml` | Script defs |
| `scripts-launcher/README.md` | Docs |

---

## Initial Curated Scripts (~10)

Start with these high-priority scripts:

1. `findit.sh` - File search (utils)
2. `macdrive.sh` - USB manager (macos)
3. `cchooks.sh` - CC hooks (ai)
4. `new-project.sh` - Scaffolding (dev)
5. `browser-activity-tracker.sh` - Session backup (utils)
6. `obsidian_harvester.sh` - Knowledge mgmt (utils)
7. `fixextensions.sh` - Extension finder (utils)
8. `nuke.sh` - Process killer (utils)
9. `safe_rm.sh` - Safe delete (utils)
10. `setup_ollama.sh` - AI setup (ai)

---

## Success Criteria

- [ ] Can launch with `sl` command
- [ ] Can search/filter scripts
- [ ] Can view script details + examples
- [ ] Can run scripts with arguments
- [ ] Output displayed in TUI
- [ ] Paths work on any machine (`$HOME`)

---

## Next Step

User approval → Start Phase 1 (Go setup + project init)
