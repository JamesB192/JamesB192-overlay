# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
KEYWORDS="-amd64 -x86"
SRC_URI="ftp://ftp.ntpsec.org/pub/releases/ntpsec-0.9.5-1.tar.gz"
S="${WORKDIR}/ntpsec-0.9.5-1"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils user systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

LICENSE="ntp"
SLOT="0"
IUSE="doc ntpviz refclock ssl seccomp" #ionice

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

pkg_setup() {
	enewgroup ntp 123
	enewuser ntp 123 -1 /dev/null ntp
}

src_configure() {
	waf-utils_src_configure --nopyc --nopyo \
		--prefix="${EPREFIX}/usr" \
		$(use	doc		&& echo "--enable-doc") \
		$(use	ssl		&& echo "--enable-crypto") \
		$(use	seccomp		&& echo "--enable-seccomp") \
		$(use	refclock	&& echo "--refclock=all")
}

src_install() {
	waf-utils_src_install
	mv -v "${ED}/usr/"{,share/}man
	if use ntpviz ; then
		dosbin	"${S}/contrib/cpu-temp-log" \
			"${S}/contrib/gps-log" \
			"${S}/contrib/smartctl-temp-log" \
			"${S}/contrib/temper-temp-log" \
			"${S}/contrib/pi-temp-log"
	else
		dorm "${ED}/bin/ntpviz" "${ED}/share/man/man1/ntpviz.1.bz2"
	fi
	dosbin "${S}/attic/ntpdate"
	systemd_newunit "${FILESDIR}/ntpd.service" ntpd.service
}

