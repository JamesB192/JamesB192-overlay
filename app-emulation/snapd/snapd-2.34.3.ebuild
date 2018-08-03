# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit bash-completion-r1 linux-info systemd

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
LICENSE="GPL-3"
SLOT="0"
IUSE=""
MY_S="${S}/src/github.com/snapcore/${PN}"
PKG_LINGUAS="am bs ca cs da de el en_GB es fi fr gl hr ia id it ja lt ms nb oc pt_BR pt ru sv tr ug zh_CN"

CONFIG_CHECK="CGROUPS CGROUP_DEVICE CGROUP_FREEZER NAMESPACES SQUASHFS SQUASHFS_ZLIB SQUASHFS_LZO SQUASHFS_XZ BLK_DEV_LOOP SECCOMP SECCOMP_FILTER"

export GOPATH="${S}/${PN}"

inherit golang-base golang-vcs-snapshot
EGO_PN="github.com/snapcore/${PN}"
SRC_URI="https://github.com/snapcore/${PN}/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"
RESTRICT="mirror"
KEYWORDS="~amd64"

RDEPEND="!sys-apps/snap-confine
	sys-libs/libseccomp[static-libs]
	sys-apps/apparmor
	dev-libs/glib
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}
	>=dev-lang/go-1.9
	dev-python/docutils
	sys-devel/gettext
	sys-fs/xfsprogs"

src_configure() {
	debug-print-function $FUNCNAME "$@"

	cd "${MY_S}/cmd/"
	cat <<EOF > "${MY_S}/cmd/version_generated.go"
package cmd

func init() {
        Version = "$PV"
}
EOF
	echo "${PV}" > "${MY_S}/cmd/VERSION"
	echo "VERSION=${PV}" > "${MY_S}/data/info"

	test -f configure.ac	# Sanity check, are we in the right directory?
	rm -f config.status
	autoreconf -i -f	# Regenerate the build system
	econf --enable-maintainer-mode --disable-silent-rules
}

src_compile() {
	debug-print-function $FUNCNAME "$@"

	C="${MY_S}/cmd/"
	emake -C "${MY_S}/data/"
	emake -C "${C}"

	export GOPATH="${S}/"
	VX="-v -x" # or "-v -x" for verbosity
	for I in snapctl snap-exec snap snapd snap-seccomp snap-update-ns; do
		einfo "go building: ${I}"
		go install $VX "github.com/snapcore/${PN}/cmd/${I}"
	done
	"${S}/bin/snap" help --man > "${C}/snap/snap.1"
	rst2man.py "${C}/snap-confine/"snap-confine.{rst,1}
	rst2man.py "${C}/snap-discard-ns/"snap-discard-ns.{rst,5}

	for I in ${PKG_LINGUAS};do
		einfo "mo building: ${I}"
		msgfmt -v --output-file="${MY_S}/po/${I}.mo" "${MY_S}/po/${I}.po"
	done
}

src_install() {
	debug-print-function $FUNCNAME "$@"

	C="${MY_S}/cmd"
	DS="${MY_S}/data/systemd"

	doman \
		"${C}/snap-confine/snap-confine.1" \
		"${C}/snap/snap.1" \
		"${C}/snap-discard-ns/snap-discard-ns.5"

	systemd_dounit \
		"${DS}/snapd.service"		"${DS}/snapd.socket"

	cd "${MY_S}"
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
#	mv -v "${C}"/snap-confine/snappy-app-dev "${ED}/lib/udev"
	doexe "${C}"/snap-discard-ns/snap-discard-ns

	mv -v data/dbus/io.snapcraft.Launcher.service "${ED}/usr/share/dbus-1/services/"
	mv -v data/polkit/io.snapcraft.snapd.policy "${ED}/usr/share/polkit-1/actions/"
	doexe "${S}/bin"/snapd
	doexe "${S}/bin"/snap-exec
	doexe "${S}/bin"/snap-update-ns
	doexe "${S}/bin"/snap-seccomp ### missing libseccomp

	mv -v "${MY_S}/data/info" "${ED}/usr/lib/snapd/"
	mv -v data/env/snapd.sh "${ED}/etc/profile.d/"
	dodoc	"${MY_S}/packaging/ubuntu-14.04"/copyright \
		"${MY_S}/packaging/ubuntu-16.04"/changelog

	dobin "${S}/bin"/{snap,snapctl}

	dobashcomp data/completion/snap

	domo "${MY_S}/po"/*.mo

	exeopts -m 6755
	doexe "${C}"/snap-confine/snap-confine
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
