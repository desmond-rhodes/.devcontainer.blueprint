FROM debian:bookworm

RUN \
	apt-get update && \
	apt-get -y dist-upgrade && \
	apt-get -y autopurge && \
	apt-get -y install \
		build-essential \
		bzip2 \
		curl \
		git \
		graphviz \
		latexmk \
		locales \
		libgraphviz-dev \
		texlive-bibtex-extra \
		texlive-xetex \
	&& \
	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
	locale-gen && \
	useradd devcontainer --shell /bin/bash --create-home

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

USER devcontainer
WORKDIR /home/devcontainer

RUN \
	curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y && \
	.elan/bin/lake --version && \
	echo 'export PATH="$HOME/.elan/bin:$PATH"' >> ~/.bashrc && \
	curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba && \
	./bin/micromamba shell init -s bash -r ~/micromamba && \
	./bin/micromamba config append channels conda-forge && \
	./bin/micromamba config set channel_priority strict && \
	./bin/micromamba env create -y -n blueprint python && \
	./bin/micromamba run -n blueprint pip install leanblueprint && \
	echo 'micromamba activate blueprint' >> ~/.bashrc

COPY blueprint-new_input .
RUN \
	export PATH="$HOME/.elan/bin:$PATH" && \
	eval "$(./bin/micromamba shell hook -s posix)" && \
	lake new example && \
	mv blueprint-new_input example && \
	cd example && \
	micromamba run -n blueprint leanblueprint new < blueprint-new_input

USER root
RUN apt-get -y install \
	man \
	less \
	vim
USER devcontainer
