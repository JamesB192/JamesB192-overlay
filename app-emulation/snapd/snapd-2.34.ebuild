# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit bash-completion-r1 linux-info systemd

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
SRC_URI="https://github.com/snapcore/${PN}/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
IUSE=""
KEYWORDS="~amd64"
RESTRICT="primaryuri"

RDEPEND="!sys-apps/snap-confine
	sys-libs/libseccomp[static-libs]
	sys-apps/apparmor
	dev-libs/glib
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}
	>=dev-lang/go-1.9
	dev-python/docutils
	sys-fs/xfsprogs"

MY_S="${S}/src/github.com/snapcore/${PN}"
PKG_LINGUAS="am bs ca cs da de el en_GB es fi fr gl hr ia id it ja lt ms nb oc pt_BR pt ru sv tr ug zh_CN"

CONFIG_CHECK="	CGROUPS \
		CGROUP_DEVICE \
		CGROUP_FREEZER \
		NAMESPACES \
		SQUASHFS \
		SQUASHFS_ZLIB \
		SQUASHFS_LZO \
		SQUASHFS_XZ \
		BLK_DEV_LOOP \
		SECCOMP \
		SECCOMP_FILTER"

export GOPATH="${S}/${PN}"

src_unpack() {
	debug-print-function $FUNCNAME "$@"

	mkdir -pv "${S}/src/github.com/${PN}/"
	if [ ${A} != "" ]; then
		unpack ${A}
		mv "${S}"/* "${S}/src/github.com/${PN}"
	fi
	ln -sv . "${S}/src/github.com"/snapcore
}

src_configure() {
	debug-print-function $FUNCNAME "$@"

	cd "${S}/src/${MINE}/cmd/"
	pwd
	cat <<EOF > "version_generated.go"
package cmd

func init() {
        Version = "${PV}"
}
EOF
	echo "${PV}" > "VERSION"
	echo "VERSION=${PV}" > "../data/info"

	test -f configure.ac	# Sanity check, are we in the right directory?
	rm -f config.status
	autoreconf -i -f	# Regenerate the build system
	econf --enable-maintainer-mode --disable-silent-rules
}

src_compile() {
	debug-print-function $FUNCNAME "$@"

	C="${S}/src/${MINE}/cmd/"
	emake -C "${S}/src/${MINE}/data/"
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

	CV="-v" # or "-c -v" for checks and verbosity
	for I in ${PKG_LINGUAS};do
		einfo -n "building mo: ${I}"
		msgfmt ${CV} --output-file="${S}/src/${MINE}/po/${I}.mo" "${S}/src/${MINE}/po/${I}.po"
	done
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
	doexe "${C}"/snap-discard-ns/snap-discard-ns

	insinto "/usr/share/dbus-1/services/"
	doins data/dbus/io.snapcraft.Launcher.service
	insinto "/usr/share/polkit-1/actions/"
	doins data/polkit/io.snapcraft.snapd.policy
	doexe "${S}/bin"/snapd
	doexe "${S}/bin"/snap-exec
	doexe "${S}/bin"/snap-update-ns
	doexe "${S}/bin"/snap-seccomp ### missing libseccomp

	insinto "/usr/lib/snapd/"
	doins "${S}/src/${MINE}/data/info"
	insinto "/etc/profile.d/"
	doins data/env/snapd.sh "${ED}/etc/profile.d/"
	dodoc	"${S}/src/${MINE}/packaging/ubuntu-14.04"/copyright \
		"${S}/src/${MINE}/packaging/ubuntu-16.04"/changelog

	dobin "${S}/bin"/{snap,snapctl}

	dobashcomp data/completion/snap

	domo "${S}/src/${MINE}/po/"*.mo

	exeopts -m6755
	doexe "${C}"/snap-confine/snap-confine
}

pkg_postrm() {
	debug-print-function $FUNCNAME "$@"

	systemctl disable snapd.service
	systemctl stop snapd.service
	systemctl disable snapd.socket
}
