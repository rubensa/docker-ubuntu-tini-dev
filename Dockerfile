FROM rubensa/ubuntu-tini-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

# Node Version Manager version to install (https://github.com/nvm-sh/nvm/releases)
ARG NVM_VERSION=v0.39.0

# Miniconda Version to install (https://repo.anaconda.com/miniconda/)
ARG MINICONDA_VERSION=py39_4.9.2

# .Net installer version (https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install)
ARG DOTNET_INSTALLER_VERSION=v1
# Use this path for shared installation
ENV DOTNET_ROOT=/opt/dotnet
# Opt out .NET SDK telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true

# Tell docker that all future commands should be run as root
USER root

# Set root home directory
ENV HOME=/root

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    # 
    # Install software and needed libraries
    && apt-get -y install --no-install-recommends build-essential libxtst6 procps lsb-release openssh-client bash-completion git vim zip unzip p7zip-full p7zip-rar rar unrar bison libicu-dev 2>&1 \
    #
    # Setup git-lfs repo
    && curl -sSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    #
    # Install git-lfs
    && apt-get -y install --no-install-recommends git-lfs 2>&1 \
    #
    # Install conda
    && curl -o miniconda.sh -sSL https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh \
    # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
    && mkdir ~/.conda \
    && /bin/bash -i miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/conda \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/conda \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/conda \
    #
    # Configure conda for the non-root user
    && printf "\n. /opt/conda/etc/profile.d/conda.sh\n" >> /home/${USER_NAME}/.bashrc \
    # Use shared folder for packages and environments
    && printf "envs_dirs:\n  - /opt/conda/envs\npkgs_dirs:\n   - /opt/conda/pkgs\n" >> /home/${USER_NAME}/.condarc \
    && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.condarc \
    # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
    && mkdir /home/${USER_NAME}/.conda \
    && chown ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME}/.conda \
    #
    # Install sdkman
    && export SDKMAN_DIR=/opt/sdkman \
    && curl -sSL "https://get.sdkman.io" | /bin/bash \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/sdkman \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/sdkman \
    #
    # Hack: create file so right permissions are applied
    && touch /opt/sdkman/var/delay_upgrade \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/sdkman \
    #
    # Configure sdkman for the non-root user
    && printf "\nexport SDKMAN_DIR=/opt/sdkman\n. /opt/sdkman/bin/sdkman-init.sh\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Install nvm
    && mkdir -p /opt/nvm \
    && export NVM_DIR=/opt/nvm \
    && curl -o nvm.sh -sSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
    && /bin/bash -i nvm.sh --no-use \
    && rm nvm.sh \
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
    && printf "\n. /opt/nvm/nvm.sh\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Add nvm bash completion
    #&& ln -s /opt/nvm/bash_completion /etc/bash_completion.d/nvm \
    # avobe not working as /etc/bash_completion.d/nvm is run before nvm.sh
    # so no nvm command available and the bash_completion scripts checks it
    && printf "\n. /opt/nvm/bash_completion\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Install gvm
    && curl -o gvm-installer -sSL "https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer" \
    && /bin/bash -i gvm-installer master /opt \
    && rm gvm-installer \
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
    && printf "\n. /opt/gvm/scripts/gvm\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Add gvm bash completion
    && ln -s /opt/gvm/scripts/completion /etc/bash_completion.d/gvm \
    #
    # Setup .Net installer
    && curl -o /usr/local/bin/dotnet-install.sh -sSL https://dot.net/v1/dotnet-install.sh \
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
    && printf "\nPATH=\$PATH:\$DOTNET_ROOT" >> /home/${USER_NAME}/.bashrc \
    #
    # Configure dotnet bash completion
    && curl -o /etc/bash_completion.d/dotnet -sSL "https://github.com/dotnet/cli/raw/master/scripts/register-completions.bash" \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=

# Tell docker that all future commands should be run as the non-root user
USER ${USER_NAME}

# Set user home directory (see: https://github.com/microsoft/vscode-remote-release/issues/852)
ENV HOME /home/$USER_NAME
