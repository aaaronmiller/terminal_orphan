#!/usr/bin/env bash
# ---
# title: Terminal Orphan Killer - Full Featured Edition
# date: 2025-11-04 00:00:00 UTC
# ver: 3.0.0
# author: Sliither
# model: Claude Sonnet 4.5
# tags: [bash, process-management, debugging, dev-tools, process-killer, pattern-matching, pgrep, terminal]
# ---

# Enhanced Dev Server Killer - SAFE & FEATURED EDITION
# Catches dev processes with SAFE pattern matching (won't kill system processes!)
# Version: 2.8.0 (Fixed critical pattern bugs, optimized speed, added safety checks)

set -o pipefail

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
USE_SIGKILL=0
USE_SUDO=0
USE_ELEVATED=0

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
    printf "  %-40s %s\\n" "$(echo -e "${YELLOW}--nuke${NC}              Process all history")" "• Database dev instances"
    printf "  %-40s %s\\n" "$(echo -e "${YELLOW}-9, --kill9${NC}        Immediate SIGKILL (skip graceful TERM)")" ""
    printf "  %-40s %s\\n" "$(echo -e "${YELLOW}-E, --elevated${NC}    Maximum: sudo kill -9 (skip TERM+KILL)")" ""
    printf "  %-40s %s\\n" "$(echo -e "${YELLOW}-S, --sudo${NC}         Use sudo for kill commands")" ""
    printf "  %-40s %s\\n" "$(echo -e "${YELLOW}-d, --debug${NC}         Show debug info")" "• ANY process listening on dev ports"
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
        -9|--kill9)
            USE_SIGKILL=1
            shift
            ;;
        -E|--elevated)
            USE_ELEVATED=1
            shift
            ;;
        -S|--sudo)
            USE_SUDO=1
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

# Pre-validate sudo if requested
if [[ $USE_SUDO -eq 1 && $EUID -ne 0 ]]; then
    echo "🔐 Validating sudo credentials..."
    if ! sudo -v; then
        echo -e "${RED}❌ Sudo authentication failed. Proceeding without sudo.${NC}"
        USE_SUDO=0
    fi
fi

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

kill_process() {
    local pid=$1
    local sig=$2
    if [[ $USE_SUDO -eq 1 && $EUID -ne 0 ]]; then
        sudo kill "-$sig" "$pid" 2>/dev/null || true
    else
        kill "-$sig" "$pid" 2>/dev/null || true
    fi
}

elevated_kill() {
    local pid=$1
    local sig="${2:-KILL}"
    sudo kill "-$sig" "$pid" 2>/dev/null || true
}

proc_exists() {
    local pid=$1
    if [[ $USE_SUDO -eq 1 && $EUID -ne 0 ]]; then
       sudo kill -0 "$pid" 2>/dev/null
    else
        kill -0 "$pid" 2>/dev/null
    fi
}

proc_exists_elevated() {
    local pid=$1
    sudo kill -0 "$pid" 2>/dev/null
}

# 3-step escalation: TERM → KILL → sudo kill -9 (+ optional elevated)
# Returns 0 if dead, 1 if survived all steps
# Pass --elevated to try elevated_kill after sudo kill -9
escalate_kill() {
    local pid=$1
    local use_elevated=${2:-$USE_ELEVATED}

    # If --elevated / -E was passed, skip straight to sudo kill -9
    if [[ $use_elevated -eq 1 ]]; then
        elevated_kill "$pid" KILL
        sleep 0.3
        proc_exists_elevated "$pid" && return 1 || return 0
    fi

    kill_process "$pid" TERM
    sleep 0.3
    if proc_exists "$pid"; then
        kill_process "$pid" KILL
        sleep 0.2
    fi
    if proc_exists "$pid"; then
        elevated_kill "$pid" KILL
        sleep 0.3
    fi

    # Ultimate fallback: if USE_SUDO and still alive, try SIGQUIT
    if [[ $USE_SUDO -eq 1 ]] && proc_exists_elevated "$pid"; then
        elevated_kill "$pid" QUIT 2>/dev/null || true
        sleep 0.3
    fi

    # Check existence — prefer elevated check if we've been using sudo
    if [[ $USE_SUDO -eq 1 ]]; then
        proc_exists_elevated "$pid" && return 1 || return 0
    else
        proc_exists "$pid" && return 1 || return 0
    fi
}

