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

# Install miniconda dependencies
RUN echo "# Installing miniconda dependencies (curl)..." \
    && apt-get -y install --no-install-recommends curl 2>&1
# Miniconda Version (https://repo.anaconda.com/miniconda/)
ARG MINICONDA_VERSION=py39_4.12.0
# Add conda
RUN echo "# Installing conda..." \
    && if [ "$TARGETARCH" = "arm64" ]; then TARGET=aarch64; elif [ "$TARGETARCH" = "amd64" ]; then TARGET=x86_64; else TARGET=$TARGETARCH; fi \
    && curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-${TARGET}.sh -o /tmp/miniconda.sh \
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
    # Use shared folder for packages and environments
    && printf "envs_dirs:\n  - /opt/conda/envs\npkgs_dirs:\n   - /opt/conda/pkgs\n" >> /home/${USER_NAME}/.condarc \
    && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.condarc \
    # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
    && mkdir /home/${USER_NAME}/.conda \
    && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.conda
# Bash completion support for the conda command (https://github.com/tartansandal/conda-bash-completion/releases)
ARG CONDA_BASHCOMPLETION_VERSION=1.6
# Add conda bash completion
RUN echo "# Installing conda autocomplete..."
ADD https://github.com/tartansandal/conda-bash-completion/archive/refs/tags/${CONDA_BASHCOMPLETION_VERSION}.tar.gz /tmp/conda-bash-completion.tar.gz
RUN tar xvfz /tmp/conda-bash-completion.tar.gz --directory /tmp \
    && rm /tmp/conda-bash-completion.tar.gz \
    && cp /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}/conda /usr/share/bash-completion/completions/conda \
    && rm -rf /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}

# Install wait-for dependencies
RUN echo "# Installing wait-for dependencies (netcat)..." \
    && apt-get -y install --no-install-recommends netcat 2>&1
# wait-for version to install (https://github.com/eficode/wait-for/releases)
ARG WAITFOR_VERSION=v2.2.3
# Add wait-for (requires netcat)
RUN echo "# Installing wait-for..."
ADD https://github.com/eficode/wait-for/releases/download/${WAITFOR_VERSION}/wait-for /usr/local/bin/wait-for
RUN chown root:root /usr/local/bin/wait-for \
    && chmod 755 /usr/local/bin/wait-for

# Install sdkman dependencies
RUN echo "# Installing sdkman dependencies (unzip, zip, curl)..." \
    && apt-get -y install --no-install-recommends unzip zip curl 2>&1
# Install sdkman (requires unzip, zip and curl)
RUN echo "# Installing sdkman..."
ADD https://get.sdkman.io /tmp/get-sdkman.sh
RUN export SDKMAN_DIR=/opt/sdkman \
    && /bin/bash -i /tmp/get-sdkman.sh \
    && rm /tmp/get-sdkman.sh \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/sdkman \
    #
    # Disable sdkman auto-update prompt
    && sed -i 's/sdkman_selfupdate_enable=true/sdkman_selfupdate_enable=false/g' /opt/sdkman/etc/config \
    #
    # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
    && chmod -R 2775 /opt/sdkman \
    #
    # Configure sdkman for the non-root user
    && echo "# Configuring sdkman for '${USER_NAME}'..." \
    && printf "\nexport SDKMAN_DIR=/opt/sdkman\n. /opt/sdkman/bin/sdkman-init.sh\n" >> /home/${USER_NAME}/.bashrc
# Add bash completion for maven
RUN echo "# Installing bash completion for maven..."
ADD https://raw.github.com/juven/maven-bash-completion/master/bash_completion.bash /usr/share/bash-completion/completions/mvn
RUN chmod 644 /usr/share/bash-completion/completions/mvn

# Install nvm dependencies
RUN echo "# Installing nvm dependencies (curl)..." \
    && apt-get -y install --no-install-recommends curl 2>&1
# Node Version Manager version to install (https://github.com/nvm-sh/nvm/releases)
ARG NVM_VERSION=v0.39.1
# Install nvm (requires curl)
RUN echo "# Installing nvm..."
ADD https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh /tmp/nvm.sh
RUN mkdir -p /opt/nvm \
    && export NVM_DIR=/opt/nvm \
    && /bin/bash -i /tmp/nvm.sh --no-use \
    && rm /tmp/nvm.sh \
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
    # Add nvm bash completion
    #&& ln -s /opt/nvm/bash_completion /usr/share/bash-completion/completions/nvm \
    # avobe not working as /usr/share/bash-completion/completions/nvm is run before nvm.sh
    # so no nvm command available and the bash_completion scripts checks it
    && echo "# Configuring nvm autocomplete for '${USER_NAME}'..." \
    && printf "\n. /opt/nvm/bash_completion\n" >> /home/${USER_NAME}/.bashrc

# Install gvm dependencies
RUN echo "# Installing gvm dependencies (build-essential, git, binutils, bison and curl)..." \
    && apt-get -y install --no-install-recommends build-essential git bison curl  2>&1
# Install Go Version Manager (requires git, binutils, bison, gcc, make and curl; go requires build-essential)
RUN echo "# Installing gvm..."
ADD https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer /tmp/gvm-installer.sh
RUN /bin/bash -i /tmp/gvm-installer.sh master /opt \
    && rm /tmp/gvm-installer.sh \
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
    # Add gvm bash completion
    #&& ln -s /opt/gvm/scripts/completion /usr/share/bash-completion/completions/gvm
    # avobe not working as $GVM_ROOT is set by /opt/gvm/scripts/gvm
    && echo "# Configuring gvm autocomplete for '${USER_NAME}'..." \
    && printf "\n. /opt/gvm/scripts/completion\n" >> /home/${USER_NAME}/.bashrc

