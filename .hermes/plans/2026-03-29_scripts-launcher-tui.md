# Scripts Launcher TUI Plan

**Date:** March 29, 2026  
**Author:** Captain Seamus "Barnacle" O'Byte  
**Status:** Planning

---

## Goal

Build a **Bubble Tea (Go) TUI launcher** for the curated scripts in `/home/cheta/code/scripts/` that:
- Shows only **useful, functional scripts** (not deprecated/duplicate junk)
- Displays **description**, **usage examples**, and **available arguments** for each script
- Allows **quick execution** with argument input
- Has **proper TUI flair** (search, filtering, categories, help panels)
- Uses **portable paths** (`$HOME` instead of hardcoded usernames)

---

## Current Context

- Scripts location: `/home/cheta/code/scripts/` (~473 files, ~45 are actually useful)
- User environment: WSL2 on Windows 11, HP Spectre 16"
- Existing launcher: None (just raw CLI aliases in `.zshrc`)
- Script metadata: Descriptions exist as comments in scripts (`# description` pattern)

---

## Proposed Approach

### Tech Stack
- **Language:** Go (Golang)
- **TUI Framework:** [Bubble Tea](https://github.com/charmbracelet/bubbletea) + [Lip Gloss](https://github.com/charmbracelet/lipgloss)
- **Components:**
  - `bubbletea` - TUI framework ( Elm architecture)
  - `lipgloss` - Styling
  - `bubble-table` - Script list table
  - `fzf`-style fuzzy search
  - `bubbles` - Standard components (text input, viewport, spinner)

### Architecture

```
scripts-launcher/
├── cmd/
│   └── launcher/
│       └── main.go          # Entry point
├── internal/
│   ├── catalog/
│   │   ├── catalog.go       # Script catalog loading/parsing
│   │   ├── metadata.go      # Script metadata extraction
│   │   └── categories.go    # Category definitions
│   ├── ui/
│   │   ├── main_view.go     # Main TUI layout
│   │   ├── script_list.go   # Filterable script list
│   │   ├── script_detail.go # Script info panel
│   │   ├── arg_input.go     # Argument input form
│   │   └── help_panel.go    # Keybindings help
│   ├── runner/
│   │   ├── executor.go      # Script execution
│   │   ├── pathfix.go       # Path normalization ($HOME fix)
│   │   └── output.go        # Output capture/display
│   └── config/
│       └── config.go        # Configuration (favorites, aliases)
├── scripts/
│   └── curated.json         # Curated script list (auto-generated)
├── go.mod
├── go.sum
└── README.md
```

---

## Step-by-Step Plan

### Phase 1: Foundation (Day 1-2)

1. **Initialize Go project**
   - `go mod init scripts-launcher`
   - Add dependencies: `bubbletea`, `lipgloss`, `bubbles`

2. **Build script catalog loader**
   - Parse scripts for metadata:
     - Shebang line
     - Description comment (`# description` or `# Purpose:`)
     - Usage examples (`# Usage:`)
     - Arguments (`# Args:` or `# Arguments:`)
   - Extract from: `/home/cheta/code/scripts/*.sh`, `*.py`
   - Store in `catalog.Catalog` struct

3. **Create curated script list**
   - Start with the **45 KEEP scripts** from audit
   - Store in `scripts/curated.json`
   - Format:
     ```json
     {
       "findit": {
         "path": "$HOME/code/scripts/findit.sh",
         "category": "utils",
         "description": "Advanced fuzzy file search with cascading engines",
         "usage": "findit [query] [-t type] [-s size] [-m mtime]",
         "examples": ["findit report.pdf", "findit -t py test"],
         "args": {"-t": "file type", "-s": "size filter", "-m": "modified time"},
         "platform": ["linux", "macos"],
         "priority": "high"
       }
     }
     ```

### Phase 2: Core TUI (Day 3-4)

4. **Build main view layout**
   - Three-pane layout:
     ```
     ┌─────────────────────────────────────────────────────┐
     │ Scripts Launcher                    [🔍 Search]     │
     ├──────────────────┬──────────────────────────────────┤
     │                  │  Description:                    │
     │ 📁 utils (12)    │  Advanced fuzzy file search with │
     │ 📁 security (5)  │  cascading engines (mdfind, fd,  │
     │ 📁 ai (8)        │  git). Supports file type presets│
     │ 📁 macos (10)    │  and size/mtime filters.         │
     │ 📁 dev (6)       │                                  │
     │ 📁 archive (4)   │  Usage: findit [query] [opts]    │
     │                  │                                  │
     │ [⭐ findit    ▼] │  Args:                           │
     │   browser-track  │  -t <type>  File type preset     │
     │   obsidian-harv  │  -s <size>  Size filter          │
     │   new-project    │  -m <mtime> Modified time        │
     │                  │                                  │
     ├──────────────────┴──────────────────────────────────┤
     │  [R] Run  [E] Edit  [F] Favorite  [Q] Quit          │
     └─────────────────────────────────────────────────────┘
     ```

5. **Implement filtering/search**
   - Fuzzy search across script names + descriptions
   - Category filter (sidebar)
   - Platform filter (Linux/macOS/Both)

6. **Add script detail panel**
   - Full description
   - Usage syntax
   - Available arguments with descriptions
   - Example commands

### Phase 3: Execution (Day 5-6)

7. **Build argument input form**
   - Modal dialog for entering arguments
   - Pre-fill from common patterns
   - Validate before execution

8. **Script execution engine**
   - Run scripts in detached subprocess
   - Capture stdout/stderr
   - Show live output in viewport
   - Handle exit codes

9. **Path normalization**
   - Replace hardcoded paths with `$HOME` tokens
   - Detect and warn about platform-specific paths
   - Offer to fix scripts on-the-fly

### Phase 4: Polish (Day 7-8)

10. **Add configuration**
    - Favorite scripts
    - Custom argument presets
    - Theme customization (Lip Gloss)

11. **Help system**
    - Interactive keybindings panel
    - Script-specific help
    - Tutorial mode for first run

12. **Install & integration**
    - Build binary
    - Add to PATH
    - Create `scripts` or `sl` alias in `.zshrc`

---

## Files to Change/Create

### New Files
| File | Purpose |
|------|---------|
| `scripts-launcher/go.mod` | Go module definition |
| `scripts-launcher/go.sum` | Dependencies |
| `scripts-launcher/cmd/launcher/main.go` | Entry point |
| `scripts-launcher/internal/catalog/catalog.go` | Script catalog |
| `scripts-launcher/internal/catalog/metadata.go` | Metadata extraction |
| `scripts-launcher/internal/catalog/categories.go` | Category definitions |
| `scripts-launcher/internal/ui/main_view.go` | Main TUI layout |
| `scripts-launcher/internal/ui/script_list.go` | Script list component |
| `scripts-launcher/internal/ui/script_detail.go` | Detail panel |
| `scripts-launcher/internal/ui/arg_input.go` | Argument input modal |
| `scripts-launcher/internal/ui/help_panel.go` | Help panel |
| `scripts-launcher/internal/runner/executor.go` | Script execution |
| `scripts-launcher/internal/runner/pathfix.go` | Path normalization |
| `scripts-launcher/internal/runner/output.go` | Output handling |
| `scripts-launcher/internal/config/config.go` | User config |
| `scripts-launcher/scripts/curated.json` | Curated script list |
| `scripts-launcher/README.md` | Documentation |

### Modified Files
| File | Change |
|------|--------|
| `~/.zshrc` | Add `alias sl='scripts-launcher'` |

---

## Tests / Validation

1. **Unit tests:**
   - Catalog loading/parsing
   - Metadata extraction
   - Path normalization

2. **Integration tests:**
   - Script execution (dry-run mode)
   - Argument parsing

3. **Manual testing:**
   - Run each curated script via launcher
   - Test on WSL2 (primary)
   - Test path normalization on different usernames

---

## Risks & Tradeoffs

| Risk | Mitigation |
|------|------------|
| **Go not installed** | Install via `apt install golang-go` or `go install` |
| **Bubble Tea learning curve** | Start with minimal example, iterate |
| **Script metadata inconsistent** | Use fallback heuristics, allow manual curation |
| **Platform-specific scripts** | Filter by platform, warn before running |
| **Hardcoded paths everywhere** | Path normalization layer, warn user |

---

## Open Questions

1. **Should the launcher auto-generate curated.json** by scanning scripts, or should it be manually curated?
   - **Recommendation:** Hybrid - auto-scan for metadata, manual curation for inclusion

2. **Should macOS scripts be shown on Linux?**
   - **Recommendation:** Yes, but filtered by default with "show all" option

3. **Should we support editing scripts from the launcher?**
   - **Recommendation:** Yes, open in `$EDITOR` (nano/vscode)

4. **Should we cache script output or always run fresh?**
   - **Recommendation:** Always fresh for safety, cache only for read-only ops

---

## Estimated Timeline

| Phase | Days | Deliverable |
|-------|------|-------------|
| Foundation | 2 | Catalog loader + curated list |
| Core TUI | 2 | Working TUI with search/filter |
| Execution | 2 | Script running + arg input |
| Polish | 2 | Config + help + install |
| **Total** | **8** | **Production-ready launcher** |

---

## Next Steps

1. User approves plan
2. Install Go if not present
3. Initialize project structure
4. Build catalog loader (Phase 1)

---

*"The Dublin coders invented TUIs, 'twas only natural after all that Guinness."* 🏴‍☠️🇮🇪
