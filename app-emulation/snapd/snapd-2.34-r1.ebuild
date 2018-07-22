# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit bash-completion-r1 linux-info systemd
inherit golang-base

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
LICENSE="GPL-3"
SLOT="0"
IUSE=""
MINE="github.com/snapcore/${PN}"
CONFIG_CHECK="CGROUPS CGROUP_DEVICE CGROUP_FREEZER NAMESPACES SQUASHFS SQUASHFS_ZLIB SQUASHFS_LZO SQUASHFS_XZ BLK_DEV_LOOP SECCOMP SECCOMP_FILTER"

export GOPATH="${S}/${PN}"

if [[ ${PV} == *9999* ]]; then
	inherit golang-vcs
	EGO_PN="github.com/snapcore/${PN}"
	S="${S}/${PN}"
	KEYWORDS=""
else
	inherit golang-vcs-snapshot
	EGO_PN="github.com/snapcore/${PN}"
	SRC_URI="https://github.com/snapcore/${PN}/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz
		${EGO_VENDOR_URI}"
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
	sys-fs/xfsprogs"

fry() {
	eerror "Died in ${FUNCNAME}: making ebuild home directory group readable and descendable."
	chmod g+rX "${HOMEDIR}"
	die
}

if [[ "a" == "b" ]]; then
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
	}
fi

src_configure() {
	debug-print-function $FUNCNAME "$@"

	cd "${S}/src/${MINE}/cmd/"
	pwd
	if [[ ${PV} == *9999* ]]; then
		( cd .. && ./mkversion.sh || fry)
	else
		( cd .. && ./mkversion.sh "${PV}" || fry)
	fi
	test -f configure.ac || fry	# Sanity check, are we in the right directory?
	rm -f config.status || fry
	autoreconf -i -f || fry	# Regenerate the build system
	econf --enable-maintainer-mode --disable-silent-rules || fry
}

src_compile() {
	debug-print-function $FUNCNAME "$@"

	C="${S}/src/${MINE}/cmd/"
	emake -C "${S}/src/${MINE}/data/" || fry
	emake -C "${C}"  || fry

	export GOPATH="${S}/"
	VX="" # or "-v -x" for verbosity
	for I in snapctl snap-exec snap snapd snap-seccomp snap-update-ns; do
		einfo "go building: ${I}"
		go install $VX "github.com/snapcore/${PN}/cmd/${I}" ||fry
	done
	"${S}/bin/snap" help --man > "${C}/snap/snap.1" || fry
#	rst2man.py "${C}/snap-confine/"snap-confine.{rst,1}
#	rst2man.py "${C}/snap-discard-ns/"snap-discard-ns.{rst,5}
}

src_install() {
	debug-print-function $FUNCNAME "$@"

	C="${S}/src/${MINE}/cmd"
	DS="${S}/src/${MINE}/data/systemd"

	doman \
		"${C}/snap-confine/snap-confine.1" \
		"${C}/snap/snap.1" \
		"${C}/snap-discard-ns/snap-discard-ns.5"

	systemd_dounit \
		"${DS}/snapd.service"		"${DS}/snapd.socket"

	cd "${S}/src/${MINE}"
	dodir  \
		"/etc/profile.d" \
		"/usr/lib/snapd" \
		"/usr/share/dbus-1/services" \
		"/usr/share/polkit-1/actions"

	exeinto "/usr/lib/${PN}"
	doexe \
			data/completion/etelpmoc.sh \
			data/completion/complete.sh
	insinto "/usr/share/selinux/targeted/include/snapd/"
	doins \
			data/selinux/snappy.if \
			data/selinux/snappy.te \
			data/selinux/snappy.fc
	doexe "${C}"/decode-mount-opts/decode-mount-opts
	doexe "${C}"/snap-confine/snap-confine
#	mv -v "${C}"/snap-confine/snappy-app-dev "${ED}/lib/udev"
	doexe "${C}"/snap-discard-ns/snap-discard-ns

	mv -v data/dbus/io.snapcraft.Launcher.service "${ED}/usr/share/dbus-1/services/"
	mv -v data/polkit/io.snapcraft.snapd.policy "${ED}/usr/share/polkit-1/actions/"
	doexe "${S}/bin"/snapd
	doexe "${S}/bin"/snap-exec
	doexe "${S}/bin"/snap-update-ns
	doexe "${S}/bin"/snap-seccomp ### missing libseccomp

	mv -v "${S}/src/${MINE}/data/info" "${ED}/usr/lib/snapd/"
	mv -v data/env/snapd.sh "${ED}/etc/profile.d/"
	dodoc	"${S}/src/${MINE}/packaging/ubuntu-14.04"/copyright \
		"${S}/src/${MINE}/packaging/ubuntu-16.04"/changelog

	dobin "${S}/bin"/{snap,snapctl}

	dobashcomp data/completion/snap

}

pkg_postinst() {
	debug-print-function $FUNCNAME "$@"

	systemctl enable snapd.socket
}

## added package post-removal instructions for tidying up added services
pkg_postrm() {
	debug-print-function $FUNCNAME "$@"

	systemctl disable snapd.service
	systemctl stop snapd.service
	systemctl disable snapd.socket
}