# Install rbenv dependencies
RUN echo "# Installing rbenv dependencies (curl, autoconf, bison, build-essential, libssl-dev, libyaml-dev, libreadline6-dev, zlib1g-dev, libncurses5-dev, libffi-dev, libgdbm6, libgdbm-dev, libdb-dev)..." \
    && apt-get -y install --no-install-recommends curl autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev 2>&1
# rbenv version to install (https://github.com/rbenv/rbenv/releases)
ARG RBENV_VERSION=1.2.0
# ruby-build version to install (https://github.com/rbenv/ruby-build/releases)
ARG RUBY_BUILD_VERSION=20220426
# rbenv installation directory
ENV RBENV_ROOT=/opt/rbenv
# Install Ruby Environment Manager
RUN echo "# Installing rbenv (with ruby-build)..."
ADD https://github.com/rbenv/rbenv/archive/refs/tags/v${RBENV_VERSION}.tar.gz /tmp/rbenv-${RBENV_VERSION}.tar.gz
ADD https://github.com/rbenv/ruby-build/archive/refs/tags/v${RUBY_BUILD_VERSION}.tar.gz /tmp/ruby-build-${RUBY_BUILD_VERSION}.tar.gz
# Create installation folders
RUN mkdir -p ${RBENV_ROOT}/plugins/ruby-build \
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
    # Configure rvm for the non-root user
    && echo "# Configuring rvm for '${USER_NAME}'..." \
    && printf "\nPATH=${RBENV_ROOT}/bin:\$PATH\neval \"\$(rbenv init -)\"\n" >> /home/${USER_NAME}/.bashrc
# Add bash completion for Ruby-related commands
RUN echo "# Installing bash completion for Ruby-related commands (bundle, gem, jruby, rails, rake, ruby)..."
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-bundle /usr/share/bash-completion/completions/bundle
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-gem /usr/share/bash-completion/completions/gem
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-jruby /usr/share/bash-completion/completions/jruby
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-rails /usr/share/bash-completion/completions/rails
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-rake /usr/share/bash-completion/completions/rake
ADD https://raw.githubusercontent.com/mernen/completion-ruby/main/completion-ruby /usr/share/bash-completion/completions/ruby
RUN chmod 644 /usr/share/bash-completion/completions/bundle \
    && chmod 644 /usr/share/bash-completion/completions/gem \
    && chmod 644 /usr/share/bash-completion/completions/jruby \
    && chmod 644 /usr/share/bash-completion/completions/rails \
    && chmod 644 /usr/share/bash-completion/completions/rake \
    && chmod 644 /usr/share/bash-completion/completions/ruby

# Install ruby build dependencies
RUN echo "# Installing ruby build dependencies (libmysqlclient-dev, unixodbc-dev, libpq-dev, freetds-dev)..." \
  && apt-get -y install --no-install-recommends libmysqlclient-dev unixodbc-dev libpq-dev freetds-dev 2>&1

# Ubuntu 18.04 comes with OpenSSL 1.1 and Ruby versions earlier than 2.4 used OpenSSL 1.0
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

# Install dotnet-install dependencies
RUN echo "# Installing dotnet-install dependencies (curl, libicu-dev)..." \
    && apt-get -y install --no-install-recommends curl libicu-dev 2>&1
# .Net installer version (https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install)
ARG DOTNET_INSTALLER_VERSION=v1
# Use this path for shared installation
ENV DOTNET_ROOT=/opt/dotnet
# Opt out .NET SDK telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
# Install .Net installer (requires curl; dotnet requires libicu-dev)
RUN echo "# Installing dotnet-install..."
ADD https://dot.net/v1/dotnet-install.sh /usr/local/bin/dotnet-install.sh
RUN chmod 755 /usr/local/bin/dotnet-install.sh
# Setup .Net shared installation directory
RUN mkdir -p ${DOTNET_ROOT} \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} ${DOTNET_ROOT} \
    #
    # Set the segid bit to the folder and give write and exec acces so any member of group can use it (but not others)
    && chmod -R 2775 ${DOTNET_ROOT} \
    #
    # Configure .Net for the non-root user
    && printf "\nPATH=\$PATH:\$DOTNET_ROOT\n" >> /home/${USER_NAME}/.bashrc
# Add dotnet bash completion
RUN echo "# Installing dotnet autocomplete..."
ADD https://github.com/dotnet/cli/raw/master/scripts/register-completions.bash /usr/share/bash-completion/completions/dotnet
RUN chmod 644 /usr/share/bash-completion/completions/dotnet

# Install git-lfs
RUN echo "# Installing git-lfs..."
ADD https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh /tmp/git-lfs-repos.sh
# Setup git-lfs repos
RUN /bin/bash -i /tmp/git-lfs-repos.sh \
    && rm /tmp/git-lfs-repos.sh \
    #
    # Install git-lfs
    && apt-get -y install --no-install-recommends git-lfs 2>&1

# Install other usefull software and libraries
RUN echo "# Installing libxtst6, procps, lsb-release, openssh-client, p7zip-full, p7zip-rar and unrar..." \ 
    && apt-get -y install --no-install-recommends libxtst6 procps lsb-release openssh-client p7zip-full p7zip-rar unrar 2>&1 \
    && if [ "$TARGETARCH" = "amd64" ]; then echo "# Installing rar..."; apt-get -y install --no-install-recommends rar 2>&1; fi

# Clean up apt
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME
