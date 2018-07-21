# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit bash-completion-r1 linux-info systemd

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
LICENSE="GPL-3"
SLOT="0"
IUSE=""
CONFIG_CHECK="CGROUPS CGROUP_DEVICE CGROUP_FREEZER NAMESPACES SQUASHFS SQUASHFS_ZLIB SQUASHFS_LZO SQUASHFS_XZ BLK_DEV_LOOP SECCOMP SECCOMP_FILTER"
#ERROR_CGROUPS="Need CONFIG_CGROUPS in kernel config"
#ERROR_CGROUP_DEVICE="Need CONFIG_CGROUP_DEVICE in kernel config"
#ERROR_CGROUP_FREEZER="Need CONFIG_CGROUP_FREEZER in kernel config"
#ERROR_NAMESPACES="Need CONFIG_NAMESPACES in kernel config"
#ERROR_SQUASHFS="Need CONFIG_SQUASHFS in kernel config"
#ERROR_SQUASHFS_ZLIB="Need CONFIG_SQUASHFS_ZLIB in kernel config"
#ERROR_SQUASHFS_LZO="Need CONFIG_SQUASHFS_LZO in kernel config"
#ERROR_SQUASHFS_XZ="Need CONFIG_SQUASHFS_XZ in kernel config"
#ERROR_BLK_DEV_LOOP="Need CONFIG_BLK_DEV_LOOP in kernel config"
#ERROR_SECCOMP="Need CONFIG_SECCOMP in kernel config"
#ERROR_SECCOMP_FILTER="Need CONFIG_SECCOMP_FILTER in kernel config"

export GOPATH="${S}/${PN}"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/snapcore/snapd.git"
#	EGIT_CLONE_TYPE="shallow"
#	EVCS_OFFLINE="yes"
	EGIT_CHECKOUT_DIR="${S}/${PN}/src/github.com/${PN}/"
	S="${S}/${PN}"
	KEYWORDS=""
else
	SRC_URI="https://github.com/snapcore/snapd/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"
	RESTRICT="mirror"
	KEYWORDS="~amd64"
fi

RDEPEND="!sys-apps/snap-confine
	sys-libs/libseccomp[static-libs]
	sys-apps/apparmor
	dev-libs/glib
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}
	dev-python/docutils
	sys-fs/xfsprogs
	>=dev-lang/go-1.8"

# TODO: ensure that used kernel supports xz compression for squashfs
# TODO: enable tests
# TODO: use more of the gentoo golang packaging helpers
# TODO: put /var/lib/snpad/desktop on XDG_DATA_DIRS

fry() {
	eerror "Died in ${FUNCNAME}: making ebuild home directory group readable and descendable."
	chmod g+rX "${HOMEDIR}"
	die
}

