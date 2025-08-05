## ⚠️ WARNING: THIS IS A NUCLEAR OPTION

**This script is designed to completely wipe all Docker-related data from your system.**  
**It will permanently delete:**

- All containers (running and stopped)
- All images, volumes, and networks
- All Docker build cache
- Docker Model Runner Beta data (AI models)
- Docker Scout configurations
- CLI plugins (Compose, Buildx, etc.)
- All configuration files in `/etc/docker`, `~/.docker`, and cache directories
- Selected `/opt` directories (with your confirmation)

**It does NOT:**
- Uninstall Docker engine/binaries
- Remove Docker from your system packages
- Delete non-Docker system files (unless you explicitly confirm `/opt` folder removal)

> **BACK UP IMPORTANT DATA BEFORE RUNNING THIS SCRIPT**  
> **THIS ACTION CANNOT BE UNDONE**

## ✨ Features

- 🔒 **Interactive safety checks** - Confirms every major action
- 🐳 **Full Docker ecosystem cleanup** - Removes all containers, images, volumes
- 🧠 **AI/ML specific cleanup** - Targets Docker Model Runner Beta data
- 🔍 **Docker Scout configuration removal**
- 📦 **CLI plugin cleanup** (Compose, Buildx)
- 📁 **Interactive `/opt` directory review** - One-by-one deletion confirmation
- 🔄 **Automatic Docker update** after cleanup
- 👥 **Automatic user group management** - Adds you to docker group if needed
- 📊 **Verification** - Shows empty Docker state after cleanup

## 📥 Installation

```bash
# Download the script
curl -LO https://raw.githubusercontent.com/yourusername/docker-clean-slate/main/docker-refresh.sh

# Make it executable
chmod +x docker-refresh.sh

# Run it (DO NOT use sudo)
./docker-refresh.sh
```

## ⚙️ Usage

1. Review the script carefully before running
2. Execute without sudo privileges: `./docker-refresh.sh`
3. Confirm each interactive prompt
4. The script will:
   - Add you to docker group if needed (and restart itself)
   - Stop Docker services
   - Remove all Docker data
   - Clean Model Runner Beta and Scout data
   - Review `/opt` directories for removal
   - Restart Docker
   - Update Docker to latest version
   - Show final clean state verification

## ❌ When NOT to Use

- If you have important containers/images you haven't backed up
- On production systems without proper authorization
- If you're not comfortable with terminal commands
- When Docker is actively running critical services

## ✅ When to Use

- Before reinstalling Docker completely
- To resolve persistent Docker issues
- When preparing a machine for decommissioning
- For security hardening (removing all container traces)
- Before selling or transferring a machine

## 📜 License

[MIT License](https://opensource.org/licenses/MIT) - See [LICENSE](LICENSE) for details.

---

#docker #docker-clean #docker-reset #devops #cleanup-script #docker-cli #container-removal #docker-model-runner #ai #docker-scout #system-administration #linux #macos #ubuntu #centos #fedora #data-cleanup #nuke-script #docker-removal #safe-cleanup #interactive-script #docker-reset-script
