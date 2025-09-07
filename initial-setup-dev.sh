#!/usr/bin/env bash
set -euo pipefail

# ---- Configurable defaults ---------------------------------------------------
DEV_USER="${SUDO_USER:-$USER}"
DEV_HOME="/home/${DEV_USER}"
DEV_DIR="${DEV_HOME}/dev"
GIT_NAME="${GIT_NAME:-David Abad}"          # optional: export GIT_NAME="Your Name" before running
GIT_EMAIL="${GIT_EMAIL:-david@corp.paymentevolution.com}"        # optional: export GIT_EMAIL="you@example.com" before running
SET_TIMEZONE="${SET_TIMEZONE:-America/Toronto}"  # optional: export SET_TIMEZONE="America/Toronto"
# ------------------------------------------------------------------------------

echo "[info] Running as: ${DEV_USER}"
if ! grep -qi microsoft /proc/version; then
  echo "[warn] This script is intended for WSL2 on Windows. Continuing anyway..."
fi

# 1) System update and base tools
echo "[step] Updating apt and installing base developer tools..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y --no-install-recommends \
  build-essential curl git unzip ca-certificates gnupg lsb-release \
  htop nano vim pkg-config

# 1.2) Install Fastfetch (latest release from GitHub)
echo "[step] Installing Fastfetch..."
curl -LO https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
sudo apt-get install -y ./fastfetch-linux-amd64.deb
rm fastfetch-linux-amd64.deb

# Optional timezone setup
if [[ -n "${SET_TIMEZONE}" ]]; then
  echo "[step] Setting timezone to ${SET_TIMEZONE}..."
  sudo ln -fs "/usr/share/zoneinfo/${SET_TIMEZONE}" /etc/localtime
  sudo dpkg-reconfigure -f noninteractive tzdata
fi

# 2) Create ~/dev and sensible subfolders
echo "[step] Creating ${DEV_DIR} and common subfolders..."
mkdir -p "${DEV_DIR}"/{scripts,experiments,datasets}

# 3) Shell quality-of-life: aliases and default working dir
# BASHRC="${DEV_HOME}/.bashrc"
# BLOCK_START="# >>> pe-dev bootstrap >>>"
# BLOCK_END="# <<< pe-dev bootstrap <<<"

# if ! grep -q "${BLOCK_START}" "${BASHRC}"; then
#   echo "[step] Updating ${BASHRC} with aliases and default dev directory logic..."
#   cat << 'BASHRC_APPEND' >> "${BASHRC}"

# # >>> pe-dev bootstrap >>>
# # Handy aliases
# alias ll='ls -lah'
# alias gs='git status'
# alias gd='git diff'
# alias gc='git commit'
# alias gp='git pull --rebase --autostash && git push'

# # When opening an interactive shell and starting from $HOME,
# # jump straight into ~/dev for faster navigation in WSL.
# if [[ $- == *i* ]] && [[ "${PWD}" == "${HOME}" ]]; then
#   cd "${HOME}/dev"
# fi
# # <<< pe-dev bootstrap <<<
# BASHRC_APPEND
# fi

# 4) (WSL) Ensure the default user is correct
# This makes sure 'wsl' launches as the non-root user.
# WSL_CONF="/etc/wsl.conf"
# if ! sudo test -f "${WSL_CONF}"; then
#   echo "[step] Creating ${WSL_CONF}..."
#   echo -e "[user]\ndefault=${DEV_USER}\n" | sudo tee "${WSL_CONF}" >/dev/null
# else
#   if grep -q "^\[user\]" "${WSL_CONF}"; then
#     echo "[step] Ensuring default user=${DEV_USER} in ${WSL_CONF}..."
#     sudo sed -i "s/^default=.*/default=${DEV_USER}/" "${WSL_CONF}" || true
#   else
#     echo -e "\n[user]\ndefault=${DEV_USER}\n" | sudo tee -a "${WSL_CONF}" >/dev/null
#   fi
# fi

# 5) Git sane defaults (optional if provided via env)
if [[ -n "${GIT_NAME}" ]]; then
  git config --global user.name "${GIT_NAME}"
fi
if [[ -n "${GIT_EMAIL}" ]]; then
  git config --global user.email "${GIT_EMAIL}"
fi
git config --global init.defaultBranch master

# When you set pull.rebase true, the git pull command becomes a shortcut for git fetch followed by git rebase
# Rebasing works differently than merging: it takes your local commits and "re-applies" them on top of the latest changes from the remote branch.
# This makes it look like your commits were made after the remote commits, resulting in a straight, linear history.
git config --global pull.rebase true
git config --global credential.helper store # consider a more secure helper in enterprise

# 6) SSH key generation (optional; only if none present)
if [[ ! -f "${DEV_HOME}/.ssh/id_ed25519" ]]; then
  echo "[step] Creating an SSH key (ed25519)..."
  mkdir -p "${DEV_HOME}/.ssh"
  chmod 700 "${DEV_HOME}/.ssh"
  ssh-keygen -t ed25519 -C "${GIT_EMAIL:-pe-dev@local}" -f "${DEV_HOME}/.ssh/id_ed25519" -N ""
  echo "[info] Public key:"
  cat "${DEV_HOME}/.ssh/id_ed25519.pub"
fi

# 7) Windows interop quality-of-life
# Expose the ~/dev path to Windows Explorer: \\wsl$\Ubuntu-22.04\home\<user>\dev
echo "[info] Access your projects from Windows Explorer at: \\\\wsl$\\$(cat /etc/hostname)\\home\\${DEV_USER}\\dev"

echo "[done] Bootstrap complete."
echo "[note] If you want Windows Terminal to open directly in ~/dev, set the Ubuntu profile startingDirectory to:"
echo "       //wsl$/Ubuntu-22.04/home/${DEV_USER}/dev"
echo "[note] If you want this to apply system-wide immediately, run:  wsl.exe --shutdown"
