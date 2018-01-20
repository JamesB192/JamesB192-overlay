# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit golang-build
inherit systemd
inherit bash-completion-r1

#EGO_PN=github.com/snapcore/snapd
EGO_PN="../../"
#EGO_SRC=github.com/snapcore/snapd/...
#EGIT_COMMIT="181f66ac30bc3a2bfb8e83c809019c037d34d1f3"

DESCRIPTION="Service and tools for management of snap packages"
HOMEPAGE="http://snapcraft.io/"
# rather than reference the git commit, it is better to src_uri to the package version (if possible) for future compatibility and ease of reading
# non-standard versioning upstream makes package renaming (below) prudent
#https://github.com/snapcore/${PN}/archive/${PV}-novendor.tar.gz -> ${PF}-no-vendor.tar.gz
SRC_URI="https://github.com/snapcore/snapd/releases/download/${PV}/${PN}_${PV}.vendor.tar.xz -> ${PF}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

# mirrors are restricted for unofficial packages
RESTRICT="mirror"

RDEPEND="sys-apps/snap-confine
	sys-fs/squashfs-tools:*"
# Not sure if the runtime dependencies need to be duplicated in the build dependencies, but added them to be safe
DEPEND="${RDEPEND}
	dev-vcs/git
	dev-vcs/bzr"
# Original ebuild had blank list of IUSE, so line was removed

# TODO: package all the upstream dependencies
# TODO: ensure that used kernel supports xz compression for squashfs
# TODO: enable tests
# TODO: ship man page for snap
# TODO: use more of the gentoo golang packaging helpers
# TODO: put /var/lib/snpad/desktop on XDG_DATA_DIRS

src_compile() {
	# Create a writable GOROOT in order to avoid sandbox violations.
	cp -sR "$(go env GOROOT)" "${T}/goroot" || die
	rm -rf "${T}/goroot/src/${EGO_SRC}" || die
	rm -rf "${T}/goroot/pkg/$(go env GOOS)_$(go env GOARCH)/${EGO_SRC}" || die
	export GOROOT="${T}/goroot"
	# Exclude $(get_golibdir_gopath) from GOPATH, for bug 577908 which may
	# or may not manifest, depending on what libraries are installed.
	export GOPATH="${WORKDIR}/${P}"
	cd src/${EGO_PN} && ./get-deps.sh
	go install -v "${EGO_PN}/cmd/snapd" || die
	go install -v "${EGO_PN}/cmd/snap" || die
	# go install -v -work -x ${EGO_BUILD_FLAGS} "${EGO_PN}/cmd/snapd" || die
	make -C "${S}/src/github.com/snapcore/snapd/data/systemd/"
}

src_install() {
	# Install snap and snapd
	export GOPATH="${WORKDIR}/${P}"
	exeinto /usr/bin
	dobin "$GOPATH/bin/snap"
	exeinto /usr/lib/snapd/
	doexe "$GOPATH/bin/snapd"
	cd "src/${EGO_PN}" || die
	# Install systemd units
	sed  -e 's!/usr/lib/snapd/!/usr/libexec/snapd/!' -i "${S}/src/github.com/snapcore/snapd/data/systemd"/snapd.service
	sed -i -e 's/RandomizedDelaySec=/#RandomizedDelaySec=/' "${S}/src/github.com/snapcore/snapd/data/systemd"/*.timer
	systemd_dounit "${S}/src/github.com/snapcore/snapd/data/systemd"/*.{service,timer,socket}
	# Work around https://github.com/zyga/snapd-gentoo/issues/1
	# Put /snap/bin on PATH
	dodir /etc/profile.d/
	echo 'PATH=$PATH:/snap/bin' > "${D}/etc/profile.d/snapd.sh"
	dobashcomp "${S}/src/github.com/snapcore/snapd/data/completion/snap"
	insinto "/usr/libexec/snapd/"
#	doins "${S}/src/github.com/snapcore/snapd/data/info"
}

pkg_postinst() {
	systemctl enable snapd.socket
	systemctl enable snapd.refresh.timer
}

# added package post-removal instructions for tidying up added services
pkg_postrm() {
	systemctl disable snapd.service
	systemctl stop snapd.service
	systemctl disable snapd.socket
	systemctl disable snapd.refresh.timer
}
