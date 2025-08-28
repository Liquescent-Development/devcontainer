FROM node:20

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  # Note: GitHub CLI now installed via ghcr.io/devcontainers/features/github-cli:1
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  curl \
  wget \
  ca-certificates \
  build-essential \
  pkg-config \
  libssl-dev \
  direnv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Note: 1Password CLI is now installed via Dev Container Feature:
# ghcr.io/itsmechlark/features/1password:1

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash and zsh history, configure direnv for bash
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && touch /commandhistory/.zsh_history \
  && chown -R $USERNAME /commandhistory \
  && echo "$SNIPPET" >> /home/$USERNAME/.bashrc \
  && echo 'eval "$(direnv hook bash)"' >> /home/$USERNAME/.bashrc \
  && mkdir -p /home/$USERNAME/.config/direnv \
  && echo 'dotenv_if_exists' > /home/$USERNAME/.config/direnv/direnvrc \
  && chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Note: Go is now installed via Dev Container Feature:
# ghcr.io/devcontainers/features/go:1

# Note: Rust is now installed via Dev Container Feature:
# ghcr.io/devcontainers/features/rust:1

# Note: .NET SDK is now installed via Dev Container Feature:
# ghcr.io/devcontainers/features/dotnet:2

# Note: Python is now installed via Dev Container Feature:
# ghcr.io/devcontainers/features/python:1

# Note: Rust permissions are handled by the Dev Container Feature

# Install oh-my-posh as root
RUN curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin

# Set up non-root user
USER node
ENV PATH="/home/node/.cargo/bin:${PATH}"

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=vim
ENV VISUAL=vim

# Install oh-my-zsh as node user
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Install zsh-autosuggestions plugin
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    # Install zsh-syntax-highlighting plugin
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Create .zshrc configuration
RUN echo '# Path to oh-my-zsh installation' > ~/.zshrc && \
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Set theme (we are using oh-my-posh instead)' >> ~/.zshrc && \
    echo 'ZSH_THEME=""' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Which plugins to load' >> ~/.zshrc && \
    echo 'plugins=(git docker docker-compose npm node golang rust python dotnet fzf zsh-autosuggestions zsh-syntax-highlighting command-not-found sudo history extract z)' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Oh-My-Zsh settings' >> ~/.zshrc && \
    echo 'HIST_STAMPS="yyyy-mm-dd"' >> ~/.zshrc && \
    echo 'DISABLE_UPDATE_PROMPT="true"' >> ~/.zshrc && \
    echo 'DISABLE_AUTO_UPDATE="true"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Load Oh-My-Zsh' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# User configuration' >> ~/.zshrc && \
    echo 'export PATH="$PATH:/usr/local/share/npm-global/bin"' >> ~/.zshrc && \
    echo '# Language paths are configured by Dev Container Features' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# FZF configuration' >> ~/.zshrc && \
    echo 'source /usr/share/doc/fzf/examples/key-bindings.zsh' >> ~/.zshrc && \
    echo 'source /usr/share/doc/fzf/examples/completion.zsh' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# History configuration' >> ~/.zshrc && \
    echo 'export HISTFILE=/commandhistory/.zsh_history' >> ~/.zshrc && \
    echo 'export HISTSIZE=10000' >> ~/.zshrc && \
    echo 'export SAVEHIST=10000' >> ~/.zshrc && \
    echo 'setopt SHARE_HISTORY' >> ~/.zshrc && \
    echo 'setopt HIST_EXPIRE_DUPS_FIRST' >> ~/.zshrc && \
    echo 'setopt HIST_IGNORE_DUPS' >> ~/.zshrc && \
    echo 'setopt HIST_IGNORE_SPACE' >> ~/.zshrc && \
    echo 'setopt HIST_VERIFY' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Aliases' >> ~/.zshrc && \
    echo "alias ll='ls -alF'" >> ~/.zshrc && \
    echo "alias la='ls -A'" >> ~/.zshrc && \
    echo "alias l='ls -CF'" >> ~/.zshrc && \
    echo "alias gs='git status'" >> ~/.zshrc && \
    echo "alias gp='git pull'" >> ~/.zshrc && \
    echo "alias gc='git commit'" >> ~/.zshrc && \
    echo "alias gd='git diff'" >> ~/.zshrc && \
    echo "alias ga='git add'" >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Oh-My-Posh prompt' >> ~/.zshrc && \
    echo 'eval "$(oh-my-posh init zsh --config /usr/local/share/liquescent.omp.json)"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Node.js memory' >> ~/.zshrc && \
    echo 'export NODE_OPTIONS="--max-old-space-size=4096"' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# Editor' >> ~/.zshrc && \
    echo 'export EDITOR=vim' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    echo '# direnv - automatically load .env files' >> ~/.zshrc && \
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc && \
    echo 'export VISUAL=vim' >> ~/.zshrc && \
    echo '' >> ~/.zshrc && \
    # Configure direnv to automatically load .env files
    mkdir -p ~/.config/direnv && \
    echo 'dotenv_if_exists' > ~/.config/direnv/direnvrc

# Install Claude and create config directory
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    mkdir -p /home/node/.claude && \
    chown -R node:node /home/node/.claude


# Copy and set up scripts and theme
COPY scripts/init-firewall.sh /usr/local/bin/
COPY scripts/setup-git.sh /usr/local/bin/
COPY scripts/setup-1password.sh /usr/local/bin/
COPY scripts/liquescent.omp.json /usr/local/share/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/setup-git.sh && \
  chmod +x /usr/local/bin/setup-1password.sh && \
  chmod 644 /usr/local/share/liquescent.omp.json && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node