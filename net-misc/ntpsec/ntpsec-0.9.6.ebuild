# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=6
KEYWORDS="~amd64 ~x86"
if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/NTPsec/ntpsec.git"
	BDEPEND="dev-libs/libsodium"
else
	SRC_URI="ftp://ftp.ntpsec.org/pub/releases/${PN}-${PV}.tar.gz"
	RESTRICT="mirror"
	BDEPEND=""
fi

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils user systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

NTPSEC_REFCLOCK=(
	oncore trimble truetime gpsd jjy generic spectracom modem
	shm pps hpgps zyfer arbiter nmea neoclock jupiter dumbclock
	local magnavox)
IUSE_NTPSEC_REFCLOCK=${NTPSEC_REFCLOCK[@]/#/rclock_}

LICENSE="HPND MIT BSD-2 BSD CC-BY-SA-4.0"
SLOT="0"
IUSE="debug doc early gdb nist ntpviz ${IUSE_NTPSEC_REFCLOCK} samba seccomp smear ssl tests" #ionice

# net-misc/pps-tools oncore,pps,jupiter,magnavox
CDEPEND="
	${BDEPEND}
	sys-libs/libcap
	 dev-python/psutil
	ssl? ( dev-libs/openssl:* )
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
		$(use	early		&& echo "--enable-early-droproot") \
		$(use	gdb		&& echo "--enable-debug-gdb") \
		$(use	nist		&& echo "--enable-lockclock") \
		$(use	samba		&& echo "--enable-mssntp") \
		$(use	seccomp		&& echo "--enable-seccomp") \
		$(use	smear		&& echo "--enable-leap-smear") \
		$(use	ssl		&& echo "--enable-crypto") \
		$(use	tests		&& echo "--alltests") \
		$(use_enable debug debug)
}

src_install() {
	waf-utils_src_install
	mv -v "${ED}/usr/"{,share/}man
	if use ntpviz ; then
		dosbin	"${S}/contrib/cpu-temp-log" \
			"${S}/contrib/smartctl-temp-log" \
			"${S}/contrib/temper-temp-log" \
			"${S}/contrib/zone-temp-log"
		if [[ ${PV} == *0.9.6* ]]; then
			dosbin "${S}/contrib/gps-log"
		fi
	fi
	systemd_newunit "${FILESDIR}/ntpd.service" ntpd.service
	newinitd "${FILESDIR}/ntpd.rc-r1" "ntp"
	newconfd "${FILESDIR}/ntpd.confd" "ntp"
	mkdir "${ED}/etc/systemd/system/"
	cp -v "${FILESDIR}/ntpd.service" "${ED}/etc/systemd/system/"
	# ntpd.confd  ntpd.rc-r1  ntpd.service

	dodoc "${S}/contrib/ntp.conf.basic.sample" "${S}/contrib/ntp.conf.log.sample"
	mkdir -pv "${ED}/etc/"{logrotate,ntp-conf}.d
	cp -v "${S}/etc/logrotate-config.ntpd" "${ED}/etc/logrotate.d/ntpd"
	cp -Rv "${S}/etc/ntp-conf.d/" "${ED}/etc/"
	mv -v "${ED}/etc/ntp-conf.d/example.conf" "${ED}/etc/ntp.conf"
	sed "s|includefile |includefile ntp-conf.d/|" -i "${ED}/etc/ntp.conf"
}
