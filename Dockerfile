FROM rubensa/ubuntu-tini-user
LABEL author="Ruben Suarez <rubensa@gmail.com>"

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
    && apt-get -y install --no-install-recommends build-essential procps lsb-release openssh-client git curl vim zip unzip p7zip-full p7zip-rar rar unrar 2>&1 \
    #
    # Setup git-lfs repo
    && curl -L https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    #
    # Install git-lfs
    && apt-get -y install --no-install-recommends git-lfs 2>&1 \
    #
    # Install conda
    && curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    # See https://github.com/ContinuumIO/anaconda-issues/issues/11148
    && mkdir ~/.conda \
    && /bin/bash -l miniconda.sh -b -p /opt/conda \
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
    && curl -s "https://get.sdkman.io" | /bin/bash \
    #
    # Assign group folder ownership
    && chgrp -R ${GROUP_NAME} /opt/sdkman  \
    #
    # Set the segid bit to the folder
    && chmod -R g+s /opt/sdkman  \
    #
    # Give write and exec acces so anyobody can use it
    && chmod -R ga+wX /opt/sdkman  \
    #
    # Configure sdkman for the non-root user
    && printf "\nexport SDKMAN_DIR=/opt/sdkman\n. /opt/sdkman/bin/sdkman-init.sh\n" >> /home/${USER_NAME}/.bashrc \
    #
    # Install nvm
    && mkdir -p /opt/nvm \
    && export NVM_DIR=/opt/nvm \
    && curl -o nvm.sh "https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh" \
    && /bin/bash -l nvm.sh --no-use \
    && rm nvm.sh \
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
