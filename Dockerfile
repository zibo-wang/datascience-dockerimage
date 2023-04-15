FROM ubuntu:22.04

LABEL maintainer="Zibo Wang <zibo.w@outlook.com>"

USER root

ARG USERNAME=data-scientist
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install Ubuntu packages
RUN apt-get update && \
    apt-get install -y wget fonts-liberation pandoc run-one sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME
WORKDIR /home/${USERNAME}

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh -O ~/mamba.sh && \
    sudo chown $USERNAME:$USERNAME /opt && \
    sudo chown $USERNAME:$USERNAME /home/${USERNAME} && \
    bash ~/mamba.sh -b -p /opt/conda && \
    rm ~/mamba.sh && \
    /opt/conda/bin/mamba init

ENV NVM_DIR /home/${USERNAME}/.nvm
# Install Node.js
RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    export NVM_DIR="/home/${USERNAME}/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm use default && \
    npm install -g @jupyter-widgets/jupyterlab-manager

# Update environment variable
ENV PATH="${PATH}:/opt/conda/bin"
# Copy environment.yml into the container
COPY environment.yml .
# Create Conda environment based on environment.yml
RUN mamba env update -n base -f environment.yml && \
    mamba clean -afy

SHELL ["/bin/bash", "-euo", "pipefail", "-c", "source /home/${USERNAME}/.bashrc"]

RUN jupyter notebook --generate-config && \
    mamba clean -afy && \
    jupyter lab build && \
    jupyter labextension enable @jupyter-widgets/jupyterlab-manager && \
    jupyter lab clean

# Expose Jupyter Lab on port 8888
EXPOSE 8888
ENV USERNAME=${USERNAME}
# Start Jupyter Lab on container startup
CMD ["/bin/bash", "-c", "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser"]