src_unpack() {
	debug-print-function $FUNCNAME "$@"

	mkdir -pv "${S}/src/github.com/${PN}/"
	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
		cd "${EGIT_CHECKOUT_DIR}"
		if ! which govendor >/dev/null;then
			export PATH="$PATH:${GOPATH%%:*}/bin"
			if ! which govendor >/dev/null;then
				echo Installing govendor
				go get -u github.com/kardianos/govendor ||fry
			fi
		fi
		echo Obtaining dependencies
		"${GOPATH}/bin/govendor" sync ||fry
	else
		if [ ${A} != "" ]; then
			unpack ${A}
			mv "${S}"/* "${S}/src/github.com/${PN}"
		fi
	fi

	ln -sv . "${S}/src/github.com"/snapcore

	grep "^CONFIG_SQUASHFS_XZ=y" /boot/config-`uname -r` || zgrep "^CONFIG_SQUASHFS_XZ=y" /proc/config.gz || \
		elog "please ensure your kernel supports xz compression for squashfs"

	grep "CONFIG_OVERLAY_FS=" /boot/config-`uname -r` || zgrep "CONFIG_OVERLAY_FS=" /proc/config.gz || \
		elog "please ensure your kernel supports overlay filesystem"
}

src_configure() {
	debug-print-function $FUNCNAME "$@"

	cd "${S}/src/github.com/${PN}/cmd/"
	pwd
	if [[ ${PV} == *9999* ]]; then
		( cd .. && ./mkversion.sh)
	else
		( cd .. && ./mkversion.sh "${PV}")
	fi
	test -f configure.ac	# Sanity check, are we in the right directory?
	rm -f config.status
	autoreconf -i -f	# Regenerate the build system
	econf --enable-maintainer-mode --disable-silent-rules
}

src_compile() {
	debug-print-function $FUNCNAME "$@"

	emake -C "${S}/src/github.com/${PN}/data/" || fry
	emake -C "${S}/src/github.com/${PN}/cmd/"  || fry

	export GOPATH="${S}/"
	go install -v -x "github.com/${PN}/cmd"/snapctl ||fry
	go install -v -x "github.com/${PN}/cmd"/snap-exec ||fry
	go install -v -x "github.com/${PN}/cmd"/snap ||fry
	"${S}/bin/snap" help --man > "${S}/src/github.com/${PN}/cmd/snap/snap.1" || fry
	go install -v -x "github.com/${PN}/cmd"/snapd ||fry
	go install -v -x "github.com/${PN}/cmd"/snap-seccomp ||fry
	go install -v -x "github.com/${PN}/cmd"/snap-update-ns ||fry
}

src_install() {
	debug-print-function $FUNCNAME "$@"

	C="${S}/src/github.com/${PN}/cmd"
	doman \
		"${C}/snap-confine/snap-confine.1" \
		"${C}/snap/snap.1" \
		"${C}/snap-discard-ns/snap-discard-ns.5"

	cd "${S}/src/github.com/${PN}"
	dodir	\
		/etc/{apparmor,profile}.d \
		/usr/share/{bash-completion,doc/snapd,man/man{1,5}} \
		/snap \
		/lib/udev/rules.d \
		/usr/lib/snapd \
		/usr/share/dbus-1/services \
		/usr/share/polkit-1/actions \
		/var/cache/snapd \
		/var/lib/snapd/apparmor/snap-confine.d \
		/var/lib/snapd/auto-import \
		/var/lib/snapd/desktop \
		/var/lib/snapd/environment \
		/var/lib/snapd/firstboot \
		/var/lib/snapd/lib/gl \
		/var/lib/snapd/snaps/partial \
		/var/lib/snapd/void \
		/var/snap

	exeinto "/usr/lib/${PN}"
	doexe \
			data/completion/etelpmoc.sh \
			data/completion/complete.sh
	insinto "/usr/share/selinux/targeted/include/snapd/"
	doins \
			data/selinux/snappy.if \
			data/selinux/snappy.te \
			data/selinux/snappy.fc
	doexe "${S}/src/github.com/${PN}/cmd"/decode-mount-opts/decode-mount-opts
	doexe "${S}/src/github.com/${PN}/cmd"/snap-confine/snap-confine
#	mv -v "${S}/src/github.com/${PN}/cmd"/snap-confine/snappy-app-dev "${ED}/lib/udev"
	doexe "${S}/src/github.com/${PN}/cmd"/snap-discard-ns/snap-discard-ns

	mv -v data/dbus/io.snapcraft.Launcher.service "${ED}/usr/share/dbus-1/services/"
	mv -v data/polkit/io.snapcraft.snapd.policy "${ED}/usr/share/polkit-1/actions/"
	doexe "${S}/bin"/snapd
	doexe "${S}/bin"/snap-exec
	doexe "${S}/bin"/snap-update-ns
	doexe "${S}/bin"/snap-seccomp ### missing libseccomp

	mv -v "${S}/src/github.com/snapd/data/info" "${ED}/usr/lib/snapd/"
	mv -v data/env/snapd.sh "${ED}/etc/profile.d/"
	dodoc	"${S}/src/github.com/snapd/packaging/ubuntu-14.04"/copyright \
		"${S}/src/github.com/snapd/packaging/ubuntu-16.04"/changelog

	dobin "${S}/bin"/{snap,snapctl}

	dobashcomp data/completion/snap

	DS="${S}/src/github.com/${PN}/data/systemd"
	systemd_dounit \
		"${DS}/snapd.service"		"${DS}/snapd.socket"
#		"${DS}/snapd.refresh.service"	"${DS}/snapd.refresh.timer"

}

pkg_postinst() {
	debug-print-function $FUNCNAME "$@"

	systemctl enable snapd.socket
	systemctl enable snapd.refresh.timer
}

## added package post-removal instructions for tidying up added services
pkg_postrm() {
debug-print-function $FUNCNAME "$@"

	systemctl disable snapd.service
	systemctl stop snapd.service
	systemctl disable snapd.socket
	systemctl disable snapd.refresh.timer
}
