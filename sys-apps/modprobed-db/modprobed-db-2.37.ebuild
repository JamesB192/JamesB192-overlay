# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI=4
inherit systemd

DESCRIPTION="Keeps track of EVERY kernel module that has ever been probed."
HOMEPAGE="https://wiki.archlinux.org/index.php/Modprobed_db"
SRC_URI="http://repo-ck.com/source/${PN}/${P}.tar.xz"
RESTRICT="mirror"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND="virtual/modutils"

src_install() {
	dobin common/${PN}
	dodoc INSTALL MIT
	doman doc/${PN}.8
	systemd_dounit init/modprobed-db.service init/modprobed-db.timer
	mkdir -pv "${D}/usr/share/zsh/site-functions/" "${D}/usr/share/modprobed-db/"
	cp -v common/zsh-completion "${D}/usr/share/zsh/site-functions/_${PN}"
	cp -v "common/modprobed-db.skel"  "${D}/usr/share/modprobed-db/"
}
