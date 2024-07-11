FROM rubensa/ubuntu-tini-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Architecture component of TARGETPLATFORM (platform of the build result)
ARG TARGETARCH

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Configure apt
RUN apt-get update

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and other usefull software and libraries
RUN echo "# Installing curl, netcat-openbsd, unzip, zip, build-essential, git, bison, libssl-dev, libyaml-dev, libreadline6-dev, zlib1g-dev, libncurses5-dev, libffi-dev, libgdbm6, libgdbm-dev, libdb-dev, libmysqlclient-dev, unixodbc-dev, libpq-dev, freetds-dev, libicu-dev, libxtst6, procps, lsb-release, openssh-client, p7zip-full, p7zip-rar, unrar, jq and bsdmainutils..." \
  && apt-get -y install --no-install-recommends curl netcat-openbsd unzip zip build-essential git bison libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev libmysqlclient-dev unixodbc-dev libpq-dev freetds-dev libicu-dev libxtst6 procps lsb-release openssh-client p7zip-full p7zip-rar unrar jq bsdmainutils 2>&1 \
  && if [ "$TARGETARCH" = "amd64" ]; then echo "# Installing rar..."; apt-get -y install --no-install-recommends rar 2>&1; fi

# Docker CLI Version (https://download.docker.com/linux/static/stable/)
ARG DOCKER_VERSION=27.0.3
# Add docker
RUN echo "# Installing docker..." \
  && if [ "$TARGETARCH" = "arm64" ]; then TARGET=aarch64; elif [ "$TARGETARCH" = "amd64" ]; then TARGET=x86_64; else TARGET=$TARGETARCH; fi \
  && curl -o /tmp/docker.tgz -sSL https://download.docker.com/linux/static/stable/${TARGET}/docker-${DOCKER_VERSION}.tgz \
  && tar xzvf /tmp/docker.tgz --directory /tmp \
  && rm /tmp/docker.tgz \
  && cp /tmp/docker/* /usr/local/bin/ \
  && rm -rf /tmp/docker \
  #
  # Setup docker bash completion
  && docker completion bash > /usr/share/bash-completion/completions/docker \
  && chmod 644 /usr/share/bash-completion/completions/docker

# Docker Compose (https://github.com/docker/compose/releases/)
ARG DOCKERCOMPOSE_VERSION=2.28.1
# Install Docker Compose
RUN echo "# Installing docker-compose..." \
  && if [ "$TARGETARCH" = "arm64" ]; then TARGET=aarch64; elif [ "$TARGETARCH" = "amd64" ]; then TARGET=x86_64; else TARGET=$TARGETARCH; fi \
  && mkdir -p /usr/local/lib/docker/cli-plugins \
  && curl -o /usr/local/lib/docker/cli-plugins/docker-compose -sSL https://github.com/docker/compose/releases/download/v${DOCKERCOMPOSE_VERSION}/docker-compose-linux-${TARGET} \
  && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Default to root only access to the Docker socket, set up docker-from-docker-init.sh for non-root access
RUN touch /var/run/docker-host.sock \
  && ln -s /var/run/docker-host.sock /var/run/docker.sock

# Add script to allow docker-from-docker
ADD docker-from-docker-init.sh /sbin/docker-from-docker-init.sh
RUN echo "# Allow docker-from-docker configuration for the non-root user..." \
  #
  # Enable docker-from-docker init script
  && chmod +x /sbin/docker-from-docker-init.sh

# Install socat (to allow docker-from-docker)
RUN echo "# Installing socat..." \ 
  && apt-get -y install --no-install-recommends socat 2>&1

# Miniconda Version (https://repo.anaconda.com/miniconda/)
# Python 3.12 conda 24.1.2 release 0 (https://docs.conda.io/projects/miniconda/en/latest/miniconda-release-notes.html)
ARG MINICONDA_VERSION=py312_24.5.0-0
# Bash completion support for the conda command (https://github.com/tartansandal/conda-bash-completion/releases)
ARG CONDA_BASHCOMPLETION_VERSION=1.7
# Add conda
RUN echo "# Installing conda..." \
  && if [ "$TARGETARCH" = "arm64" ]; then TARGET=aarch64; elif [ "$TARGETARCH" = "amd64" ]; then TARGET=x86_64; else TARGET=$TARGETARCH; fi \
  && curl -o /tmp/miniconda.sh -sSL https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-${TARGET}.sh \
  # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
  && mkdir ~/.conda \
  && /bin/bash -i /tmp/miniconda.sh -b -p /opt/conda \
  && rm /tmp/miniconda.sh \
  #
  # Assign group folder ownership
  && echo "# Configuring conda for '${GROUP_NAME}'..." \
  && chgrp -R ${GROUP_NAME} /opt/conda \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 /opt/conda \
  #
  # Configure conda for the non-root user
  && echo "# Configuring conda for '${USER_NAME}'..." \
  && printf "\n. /opt/conda/etc/profile.d/conda.sh\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Use shared folder for packages and environments
  && printf "envs_dirs:\n  - /opt/conda/envs\npkgs_dirs:\n   - /opt/conda/pkgs\n" >> /home/${USER_NAME}/.condarc \
  && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.condarc \
  #
  # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
  && mkdir /home/${USER_NAME}/.conda \
  && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.conda \
  #
  # Add conda bash completion
  && echo "# Installing conda autocomplete..." \
  && curl -o /tmp/conda-bash-completion.tar.gz -sSL https://github.com/tartansandal/conda-bash-completion/archive/refs/tags/${CONDA_BASHCOMPLETION_VERSION}.tar.gz \
  && tar xvfz /tmp/conda-bash-completion.tar.gz --directory /tmp \
  && rm /tmp/conda-bash-completion.tar.gz \
  && cp /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}/conda /usr/share/bash-completion/completions/conda \
  && chmod 644 /usr/share/bash-completion/completions/conda \
  && rm -rf /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}

# wait-for version to install (https://github.com/eficode/wait-for/releases)
ARG WAITFOR_VERSION=v2.2.4
# Install wait-for (requires netcat-openbsd)
RUN echo "# Installing wait-for..." \
  && curl -o /usr/local/bin/wait-for -sSL https://github.com/eficode/wait-for/releases/download/${WAITFOR_VERSION}/wait-for \
  && chown root:root /usr/local/bin/wait-for \
  && chmod 755 /usr/local/bin/wait-for

# Install sdkman (requires unzip, zip and curl)
RUN echo "# Installing sdkman..." \
  && curl -o /tmp/get-sdkman.sh -sSL https://get.sdkman.io  \
  && export SDKMAN_DIR=/opt/sdkman \
  && /bin/bash -i /tmp/get-sdkman.sh \
  && rm /tmp/get-sdkman.sh \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} /opt/sdkman \
  #
  # Disable sdkman auto-update prompt
  && sed -i 's/sdkman_auto_selfupdate=true/sdkman_auto_selfupdate=false/g' /opt/sdkman/etc/config \
  && sed -i 's/sdkman_selfupdate_enable=true/sdkman_selfupdate_enable=false/g' /opt/sdkman/etc/config \
  && sed -i 's/sdkman_selfupdate_feature=true/sdkman_selfupdate_feature=false/g' /opt/sdkman/etc/config \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 /opt/sdkman \
  #
  # Configure sdkman for the non-root user
  && echo "# Configuring sdkman for '${USER_NAME}'..." \
  && printf "\nexport SDKMAN_DIR=/opt/sdkman\n. /opt/sdkman/bin/sdkman-init.sh\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Add bash completion for maven
  && echo "# Installing bash completion for maven..." \
  && curl -o /usr/share/bash-completion/completions/mvn -sSL https://raw.github.com/juven/maven-bash-completion/master/bash_completion.bash \
  && chmod 644 /usr/share/bash-completion/completions/mvn

# Node Version Manager version to install (https://github.com/nvm-sh/nvm/releases)
ARG NVM_VERSION=v0.39.7
# Install nvm (requires curl)
RUN echo "# Installing nvm..." \
  && curl -o /tmp/nvm.sh -sSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh \
  && mkdir -p /opt/nvm \
  && export NVM_DIR=/opt/nvm \
  && /bin/bash -i /tmp/nvm.sh --no-use \
  && rm /tmp/nvm.sh \
  #
  # Create nvm cache directory so it is owned by the group
  && mkdir -p /opt/nvm/.cache \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} /opt/nvm \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 /opt/nvm \
  #
  # Configure nvm for the non-root user
  && echo "# Configuring nvm for '${USER_NAME}'..." \
  && printf "\n. /opt/nvm/nvm.sh\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Configure nvm bash completion for the non root user
  && echo "# Configuring nvm autocomplete for '${USER_NAME}'..." \
  && printf "\n. /opt/nvm/bash_completion\n" >> /home/${USER_NAME}/.bashrc

# Go Version Manager version to install (https://github.com/moovweb/gvm/tags)
ARG GVM_VERSION=1.0.22
# Install Go Version Manager (requires git, binutils, bison, gcc, make, curl and bsdmainutils; go requires build-essential)
RUN echo "# Installing gvm..." \
  && curl -o /tmp/gvm-installer.sh -sSL https://raw.githubusercontent.com/moovweb/gvm/${GVM_VERSION}/binscripts/gvm-installer \
  && /bin/bash -i /tmp/gvm-installer.sh ${GVM_VERSION} /opt \
  && rm /tmp/gvm-installer.sh \
  #
  # Create gvm pkgsets directory so it is owned by the group
  && mkdir -p /opt/gvm/pkgsets \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} /opt/gvm \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 /opt/gvm \
  #
  # Configure gvm for the non-root user
  && echo "# Configuring gvm for '${USER_NAME}'..." \
  && printf "\n. /opt/gvm/scripts/gvm\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Configure gvm bash completion for the non root user
  && echo "# Configuring gvm autocomplete for '${USER_NAME}'..." \
  && printf "\n. /opt/gvm/scripts/completion\n" >> /home/${USER_NAME}/.bashrc

# rbenv version to install (https://github.com/rbenv/rbenv/releases)
ARG RBENV_VERSION=1.3.0
# ruby-build version to install (https://github.com/rbenv/ruby-build/releases)
ARG RUBY_BUILD_VERSION=20240709.1
# rbenv installation directory
ENV RBENV_ROOT=/opt/rbenv
# Install Ruby Environment Manager (requires curl, autoconf, bison, build-essential, libssl-dev, libyaml-dev, libreadline6-dev, zlib1g-dev, libncurses5-dev, libffi-dev, libgdbm6, libgdbm-dev, libdb-dev)
RUN echo "# Installing rbenv (with ruby-build)..." \
  && curl -o /tmp/rbenv-${RBENV_VERSION}.tar.gz -sSL https://github.com/rbenv/rbenv/archive/refs/tags/v${RBENV_VERSION}.tar.gz \
  && curl -o /tmp/ruby-build-${RUBY_BUILD_VERSION}.tar.gz -sSL https://github.com/rbenv/ruby-build/archive/refs/tags/v${RUBY_BUILD_VERSION}.tar.gz \
  #
  # Create installation folders
  && mkdir -p ${RBENV_ROOT}/plugins/ruby-build \
  #
  # Create sources cache directory
  && mkdir -p ${RBENV_ROOT}/cache \
  #
  # Create installed versions directory
  && mkdir -p ${RBENV_ROOT}/versions \
  #
  # Install rbenv
  && tar xzf /tmp/rbenv-${RBENV_VERSION}.tar.gz -C ${RBENV_ROOT} --strip-components=1 \
  #
  # Compile dynamic bash extension to speed up rbenv
  && cd ${RBENV_ROOT} && src/configure && make -C src \
  #
  # Install ruby-build
  && tar xzf /tmp/ruby-build-${RUBY_BUILD_VERSION}.tar.gz -C ${RBENV_ROOT}/plugins/ruby-build --strip-components=1 \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} ${RBENV_ROOT} \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 ${RBENV_ROOT} \
  #
  # Cleanup
  && rm /tmp/rbenv-${RBENV_VERSION}.tar.gz \
  && rm /tmp/ruby-build-${RUBY_BUILD_VERSION}.tar.gz \
  #
  # Configure rbenv for the non-root user
  && echo "# Configuring rbenv for '${USER_NAME}'..." \
  && printf "\nPATH=${RBENV_ROOT}/bin:\$PATH\neval \"\$(rbenv init -)\"\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Add bash completion for Ruby-related commands
  && echo "# Installing bash completion for Ruby-related commands (bundle, gem, jruby, rails, rake, ruby)..." \
  && curl -o /usr/share/bash-completion/completions/bundle -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-bundle \
  && chmod 644 /usr/share/bash-completion/completions/bundle \
  && curl -o /usr/share/bash-completion/completions/gem -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-gem \
  && chmod 644 /usr/share/bash-completion/completions/gem \
  && curl -o /usr/share/bash-completion/completions/jruby -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-jruby \
  && chmod 644 /usr/share/bash-completion/completions/jruby \
  && curl -o /usr/share/bash-completion/completions/rails -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-rails \
  && chmod 644 /usr/share/bash-completion/completions/rails \
  && curl -o /usr/share/bash-completion/completions/rake -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-rake \
  && chmod 644 /usr/share/bash-completion/completions/rake \
  && curl -o /usr/share/bash-completion/completions/ruby -sSL https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-ruby \
  && chmod 644 /usr/share/bash-completion/completions/ruby

# Ubuntu 22.04 comes with OpenSSL 3.0 and Ruby versions earlier than 2.4 used OpenSSL 1.0
# openssl installation directory
ENV OPENSSL_ROOT_1_0=/opt/openssl-1.0
COPY --from=rubensa/ubuntu-openssl-old ${OPENSSL_ROOT_1_0} ${OPENSSL_ROOT_1_0}
# Install OpenSSL 1.0
RUN echo "# Installing OpenSSL 1.0..." \
  #
  # Link the system's certs to OpenSSL directory
  && rm -rf ${OPENSSL_ROOT_1_0}/certs \
  && ln -s /etc/ssl/certs ${OPENSSL_ROOT_1_0}
# Use RUBY_CONFIGURE_OPTS=--with-openssl-dir=${OPENSSL_ROOT_1_0} before the command to install the ruby version < 2.4

# Ubuntu 22.04 comes with OpenSSL 3.0 and Ruby versions earlier than 3.1 used OpenSSL 1.1
# openssl installation directory
ENV OPENSSL_ROOT_1_1=/opt/openssl-1.1
COPY --from=rubensa/ubuntu-openssl-old ${OPENSSL_ROOT_1_1} ${OPENSSL_ROOT_1_1}
# Install OpenSSL 1.1
RUN echo "# Installing OpenSSL 1.1..." \
  # Link the system's certs to OpenSSL directory
  && rm -rf ${OPENSSL_ROOT_1_1}/certs \
  && ln -s /etc/ssl/certs ${OPENSSL_ROOT_1_1}
# Use RUBY_CONFIGURE_OPTS=--with-openssl-dir=${OPENSSL_ROOT_1_1} before the command to install the ruby version < 3.1

# .Net installer version (https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install)
ARG DOTNET_INSTALLER_VERSION=v1
# Use this path for shared installation
ENV DOTNET_ROOT=/opt/dotnet
# Opt out .NET SDK telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
# Install .Net installer (requires curl; dotnet requires libicu-dev)
RUN echo "# Installing dotnet-install..." \
  && curl -o /usr/local/bin/dotnet-install.sh -k -sSL https://dot.net/v1/dotnet-install.sh \
  && chmod 755 /usr/local/bin/dotnet-install.sh \
  #
  # Setup .Net shared installation directory
  && mkdir -p ${DOTNET_ROOT} \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} ${DOTNET_ROOT} \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 ${DOTNET_ROOT} \
  #
  # Configure .Net for the non-root user
  && printf "\nPATH=\$PATH:\$DOTNET_ROOT\n" >> /home/${USER_NAME}/.bashrc \
  #
  # Add dotnet bash completion
  && echo "# Installing dotnet autocomplete..." \
  && curl -o /usr/share/bash-completion/completions/dotnet -sSL https://github.com/dotnet/cli/raw/master/scripts/register-completions.bash \
  && chmod 644 /usr/share/bash-completion/completions/dotnet

# Install git-lfs
RUN echo "# Installing git-lfs..." \
  && curl -o /tmp/git-lfs-repos.sh -sSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh \
  #
  # Setup git-lfs repos
  && /bin/bash -i /tmp/git-lfs-repos.sh \
  && rm /tmp/git-lfs-repos.sh \
  #
  # Install git-lfs
  && apt-get -y install --no-install-recommends git-lfs 2>&1

# Install Rust (https://github.com/rust-lang/rust/releases)
# (requires curl and build-essential as for GNU targets Rust uses gcc for linking, and gcc in turn calls ld)
# see: https://github.com/rust-lang/rust/issues/71515
ARG RUST_VERSION=1.79.0
# Use this path for shared installation
ENV RUST_ROOT=/opt/rust
RUN echo "# Installing Rust..." \
  && curl -o /tmp/rustup-init.sh -sSL https://sh.rustup.rs \
  #
  # Setup rustup
  && RUSTUP_HOME=${RUST_ROOT}/rustup CARGO_HOME=${RUST_ROOT}/cargo /bin/bash -i /tmp/rustup-init.sh -y --default-toolchain=${RUST_VERSION} --profile minimal --no-modify-path \
  && rm /tmp/rustup-init.sh \
  #
  # Assign group folder ownership
  && chgrp -R ${GROUP_NAME} ${RUST_ROOT} \
  #
  # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
  && chmod -R 2775 ${RUST_ROOT} \
  #
  # Setup rustup completion
  && ${RUST_ROOT}/cargo/bin/rustup completions bash > /usr/share/bash-completion/completions/rustup \
  && chmod 644 /usr/share/bash-completion/completions/rustup \
  #
  # Setup cargo completion
  && ${RUST_ROOT}/cargo/bin/rustup completions bash cargo > /usr/share/bash-completion/completions/cargo \
  && chmod 644 /usr/share/bash-completion/completions/cargo \
  #
  # Configure Rust for the non-root user
  && echo "# Configuring Rust for '${USER_NAME}'..." \
  && printf "\nexport RUSTUP_HOME=$RUST_ROOT/rustup\nPATH=\$PATH:\$RUST_ROOT/cargo/bin\n" >> /home/${USER_NAME}/.bashrc

# Clean up apt
RUN apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME=/home/$USER_NAME

# Allways execute tini, fixuid and docker-from-docker-init
ENTRYPOINT [ "/sbin/tini", "--", "/sbin/fixuid", "/sbin/docker-from-docker-init.sh" ]

# If CMD is defined from the base image, setting ENTRYPOINT will reset CMD to an empty value.
# In this scenario, CMD must be defined in the current image to have a value.
# By default execute an interactive shell (executes ~/.bashrc)
CMD [ "/bin/bash", "-i" ]