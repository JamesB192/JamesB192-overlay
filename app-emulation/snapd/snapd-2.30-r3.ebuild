# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit systemd
inherit bash-completion-r1

#EGO_SRC=github.com/snapcore/snapd/...

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/snapcore/snapd/"
	EGIT_CLONE_TYPE="shallow"
	S="${WORKDIR}/${PN}"
else
	SRC_URI="https://github.com/snapcore/snapd/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${P}.tar.xz"
	RESTRICT="mirror"
fi

RDEPEND="!sys-apps/snap-confine
	sys-fs/squashfs-tools:*"
DEPEND="${RDEPEND}"

# Original ebuild had blank list of IUSE, so line was removed

# TODO: package all the upstream dependencies
# TODO: ensure that used kernel supports xz compression for squashfs
# TODO: enable tests
# TODO: ship man page for snap
# TODO: use more of the gentoo golang packaging helpers
# TODO: put /var/lib/snpad/desktop on XDG_DATA_DIRS

src_unpack() {
	debug-print-function $FUNCNAME "$@"

	mkdir -pv "${S}/src/github.com/${P}/"
	if [[ ${PV} == *9999* ]]; then
		_git-r3_env_setup
		git-r3_src_fetch
		git-r3_checkout
		mv -v "$P" "${S}/src/github.com/${PN}/"
	else
		if [ ${A} != "" ]; then
			cd "${S}/src/github.com/"
			tar -Jpxf "${PORTAGE_BUILDDIR}/distdir/${A}" || die
			mv -v "${P}" "${PN}"
		fi
	fi

	# try linkage
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

	cd "${S}/src/github.com/${PN}/cmd/"
	./autogen.sh || die
#	./configure --prefix="${ED}"
}

src_compile() {
	debug-print-function $FUNCNAME "$@"

	make -C "${S}/src/github.com/${PN}/data/" || die ### This works
	make -C "${S}/src/github.com/${PN}/cmd/"  || die ### This works

	export GOPATH="${S}/"
	go install -v -x "github.com/${PN}/cmd"/snapctl ||die
	go install -v -x "github.com/${PN}/cmd"/snap-exec ||die
	go install -v -x "github.com/${PN}/cmd"/snap ||die
	go install -v -x "github.com/${PN}/cmd"/snapd ||die
}

src_install() {
	debug-print-function $FUNCNAME "$@"

	cd "${S}/src/github.com/${PN}"
	dodir	/var/snap /var/{lib,cache}/snapd \
		/usr/share/{bash-completion,dbus-1,doc/snapd,man/man{1,5},polkit-1} \
		/snap /etc/{apparmor,profile}.d \
		/lib/udev/rules.d

	### The following is a misbegotten implementaton
	dodir "/opt/${PN}"
	(cd data&&tar -cpf - \
			./completion/etelpmoc.sh \
			./completion/complete.sh \
			./selinux/snappy.if \
			./selinux/snappy.te \
			./selinux/snappy.fc \
			./env/snapd.sh \
		)|(cd "${ED}/opt/${PN}"&&tar -xpvf -)

	dobin "${S}/src/github.com/${PN}/cmd"/decode-mount-opts/decode-mount-opts
	dobin "${S}/src/github.com/${PN}/cmd"/snap-confine/snap-confine
	dobin "${S}/src/github.com/${PN}/cmd"/snap-confine/snappy-app-dev
	dobin "${S}/src/github.com/${PN}/cmd"/snap-discard-ns/snap-discard-ns
	dobin "${S}/bin"/*

	cp data/dbus/io.snapcraft.Launcher.service "${ED}/usr/share/dbus-1/services/"
	cp data/udev/rules.d/66-snapd-autoimport.rules "${ED}/lib/udev/rules.d/"
	cp data/polkit/io.snapcraft.snapd.policy "${ED}/usr/share/polkit-1/actions/"

	dobashcomp data/completion/snap

	systemd_dounit data/systemd/*.{service,timer,socket}
	echo 'PATH=$PATH:/snap/bin' > "${ED}/etc/profile.d/snapd.sh"

#	# Install snap and snapd
#	export GOPATH="${WORKDIR}/${P}"
#	exeinto /usr/lib/snapd/
#	cd "src/${EGO_PN}" || die
#	# Install systemd units
#	sed  -e 's!/usr/lib/snapd/!/usr/libexec/snapd/!' -i "${S}/src/github.com/snapcore/snapd/data/systemd"/snapd.service
#	sed -i -e 's/RandomizedDelaySec=/#RandomizedDelaySec=/' "${S}/src/github.com/snapcore/snapd/data/systemd"/*.timer
#	# Work around https://github.com/zyga/snapd-gentoo/issues/1
#	# Put /snap/bin on PATH
#	dodir /etc/profile.d/
#	insinto "/usr/libexec/snapd/"
#	#doins "${S}/src/github.com/snapcore/snapd/data/info"
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
