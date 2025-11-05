#!/usr/bin/env bash
# ---
# title: Enhanced Dev Server Killer - Full Featured Edition
# date: 2025-11-04 00:00:00 UTC
# ver: 2.7.0
# author: Sliither
# model: Claude Sonnet 4.5
# tags: [bash, process-management, debugging, dev-tools, process-killer, pattern-matching, pgrep, terminal]
# ---

# Enhanced Dev Server Killer - AGGRESSIVE EDITION (FULL FEATURED)
# Catches ALL dev processes with corrected pattern matching
# Version: 2.7.0 (Added parent discovery, quiet/force/exclude/log/no-color modes)

set -euo pipefail

# --- Configuration & Colors ---
DRY_RUN=0
CUSTOM_TARGET=""
SHOW_PORTS=0
AGGRESSIVE=1  # Default to aggressive mode
HISTORY=0
NUKE=0
SHOW_HEADER=1
DEBUG=0
QUIET=0
FORCE=0
EXCLUDE_PATTERN=""
LOG_FILE=""
NO_COLOR=0

# Shell color constants (will be disabled if --no-color is set)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Function to disable colors
disable_colors() {
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    BOLD=''
    DIM=''
    NC=''
}

# --- UI Functions ---

show_header() {
    echo -e "${CYAN}"
    echo "=___________      .__                                   .___ ___________                  .__              .__ "
    echo "\\_   _____/ ____ |  |__ _____    ____   ____  ____   __| _/ \\__    ___/__________  _____ |__| ____ _____  |  |"
    echo " |    __)_ /    \\|  |  \\__  \\  /    \\_/ ___\\/ __ \\ / __ |    |    |_/ __ \\_  __ \\/     \\|  |/    \\\\__  \\ |  |"
    echo " |        \\   |  \\   Y  \\/ __ \\|   |  \\  \\__\\  ___// /_/ |    |    |\\  ___/|  | \\/  Y Y  \\  |   |  \\/ __ \\|  |__"
    echo "/_______  /___|  /___|  (____  /___|  /\\___  >___  >____ |    |____| \\___  >__|  |__|_|  /__|___|  (____  /____/"
    echo "       \\/     \\/     \\/     \\/     \\/     \\/    \\/     \\/               \\/            \\/        \\/     \\/"
    echo "__________                                             ____  __.__.__  .__"
    echo "\\______   \\_______  ____   ____  ____   ______ ______ |    |/ _|__|  | |  |   ___________"
    echo " |     ___/\\_  __ \\/  _ \\_/ ___\\/ __ \\ /  ___//  ___/ |      < |  |  | |  | _/ __ \\_  __ \\"
    echo " |    |     |  | \\(  <_> )  \\__\\  ___/ \\___ \\ \\___ \\  |    |  \\|  |  |_|  |_\\  ___/|  | \\/"
    echo " |____|     |__|   \\____/ \\___  >___  >____  >____  > |____|__ \\__|____/____/\\___  >__|"
    echo "                              \\/    \\/     \\/     \\/          \\/                 \\/"
    echo -e "${NC}"
}

