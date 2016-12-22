# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
KEYWORDS="~amd64 ~x86"
SRC_URI="ftp://ftp.ntpsec.org/pub/releases/ntpsec-0.9.3.tar.bz2"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

LICENSE="ntp"
SLOT="0"
IUSE="ntpviz refclock ssl seccomp" #ionice

CDEPEND="
sys-libs/libcap
 dev-python/psutil 
ssl? ( dev-libs/openssl )
seccomp? ( sys-libs/libseccomp )
"
RDEPEND="${CDEPEND}
ntpviz? ( sci-visualization/gnuplot media-fonts/liberation-fonts )
"
DEPEND="${CDEPEND}
app-text/asciidoc
app-text/docbook-xsl-stylesheets
sys-devel/bison
"

src_prepare() {
	python_setup
	eapply_user
}

src_configure() {

	waf-utils_src_configure \
		--prefix="${EPREFIX}/usr" \
		$(use_enable ssl crypto) \
		$(use  refclock	&& echo "--refclock=all")
}

src_install() {
	waf-utils_src_install
	mv -v ${D}/usr/{,share/}man
}
