FROM debian:bookworm

ARG workspaceFolder="/workspaces"
ARG nonroot="devcontainer"

ARG __file__cache_curl="cache-curl"
ARG __file__cache_elan="cache-elan"
ARG __file__cache_micromamba="cache-micromamba"
ARG __file__cache_pip="cache-pip"

COPY "${__file__cache_curl}" "/usr/local/bin/cache-curl"
COPY "${__file__cache_elan}" "/usr/local/bin/cache-elan"
COPY "${__file__cache_micromamba}" "/usr/local/bin/cache-micromamba"
COPY "${__file__cache_pip}" "/usr/local/bin/cache-pip"

ARG __file__setup_root="setup-root"
ARG __file__setup_nonroot="setup-nonroot"
ARG __file__setup_config="setup-config"

COPY "${__file__setup_root}" "setup-root"
COPY "${__file__setup_nonroot}" "setup-nonroot"
COPY "${__file__setup_config}" "setup-config"

RUN \
	--mount=type=cache,target="/var/cache/apt",sharing=locked \
	--mount=type=cache,target="/var/tmp",sharing=locked \
bash <<-'EOF'
	set -euxo pipefail

	rm -f '/etc/apt/apt.conf.d/docker-clean'
	chmod 777 '/var/tmp'

	apt-get update
	apt-get -y dist-upgrade
	apt-get -y autopurge
	apt-get -y install locales
	sed -i '/en_US.UTF-8/s/^# //g' '/etc/locale.gen'
	locale-gen

	export LANG='en_US.UTF-8'
	export LANGUAGE='en_US:en'
	export LC_ALL='en_US.UTF-8'

	mkdir -p "${workspaceFolder}"
	chmod 777 "${workspaceFolder}"

	'./setup-root'

	sed -i '/PS1.*\\\$/s/\\\$/\\n\0/' '/etc/skel/.bashrc'
	useradd "${nonroot}" -ms '/bin/bash'

	su "${nonroot}" 'setup-nonroot'

	'./setup-config'

	rm -f 'setup-root'
	rm -f 'setup-nonroot'
	rm -f 'setup-config'

	rm -f '/usr/local/bin/cache-curl'
	rm -f '/usr/local/bin/cache-elan'
	rm -f '/usr/local/bin/cache-micromamba'
	rm -f '/usr/local/bin/cache-pip'
EOF

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

USER "${nonroot}"
