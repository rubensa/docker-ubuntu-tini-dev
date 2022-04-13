FROM rubensa/ubuntu-tini-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Miniconda Version (https://repo.anaconda.com/miniconda/)
ARG MINICONDA_VERSION=py39_4.10.3
# Add conda
ADD https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh /tmp/miniconda.sh
RUN echo "# Installing conda..." \
    # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
    && mkdir ~/.conda \
    && /bin/bash -i /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh \
    #
    # Assign group folder ownership
    && echo "# Configuring conda for '${GROUP_NAME}'..." \
    && chgrp -R ${GROUP_NAME} /opt/conda \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/conda \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/conda \
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
ARG CONDA_BASHCOMPLETION_VERSION=1.5
# Add conda bash completion
ADD https://github.com/tartansandal/conda-bash-completion/archive/refs/tags/${CONDA_BASHCOMPLETION_VERSION}.tar.gz /tmp/conda-bash-completion.tar.gz
RUN echo "# Installing conda autocomplete..." \
    && tar xvfz /tmp/conda-bash-completion.tar.gz --directory /tmp \
    && rm /tmp/conda-bash-completion.tar.gz \
    && cp /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}/conda /usr/share/bash-completion/completions/conda \
    && rm -rf /tmp/conda-bash-completion-${CONDA_BASHCOMPLETION_VERSION}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt
RUN apt-get update

# Install wait-for dependencies
RUN echo "# Installing wait-for dependencies..." \
    && apt-get -y install --no-install-recommends netcat 2>&1
# wait-for version to install (https://github.com/eficode/wait-for/releases)
ARG WAITFOR_VERSION=v2.2.2
# Add wait-for (requires netcat)
ADD https://github.com/eficode/wait-for/releases/download/${WAITFOR_VERSION}/wait-for /usr/bin/wait-for
RUN echo "# Installing wait-for..." \
    && chown root:root /usr/bin/wait-for \
    && chmod 4755 /usr/bin/wait-for

# Install sdkman dependencies
RUN echo "# Installing sdkman dependencies..." \
    && apt-get -y install --no-install-recommends unzip zip curl 2>&1
# Install sdkman (requires unzip, zip and curl)
ADD https://get.sdkman.io /tmp/get-sdkman.sh
RUN echo "# Installing sdkman..." \
    && export SDKMAN_DIR=/opt/sdkman \
    && /bin/bash -i /tmp/get-sdkman.sh \
    && rm /tmp/get-sdkman.sh \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/sdkman \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/sdkman \
    #
    # Disable sdkman auto-update prompt
    && sed -i 's/sdkman_selfupdate_enable=true/sdkman_selfupdate_enable=false/g' /opt/sdkman/etc/config \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/sdkman \
    #
    # Configure sdkman for the non-root user
    && echo "# Configuring sdkman for '${USER_NAME}'..." \
    && printf "\nexport SDKMAN_DIR=/opt/sdkman\n. /opt/sdkman/bin/sdkman-init.sh\n" >> /home/${USER_NAME}/.bashrc

# Install nvm dependencies
RUN echo "# Installing nvm dependencies..." \
    && apt-get -y install --no-install-recommends curl 2>&1
# Node Version Manager version to install (https://github.com/nvm-sh/nvm/releases)
ARG NVM_VERSION=v0.39.1
# Install nvm (requires curl)
ADD https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh /tmp/nvm.sh
RUN echo "# Installing nvm..." \
    && mkdir -p /opt/nvm \
    && export NVM_DIR=/opt/nvm \
    && /bin/bash -i /tmp/nvm.sh --no-use \
    && rm /tmp/nvm.sh \
    # Create nvm cache directory so it is owned by the group
    && mkdir -p /opt/nvm/.cache \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/nvm \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/nvm \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/nvm \
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
RUN echo "# Installing gvm dependencies..." \
    && apt-get -y install --no-install-recommends git binutils bison gcc make curl build-essential 2>&1
# Install Go Version Manager (requires git, binutils, bison, gcc, make and curl; go requires build-essential)
ADD https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer /tmp/gvm-installer.sh
RUN echo "# Installing gvm..." \
    && /bin/bash -i /tmp/gvm-installer.sh master /opt \
    && rm /tmp/gvm-installer.sh \
    # Create gvm pkgsets directory so it is owned by the group
    && mkdir -p /opt/gvm/pkgsets \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/gvm \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/gvm \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/gvm \
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

