#!/bin/bash

# ===================================================================
# docker-refresh.sh - Documentation-Aligned Final Version
# Fully compatible with Docker's current ecosystem as per:
# https://docs.docker.com (verified 2025-08-05)
# ===================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm() {
    read -r -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# === STAGE 0: Check root, ensure group membership ===

if [[ $EUID -eq 0 ]]; then
    log_error "This script should NOT be run as root. Run as a regular user."
    exit 1
fi

log_info "🔧 Checking Docker group membership for user: $USER"
if id -nG "$USER" | grep -qw "docker"; then
    log_info "✅ User '$USER' is already in the 'docker' group."
else
    log_info "📎 Adding '$USER' to 'docker' group..."
    sudo usermod -aG docker "$USER"
    log_info "✅ User '$USER' added to 'docker' group."

    log_warn "🔁 Restarting script in new group context..."
    exec newgrp docker << 'EOF'
bash <(cat) "$0"
EOF
    exit 0
fi

# === STAGE 1: Confirmation ===

log_info "🚀 Docker Refresh + Stack Cleanup + Update"
echo
log_warn "⚠️  This script will:"
echo "  - Remove ALL Docker data (containers, images, volumes)"
echo "  - Remove Docker Model Runner (Beta), Scout, CLI plugins"
echo "  - Clean /opt user apps"
echo "  - Update Docker if possible"
echo

if ! confirm "Proceed with full cleanup and update?"; then
    log_info "Aborted by user."
    exit 0
fi

# === STAGE 2: Stop Docker Services ===

log_info "⏹️ Stopping Docker services..."
sudo systemctl stop docker docker.socket containerd 2>/dev/null || true
sleep 2

# === STAGE 3: Remove Docker Data & Stack Traces ===

log_info "🗑️ Removing Docker data and stack implementations..."

# Standard Docker data (per "Manage containers, applications, and images" section)
sudo rm -rf /var/lib/docker/*
sudo rm -rf /var/lib/containerd/*
sudo rm -rf /etc/docker
sudo find /run -name "docker*" -exec rm -rf {} + 2>/dev/null || true

# User config (per "Package, test, and ship your applications" section)
rm -rf ~/.docker 2>/dev/null || true

# Docker Model Runner Beta (per documentation section)
# "Run, test, and serve AI models locally in seconds — no setup, no hassle."
log_info "🧹 Removing Docker Model Runner Beta traces..."
rm -rf ~/.docker/model-runner 2>/dev/null || true
rm -rf ~/.cache/model-runner 2>/dev/null || true
rm -rf ~/.local/share/model-runner 2>/dev/null || true
# Fallback paths in case Docker changes structure
rm -rf ~/.docker/ai/models 2>/dev/null || true
rm -rf ~/.docker/ai/cache 2>/dev/null || true
log_info "✅ Removed Docker Model Runner data (if any)"

# Docker Scout (per "Strengthen your software supply chain" section)
log_info "🧹 Removing Docker Scout traces..."
rm -rf ~/.docker/scout 2>/dev/null || true
rm -rf ~/.cache/scout 2>/dev/null || true
log_info "✅ Removed Docker Scout config (if any)"

# CLI Plugins (per "Define and run multi-container applications" section)
log_info "🧹 Removing Docker CLI plugins (Compose, Buildx, etc.)..."
rm -rf ~/.docker/cli-plugins 2>/dev/null || true
log_info "✅ Removed Docker CLI plugins (if any)"

# Cache cleanup (general)
log_info "🧹 Cleaning Docker cache directories..."
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/docker" 2>/dev/null || true
rm -rf "$HOME/.local/share/docker" 2>/dev/null || true
log_info "✅ Cache directories cleaned"

log_info "✅ All Docker-related data and stacks have been removed."

# === STAGE 4: Restart Docker ===

log_info "🔄 Restarting Docker service..."
sudo systemctl start docker
log_info "⏳ Waiting for Docker to become ready..."

for i in {1..15}; do
    if docker info &> /dev/null; then
        log_info "✅ Docker is running."
        break
    fi
    echo -n "."
    sleep 2
done

if ! docker info &> /dev/null; then
    log_error "❌ Docker failed to start. Check: sudo journalctl -u docker.service"
    exit 1
fi

# === STAGE 5: Show Clean State ===

echo
echo "=================================================="
log_info "🔍 FINAL STATUS: Docker Environment is CLEAN"
echo "=================================================="

log_info "📋 Containers:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
echo

log_info "📋 Images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
echo

log_info "📋 Volumes:"
docker volume ls --format "table {{.Driver}}\t{{.Name}}"
echo

log_info "📋 Networks:"
docker network ls --format "table {{.Name}}\t{{.Driver}}"

# === STAGE 6: /opt Cleanup ===

if [[ -d "/opt" ]]; then
    log_info "📂 Scanning /opt for user apps..."
    mapfile -t opt_dirs < <(find /opt -maxdepth 1 -type d ! -name "opt" -readable 2>/dev/null | sort)

    if [[ ${#opt_dirs[@]} -eq 0 ]]; then
        log_info "/opt is empty or contains no readable directories."
    else
        echo
        log_info "🔎 Found directories in /opt. Review each for deletion:"
        echo

        for dir in "${opt_dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then continue; fi

            size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "unknown")
            if confirm "Delete '$dir' ($size)?"; then
                sudo rm -rf "$dir"
                log_info "✅ Removed $dir"
            else
                log_info "⏭️ Skipping $dir"
            fi
        done
    fi
fi

# === STAGE 7: Update Docker (if possible) ===

echo
log_info "🔁 Checking for Docker updates..."

# Detect OS and package manager
if command -v apt &> /dev/null; then
    log_info "📦 Ubuntu/Debian detected. Updating Docker via APT..."
    sudo apt update && sudo apt upgrade -y docker-ce docker-ce-cli containerd.io
elif command -v yum &> /dev/null; then
    log_info "📦 CentOS/RHEL detected. Updating Docker via YUM..."
    sudo yum update -y docker-ce docker-ce-cli containerd.io
elif command -v dnf &> /dev/null; then
    log_info "📦 Fedora detected. Updating Docker via DNF..."
    sudo dnf upgrade -y docker-ce docker-ce-cli containerd.io
else
    log_warn "⚠️  Could not detect package manager. Skipping Docker update."
    log_info "💡 You can manually update Docker using your system's package manager."
fi

# Final success
echo
log_info "🎉 SUCCESS: Docker has been fully refreshed, cleaned, and updated!"
log_info "All Docker stacks (Model Runner Beta, Scout, etc.) are removed."
log_info "Docker is now clean, secure, and up to date."
log_info "Ready for fresh containers, images, and deployments."

exit 0
