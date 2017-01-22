# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
SRC_URI="ftp://ftp.ntpsec.org/pub/releases/ntpsec-0.9.4.tar.gz"
RESTRICT="mirror"
KEYWORDS="~amd64 ~x86"
S="${WORKDIR}/ntpsec"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils user systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

NTPSEC_REFCLOCK=(
	oncore trimble truetime gpsd jjy generic spectracom acts
	shm pps hpgps zyfer arbiter nmea neoclock jupiter dumbclock
	local magnavox )
IUSE_NTPSEC_REFCLOCK=${NTPSEC_REFCLOCK[@]/#/rclock_}

LICENSE="ntp"
SLOT="0"
IUSE="doc ntpviz ${IUSE_NTPSEC_REFCLOCK} ssl seccomp" #ionice

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
	doc? ( app-text/asciidoc app-text/docbook-xsl-stylesheets )
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
	local string_127=""
	local rclocks="";
	local CLOCKSTRING=""
	for refclock in ${NTPSEC_REFCLOCK[@]} ; do
		if use  rclock_${refclock} ; then
			string_127+="$refclock,"
			CLOCKSTRING="`echo ${string_127}|sed 's|,$||'`"
		fi
	done

	elog "refclocks: ${CLOCKSTRING}"
	waf-utils_src_configure --nopyc --nopyo --refclock="${CLOCKSTRING}" \
		--prefix="${EPREFIX}/usr" \
		$(use	doc		&& echo "--enable-doc") \
		$(use	ssl		&& echo "--enable-crypto") \
		$(use	seccomp		&& echo "--enable-seccomp")
}

src_install() {
	waf-utils_src_install
	mv -v "${ED}/usr/"{,share/}man
	if use ntpviz ; then
		elog "ntpviz: placeholder"
	else
		dorm "${ED}/bin/ntpviz" "${ED}/share/man/man1/ntpviz.1.bz2"
	fi
	systemd_newunit "${FILESDIR}/ntpd.service" ntpd.service
}
