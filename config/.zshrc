# Flexing specs
# sleep 0.1
# fastfetch

eval "$(starship init zsh)"

# Default zsh config
source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# Plugins
plugins=(archlinux conda git pip python uv)

# --- Initialize environment (EXPORT) ---

# Python
export PYTHON_VENV_AUTO_ACTIVATE=true

# JAVA
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# WINE
export WINEDEBUG=fixme-all,warn+cursor,+relay

# DOCKER
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# IBus Input Method
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# source /usr/share/nvm/init-nvm.sh

# BUN
export BUN_INSTALL="$HOME/.bun"

# PERL
PATH="/home/ultimatebrok/perl5/bin${PATH:+:${PATH}}"; export PATH;
RL5LIB="/home/ultimatebrok/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/ultimatebrok/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/ultimatebrok/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/ultimatebrok/perl5"; export PERL_MM_OPT;

# VSCode
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# LM Studio
export PATH="$PATH:/home/ultimatebrok/.lmstudio/bin"

# --- PATH ---
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
export PATH="$PATH:/home/ultimatebrok/.lmstudio/bin"
export PATH="$PATH:/home/ultimatebrok/.spicetify"
export PATH="$PATH:/usr/lib/jvm/java-17-openjdk/bin"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/home/ultimatebrok/bin:$PATH"

# pnpm
PNPM_HOME="/home/ultimatebrok/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# RUBY GEM
export PATH="$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"

# npm global bin
export PATH="$PATH:$(npm bin -g)"

# --- ALIAS ---
alias lzd='lazydocker'
alias fix-caps="/home/ultimatebrok/.local/bin/fix-capslock"

# --- DEFINED FUNCTIONS ---
updateme() { 
  echo "===Update arch packages==="
  paru -Syu 
  echo "===Update flatpak packages==="
  flatpak update
  echo "===Clean caches==="
  paru -Scc
}

logout() {
  canberra-gtk-play --file="/home/ultimatebrok/.local/share/sounds/modern-minimal-ui-sounds/stereo/desktop-logout.oga"
  gnome-session-quit --logout --no-prompt
}

shutdown() {
  canberra-gtk-play --file="/home/ultimatebrok/.local/share/sounds/modern-minimal-ui-sounds/stereo/_desktop-logout.oga"
  sleep 2
  systemctl poweroff
}

fucklife() {
  wine /home/ultimatebrok/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe
}

# --- CONDA ---
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/ultimatebrok/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#   eval "$__conda_setup"
# else
#   if [ -f "/home/ultimatebrok/miniforge3/etc/profile.d/conda.sh" ]; then
#     . "/home/ultimatebrok/miniforge3/etc/profile.d/conda.sh"
#   else
#     export PATH="/home/ultimatebrok/miniforge3/bin:$PATH"
#   fi
# fi
# unset __conda_setup

# --- Others ---

# bun completions
[ -s "/home/ultimatebrok/.bun/_bun" ] && source "/home/ultimatebrok/.bun/_bun"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
# . "$HOME/.local/bin/env"
# source /usr/share/nvm/init-nvm.sh
export PATH=/home/ultimatebrok/.local/bin:$PATH

# Detect .env
eval "$(direnv hook zsh)"
eval "$(pixi completion --shell zsh)"
# eval "$(pixi shell-hook)"
unsetopt correct_all

GITSTATUS_LOG_LEVEL=DEBUG


# Weave Agent Fleet
export PATH="$HOME/.weave/fleet/bin:$PATH"
