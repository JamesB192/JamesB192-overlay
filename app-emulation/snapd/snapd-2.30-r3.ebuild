# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit bash-completion-r1 systemd

#EGO_SRC=github.com/snapcore/snapd/...

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
LICENSE="GPL-3"
SLOT="0"
IUSE=""

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/snapcore/snapd/"
	EGIT_CLONE_TYPE="shallow"
	EGIT_CHECKOUT_DIR="${S}/src/github.com/${PN}/"
	S="${S}/${PN}"
	KEYWORDS="-amd64"
else
	SRC_URI="https://github.com/snapcore/snapd/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"
	RESTRICT="mirror"
	KEYWORDS="~amd64"
fi

RDEPEND="!sys-apps/snap-confine
	sys-libs/libseccomp[static-libs]
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}
	sys-fs/xfsprogs
	>=dev-lang/go-1.8"

# Original ebuild had blank list of IUSE, so line was removed

# TODO: package all the upstream dependencies
# TODO: ensure that used kernel supports xz compression for squashfs
# TODO: enable tests
# TODO: ship man page for snap
# TODO: use more of the gentoo golang packaging helpers
# TODO: put /var/lib/snpad/desktop on XDG_DATA_DIRS

fry() {
	eerror "something died"
	chmod g+rX "${WORKDIR}"
	die
}

src_unpack() {
	debug-print-function $FUNCNAME "$@"

	mkdir -pv "${S}/src/github.com/${PN}/"
	if [[ ${PV} == *9999* ]]; then
		git-r3_src_unpack
#		mv -v "$P" "${S}/src/github.com/${PN}/"
	else
		if [ ${A} != "" ]; then
			unpack ${A}
#mv: target '/var/tmp/portage/app-emulation/snapd-2.30-r3/work/snapd-2.30/src/github.com/snapd' is not a directory
			mv -v "${S}"/* "${S}/src/github.com/${PN}"
		fi
	fi

	ln -sv . "${S}/src/github.com"/snapcore
}

src_prepare () {
	debug-print-function $FUNCNAME "$@"

	eapply_user
	if [[ ${PV} != *9999* ]]; then
		sed "/mkversion.sh/s|.$|${PV} \)|" -i \
			"${S}/src/github.com/${PN}/cmd/autogen.sh"
	fi
}

src_configure() {
	debug-print-function $FUNCNAME "$@"

#	        /src/github.com/snapd/cmd
	cd "${S}/src/github.com/${PN}/cmd/"
	pwd
	./autogen.sh || fry

#	set -eux
#	( cd .. && ./mkversion.sh 2.30)
##	test -f configure.ac	# Sanity check, are we in the right directory?
##	rm -f config.status	# Regenerate the build system
#	autoreconf -i -f
#	econf --enable-maintainer-mode
##	econf --enable-maintainer-mode --prefix=/usr
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
#	go install -v -x "github.com/${PN}/cmd"/snap-repair ||fry ### Broken in upstream? and only in Core
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
	dodir	/var/snap /var/{lib,cache}/snapd \
		/usr/share/{bash-completion,dbus-1,doc/snapd,man/man{1,5},polkit-1} \
		/snap /etc/{apparmor,profile}.d \
		/lib/udev/rules.d \
		/usr/lib/snapd \
		/usr/share/dbus-1/services \
		/usr/share/polkit-1/actions \
		/var/lib/snapd/apparmor/snap-confine.d \
		/var/lib/snapd/auto-import \
		/var/lib/snapd/desktop \
		/var/lib/snapd/environment \
		/var/lib/snapd/firstboot \
		/var/lib/snapd/lib/gl \
		/var/lib/snapd/snaps/partial \
		/var/lib/snapd/void \
		"/opt/${PN}"

	exeinto "/usr/lib/${PN}"
	doexe \
			data/completion/etelpmoc.sh \
			data/completion/complete.sh
	insinto "/opt/${PN}"
	doins \
			data/selinux/snappy.if \
			data/selinux/snappy.te \
			data/selinux/snappy.fc
	doexe "${S}/src/github.com/${PN}/cmd"/decode-mount-opts/decode-mount-opts
	doexe "${S}/src/github.com/${PN}/cmd"/snap-confine/snap-confine
	mv -v "${S}/src/github.com/${PN}/cmd"/snap-confine/snappy-app-dev "${ED}/lib/udev"
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
		"${DS}/snapd.refresh.service"	"${DS}/snapd.service" \
		"${DS}/snapd.refresh.timer"	"${DS}/snapd.socket"

### only on Ubuntu core
#	systemd_dounit data/systemd/*.{service,timer,socket}
#snapd.autoimport.service	snapd.core-fixup.service	snapd.snap-repair.service	snapd.system-shutdown.service
#								snapd.snap-repair.timer
#	mv -v "${S}/bin"/snap-repair "${ED}/usr/lib/snapd/" ### broken in upstream?
#	cp data/udev/rules.d/66-snapd-autoimport.rules "${ED}/lib/udev/rules.d/"
#	cp src/github.com/snapd/data/systemd/snapd.core-fixup.sh "${ED}/usr/lib/snapd/"
#	ln "${ED}/usr/bin/ubuntu-core-launcher" ../lib/snapd/snap-confine

### this is from the previous package
#	echo 'PATH=$PATH:/snap/bin' > "${ED}/etc/profile.d/snapd.sh"
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
