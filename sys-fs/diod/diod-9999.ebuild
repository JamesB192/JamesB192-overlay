# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit git-r3 eutils autotools-utils

AUTOTOOLS_IN_SOURCE_BUILD=1

DESCRIPTION="Distributed I/O Daemon - a 9P file server"
HOMEPAGE="https://github.com/chaos/diod"
EGIT_REPO_URI="https://github.com/chaos/diod.git"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="rdma tcmalloc luajit"

DEPEND="
	|| (
		virtual/lua
		>=dev-lang/lua-5.1:*
		>=dev-lang/luajit-2:*
	)
	sys-apps/tcp-wrappers
	virtual/libc
	sys-libs/libcap
	sys-libs/ncurses:*
	tcmalloc? ( dev-util/google-perftools )
"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}/git-01.patch"
	epatch "${FILESDIR}/git-02.patch"
#	epatch_user
	./autogen.sh
}

src_configure() {
	local myeconfargs=(
		$(use_enable rdma rdmatrans)
		--with-ncurses
		$(use_with tcmalloc)
		$(use luajit && echo --with-lua-suffix=jit-5.1)
	)
	autotools-utils_src_configure
}
