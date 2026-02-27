#!/usr/bin/env zsh
# ╭──────────────────────────────────────────────────────────────╮
# │                    🐳 DDEV Enhancements                       │
# ╰──────────────────────────────────────────────────────────────╯

DDEV_ART='
   ╭─────────────────────────────────────╮
   │  🐳 DDEV                            │
   ╰─────────────────────────────────────╯
'

# Check if we're in a DDEV project
is_ddev_project() {
    [[ -f ".ddev/config.yaml" ]] && return 0
    return 1
}

# DDEV status indicator
ddev_status() {
    if is_ddev_project; then
        local status=$(ddev describe -j 2>/dev/null | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
        case "$status" in
            running)
                echo -e "\033[38;5;46m●\033[0m $(_t ddev_running)"
                ;;
            stopped)
                echo -e "\033[38;5;196m●\033[0m $(_t ddev_stopped)"
                ;;
            *)
                echo -e "\033[38;5;245m●\033[0m $(_t ddev_status_unknown)"
                ;;
        esac
    else
        echo -e "\033[38;5;245m$(_t not_ddev_project)\033[0m"
    fi
}

# ─────────────────────────────────────────────────────────────────
# DDEV NPM/PNPM Commands
# ─────────────────────────────────────────────────────────────────

# Smart npm - uses ddev if in ddev project
dd.ni() {
    local packages="$@"
    
    if is_ddev_project; then
        echo -e "\033[38;5;39m$DDEV_ART\033[0m"
        echo -e "  \033[38;5;39m🐳 $(_t ddev_npm_install)\033[0m"
        echo ""
        
        local frames=("📦    " "📦📦   " "📦📦📦  " "📦📦📦📦 " "📦📦📦📦📦")
        
        ddev npm install $packages 2>&1 &
        local pid=$!
        local i=0
        
        while kill -0 $pid 2>/dev/null; do
            printf "\r  %s $(_t installing)..." "${frames[$((i % 5))]}"
            sleep 0.2
            ((i++))
        done
        
        wait $pid
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "\r  \033[38;5;46m✓ $(_t ddev_install_complete)\033[0m 🐳✨\033[K"
        else
            echo -e "\r  \033[38;5;196m✗ $(_t ddev_install_failed)\033[0m\033[K"
        fi
    else
        # Fall back to regular npm install
        ni $packages
    fi
}

# Smart pnpm - uses ddev if in ddev project
dd.pi() {
    local packages="$@"
    
    if is_ddev_project; then
        echo -e "\033[38;5;208m$DDEV_ART\033[0m"
        echo -e "  \033[38;5;208m🐳 $(_t ddev_pnpm_install)\033[0m"
        echo ""
        
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        
        ddev pnpm install $packages 2>&1 &
        local pid=$!
        local i=0
        
        while kill -0 $pid 2>/dev/null; do
            printf "\r  \033[38;5;208m%s\033[0m $(_t installing)..." "${frames[$((i % 10))]}"
            sleep 0.1
            ((i++))
        done
        
        wait $pid
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "\r  \033[38;5;46m✓ $(_t ddev_install_complete)\033[0m 🐳✨\033[K"
        else
            echo -e "\r  \033[38;5;196m✗ $(_t ddev_install_failed)\033[0m\033[K"
        fi
    else
        # Fall back to regular pnpm install
        pi $packages
    fi
}

# DDEV dev server
dd.pd() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    
    echo -e "\033[38;5;46m$DDEV_ART\033[0m"
    
    # Rocket animation
    local rocket_frames=("🐳       " " 🐳      " "  🐳     " "   🐳    " "    🐳   " "     🐳  " "      🐳 " "       🐳")
    for frame in "${rocket_frames[@]}"; do
        printf "\r  %s" "$frame"
        sleep 0.08
    done
    echo ""
    
    echo -e "  \033[38;5;46m▶ $(_t ddev_starting_server)\033[0m"
    echo ""
    
    # Check for package manager preference
    if [[ -f "pnpm-lock.yaml" ]]; then
        ddev pnpm run dev
    elif [[ -f "yarn.lock" ]]; then
        ddev yarn dev
    else
        ddev npm run dev
    fi
}

