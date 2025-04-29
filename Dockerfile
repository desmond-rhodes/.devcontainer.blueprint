FROM debian:bookworm

ARG nonroot="devcontainer"
ARG tools=""

COPY cache-curl /usr/local/bin
COPY cache-elan /usr/local/bin

RUN \
	--mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/cache/curl,sharing=locked \
	--mount=type=cache,target=/var/cache/elan,sharing=locked \
	--mount=type=cache,target=/var/cache/micromamba,sharing=locked \
	--mount=type=cache,target=/var/cache/pip,sharing=locked \
bash <<-'RUNROOT'
	set -euxo pipefail
	rm -f /etc/apt/apt.conf.d/docker-clean
	chmod 777 /var/cache/curl /var/cache/elan /var/cache/micromamba /var/cache/pip
	apt-get update
	apt-get -y dist-upgrade
	apt-get -y autopurge
	apt-get -y install locales
	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
	locale-gen
	export LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
	apt-get -y install \
		build-essential \
		bzip2 \
		curl \
		git \
		graphviz \
		latexmk \
		libgraphviz-dev \
		texlive-bibtex-extra \
		texlive-xetex
	sed -i '/PS1.*\\\$/s/\\\$/\\n\0/' /etc/skel/.bashrc
	useradd "${nonroot}" -ms /bin/bash
	su "${nonroot}" <<-'RUNNONROOT'
		set -euxo pipefail
		cache-curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
		cache-curl https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -jxC ~ bin/micromamba
		mkdir -p ~/micromamba ~/.cache
		ln -s /var/cache/micromamba ~/micromamba/pkgs
		ln -s /var/cache/pip ~/.cache/pip
		bash -l <<-'EOF'
			set -euxo pipefail
			cache-elan `curl https://api.github.com/repos/leanprover/lean4/tags | grep 'name' | sed 's/.*"name": "\([^"]*\)".*/\1/' | grep -v 'rc' | sort -r | head -1`
			cache-elan `curl https://raw.githubusercontent.com/PatrickMassot/checkdecls/refs/heads/master/lean-toolchain | sed 's/.*://'`
			cache-elan `curl https://raw.githubusercontent.com/leanprover/doc-gen4/refs/heads/main/lean-toolchain | sed 's/.*://'`
			micromamba shell init -s bash -r ~/micromamba
			micromamba config append channels conda-forge
			micromamba config set channel_priority strict
			micromamba env create -y -n blueprint python
			micromamba run -n blueprint pip install leanblueprint
		EOF
		rm -f ~/micromamba/pkgs ~/.cache/pip
		printf '\nmicromamba activate blueprint\n' >> ~/.bashrc
	RUNNONROOT
	apt-get -y install ${tools}
RUNROOT

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
USER "${nonroot}"