draw_kill_list() {
    # _ic_cmd, _ic_cpu, _ic_mem, killed_count, total — all from interactive_kill_select scope
    local selected=$1
    local -n _km=$2
    local i=0
    local cols
    cols=$(tput cols 2>/dev/null || echo 120)
    local max_cmd=$(( cols - 40 ))
    [[ $max_cmd -lt 15 ]] && max_cmd=15

    for pid in "${UNIQUE_PIDS[@]}"; do
        local src="${pid_sources[$pid]:-?}"
        local cmd="${_ic_cmd[$pid]:-[ended]}"
        local cpu="${_ic_cpu[$pid]:-?}"
        local mem="${_ic_mem[$pid]:-?}"
        [[ ${#cmd} -gt $max_cmd ]] && cmd="${cmd:0:$max_cmd}…"
        local status="${_km[$pid]:-}"
        local level="${_kl[$pid]:-}"

        printf '\033[2K\r'
        case "$status" in
            ok)
                printf "  ${GREEN}✓ killed ${NC}%-7s %-12s %s\n" \
                    "$pid" "$src" "$cmd" ;;
            ok9)
                printf "  ${GREEN}✓ -9     ${NC}%-7s %-12s %s\n" \
                    "$pid" "$src" "$cmd" ;;
            okelev)
                printf "  ${GREEN}✓ elev   ${NC}%-7s %-12s %s\n" \
                    "$pid" "$src" "$cmd" ;;
            failed)
                printf "  ${RED}✗ alive! ${NC}%-7s %-12s %s\n" \
                    "$pid" "$src" "$cmd" ;;
            killing)
                printf "  ${YELLOW}… wait   ${NC}%-7s %-12s %s\n" \
                    "$pid" "$src" "$cmd" ;;
            *)
                # Show the kill level indicator for the selected item
                if [[ $i -eq $selected ]]; then
                    local lvl_str=""
                    case "${level:-normal}" in
                        normal) lvl_str="${DIM}[TERM]${NC}" ;;
                        sigkill) lvl_str="${YELLOW}[-9]${NC}" ;;
                        elevated) lvl_str="${RED}[ELEV]${NC}" ;;
                    esac
                    printf "  ${CYAN}${BOLD}▶${NC} %s ${CYAN}%-7s %-12s${NC} ${DIM}cpu:%-4s mem:%-4s${NC} ${CYAN}%s${NC}\n" \
                        "$lvl_str" "$pid" "$src" "$cpu" "$mem" "$cmd"
                else
                    printf "    ${DIM}pending ${NC}%-7s %-12s ${DIM}cpu:%-4s mem:%-4s${NC} %s\n" \
                        "$pid" "$src" "$cpu" "$mem" "$cmd"
                fi ;;
        esac
        ((i++))
    done

    # Footer: progress counter + controls (always the last line of the block)
    printf '\033[2K\r'
    printf "  ${DIM}killed %d/%d  ·  Enter=kill 9=kill9  E=elevated  y=all  q=done${NC}\n" \
        "${killed_count:-0}" "${total:-0}"
}

