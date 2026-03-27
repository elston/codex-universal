# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETOS
ARG TARGETARCH

ENV LANG="C.UTF-8"
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
# Crucial for Codex CLI to run inside a container
ENV CODEX_UNSAFE_ALLOW_NO_SANDBOX=1 

### BASE ###

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils=2.42-* \
        sudo=1.9.* \
        build-essential=12.10* \
        bzr=2.7.* \
        curl=8.5.* \
        default-libmysqlclient-dev=1.1.* \
        dnsutils=1:9.18.* \
        fd-find=9.0.* \
        gettext=0.21-* \
        git=1:2.43.* \
        git-lfs=3.4.* \
        gnupg=2.4.* \
        inotify-tools=3.22.* \
        iputils-ping=3:20240117-* \
        jq=1.7.* \
        libbz2-dev=1.0.* \
        libc6=2.39-* \
        libc6-dev=2.39-* \
        libcurl4-openssl-dev=8.5.* \
        libedit2=3.1-* \
        libffi-dev=3.4.* \
        libgcc-13-dev=13.3.* \
        libgdbm-compat-dev=1.23-* \
        libgdbm-dev=1.23-* \
        libgssapi-krb5-2=1.20.* \
        liblzma-dev=5.6.* \
        libncurses-dev=6.4+20240113-* \
        libnss3-dev=2:3.98-* \
        libpq-dev=16.* \
        libpsl-dev=0.21.* \
        libpython3-dev=3.12.* \
        libreadline-dev=8.2-* \
        libsqlite3-dev=3.45.* \
        libssl-dev=3.0.* \
        libstdc++-13-dev=13.3.* \
        libuuid1=2.39.* \
        libxml2-dev=2.9.* \
        make=4.3-* \
        moreutils=0.69-* \
        netcat-openbsd=1.226-* \
        openssh-client=1:9.6p1-* \
        pkg-config=1.8.* \
        ripgrep=14.1.* \
        rsync=3.2.* \
        software-properties-common=0.99.* \
        sqlite3=3.45.* \
        tk-dev=8.6.* \
        tzdata=2025b-* \
        universal-ctags=5.9.* \
        unzip=6.0-* \
        uuid-dev=2.39.* \
        wget=1.21.* \
        xz-utils=5.6.* \
        zip=3.0-* \
        zlib1g=1:1.3.* \
        zlib1g-dev=1:1.3.* \
    && rm -rf /var/lib/apt/lists/*

### PYTHON ###

ARG PYTHON_VERSIONS="3.12"
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN git -c advice.detachedHead=0 clone --depth 1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"  \
    && cd "$PYENV_ROOT" && src/configure && make -C src \
    && pyenv install $PYTHON_VERSIONS \
    && pyenv global $PYTHON_VERSIONS \
    && rm -rf "$PYENV_ROOT/cache"

# Install pipx & global tools
ENV PIPX_BIN_DIR=/root/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    && pip install pipx \
    && pipx install poetry==2.1.* \
    && pipx install uv==0.7.* \
    && pip install ruff black mypy pyright isort pytest

ENV UV_NO_PROGRESS=1

### NODE & CODEX ###

ARG NVM_VERSION=v0.40.2
ARG NODE_VERSION=22
ENV NVM_DIR=/root/.nvm

# Corepack tries to do too much - disable some of its features:
# https://github.com/nodejs/corepack/blob/main/README.md
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0

# Ensure node binaries are in path immediately
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/root/.cache/yarn \
    --mount=type=cache,target=/root/.local/share/pnpm/store \
    git -c advice.detachedHead=0 clone --branch "$NVM_VERSION" --depth 1 https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
    && echo 'source $NVM_DIR/nvm.sh' >> /etc/profile \
    && echo "prettier\neslint\ntypescript" > $NVM_DIR/default-packages \
    && . $NVM_DIR/nvm.sh \
    && nvm install "$NODE_VERSION" \
    && nvm use "$NODE_VERSION" \
    && npm install -g npm@11.4 pnpm@10.12 @openai/codex \
    && corepack enable \
    && corepack install -g yarn \
    && nvm alias default "$NODE_VERSION" \
    && npm cache clean --force || true \
    && pnpm store prune || true \
    && yarn cache clean || true

# Copy the custom bashrc to the root user's home
COPY .bashrc /root/.bashrc

# Ensure the entrypoint and bashrc are synced
RUN echo "source /root/.bashrc" >> /etc/bash.bashrc

### SETUP & ENTRYPOINT ###

WORKDIR /workspace

# Copy your scripts
COPY setup_universal.sh /opt/codex/setup_universal.sh
COPY verify.sh /opt/verify.sh
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/codex/setup_universal.sh /opt/verify.sh /opt/entrypoint.sh \
    && /opt/verify.sh


# The entrypoint will handle the runtime switching logic you wrote
ENTRYPOINT ["/opt/entrypoint.sh"]

# Default to running the codex CLI
CMD ["codex"]
# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETOS
ARG TARGETARCH

ENV LANG="C.UTF-8"
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive
# Crucial for Codex CLI to run inside a container
ENV CODEX_UNSAFE_ALLOW_NO_SANDBOX=1 

### BASE ###

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils=2.42-* \
        sudo=1.9.* \
        build-essential=12.10* \
        bzr=2.7.* \
        curl=8.5.* \
        default-libmysqlclient-dev=1.1.* \
        dnsutils=1:9.18.* \
        fd-find=9.0.* \
        gettext=0.21-* \
        git=1:2.43.* \
        git-lfs=3.4.* \
        gnupg=2.4.* \
        inotify-tools=3.22.* \
        iputils-ping=3:20240117-* \
        jq=1.7.* \
        libbz2-dev=1.0.* \
        libc6=2.39-* \
        libc6-dev=2.39-* \
        libcurl4-openssl-dev=8.5.* \
        libedit2=3.1-* \
        libffi-dev=3.4.* \
        libgcc-13-dev=13.3.* \
        libgdbm-compat-dev=1.23-* \
        libgdbm-dev=1.23-* \
        libgssapi-krb5-2=1.20.* \
        liblzma-dev=5.6.* \
        libncurses-dev=6.4+20240113-* \
        libnss3-dev=2:3.98-* \
        libpq-dev=16.* \
        libpsl-dev=0.21.* \
        libpython3-dev=3.12.* \
        libreadline-dev=8.2-* \
        libsqlite3-dev=3.45.* \
        libssl-dev=3.0.* \
        libstdc++-13-dev=13.3.* \
        libuuid1=2.39.* \
        libxml2-dev=2.9.* \
        make=4.3-* \
        moreutils=0.69-* \
        netcat-openbsd=1.226-* \
        openssh-client=1:9.6p1-* \
        pkg-config=1.8.* \
        ripgrep=14.1.* \
        rsync=3.2.* \
        software-properties-common=0.99.* \
        sqlite3=3.45.* \
        tk-dev=8.6.* \
        tzdata=2025b-* \
        universal-ctags=5.9.* \
        unzip=6.0-* \
        uuid-dev=2.39.* \
        wget=1.21.* \
        xz-utils=5.6.* \
        zip=3.0-* \
        zlib1g=1:1.3.* \
        zlib1g-dev=1:1.3.* \
    && rm -rf /var/lib/apt/lists/*

### PYTHON ###

ARG PYTHON_VERSIONS="3.12"
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

RUN git -c advice.detachedHead=0 clone --depth 1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"  \
    && cd "$PYENV_ROOT" && src/configure && make -C src \
    && pyenv install $PYTHON_VERSIONS \
    && pyenv global $PYTHON_VERSIONS \
    && rm -rf "$PYENV_ROOT/cache"

# Install pipx & global tools
ENV PIPX_BIN_DIR=/root/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    && pip install pipx \
    && pipx install poetry==2.1.* \
    && pipx install uv==0.7.* \
    && pip install ruff black mypy pyright isort pytest

ENV UV_NO_PROGRESS=1

### NODE & CODEX ###

ARG NVM_VERSION=v0.40.2
ARG NODE_VERSION=22
ENV NVM_DIR=/root/.nvm

# Corepack tries to do too much - disable some of its features:
# https://github.com/nodejs/corepack/blob/main/README.md
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0

# Ensure node binaries are in path immediately
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/root/.cache/yarn \
    --mount=type=cache,target=/root/.local/share/pnpm/store \
    git -c advice.detachedHead=0 clone --branch "$NVM_VERSION" --depth 1 https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
    && echo 'source $NVM_DIR/nvm.sh' >> /etc/profile \
    && echo "prettier\neslint\ntypescript" > $NVM_DIR/default-packages \
    && . $NVM_DIR/nvm.sh \
    && nvm install "$NODE_VERSION" \
    && nvm use "$NODE_VERSION" \
    && npm install -g npm@11.4 pnpm@10.12 @openai/codex \
    && corepack enable \
    && corepack install -g yarn \
    && nvm alias default "$NODE_VERSION" \
    && npm cache clean --force || true \
    && pnpm store prune || true \
    && yarn cache clean || true

# Copy the custom bashrc to the root user's home
COPY .bashrc /root/.bashrc

# Ensure the entrypoint and bashrc are synced
RUN echo "source /root/.bashrc" >> /etc/bash.bashrc

### SETUP & ENTRYPOINT ###

WORKDIR /workspace

# Copy your scripts
COPY setup_universal.sh /opt/codex/setup_universal.sh
COPY verify.sh /opt/verify.sh
COPY entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/codex/setup_universal.sh /opt/verify.sh /opt/entrypoint.sh \
    && /opt/verify.sh


# The entrypoint will handle the runtime switching logic you wrote
ENTRYPOINT ["/opt/entrypoint.sh"]

# Default to running the codex CLI
CMD ["codex"]
