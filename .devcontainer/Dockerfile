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
  gh \
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
  && echo 'eval "$(direnv hook bash)"' >> /home/$USERNAME/.bashrc

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

# Install Go
ARG GO_VERSION=1.25.0
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
  sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
  rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/home/node/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

# Install cargo-binstall for faster binary installation
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# Install common Rust tools using pre-built binaries
RUN /root/.cargo/bin/cargo binstall --no-confirm \
    cargo-watch \
    cargo-edit \
    cargo-audit \
    cargo-outdated

# Install .NET SDK
ARG DOTNET_VERSION=8.0
RUN wget https://dot.net/v1/dotnet-install.sh && \
  chmod +x dotnet-install.sh && \
  ./dotnet-install.sh --channel ${DOTNET_VERSION} --install-dir /usr/local/dotnet && \
  rm dotnet-install.sh
ENV PATH="/usr/local/dotnet:${PATH}"
ENV DOTNET_ROOT="/usr/local/dotnet"
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install Python and common tools
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install common Python tools
RUN pip3 install --no-cache-dir --break-system-packages \
  pipenv \
  poetry \
  black \
  pylint \
  pytest \
  requests \
  ipython

# Fix Rust permissions for node user (do this as root before switching)
RUN mv /root/.cargo /home/node/.cargo && \
  mv /root/.rustup /home/node/.rustup && \
  chown -R node:node /home/node/.cargo /home/node/.rustup

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
    echo 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"' >> ~/.zshrc && \
    echo 'export PATH="$PATH:$HOME/.cargo/bin"' >> ~/.zshrc && \
    echo 'export PATH="$PATH:/usr/local/dotnet"' >> ~/.zshrc && \
    echo 'export GOPATH="$HOME/go"' >> ~/.zshrc && \
    echo 'export DOTNET_ROOT="/usr/local/dotnet"' >> ~/.zshrc && \
    echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=1' >> ~/.zshrc && \
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
    echo 'export VISUAL=vim' >> ~/.zshrc

# Install Claude and create config directory
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} && \
    mkdir -p /home/node/.claude && \
    chown -R node:node /home/node/.claude


# Copy and set up scripts and theme
COPY init-firewall.sh /usr/local/bin/
COPY setup-git.sh /usr/local/bin/
COPY create-limited-git-setup.sh /usr/local/bin/
COPY setup-direnv.sh /usr/local/bin/
COPY liquescent.omp.json /usr/local/share/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/setup-git.sh && \
  chmod +x /usr/local/bin/create-limited-git-setup.sh && \
  chmod +x /usr/local/bin/setup-direnv.sh && \
  chmod 644 /usr/local/share/liquescent.omp.json && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node