interactive_kill_select() {
    # Global cache: one ps call populates these, draw_kill_list reads them
    declare -g -A _ic_cmd _ic_cpu _ic_mem _kl

    _ic_load_cache() {
        local pid_csv
        pid_csv=$(printf '%s,' "${UNIQUE_PIDS[@]}")
        pid_csv="${pid_csv%,}"
        [[ -z "$pid_csv" ]] && return
        # Single ps call for all pids; last field (command) may contain spaces
        while read -r p cpu mem cmd; do
            [[ -z "$p" ]] && continue
            _ic_cmd[$p]="$cmd"
            _ic_cpu[$p]="$cpu"
            _ic_mem[$p]="$mem"
            # Initialize kill level if not set
            [[ -z "${_kl[$p]:-}" ]] && _kl[$p]="normal"
        done < <(ps --no-headers -p "$pid_csv" -o pid,pcpu,pmem,command 2>/dev/null || true)
    }

    local selected=0
    local total=${#UNIQUE_PIDS[@]}
    declare -A killed_map
    local killed_count=0
    local list_lines=$(( total + 1 ))  # list rows + footer row

    # Initialize kill levels for all pids
    for pid in "${UNIQUE_PIDS[@]}"; do
        _kl[$pid]="normal"
    done

    _ic_load_cache

    tput civis 2>/dev/null
    trap 'tput cnorm 2>/dev/null' RETURN INT TERM

    echo ""
    draw_kill_list "$selected" killed_map

    _ic_redraw() {
        printf '\033[%dA' "$list_lines"
        draw_kill_list "$selected" killed_map
    }

    while true; do
        local k1 k2
        IFS= read -r -s -n1 k1

        if [[ "$k1" == $'\x1b' ]]; then
            IFS= read -r -s -n2 -t 0.05 k2
            case "$k2" in
                '[A'|'[D')  # up / left
                    [[ $selected -gt 0 ]] && ((selected--)) ;;
                '[B'|'[C')  # down / right
                    [[ $selected -lt $((total-1)) ]] && ((selected++)) ;;
            esac

        elif [[ "$k1" == '' || "$k1" == $'\n' || "$k1" == $'\r' ]]; then
            # Kill selected with current kill level
            local pid="${UNIQUE_PIDS[$selected]}"
            if [[ -z "${killed_map[$pid]:-}" ]]; then
                local lvl="${_kl[$pid]:-normal}"
                killed_map[$pid]="killing"
                _ic_redraw

                local ok=false
                case "$lvl" in
                    normal)
                        if escalate_kill "$pid" 0; then ok=true; fi ;;
                    sigkill)
                        kill_process "$pid" KILL
                        sleep 0.3
                        proc_exists "$pid" || ok=true
                        if ! $ok && [[ $USE_SUDO -eq 1 ]]; then
                            elevated_kill "$pid" KILL
                            sleep 0.3
                            proc_exists "$pid" || ok=true
                        fi
                        ;;
                    elevated)
                        elevated_kill "$pid" KILL
                        sleep 0.3
                        proc_exists_elevated "$pid" || ok=true
                        if ! $ok; then
                            elevated_kill "$pid" QUIT
                            sleep 0.3
                            proc_exists_elevated "$pid" || ok=true
                        fi
                        ;;
                esac

                if $ok; then
                    case "$lvl" in
                        normal)   killed_map[$pid]="ok" ;;
                        sigkill)  killed_map[$pid]="ok9" ;;
                        elevated) killed_map[$pid]="okelev" ;;
                    esac
                    ((killed_count++))
                else
                    killed_map[$pid]="failed"
                fi
                _ic_load_cache
                # Advance to next unkilled
                local found=0
                for ((j=selected+1; j<total; j++)); do
                    [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; found=1; break; }
                done
                if [[ $found -eq 0 ]]; then
                    for ((j=0; j<selected; j++)); do
                        [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; found=1; break; }
                    done
                fi
                _ic_redraw
                # All processed — break only if every item has a result
                local pending=0
                for p in "${UNIQUE_PIDS[@]}"; do [[ -z "${killed_map[$p]:-}" ]] && ((pending++)); done
                [[ $pending -eq 0 ]] && break
            fi

        elif [[ "$k1" == '1' ]]; then
            # Toggle kill level for selected: normal → sigkill
            local pid="${UNIQUE_PIDS[$selected]}"
            [[ -z "${killed_map[$pid]:-}" ]] && _kl[$pid]="normal"
            _ic_redraw

        elif [[ "$k1" == '2' ]]; then
            # Toggle kill level for selected: normal → sigkill
            local pid="${UNIQUE_PIDS[$selected]}"
            [[ -z "${killed_map[$pid]:-}" ]] && _kl[$pid]="sigkill"
            _ic_redraw

        elif [[ "$k1" == '3' ]]; then
            # Toggle kill level for selected: normal → elevated
            local pid="${UNIQUE_PIDS[$selected]}"
            [[ -z "${killed_map[$pid]:-}" ]] && _kl[$pid]="elevated"
            _ic_redraw

        elif [[ "$k1" == '9' ]]; then
            # SIGKILL on selected (shortcut)
            local pid="${UNIQUE_PIDS[$selected]}"
            if [[ -z "${killed_map[$pid]:-}" ]]; then
                _kl[$pid]="sigkill"
                killed_map[$pid]="killing"
                _ic_redraw

                kill_process "$pid" KILL
                sleep 0.3
                local ok=false
                proc_exists "$pid" || ok=true
                if ! $ok; then
                    elevated_kill "$pid" KILL
                    sleep 0.3
                    proc_exists "$pid" || ok=true
                fi

                if $ok; then
                    killed_map[$pid]="ok9"
                    ((killed_count++))
                else
                    killed_map[$pid]="failed"
                fi
                _ic_load_cache
                local found=0
                for ((j=selected+1; j<total; j++)); do
                    [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; found=1; break; }
                done
                [[ $found -eq 0 ]] && for ((j=0; j<selected; j++)); do
                    [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; break; }
                done
                _ic_redraw
                local pending=0
                for p in "${UNIQUE_PIDS[@]}"; do [[ -z "${killed_map[$p]:-}" ]] && ((pending++)); done
                [[ $pending -eq 0 ]] && break
            fi

        elif [[ "$k1" == 'e' || "$k1" == 'E' ]]; then
            # Elevated kill on selected (sudo kill -9)
            local pid="${UNIQUE_PIDS[$selected]}"
            if [[ -z "${killed_map[$pid]:-}" ]]; then
                _kl[$pid]="elevated"
                killed_map[$pid]="killing"
                _ic_redraw

                local ok=false
                elevated_kill "$pid" KILL
                sleep 0.3
                proc_exists_elevated "$pid" || ok=true
                if ! $ok; then
                    elevated_kill "$pid" QUIT
                    sleep 0.3
                    proc_exists_elevated "$pid" || ok=true
                fi

                if $ok; then
                    killed_map[$pid]="okelev"
                    ((killed_count++))
                else
                    killed_map[$pid]="failed"
                fi
                _ic_load_cache
                local found=0
                for ((j=selected+1; j<total; j++)); do
                    [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; found=1; break; }
                done
                [[ $found -eq 0 ]] && for ((j=0; j<selected; j++)); do
                    [[ -z "${killed_map[${UNIQUE_PIDS[$j]}]:-}" ]] && { selected=$j; break; }
                done
                _ic_redraw
                local pending=0
                for p in "${UNIQUE_PIDS[@]}"; do [[ -z "${killed_map[$p]:-}" ]] && ((pending++)); done
                [[ $pending -eq 0 ]] && break
            fi

        elif [[ "$k1" == 'y' || "$k1" == 'Y' ]]; then
            # Kill all pending with their CURRENT kill levels
            # First show all as "killing"
            for p in "${UNIQUE_PIDS[@]}"; do
                [[ -z "${killed_map[$p]:-}" ]] && killed_map[$p]="killing"
            done
            _ic_redraw

            # Phase 1: normal TERM kills
            local normal_pids=()
            local sigkill_pids=()
            local elevated_pids=()
            for p in "${UNIQUE_PIDS[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                case "${_kl[$p]:-normal}" in
                    normal)   normal_pids+=("$p") ;;
                    sigkill)  sigkill_pids+=("$p") ;;
                    elevated) elevated_pids+=("$p") ;;
                esac
            done

            # Normal: TERM
            for p in "${normal_pids[@]}"; do kill_process "$p" TERM; done
            sleep 1
            for p in "${normal_pids[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                proc_exists "$p" && kill_process "$p" KILL
            done
            sleep 0.3
            for p in "${normal_pids[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                proc_exists "$p" && elevated_kill "$p" KILL || true
            done
            sleep 0.3

            # SIGKILL: skip TERM, go straight to KILL + sudo fallback
            for p in "${sigkill_pids[@]}"; do kill_process "$p" KILL; done
            sleep 0.3
            for p in "${sigkill_pids[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                proc_exists "$p" && elevated_kill "$p" KILL || true
            done
            sleep 0.3

            # Elevated: sudo kill -9
            for p in "${elevated_pids[@]}"; do elevated_kill "$p" KILL; done
            sleep 0.3
            for p in "${elevated_pids[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                proc_exists_elevated "$p" && elevated_kill "$p" QUIT || true
            done
            sleep 0.3

            # Check results
            local all_pids=( "${normal_pids[@]}" "${sigkill_pids[@]}" "${elevated_pids[@]}" )
            for p in "${all_pids[@]}"; do
                [[ "${killed_map[$p]:-}" != "killing" ]] && continue
                local survivor=false
                case "${_kl[$p]:-normal}" in
                    normal|sigkill) proc_exists "$p" && survivor=true || true ;;
                    elevated) proc_exists_elevated "$p" && survivor=true || true ;;
                esac
                if $survivor; then killed_map[$p]="failed"
                else
                    case "${_kl[$p]:-normal}" in
                        normal)   killed_map[$p]="ok" ;;
                        sigkill)  killed_map[$p]="ok9" ;;
                        elevated) killed_map[$p]="okelev" ;;
                    esac
                    ((killed_count++))
                fi
            done
            _ic_load_cache
            _ic_redraw
            break

        elif [[ "$k1" == 'q' || "$k1" == 'Q' || "$k1" == $'\x03' ]]; then
            _ic_redraw
            tput cnorm 2>/dev/null
            echo ""
            if [[ $killed_count -eq 0 ]]; then
                echo "🚫 Nothing killed. Exited."
            else
                local left=$(( total - killed_count ))
                echo -e "✅ ${GREEN}Done. Killed ${killed_count} of ${total}.${NC}"
                [[ $left -gt 0 ]] && echo -e "   ${DIM}${left} process(es) left running.${NC}"
            fi
            return 0
        fi

        _ic_redraw
    done

    tput cnorm 2>/dev/null
    echo ""

    local survivors=()
    for p in "${UNIQUE_PIDS[@]}"; do
        [[ "${killed_map[$p]:-}" == "failed" ]] && survivors+=("$p")
    done

    if [[ ${#survivors[@]} -eq 0 ]]; then
        echo -e "✅ ${GREEN}All ${killed_count} process(es) terminated.${NC}"
        echo -e "🌡️  ${CYAN}Your system should cool down now...${NC}"
    else
        echo -e "✅ ${GREEN}${killed_count} terminated.${NC}  ${YELLOW}⚠️  ${#survivors[@]} survived all kill levels${NC}"
        for p in "${survivors[@]}"; do
            echo -e "   ${RED}PID $p: ${_ic_cmd[$p]:-[unknown]}${NC}"
        done
        echo -e "${DIM}   Try: re-run with --sudo${NC}"
    fi

    if [[ -n "$LOG_FILE" ]]; then
        echo "" >> "$LOG_FILE"
        echo "# Kill completed at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
        echo "# Killed: $killed_count  Survivors: ${#survivors[@]}" >> "$LOG_FILE"
    fi
}

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
    
    # Core dev process patterns (SAFE - won't match system processes)
    declare -A targets_map=(
        # Node ecosystem - match executables, not paths
        ["node"]="/node"           # Matches /usr/bin/node, /usr/local/bin/node
        ["npm"]="/npm"
        ["yarn"]="/yarn"
        ["pnpm"]="/pnpm"
        ["bun"]="/bun"             # Matches /usr/local/bin/bun, not "bundle"
        ["deno"]="/deno"

        # Python - match python executables
        ["python"]="/python"       # Matches /usr/bin/python, not paths with "python"

        # VSCode processes (these are safe - specific names)
        ["vscode-ext"]="extensionHost"
        ["vscode-ts"]="tsserver"

        # Ollama (local LLM server — runs as 'ollama' user)
        ["ollama"]="ollama serve"
        ["ollama-proc"]="bin/ollama"

        # Headroom compression proxy + RTK
        ["headroom"]="headroom proxy"
        ["rtk"]="/rtk"

        # Watchers / daemons
        ["ramwatch"]="ramwatch-daemon"
        ["watchman"]="watchman"

        # Claude Code CLI and MCP processes
        ["claude"]="claude --"
        ["context7"]="context7-mcp"

        # JavaScript tooling
        ["vite"]="/vite"
        ["webpack"]="webpack-dev-server"
        ["next"]="next dev"
        ["nodemon"]="/nodemon"

        # Python servers (specific commands)
        ["uvicorn"]="uvicorn"
        ["flask"]="flask run"

        # Other languages - be specific!
        ["ruby"]="/ruby"
        ["rails"]="rails server"
        ["cargo"]="cargo run"
        ["php"]="php -S"           # PHP dev server
        ["java"]="java -jar"       # Java with jar flag
        ["dotnet"]="dotnet run"    # .NET run command

        # Docker
        ["docker"]="dockerd"       # Docker daemon, not just "docker" in path

        # Databases (dev instances) - specific daemons
        ["postgres"]="postgres -D" # Postgres with data directory
        ["redis"]="redis-server"
        ["mongodb"]="mongod"

        # Python scripts (running .py files directly)
        ["py-script"]="python.* .*\.py"

        # Shell scripts
        ["sh-script"]="bash .*\.sh"

        # Named launchers and proxies
        ["start_proxy"]="start_proxy"

        # Claude Code CLI and MCP processes
        ["claude"]="claude --"
        ["context7"]="context7-mcp"
    )

    # Calculate how many lines we need (3 columns per line)
    total_targets=${#targets_map[@]}
    lines_needed=$(( (total_targets + 2) / 3 ))

    # Initialize output_lines array with enough empty strings
    output_lines=()
    for ((i=0; i<lines_needed; i++)); do
        output_lines+=("")
    done

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

    # User TTY sweep: anything the user explicitly started in a terminal
    echo -e "${MAGENTA}▶ Scanning user-started TTY processes...${NC}"
    tty_pids_found=0
    while IFS= read -r pid; do
        [[ -z "$pid" ]] && continue
        [[ "$pid" == "$$" || "$pid" == "$PPID" ]] && continue
        [[ -n "${pid_sources[$pid]:-}" ]] && continue
        local tty_cmd
        tty_cmd=$(ps -o command= -p "$pid" 2>/dev/null || true)
        # Skip bare interactive shells
        [[ "$tty_cmd" =~ ^-?(zsh|bash|sh|fish)(\ -l)?$ ]] && continue
        # Skip this script
        [[ "$tty_cmd" =~ terminal_orphan ]] && continue
        # Skip exclude pattern
        [[ -n "$EXCLUDE_PATTERN" && "$tty_cmd" =~ $EXCLUDE_PATTERN ]] && continue
        TARGET_PIDS+=("$pid")
        pid_sources["$pid"]="user-tty"
        ((tty_pids_found++))
    done < <(ps -u "$USER" --no-headers -o pid,tty 2>/dev/null | awk '$2 != "?" {print $1}')

    if [[ $tty_pids_found -gt 0 ]]; then
        echo -e "  ${GREEN}Found ${tty_pids_found} user TTY process(es)${NC}"
    else
        echo -e "  ${DIM}No additional user TTY processes found${NC}"
    fi
    echo ""
fi

# --- Parent Process Discovery ---
declare -a ALL_PIDS=()
if [[ ${#TARGET_PIDS[@]} -gt 0 ]]; then
    ALL_PIDS=("${TARGET_PIDS[@]}")
fi

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
        cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | tr -d ' ' || echo "?")
        mem=$(ps -o %mem= -p "$pid" 2>/dev/null | tr -d ' ' || echo "?")
        printf "%-8s %-8s %-15s cpu:%-5s mem:%-5s\n" "$pid" "$ppid" "$source" "$cpu%" "$mem%" >> "$LOG_FILE"
        printf "  %s\n" "$cmd" >> "$LOG_FILE"
    done
    echo "" >> "$LOG_FILE"
fi

if (( DRY_RUN )); then
    printf "  %-7s %-12s %-6s %-6s %s\n" "PID" "SOURCE" "CPU%" "MEM%" "COMMAND"
    printf "  %-7s %-12s %-6s %-6s %s\n" "---" "------" "----" "----" "-------"
    local cols
    cols=$(tput cols 2>/dev/null || echo 120)
    for pid in "${UNIQUE_PIDS[@]}"; do
        local dr_ppid dr_src dr_cmd dr_cpu dr_mem
        dr_src="${pid_sources[$pid]:-?}"
        read -r dr_cpu dr_mem dr_cmd <<< "$(ps --no-headers -p "$pid" -o pcpu,pmem,command 2>/dev/null || echo "? ? ?")"
        [[ ${#dr_cmd} -gt $((cols-36)) ]] && dr_cmd="${dr_cmd:0:$((cols-37))}…"
        printf "  %-7s %-12s %-6s %-6s %s\n" "$pid" "$dr_src" "$dr_cpu" "$dr_mem" "$dr_cmd"
    done
    echo ""
    echo -e "🔍 ${YELLOW}[DRY RUN]${NC} No processes were harmed."
    echo -e "${DIM}   Remove -n flag to actually kill these processes.${NC}"
    [[ -n "$LOG_FILE" ]] && echo -e "${DIM}   Log written to: $LOG_FILE${NC}"
    exit 0
fi

[[ -n "$LOG_FILE" ]] && echo "# Kill started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"

if [[ $FORCE -eq 0 ]]; then
    interactive_kill_select
else
    echo -e "${YELLOW}⚡ Force mode - killing all ${#UNIQUE_PIDS[@]} process(es)...${NC}"
    local sig="TERM"
    [[ $USE_SIGKILL -eq 1 ]] && sig="KILL"
    for pid in "${UNIQUE_PIDS[@]}"; do
        kill_process "$pid" "$sig"
    done
    [[ "$sig" == "TERM" ]] && sleep 1
    sleep 0.3

    declare -a force_survivors=()
    for pid in "${UNIQUE_PIDS[@]}"; do
        proc_exists "$pid" && force_survivors+=("$pid")
    done
    if [[ ${#force_survivors[@]} -gt 0 ]]; then
        echo "💥 SIGKILL on ${#force_survivors[@]} stubborn process(es)..."
        for pid in "${force_survivors[@]}"; do
            kill_process "$pid" KILL
        done
        sleep 0.5
    fi

    declare -a final_survivors=()
    for pid in "${UNIQUE_PIDS[@]}"; do
        proc_exists "$pid" && final_survivors+=("$pid")
    done

    echo ""
    if [[ ${#final_survivors[@]} -eq 0 ]]; then
        echo -e "✅ ${GREEN}All processes terminated successfully!${NC}"
        echo -e "🌡️  ${CYAN}Your system should cool down now...${NC}"
        [[ -n "$LOG_FILE" ]] && { echo "" >> "$LOG_FILE"; echo "# Result: SUCCESS" >> "$LOG_FILE"; }
    else
        echo -e "⚠️  ${YELLOW}${#final_survivors[@]} process(es) survived SIGKILL:${NC}"
        for pid in "${final_survivors[@]}"; do
            local fcmd
            fcmd=$(ps -o command= -p "$pid" 2>/dev/null || echo "?")
            echo "   PID $pid: $fcmd"
        done
        echo -e "${DIM}   Try re-running with --sudo${NC}"
        [[ -n "$LOG_FILE" ]] && { echo "" >> "$LOG_FILE"; echo "# Result: PARTIAL" >> "$LOG_FILE"; }
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