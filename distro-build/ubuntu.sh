dist_name="Ubuntu"

# Must contain current LTS version.
# After changing, update the DISTRO_NAME below.
dist_version="noble"

bootstrap_distribution() {
	sudo rm -f "${ROOTFS_DIR}"/ubuntu-"${dist_version}"-*.tar.xz

	for arch in arm64 armhf amd64; do
		sudo rm -rf "${WORKDIR}/ubuntu-${dist_version}-$(translate_arch "$arch")"
		sudo mmdebstrap \
			--architectures=${arch} \
			--variant=apt \
			--components="main,universe,multiverse" \
			--include="locales,passwd,software-properties-common" \
			--format=directory \
			"${dist_version}" \
			"${WORKDIR}/ubuntu-${dist_version}-$(translate_arch "$arch")"
		archive_rootfs "${ROOTFS_DIR}/ubuntu-${dist_version}-$(translate_arch "$arch")-pd-${CURRENT_VERSION}.tar.xz" \
			"ubuntu-${dist_version}-$(translate_arch "$arch")"
	done
	unset arch
}

write_plugin() {
	cat <<- EOF > "${PLUGIN_DIR}/ubuntu.sh"
	# This is a default distribution plug-in.
	# Do not modify this file as your changes will be overwritten on next update.
	# If you want customize installation, please make a copy.
	DISTRO_NAME="Ubuntu (24.04)"
	DISTRO_COMMENT="LTS release (${dist_version})."

	TARBALL_URL['aarch64']="${GIT_RELEASE_URL}/ubuntu-${dist_version}-aarch64-pd-${CURRENT_VERSION}.tar.xz"
	TARBALL_SHA256['aarch64']="$(sha256sum "${ROOTFS_DIR}/ubuntu-${dist_version}-aarch64-pd-${CURRENT_VERSION}.tar.xz" | awk '{ print $1}')"
	TARBALL_URL['arm']="${GIT_RELEASE_URL}/ubuntu-${dist_version}-arm-pd-${CURRENT_VERSION}.tar.xz"
	TARBALL_SHA256['arm']="$(sha256sum "${ROOTFS_DIR}/ubuntu-${dist_version}-arm-pd-${CURRENT_VERSION}.tar.xz" | awk '{ print $1}')"
	TARBALL_URL['x86_64']="${GIT_RELEASE_URL}/ubuntu-${dist_version}-x86_64-pd-${CURRENT_VERSION}.tar.xz"
	TARBALL_SHA256['x86_64']="$(sha256sum "${ROOTFS_DIR}/ubuntu-${dist_version}-x86_64-pd-${CURRENT_VERSION}.tar.xz" | awk '{ print $1}')"

	distro_setup() {
	${TAB}# Configure en_US.UTF-8 locale.
	${TAB}sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' ./etc/locale.gen
	${TAB}run_proot_cmd DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

	${TAB}# Configure Firefox PPA.
	${TAB}echo "Configuring PPA repository for Firefox..."
	${TAB}run_proot_cmd add-apt-repository --yes --no-update ppa:mozillateam/firefox-next || true
	${TAB}cat <<- CONFIG_EOF > ./etc/apt/preferences.d/pin-mozilla-ppa
	${TAB}Package: *
	${TAB}Pin: release o=LP-PPA-mozillateam-firefox-next
	${TAB}Pin-Priority: 9999
	${TAB}CONFIG_EOF

	${TAB}# Configure Thunderbird PPA.
	${TAB}echo "Configuring PPA repository for Thunderbird..."
	${TAB}run_proot_cmd add-apt-repository --yes --no-update ppa:mozillateam/thunderbird-next || true
	${TAB}cat <<- CONFIG_EOF > ./etc/apt/preferences.d/pin-thunderbird-ppa
	${TAB}Package: *
	${TAB}Pin: release o=LP-PPA-mozillateam-thunderbird-next
	${TAB}Pin-Priority: 9999
	${TAB}CONFIG_EOF
	}
	EOF
}