# Install rvm dependencies
RUN echo "# Installing rvm dependencies..." \
    && apt-get -y install --no-install-recommends curl patch gawk g++ gcc autoconf automake bison libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev make patch pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev git 2>&1
# Ruby < 2.4 is not compatible with openssl 1.1, so, you need libssl1.0-dev
# For installing an old ruby version run:
# rvm pkg install openssl
# rvm install 2.3.1 --with-openssl-dir=$rvm_path/usr --autolibs=disable
# RVM version to install (https://github.com/rvm/rvm/releases)
ARG RVM_VERSION=1.29.12
# Install Ruby Version Manager
ADD https://github.com/rvm/rvm/archive/refs/tags/${RVM_VERSION}.tar.gz /tmp/rvm-${RVM_VERSION}.tar.gz
RUN echo "# Installing rvm..." \
    #
    # Install rvm
    && tar xzf /tmp/rvm-${RVM_VERSION}.tar.gz -C /tmp \
    && cd /tmp/rvm-${RVM_VERSION} \
    && ./install --path /opt/rvm \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/rvm \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/rvm \
    #
    # Give write and exec acces so any member of group can use it
    && chmod -R g+wX /opt/rvm \
    #
    # Cleanup
    && rm /tmp/rvm-${RVM_VERSION}.tar.gz \
    && rm -rf rvm-${RVM_VERSION} \
    #
    # Configure rvm for the non-root user
    && echo "# Configuring rvm for '${USER_NAME}'..." \
    && printf "\nPATH=\$PATH:/opt/rvm/bin\n. /opt/rvm/scripts/rvm\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Add rvm bash completion
    #&& ln -s /opt/rvm/scripts/completion /usr/share/bash-completion/completions/rvm
    # avobe not working as $rvm_path is set by /opt/rvm/scripts/rvm
    && echo "# Configuring rvm autocomplete for '${USER_NAME}'..." \
    && printf "\n. /opt/rvm/scripts/completion\n" >> /home/${USER_NAME}/.bashrc

# Install dotnet-install dependencies
RUN echo "# Installing dotnet-install dependencies..." \
    && apt-get -y install --no-install-recommends curl libicu-dev 2>&1
# .Net installer version (https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install)
ARG DOTNET_INSTALLER_VERSION=v1
# Use this path for shared installation
ENV DOTNET_ROOT=/opt/dotnet
# Opt out .NET SDK telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
# Install .Net installer (requires curl; dotnet requires libicu-dev)
ADD https://dot.net/v1/dotnet-install.sh /usr/local/bin/dotnet-install.sh
RUN echo "# Installing dotnet-install..." \
    && chmod a+rx /usr/local/bin/dotnet-install.sh \
    #
    # Setup .Net shared installation directory
    && mkdir -p ${DOTNET_ROOT} \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} ${DOTNET_ROOT} \
    #
    # Set the segid bit to the folder
    && chmod -R g+s ${DOTNET_ROOT} \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX ${DOTNET_ROOT} \
    #
    # Configure .Net for the non-root user
    && printf "\nPATH=\$PATH:\$DOTNET_ROOT\n" >> /home/${USER_NAME}/.bashrc
# Add dotnet bash completion
ADD https://github.com/dotnet/cli/raw/master/scripts/register-completions.bash /usr/share/bash-completion/completions/dotnet
RUN echo "# Installing dotnet autocomplete..." \
    #
    # Configure dotnet bash completion
    && chmod 644 /usr/share/bash-completion/completions/dotnet

# Install git-lfs
ADD https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh /tmp/git-lfs-repos.sh
RUN echo "# Installing git-lfs..." \ 
    #
    # Setup git-lfs repos
    && /bin/bash -i /tmp/git-lfs-repos.sh \
    && rm /tmp/git-lfs-repos.sh \
    #
    # Install git-lfs
    && apt-get -y install --no-install-recommends git-lfs 2>&1

# Install other usefull software and libraries
RUN echo "# Installing libxtst6, procps, lsb-release, openssh-client, p7zip-full, p7zip-rar, rar and unrar..." \ 
    && apt-get -y install --no-install-recommends libxtst6 procps lsb-release openssh-client p7zip-full p7zip-rar rar unrar 2>&1

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
