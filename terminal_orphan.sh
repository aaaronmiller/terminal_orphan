#!/usr/bin/env bash
#
# Enhanced Dev Server Killer - AGGRESSIVE EDITION
# Catches ALL dev processes, not just the fancy named ones
# Version: 2.5.0 (Broadened patterns + VSCode process detection)

set -euo pipefail

# --- Configuration & Colors ---
DRY_RUN=0
CUSTOM_TARGET=""
SHOW_PORTS=0
AGGRESSIVE=1  # Default to aggressive mode
HISTORY=0
NUKE=0
SHOW_HEADER=1

# Shell color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- UI Functions ---

show_header() {
    echo -e "${CYAN}"
    echo "=___________      .__                                   .___ ___________                  .__              .__ "
    echo "\\_   _____/ ____ |  |__ _____    ____   ____  ____   __| _/ \\__    ___/__________  _____ |__| ____ _____  |  |"
    echo " |    __)_ /    \\|  |  \\\\__  \\  /    \\_/ ___\\/ __ \\ / __ |    |    |_/ __ \\_  __ \\/     \\|  |/    \\\\__  \\ |  |"
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
    printf "  %-35s %s\n" "$(echo -e ${CYAN}OPTIONS${NC})" "$(echo -e ${CYAN}TARGETS${NC})"
    printf "  %-35s %s\n" "$(echo -e ${DIM}----------------------------${NC})" "$(echo -e ${DIM}-------------------------${NC})"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}-n, --dry-run${NC}   Preview kills")" "• ALL node/python/bun/deno processes"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}-p, --ports${NC}      Show port usage")" "• VSCode extension hosts & language servers"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}-t 'pattern'${NC}  Custom target")" "• Docker containers & compose"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}-H, --history${NC}  Browse target history")" "• Ruby/Go/Rust/PHP dev servers"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}--nuke${NC}         Process all history")" "• Database dev instances"
    printf "  %-35s %s\n" "$(echo -e "${YELLOW}-h, --help${NC}     Show this and exit")" "• ANY process listening on dev ports"
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

# --- Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="$SCRIPT_DIR/terminal_orphan_targets.txt"

# --- Main Execution ---

show_header
show_usage

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
            TARGET_PIDS+=("$pid")
            pid_sources["$pid"]="custom"
        done
    else
        echo -e "  ${DIM}No matches found.${NC}"
    fi
else
    echo -e "${MAGENTA}▶ Scanning for ALL dev processes (aggressive mode)...${NC}"
    
    # ULTRA-AGGRESSIVE PATTERNS - Catches everything!
    declare -A targets_map=(
        # Node ecosystem - BROAD patterns
        ["node"]="^node "
        ["npm"]="npm"
        ["yarn"]="yarn"
        ["pnpm"]="pnpm"
        ["bun"]="^bun "
        ["deno"]="^deno "
        
        # Python ecosystem - BROAD patterns
        ["python"]="^python[0-9\.]* "
        ["python3"]="^python3"
        
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
        ["ruby"]="^ruby "
        ["rails"]="rails"
        ["puma"]="puma"
        
        # Go
        ["go"]="^go run"
        ["air"]="air"
        
        # Rust
        ["cargo"]="cargo (run|watch)"
        
        # PHP
        ["php"]="php.*(-S|artisan)"
        
        # Docker
        ["docker"]="docker(-compose)?"
        ["podman"]="podman"
        
        # Databases (dev instances only)
        ["postgres"]="postgres.*localhost"
        ["redis"]="redis-server"
        ["mongodb"]="mongod"
        ["mysql"]="mysqld.*--port"
    )

    output_lines=("" "" "" "" "")
    count=0
    line_idx=0
    
    for key in "${!targets_map[@]}"; do
        readarray -t pids <<< "$(pgrep -f "${targets_map[$key]}" 2>/dev/null || true)"
        
        # Filter out current shell and this script
        filtered_pids=()
        for pid in "${pids[@]}"; do
            if [[ -n "$pid" && "$pid" != "$$" && "$pid" != "$PPID" ]]; then
                cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
                # Skip if it's this script or the shell running it
                if [[ ! "$cmd" =~ (bash.*dev.*killer|/bin/(ba)?sh$) ]]; then
                    filtered_pids+=("$pid")
                    pid_sources["$pid"]="$key"
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
    
    for line in "${output_lines[@]}"; do
        [[ -n "$line" ]] && echo -e "$line"
    done
    
    # BONUS: Check for processes listening on dev ports
    echo ""
    echo -e "${MAGENTA}▶ Scanning processes listening on dev ports...${NC}"
    dev_ports=(3000 3001 4000 4200 5000 5173 5174 8000 8080 8081 8888 9000)
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
                if [[ "$parent_cmd" =~ (npm|node|yarn|pnpm|bun|python|ruby|cargo|go) && ! "$parent_cmd" =~ (bash.*dev.*killer) ]]; then
                    if [[ -z "${pid_sources[$ppid]:-}" ]]; then
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
    echo -e "${GREEN}✅ No matching processes found to terminate.${NC}"
    echo -e "${DIM}   (If your fan is still spinning, check Activity Monitor for non-dev processes)${NC}"
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

if (( DRY_RUN )); then
    echo -e "🔍 ${YELLOW}[DRY RUN]${NC} No processes were harmed."
    echo -e "${DIM}   Remove -n flag to actually kill these processes.${NC}"
    exit 0
fi

read -p "❓ Kill these processes? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🚫 Operation cancelled."
    exit 0
fi

echo "💀 Terminating processes gracefully (TERM)..."
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
else
    echo "⚠️  ${YELLOW}Warning: ${#final_survivors[@]} process(es) survived:${NC}"
    for pid in "${final_survivors[@]}"; do
        cmd=$(ps -o command= -p "$pid" 2>/dev/null || echo "?")
        echo "   PID $pid: $cmd"
    done
    echo "${DIM}   These may require sudo or are protected by the system.${NC}"
fi
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
   for i in "${!history_lines[@]}"; do
       timestamp=$(echo "${history_lines[$i]}" | cut -d' ' -f1-2)
       pattern=$(echo "${history_lines[$i]}" | cut -d' ' -f3-)
       echo "$((i+1)). $pattern (used: $timestamp)"
   done
   read -p "Enter number: " selection
   if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#history_lines[@]} )); then
       echo -e "${RED}Invalid selection.${NC}"
       exit 1
   fi
   selected_line="${history_lines[$((selection-1))]}"
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
   for line in "${history_lines[@]}"; do
       CUSTOM_TARGET=$(echo "$line" | cut -d' ' -f3-)
       echo -e "${MAGENTA}Processing pattern: $CUSTOM_TARGET${NC}"
       process_and_kill
   done
else
   process_and_kill
fi