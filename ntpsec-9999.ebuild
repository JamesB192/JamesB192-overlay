# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
KEYWORDS="~amd64 ~x86"
inherit git-r3
EGIT_REPO_URI="https://gitlab.com/NTPsec/ntpsec.git"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils user systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

NTPSEC_REFCLOCK=(
	oncore trimble truetime gpsd jjy generic spectracom acts
	shm pps hpgps zyfer arbiter nmea neoclock jupiter dumbclock
	local magnavox)
IUSE_NTPSEC_REFCLOCK=${NTPSEC_REFCLOCK[@]/#/rclock_}

LICENSE="ntp"
SLOT="0"
IUSE="doc ntpviz ${IUSE_NTPSEC_REFCLOCK} ssl seccomp" #ionice

# net-misc/pps-tools oncore,pps,jupiter,magnavox
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
	rclock_jupiter? ( net-misc/pps-tools )
	rclock_magnavox? ( net-misc/pps-tools )
	rclock_oncore? ( net-misc/pps-tools )
	rclock_pps? ( net-misc/pps-tools )
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
		fi
	done
	CLOCKSTRING="`echo ${string_127}|sed 's|,$||'`"

	waf-utils_src_configure --nopyc --nopyo --refclock="${CLOCKSTRING}" \
		$(use	doc		&& echo "--enable-doc") \
		$(use	seccomp		&& echo "--enable-seccomp") \
		$(use	ssl		&& echo "--enable-crypto") \

}

src_install() {
	waf-utils_src_install
	mv -v "${ED}/usr/"{,share/}man
	if use ntpviz ; then
		dosbin	"${S}/contrib/cpu-temp-log" \
			"${S}/contrib/gps-log" \
			"${S}/contrib/smartctl-temp-log" \
			"${S}/contrib/temper-temp-log" \
			"${S}/contrib/zone-temp-log"
	fi
	dodoc "${S}/contrib/ntp.conf.basic.sample" "${S}/contrib/ntp.conf.log.sample"
	systemd_newunit "${S}/etc/ntpd.service" ntpd.service
	mkdir -pv "${ED}/etc/"{logrotate,ntpconf}.d
	cp -v "${S}/etc/logrotate-config.ntpd" "${ED}/etc/logrotate.d/ntpd"
	cp -Rv "${S}/etc/ntpconf.d/" "${ED}/etc/"
	mv -v "${ED}/etc/ntpconf.d/example.conf" "${ED}/etc/ntp.conf"
	sed "s|includefile |includefile ntpconf.d/|" -i "${ED}/etc/ntp.conf"
	newconfd "${S}"/etc/ntpd.confd ntpd
}
