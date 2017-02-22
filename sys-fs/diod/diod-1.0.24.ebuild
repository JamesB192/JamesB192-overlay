# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils autotools-utils

AUTOTOOLS_IN_SOURCE_BUILD=1

DESCRIPTION="Distributed I/O Daemon - a 9P file server"
HOMEPAGE="https://github.com/chaos/diod"
SRC_URI="https://github.com/chaos/diod/archive/1.0.24.tar.gz"
RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
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
	epatch_user
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