# DDEV build
dd.pb() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    
    echo -e "\033[38;5;226m$DDEV_ART\033[0m"
    echo -e "  \033[38;5;226m🔨 $(_t ddev_building)\033[0m"
    echo ""
    
    local start_time=$(date +%s)
    
    if [[ -f "pnpm-lock.yaml" ]]; then
        ddev pnpm run build
    elif [[ -f "yarn.lock" ]]; then
        ddev yarn build
    else
        ddev npm run build
    fi
    
    local exit_code=$?
    local total_time=$(($(date +%s) - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\n  \033[38;5;46m✓ $(_t ddev_build_complete)\033[0m (${total_time}s) 🐳"
    fi
}

# DDEV scripts list
dd.ps-list() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    
    echo ""
    echo -e "  \033[38;5;51m╭───────────────────────────────────────╮\033[0m"
    echo -e "  \033[38;5;51m│\033[0m      \033[1m🐳 $(_t ddev_available_scripts)\033[0m         \033[38;5;51m│\033[0m"
    echo -e "  \033[38;5;51m╰───────────────────────────────────────╯\033[0m"
    echo ""
    
    scripts
}

# DDEV start
dd.start() {
    echo -e "\n  \033[38;5;39m🐳 $(_t ddev_starting)\033[0m"
    
    local frames=("◐" "◓" "◑" "◒")
    ddev start 2>&1 &
    local pid=$!
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r  \033[38;5;39m%s\033[0m $(_t ddev_starting_containers)" "${frames[$((i % 4))]}"
        sleep 0.2
        ((i++))
    done
    
    wait $pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "\r  \033[38;5;46m✓ $(_t ddev_started)\033[0m 🐳\033[K"
        echo ""
        ddev describe 2>/dev/null | grep -E "(URL|mailhog)" | head -5
    else
        echo -e "\r  \033[38;5;196m✗ $(_t ddev_start_failed)\033[0m\033[K"
    fi
    echo ""
}

# DDEV stop
dd.stop() {
    echo -e "\n  \033[38;5;208m🐳 $(_t ddev_stopping)\033[0m"
    
    local frames=("◐" "◓" "◑" "◒")
    ddev stop 2>&1 &
    local pid=$!
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r  \033[38;5;208m%s\033[0m $(_t ddev_stopping_containers)" "${frames[$((i % 4))]}"
        sleep 0.2
        ((i++))
    done
    
    wait $pid
    echo -e "\r  \033[38;5;46m✓ $(_t ddev_stopped_msg)\033[0m\033[K"
    echo ""
}

# DDEV restart
dd.restart() {
    echo -e "\n  \033[38;5;226m🐳 $(_t ddev_restarting)\033[0m"
    ddev restart
    echo -e "  \033[38;5;46m✓ $(_t ddev_restarted)\033[0m 🐳"
    echo ""
}

# DDEV SSH with style
dd.ssh() {
    echo -e "\n  \033[38;5;51m🐳 $(_t ddev_connecting)\033[0m\n"
    ddev ssh
}

# DDEV logs with style  
dd.logs() {
    echo -e "\n  \033[38;5;51m🐳 $(_t ddev_logs)\033[0m\n"
    ddev logs -f
}

# DDEV describe with better formatting
dd.describe() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    
    echo ""
    echo -e "  \033[38;5;51m╭───────────────────────────────────────╮\033[0m"
    echo -e "  \033[38;5;51m│\033[0m         \033[1m🐳 $(_t ddev_project_info)\033[0m           \033[38;5;51m│\033[0m"
    echo -e "  \033[38;5;51m╰───────────────────────────────────────╯\033[0m"
    echo ""
    ddev describe
}

# DDEV composer
dd.comp() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    
    echo -e "\n  \033[38;5;141m🎼 $(_t ddev_composer)\033[0m\n"
    ddev composer "$@"
}

# DDEV sequelace
dd.seq() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi

    echo -e "\n  \033[38;5;33m🗄️ $(_t ddev_sequelace)\033[0m\n"
    ddev sequelace
}

# DDEV Console
dd.c() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    ddev console "$@"
}

# DDEV Console Cache Clear
dd.cc() {
    if ! is_ddev_project; then
        echo -e "  \033[38;5;196m✗ $(_t not_ddev_project)"
        return 1
    fi
    echo -e "  \033[38;5;46m🧹 $(_t ddev_clearing_cache)\033[0m"
    ddev console cache:clear "$@"
}

# Fuzzy DDEV project selector (if multiple projects)
fddev() {
    if ! command -v fzf &>/dev/null; then
        echo -e "  \033[38;5;196m✗ $(_t fzf_required)"
        return 1
    fi
    
    local project
    project=$(ddev list -j 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | 
        fzf --header="  🐳 $(_t ddev_select_project)" \
            --preview 'ddev describe {} 2>/dev/null')
    
    if [[ -n "$project" ]]; then
        local project_dir=$(ddev describe "$project" -j 2>/dev/null | grep -o '"approot":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$project_dir" && -d "$project_dir" ]]; then
            cd "$project_dir"
            echo -e "  \033[38;5;46m✓ $(_t switched_to):\033[0m $project"
        fi
    fi
}

# List all DDEV projects
dd.list() {
    echo ""
    echo -e "  \033[38;5;51m╭───────────────────────────────────────╮\033[0m"
    echo -e "  \033[38;5;51m│\033[0m          \033[1m🐳 $(_t ddev_projects)\033[0m              \033[38;5;51m│\033[0m"
    echo -e "  \033[38;5;51m╰───────────────────────────────────────╯\033[0m"
    echo ""
    ddev list
    echo ""
}

# ─────────────────────────────────────────────────────────────────
# DDEV Main Command Dispatcher
# ─────────────────────────────────────────────────────────────────

# dd command with subcommands
dd() {
    if [[ $# -eq 0 ]]; then
        ddev
        return $?
    fi

    local cmd=$1
    shift

    case "$cmd" in
        ni|pi|pd|pb|ps-list|start|stop|restart|ssh|logs|describe|comp|seq|c|cc|list)
            "dd.$cmd" "$@"
            ;;
        *)
            ddev "$cmd" "$@"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# DDEV Aliases
# ─────────────────────────────────────────────────────────────────
# DDEV alias for ddev
alias dd.="ddev"
alias dstart="dd.start"
alias dinfo="dd.describe"