show_usage() {
    echo -e "${BOLD}Enhanced Terminal Process Killer - AGGRESSIVE MODE${NC}"
    echo -e "${YELLOW}⚠️  Now catches ALL dev processes with broad patterns!${NC}"
    echo ""
    printf "  %-40s %s\n" "$(echo -e ${CYAN}OPTIONS${NC})" "$(echo -e ${CYAN}TARGETS${NC})"
    printf "  %-40s %s\n" "$(echo -e ${DIM}-----------------------------------${NC})" "$(echo -e ${DIM}-------------------------${NC})"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-n, --dry-run${NC}        Preview kills")" "• ALL node/python/bun/deno processes"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-p, --ports${NC}           Show port usage")" "• VSCode extension hosts & language servers"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-t 'pattern'${NC}       Custom target")" "• Docker containers & compose"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-H, --history${NC}       Browse target history")" "• Ruby/Go/Rust/PHP dev servers"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}--nuke${NC}              Process all history")" "• Database dev instances"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-d, --debug${NC}         Show debug info")" "• ANY process listening on dev ports"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-q, --quiet${NC}         Suppress header/verbose output")" "• Parent process discovery"
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-f, --force${NC}         Skip confirmation prompts")" ""
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-e 'pattern'${NC}     Exclude matching processes")" ""
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-l 'file'${NC}        Log killed processes to file")" ""
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}--no-color${NC}          Disable colored output")" ""
    printf "  %-40s %s\n" "$(echo -e "${YELLOW}-h, --help${NC}          Show this and exit")" ""
    echo ""
}

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -t|--target)
            if [[ -z "${2-}" || "${2-}" =~ ^- ]]; then
              echo -e "${RED}Error: --target option requires an argument.${NC}" >&2
              exit 1
            fi
            CUSTOM_TARGET="$2"
            shift 2
            ;;
        -p|--ports)
            SHOW_PORTS=1
            shift
            ;;
        -H|--history)
            HISTORY=1
            shift
            ;;
        --nuke)
            NUKE=1
            shift
            ;;
        -d|--debug)
            DEBUG=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            SHOW_HEADER=0
            shift
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        -e|--exclude)
            if [[ -z "${2-}" || "${2-}" =~ ^- ]]; then
              echo -e "${RED}Error: --exclude option requires an argument.${NC}" >&2
              exit 1
            fi
            EXCLUDE_PATTERN="$2"
            shift 2
            ;;
        -l|--log)
            if [[ -z "${2-}" || "${2-}" =~ ^- ]]; then
              echo -e "${RED}Error: --log option requires an argument.${NC}" >&2
              exit 1
            fi
            LOG_FILE="$2"
            shift 2
            ;;
        --no-color)
            NO_COLOR=1
            shift
            ;;
        -h|--help)
            show_header
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            exit 1
            ;;
    esac
done

# Apply --no-color if set
[[ $NO_COLOR -eq 1 ]] && disable_colors

# Quiet mode suppresses header
[[ $QUIET -eq 1 ]] && SHOW_HEADER=0

# --- Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="$SCRIPT_DIR/terminal_orphan_targets.txt"

# --- Main Execution ---

[[ $SHOW_HEADER -eq 1 ]] && show_header
[[ $SHOW_HEADER -eq 1 ]] && show_usage

