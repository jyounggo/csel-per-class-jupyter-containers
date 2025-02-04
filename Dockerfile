#
# You need to change the BASE_CONTAINER in the Makefile, not here
#
ARG BASE_CONTAINER=this/is-a-place-holder
FROM $BASE_CONTAINER
LABEL MAINTAINER="CSIT Admin<cscihelp@colorado.edu>"

#############################################################################
## CU specific
#############################################################################

USER root

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
	ubuntu-minimal ubuntu-standard \
	ca-certificates-java \
	emacs-nox \
	libgtest-dev cmake-curses-gui \
	net-tools \
	openssh-client gdb \
	build-essential libc6-dev-i386 man \
	valgrind gcc-multilib g++-multilib libgmp-dev\
	software-properties-common python3-software-properties curl gnupg \
	mysql-client apt-transport-https psmisc graphviz graphviz-dev vim nano ffmpeg \
	fonts-dejavu \
	gfortran \
	googletest libopencv-dev \
	clang lldb \
	rustc rust-gdb lldb python3-lldb && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove pluto proxy 
RUN mamba remove -y jupyter-pluto-proxy

# "jupyterlab-drawio jupyterlab-link-share" does not support jupyterlab 4.x
RUN    mamba install --yes nbgitpuller jupyterlab-git jupyterlab-latex jupyter-server-proxy \
              libiconv python-lsp-server flake8 autopep8 \
	      altair vega_datasets \
	      bokeh datashader holoviews \
              cppcheck \ 
              nodejs jupyter-archive \
              networkx pygraphviz pydot pyyaml openpyxl \
              && mamba clean --all -f -y && \
   	      fix-permissions "${CONDA_DIR}" && \
              fix-permissions "/home/${NB_USER}"


# FIX: Change the default websocket max size of jupserver server proxy
ENV JSP_VERSION=v4.4.0
ADD jsp_websocket2.patch /tmp/jsp_websocket.patch
RUN git -c advice.detachedHead=false clone --single-branch --depth=1 --recursive -b ${JSP_VERSION} \
	https://github.com/jupyterhub/jupyter-server-proxy.git /tmp/jupyter-server-proxy && patch -d /tmp/jupyter-server-proxy -p1 < /tmp/jsp_websocket.patch
RUN pip install --upgrade --no-deps --force-reinstall /tmp/jupyter-server-proxy && rm -rf /tmp/jupyter-server-proxy /tmp/jsp_websocket.patch


# Install code-server
RUN	cd /opt && \
	wget https://github.com/coder/code-server/releases/download/v4.95.3/code-server_4.95.3_amd64.deb && \
	dpkg -i ./code-server*.deb && \
	rm -f ./code-server*.deb

##
## gtest
##
RUN	cd /usr/src/gtest && \
	cmake CMakeLists.txt && \
	make && \
	cp lib/*.a /usr/lib

RUN	$CONDA_DIR/bin/pip  install --index-url https://test.pypi.org/simple/ \
	       --extra-index-url https://pypi.org/simple jupyter-codeserver-proxy==1.0b4

##
## Build jupyter lab extensions
##
#RUN	jupyter lab build --dev-build=False && jupyter lab clean

COPY	start-notebook.d /usr/local/bin/start-notebook.d

RUN	rm -rf /home/jovyan  && \
	mkdir /home/jovyan && \
	chown $NB_UID:$NB_GID /home/jovyan

USER	$NB_UID
