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

if [[ ${PV} == *9999* ]]; then
#	inherit golang-vcs
#	EGO_PN="github.com/snapcore/${PN}"
	inherit git-r3
	EGIT_REPO_URI="https://github.com/snapcore/${PN}.git"
	EGIT_CHECKOUT_DIR="${S}/${PN}/src/github.com/${PN}/"
	S="${S}/${PN}"
	KEYWORDS="-*"
else
	SRC_URI="https://github.com/snapcore/${PN}/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"
	RESTRICT="mirror"
	KEYWORDS="~amd64"
fi

RDEPEND="!sys-apps/snap-confine
	sys-libs/libseccomp[static-libs]
	sys-apps/apparmor
	dev-libs/glib
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}
	>=dev-lang/go-1.9
	dev-python/docutils
	sys-fs/xfsprogs"

if [[ 9999 == *9999* ]]; then
	src_unpack() {
		debug-print-function $FUNCNAME "$@"

		mkdir -pv "${S}/src/github.com/${PN}/"
		if [[ ${PV} == *9999* ]]; then
			git-r3_src_unpack
			cd "${EGIT_CHECKOUT_DIR}"
			if ! which govendor >/dev/null;then
				export PATH="$PATH:${GOPATH%%:*}/bin"
				if ! which govendor >/dev/null;then
					einfo Installing govendor
					go get -u github.com/kardianos/govendor
				fi
			fi
			einfo Obtaining dependencies
			"${GOPATH}/bin/govendor" sync
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
		MY_V="$(git describe --dirty --always | sed -e 's/-/+git/;y/-/./' )"
	else
		MY_V="${PV}"
	fi
	cat <<EOF > "version_generated.go"
package cmd

func init() {
        Version = "$v"
}
EOF
	echo "${MY_V}" > "VERSION"
	echo "VERSION=${MY_V}" > "../data/info"

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
	VX="" # or "-v -x" for verbosity
	for I in snapctl snap-exec snap snapd snap-seccomp snap-update-ns; do
		einfo "go building: ${I}"
		go install $VX "github.com/snapcore/${PN}/cmd/${I}"
	done
	"${S}/bin/snap" help --man > "${C}/snap/snap.1"
	rst2man.py "${C}/snap-confine/"snap-confine.{rst,1}
	rst2man.py "${C}/snap-discard-ns/"snap-discard-ns.{rst,5}

	CV="" # or "-c -v" for chacks and verbosity
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

	domo "${S}/src/${MINE}/po/"*.mo

	exeopts -m6755
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