# --- Save target to history if provided ---
if [[ -n "$CUSTOM_TARGET" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') $CUSTOM_TARGET" >> "$HISTORY_FILE"
fi

process_and_kill() {
# --- Process Discovery ---
declare -a TARGET_PIDS=()
declare -A pid_sources=()  # Track where each PID came from

if [[ -n "$CUSTOM_TARGET" ]]; then
    echo -e "${MAGENTA}▶ Hunting for custom target:${NC} '${YELLOW}$CUSTOM_TARGET${NC}'"
    readarray -t pids <<< "$(pgrep -f "$CUSTOM_TARGET" 2>/dev/null || true)"
    if [[ ${#pids[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Found:${NC} ${pids[*]}"
        for pid in "${pids[@]}"; do
            if [ -z "$pid" ]; then continue; fi
            TARGET_PIDS+=("$pid")
            pid_sources["$pid"]="custom"
        done
    else
        echo -e "  ${DIM}No matches found.${NC}"
    fi
else
    echo -e "${MAGENTA}▶ Scanning for ALL dev processes (aggressive mode)...${NC}"
    
    # FIXED: More lenient patterns that actually catch processes
    declare -A targets_map=(
        # Node ecosystem - RELAXED patterns (removed ^ and trailing space)
        ["node"]="node"           # Catches /usr/bin/node, node, nodejs, etc.
        ["npm"]="npm"
        ["yarn"]="yarn"
        ["pnpm"]="pnpm"
        ["bun"]="bun"
        ["deno"]="deno"
        
        # Python ecosystem - RELAXED patterns
        ["python"]="python"       # Catches python, python3, python3.11, etc.
        
        # VSCode nightmare processes
        ["vscode-ext"]="extensionHost"
        ["vscode-ts"]="tsserver"
        ["vscode-eslint"]="eslint.*--server"
        ["vscode-langserv"]="language.*server"
        
        # JavaScript tooling
        ["vite"]="vite"
        ["webpack"]="webpack"
        ["next"]="next"
        ["nodemon"]="nodemon"
        ["ts-node"]="ts-node"
        ["esbuild"]="esbuild"
        ["rollup"]="rollup"
        ["parcel"]="parcel"
        
        # Python servers
        ["uvicorn"]="uvicorn"
        ["gunicorn"]="gunicorn"
        ["flask"]="flask"
        ["django"]="manage\.py"
        ["fastapi"]="fastapi"
        ["streamlit"]="streamlit"
        ["jupyter"]="jupyter"
        
        # Ruby
        ["ruby"]="ruby"
        ["rails"]="rails"
        ["puma"]="puma"
        
        # Go
        ["go"]="go run"
        ["air"]="air"
        
        # Rust
        ["cargo"]="cargo (run|watch)"
        
        # PHP
        ["php"]="php.*(-S|artisan)"
        
        # Docker
        ["docker"]="docker"
        ["compose"]="docker-compose"
        ["podman"]="podman"
        
        # Databases (dev instances only)
        ["postgres"]="postgres"
        ["redis"]="redis-server"
        ["mongodb"]="mongod"
        ["mysql"]="mysqld"

        # Java/JVM ecosystem
        ["java"]="java.*(-jar|spring|tomcat)"
        ["gradle"]="gradle"
        ["maven"]="mvn"
        ["kotlin"]="kotlin"

        # .NET ecosystem
        ["dotnet"]="dotnet"

        # Elixir/Erlang
        ["elixir"]="elixir"
        ["mix"]="mix (phx\.server|run)"
        ["phoenix"]="phoenix"
        ["beam"]="beam.*smp"

        # Build tools
        ["grunt"]="grunt"
        ["gulp"]="gulp"
        ["turbo"]="turbo"
        ["nx"]="nx"
        ["make"]="make.*watch"

        # Modern JS frameworks
        ["astro"]="astro"
        ["remix"]="remix"
        ["nuxt"]="nuxt"
        ["sveltekit"]="svelte-kit"
        ["qwik"]="qwik"
        ["solid"]="solid-start"

        # Test runners (watch modes)
        ["jest"]="jest.*--watch"
        ["vitest"]="vitest"
        ["playwright"]="playwright"
        ["cypress"]="cypress"
        ["mocha"]="mocha.*--watch"

        # CSS/Style processors
        ["sass"]="sass.*--watch"
        ["less"]="less.*--watch"
        ["tailwind"]="tailwindcss.*--watch"
        ["postcss"]="postcss.*--watch"

        # Tunneling/Proxy
        ["ngrok"]="ngrok"
        ["cloudflared"]="cloudflared"
        ["localtunnel"]="localtunnel"

        # Editors/IDEs (language servers)
        ["cursor"]="cursor"
        ["zed"]="zed"
        ["sublime"]="sublime"
        ["neovim"]="nvim"
        ["vim-lsp"]="vim.*lsp"

        # Electron helpers
        ["electron"]="[Ee]lectron"
        ["electron-helper"]="[Ee]lectron.*[Hh]elper"

        # Emerging languages
        ["zig"]="zig"
        ["nim"]="nim"
        ["crystal"]="crystal"
        ["vlang"]="v run"

        # Other dev servers
        ["livereload"]="livereload"
        ["browsersync"]="browser-sync"
        ["webpack-dev"]="webpack-dev-server"
        ["http-server"]="http-server"
        ["serve"]="serve"
        ["static-server"]="static-server"
    )

    output_lines=("" "" "" "" "")
    count=0
    line_idx=0
    
    for key in "${!targets_map[@]}"; do
        if [[ $DEBUG -eq 1 ]]; then
            echo -e "${DIM}[DEBUG] Searching for pattern: '${targets_map[$key]}'${NC}"
        fi
        
        readarray -t pids <<< "$(pgrep -f "${targets_map[$key]}" 2>/dev/null || true)"
        
        if [[ $DEBUG -eq 1 && ${#pids[@]} -gt 0 ]]; then
            echo -e "${DIM}[DEBUG] Raw PIDs for '$key': ${pids[*]}${NC}"
        fi
        
        # Filter out current shell and this script
        filtered_pids=()
        for pid in "${pids[@]}"; do
            if [[ -n "$pid" && "$pid" != "$$" && "$pid" != "$PPID" ]]; then
                cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
                
                if [[ $DEBUG -eq 1 ]]; then
                    echo -e "${DIM}[DEBUG] PID $pid command: $cmd${NC}"
                fi
                
                # FIXED: More specific exclusion - only exclude THIS script
                if [[ ! "$cmd" =~ terminal_orphan.*sh ]]; then
                    # Check exclude pattern if provided
                    if [[ -n "$EXCLUDE_PATTERN" && "$cmd" =~ $EXCLUDE_PATTERN ]]; then
                        if [[ $DEBUG -eq 1 ]]; then
                            echo -e "${DIM}[DEBUG] PID $pid excluded by pattern: $EXCLUDE_PATTERN${NC}"
                        fi
                    else
                        filtered_pids+=("$pid")
                        pid_sources["$pid"]="$key"
                    fi
                fi
            fi
        done
        
        if [[ ${#filtered_pids[@]} -gt 0 ]]; then
            TARGET_PIDS+=("${filtered_pids[@]}")
            formatted_output=$(printf "%-28s" "$(echo -e "${GREEN}${key}:${NC} ${#filtered_pids[@]}")")
        else
            formatted_output=$(printf "%-28s" "$(echo -e "${DIM}${key}: none${NC}")")
        fi

        output_lines[$line_idx]+="$formatted_output"
        ((count++))
        
        # 3 columns per line
        if (( count % 3 == 0 )); then
            ((line_idx++))
        fi
    done
    
    # Only print non-empty lines
    printed_any=0
    for line in "${output_lines[@]}"; do
        if [[ -n "$line" ]]; then
            echo -e "$line"
            printed_any=1
        fi
    done
    
    # If we printed the grid, add a spacer
    [[ $printed_any -eq 1 ]] && echo ""
    
    # BONUS: Check for processes listening on dev ports
    echo ""
    echo -e "${MAGENTA}▶ Scanning processes listening on dev ports...${NC}"
    dev_ports=(3000 3001 4000 4200 5000 5173 5174 8000 8080 8081 8888 9000 5432 6379 27017)
    port_pids_found=0
    
    for port in "${dev_ports[@]}"; do
        readarray -t port_pids <<< "$(lsof -ti ":$port" 2>/dev/null || true)"
        for pid in "${port_pids[@]}"; do
            if [[ -n "$pid" && "$pid" != "$$" ]]; then
                # Check if we haven't already caught this PID
                if [[ -z "${pid_sources[$pid]:-}" ]]; then
                    TARGET_PIDS+=("$pid")
                    pid_sources["$pid"]="port:$port"
                    ((port_pids_found++))
                fi
            fi
        done
    done
    
    if [[ $port_pids_found -gt 0 ]]; then
        echo -e "  ${GREEN}Found ${port_pids_found} additional process(es) on dev ports${NC}"
    else
        echo -e "  ${DIM}No additional processes found on dev ports${NC}"
    fi
    
    echo "" # Spacer after port scan
fi

# --- Parent Process Discovery ---
declare -a ALL_PIDS=("${TARGET_PIDS[@]}")

if [[ -z "$CUSTOM_TARGET" && ${#TARGET_PIDS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${MAGENTA}▶ Checking for parent processes...${NC}"
    parent_count=0

    for pid in "${TARGET_PIDS[@]}"; do
        if [[ -n "$pid" ]]; then
            ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)
            if [[ -n "$ppid" && "$ppid" != "1" && "$ppid" != "$$" ]]; then
                parent_cmd=$(ps -o command= -p "$ppid" 2>/dev/null || true)
                # Catch parent shells/runners but not system shells
                if [[ "$parent_cmd" =~ (npm|node|yarn|pnpm|bun|python|ruby|cargo|go|java|dotnet|mix|elixir) && ! "$parent_cmd" =~ terminal_orphan.*sh ]]; then
                    # Check exclude pattern if provided
                    if [[ -n "$EXCLUDE_PATTERN" && "$parent_cmd" =~ $EXCLUDE_PATTERN ]]; then
                        if [[ $DEBUG -eq 1 ]]; then
                            echo -e "${DIM}[DEBUG] Parent PID $ppid excluded by pattern: $EXCLUDE_PATTERN${NC}"
                        fi
                    elif [[ -z "${pid_sources[$ppid]:-}" ]]; then
                        ALL_PIDS+=("$ppid")
                        pid_sources["$ppid"]="parent"
                        ((parent_count++))
                    fi
                fi
            fi
        fi
    done

    [[ $parent_count -gt 0 ]] && echo -e "  ${GREEN}+ Added ${parent_count} parent process(es)${NC}" || echo -e "  ${DIM}No parent processes found${NC}"
fi

# Remove duplicates
declare -A seen
declare -a UNIQUE_PIDS=()
for pid in "${ALL_PIDS[@]}"; do
    if [[ -n "$pid" && -z "${seen[$pid]:-}" ]]; then
        UNIQUE_PIDS+=("$pid")
        seen["$pid"]=1
    fi
done

echo "" # Spacer

# --- Port Information Display ---
if [[ $SHOW_PORTS -eq 1 ]]; then
    echo -e "${MAGENTA}▶ Port usage details:${NC}"
    echo ""
    printf "  %-8s %-8s %-15s %s\n" "PORT" "PID" "PROCESS" "COMMAND"
    printf "  %-8s %-8s %-15s %s\n" "----" "---" "-------" "-------"
    
    for port in 3000 3001 4000 4200 5000 5173 5174 8000 8080 8081 8888 9000 5432 6379 27017; do
        pid=$(lsof -ti ":$port" 2>/dev/null | head -1 || true)
        if [[ -n "$pid" ]]; then
            cmd=$(ps -o comm= -p "$pid" 2>/dev/null || true)
            full_cmd=$(ps -o command= -p "$pid" 2>/dev/null | head -c 40 || true)
            printf "  %-8s %-8s %-15s %s\n" "$port" "$pid" "$cmd" "$full_cmd"
        fi
    done
    echo "" # Spacer
fi

# --- Execution & Termination ---
if [[ ${#UNIQUE_PIDS[@]} -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}✅ SCAN COMPLETE - No matching processes found to terminate.${NC}"
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${GREEN}Good news!${NC} Your system is clean of orphaned dev processes.      ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show what was scanned
    echo -e "${BOLD}📋 Scanned categories:${NC}"
    echo -e "${DIM}"
    categories=($(printf '%s\n' "${!targets_map[@]}" | sort))
    category_count=${#categories[@]}
    
    # Print in columns
    col_width=25
    cols=3
    for ((i=0; i<category_count; i++)); do
        printf "  %-${col_width}s" "• ${categories[$i]}"
        if (( (i+1) % cols == 0 )); then
            echo ""
        fi
    done
    
    # Print final newline if needed
    (( category_count % cols != 0 )) && echo ""
    echo -e "${NC}"
    
    echo -e "${DIM}💡 If your fan is still spinning, try:${NC}"
    echo -e "${DIM}   • Check Activity Monitor for non-dev processes${NC}"
    echo -e "${DIM}   • Run with -d flag for debug info: ./terminal_orphan.sh -d${NC}"
    echo ""
    
    if [[ $DEBUG -eq 1 ]]; then
        echo ""
        echo -e "${YELLOW}[DEBUG] Showing ALL node/python processes for comparison:${NC}"
        echo -e "${DIM}$(ps aux | grep -E 'node|python' | grep -v grep)${NC}"
    fi
    
    exit 0
fi

echo -e "${BOLD}🎯 Found ${#UNIQUE_PIDS[@]} process(es) to terminate:${NC}"
echo ""
printf "  %-8s %-8s %-15s %s\n" "PID" "PPID" "SOURCE" "COMMAND"
printf "  %-8s %-8s %-15s %s\n" "---" "----" "------" "-------"

for pid in "${UNIQUE_PIDS[@]}"; do
    ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || echo "?")
    source="${pid_sources[$pid]:-unknown}"
    cmd=$(ps -o command= -p "$pid" 2>/dev/null | head -c 60 || echo "?")
    printf "  %-8s %-8s %-15s %s\n" "$pid" "$ppid" "$source" "$cmd"
done

echo "" # Spacer

# Initialize log file if provided
if [[ -n "$LOG_FILE" ]]; then
    echo "# Terminal Orphan Killer - Kill Log" > "$LOG_FILE"
    echo "# Date: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "# Total processes: ${#UNIQUE_PIDS[@]}" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    printf "%-8s %-8s %-15s %s\n" "PID" "PPID" "SOURCE" "COMMAND" >> "$LOG_FILE"
    printf "%-8s %-8s %-15s %s\n" "---" "----" "------" "-------" >> "$LOG_FILE"
    for pid in "${UNIQUE_PIDS[@]}"; do
        ppid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || echo "?")
        source="${pid_sources[$pid]:-unknown}"
        cmd=$(ps -o command= -p "$pid" 2>/dev/null || echo "?")
        printf "%-8s %-8s %-15s %s\n" "$pid" "$ppid" "$source" "$cmd" >> "$LOG_FILE"
    done
    echo "" >> "$LOG_FILE"
fi

if (( DRY_RUN )); then
    echo -e "🔍 ${YELLOW}[DRY RUN]${NC} No processes were harmed."
    echo -e "${DIM}   Remove -n flag to actually kill these processes.${NC}"
    [[ -n "$LOG_FILE" ]] && echo -e "${DIM}   Log written to: $LOG_FILE${NC}"
    exit 0
fi

# Skip confirmation if --force is set
if [[ $FORCE -eq 0 ]]; then
    read -p "❓ Kill these processes? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🚫 Operation cancelled."
        exit 0
    fi
else
    echo -e "${YELLOW}⚡ Force mode enabled - skipping confirmation${NC}"
fi

echo "💀 Terminating processes gracefully (TERM)..."
[[ -n "$LOG_FILE" ]] && echo "# Kill started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
for pid in "${UNIQUE_PIDS[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
done

sleep 2

declare -a survivors=()
for pid in "${UNIQUE_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        survivors+=("$pid")
    fi
done

if [[ ${#survivors[@]} -gt 0 ]]; then
    echo "💥 Force killing ${#survivors[@]} stubborn process(es) (KILL)..."
    for pid in "${survivors[@]}"; do
        kill -KILL "$pid" 2>/dev/null || true
    done
    sleep 0.5
fi

# Final check
final_survivors=()
for pid in "${UNIQUE_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        final_survivors+=("$pid")
    fi
done

echo ""
if [[ ${#final_survivors[@]} -eq 0 ]]; then
    echo "✅ ${GREEN}All processes terminated successfully!${NC}"
    echo "🌡️  ${CYAN}Your laptop should cool down now...${NC}"

    # Log success
    if [[ -n "$LOG_FILE" ]]; then
        echo "" >> "$LOG_FILE"
        echo "# Kill completed at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        echo "# Result: SUCCESS - All ${#UNIQUE_PIDS[@]} process(es) terminated" >> "$LOG_FILE"
    fi
else
    echo "⚠️  ${YELLOW}Warning: ${#final_survivors[@]} process(es) survived:${NC}"
    for pid in "${final_survivors[@]}"; do
        cmd=$(ps -o command= -p "$pid" 2>/dev/null || echo "?")
        echo "   PID $pid: $cmd"
    done
    echo "${DIM}   These may require sudo or are protected by the system.${NC}"

    # Log survivors
    if [[ -n "$LOG_FILE" ]]; then
        echo "" >> "$LOG_FILE"
        echo "# Kill completed at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        echo "# Result: PARTIAL - ${#final_survivors[@]} process(es) survived" >> "$LOG_FILE"
        echo "# Survivors:" >> "$LOG_FILE"
        for pid in "${final_survivors[@]}"; do
            cmd=$(ps -o command= -p "$pid" 2>/dev/null || echo "?")
            echo "#   PID $pid: $cmd" >> "$LOG_FILE"
        done
    fi
fi

[[ -n "$LOG_FILE" ]] && echo -e "${DIM}📝 Kill log saved to: $LOG_FILE${NC}"
}

# --- Mode Handling ---
if [[ $HISTORY -eq 1 ]]; then
   if [[ ! -f "$HISTORY_FILE" ]]; then
       echo -e "${RED}No history file found.${NC}"
       exit 1
   fi
   mapfile -t history_lines < "$HISTORY_FILE"
   if [[ ${#history_lines[@]} -eq 0 ]]; then
       echo -e "${RED}History is empty.${NC}"
       exit 1
   fi
   echo -e "${CYAN}Select a pattern from history:${NC}"

   # Build list of valid entries only
   declare -a valid_entries=()
   declare -a valid_indices=()

   for i in "${!history_lines[@]}"; do
       line="${history_lines[$i]}"
       # Skip empty lines or lines that don't match timestamp format
       if [[ -n "$line" && "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ .+ ]]; then
           pattern=$(echo "$line" | cut -d' ' -f3-)
           # Skip if pattern is empty after extraction
           if [[ -n "$pattern" ]]; then
               timestamp=$(echo "$line" | cut -d' ' -f1-2)
               valid_entries+=("$line")
               valid_indices+=("${#valid_entries[@]}")
               echo "${#valid_entries[@]}. $pattern (used: $timestamp)"
           fi
       fi
   done

   if [[ ${#valid_entries[@]} -eq 0 ]]; then
       echo -e "${RED}No valid history entries found.${NC}"
       exit 1
   fi

   read -p "Enter number: " selection
   if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#valid_entries[@]} )); then
       echo -e "${RED}Invalid selection.${NC}"
       exit 1
   fi
   selected_line="${valid_entries[$((selection-1))]}"
   CUSTOM_TARGET=$(echo "$selected_line" | cut -d' ' -f3-)
   process_and_kill
elif [[ $NUKE -eq 1 ]]; then
   if [[ ! -f "$HISTORY_FILE" ]]; then
       echo -e "${RED}No history file found.${NC}"
       exit 1
   fi
   mapfile -t history_lines < "$HISTORY_FILE"
   if [[ ${#history_lines[@]} -eq 0 ]]; then
       echo -e "${RED}History is empty.${NC}"
       exit 1
   fi

   processed_count=0
   skipped_count=0

   for line in "${history_lines[@]}"; do
       # Skip empty lines or lines that don't match timestamp format
       if [[ -z "$line" || ! "$line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ .+ ]]; then
           ((skipped_count++))
           continue
       fi

       CUSTOM_TARGET=$(echo "$line" | cut -d' ' -f3-)

       # Skip if pattern is empty after extraction
       if [[ -z "$CUSTOM_TARGET" ]]; then
           ((skipped_count++))
           continue
       fi

       echo -e "${MAGENTA}Processing pattern: $CUSTOM_TARGET${NC}"
       process_and_kill
       ((processed_count++))
       echo "" # Spacer between history items
   done

   echo -e "${CYAN}Nuke complete: Processed $processed_count pattern(s), skipped $skipped_count invalid line(s)${NC}"
else
   process_and_kill
fi