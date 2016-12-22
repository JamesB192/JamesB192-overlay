# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
SRC_URI="ftp://ftp.ntpsec.org/pub/releases/ntpsec-0.9.5.tar.gz"
KEYWORDS="-amd64 -x86"
S="${WORKDIR}"


PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

LICENSE="ntp"
SLOT="0"
IUSE="ntpviz refclock ssl seccomp" #ionice

RDEPEND="
sys-libs/libcap
 dev-python/psutil 
ntpviz? ( sci-visualization/gnuplot media-fonts/liberation-fonts )
ssl? ( dev-libs/openssl )
seccomp? ( sys-libs/libseccomp )
"

DEPEND="${RDEPEND}
app-text/asciidoc
app-text/docbook-xsl-stylesheets
sys-devel/bison
"

src_prepare() {
	python_setup
	eapply_user
}

src_configure() {
	local group_127=()

#		$(use  ssl	&& echo "--enable-crypto") \ ## Replaced
	waf-utils_src_configure --nopyc --nopyo \
		--prefix="${EPREFIX}/usr" \
		$(use_enable ssl crypto) \
		$(use_enable seccomp seccomp) \
		$(use  refclock	&& echo "--refclock=all") \
		--mandir=/usr/share/man/
}

src_install() {
	waf-utils_src_install
	mv -v ${D}/usr/{,share/}man
}
