# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
KEYWORDS="~amd64 ~x86"

inherit git-r3
EGIT_REPO_URI="https://gitlab.com/NTPsec/ntpsec.git"
EGIT_MIN_CLONE_TYPE="shallow"
EGIT_COMMIT="0516111ce405338d94f98cb9650402f068bf78a9"

PYTHON_COMPAT=( python2_7 python3_{4,5,6} )
PYTHON_REQ_USE='threads(+)'
inherit python-r1 waf-utils user systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

NTPSEC_REFCLOCK=(
		arbiter generic gpsd hpgps jjy local
		modem neoclock nmea oncore pps shm
		spectracom trimble truetime zyfer
	)
IUSE_NTPSEC_REFCLOCK=${NTPSEC_REFCLOCK[@]/#/rclock_}

#(BSD2 with BSD3 with ISC with NTP with MIT with CC-BY-4.0 with Beerware)
LICENSE="BSD-2 BSD ISC MIT CC-BY-4.0 BEER-WARE"
SLOT="0"
IUSE="debug doc early gdb nist ntpviz ${IUSE_NTPSEC_REFCLOCK} samba seccomp smear tests" #ionice

CDEPEND="
	sys-libs/libcap
	 dev-python/psutil
	dev-libs/openssl:*
	seccomp? ( sys-libs/libseccomp )
"
RDEPEND="${CDEPEND}
"

DEPEND="${CDEPEND}
	app-text/asciidoc
	app-text/docbook-xsl-stylesheets
	sys-devel/bison
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
	if use samba; then
		elog "[samba] These services involve a TCP connection to another process that could"
		elog "[samba] potentially block, denying services to other users. Therefore, this flag"
		elog "[samba] shoud be used only for a dedicated server with no clients other than MS-SNTP"
	fi
	if use seccomp; then
		elog "[seccomp] System call sandboxing may cause ntpsec to fail on some"
		elog "[seccomp] systems where seccomp is not implemented / supported."
	fi
	if use smear; then
		elog "[smear] This is an experimental option. DO NOT USE THIS OPTION ON PUBLIC-ACCESS SERVERS!"
	fi

	local string_127=""
	local rclocks="";
	local CLOCKSTRING=""
	for refclock in ${NTPSEC_REFCLOCK[@]} ; do
		if use  rclock_${refclock} ; then
			string_127+="$refclock,"
		fi
	done
	CLOCKSTRING="`echo ${string_127}|sed 's|,$||'`"
	waf-utils_src_configure --refclock="${CLOCKSTRING}" \
		$(use	doc		&& echo "--enable-doc --docdir=/usr/share/doc/${PN}-${PVR}" ) \
		$(use	early		&& echo "--enable-early-droproot") \
		$(use	gdb		&& echo "--enable-debug-gdb") \
		$(use	nist		&& echo "--enable-lockclock") \
		$(use	samba		&& echo "--enable-mssntp") \
		$(use	seccomp		&& echo "--enable-seccomp") \
		$(use	smear		&& echo "--enable-leap-smear") \
		$(use	tests		&& echo "--alltests") \
		$(use	debug		&& echo "--enable-debug")
}

src_install() {
	waf-utils_src_install
	if use ntpviz; then
		elog "[ntpviz] Please have sci-visualization/gnuplot and media-fonts/liberation-fonts installed"
		elog "[ntpviz] these are not needed but provide graphs and prettier fonts for the graphs."
		for I in ntplog{gps,temp} ntpviz-{dai,week}ly; do
			systemd_newunit "${S}/etc/${I}.service" "${I}.service"
			systemd_newunit "${S}/etc/${I}.timer"   "${I}.timer"
		done
	else
		rm -v "${ED}usr/bin/"ntp{viz,log{gps,temp}}
		rm -v "${ED}usr/share/man/man1/"ntp{loggps,logtemp,viz}.1
		rm -v "${ED}usr/share/doc/${PV}-${PV}/"ntp{loggps,viz}.html
	fi
	dosbin	"${S}/contrib/ntpheat"{,usb}
	dodoc	"${S}/contrib/logrotate-ntpd"
	systemd_newunit "${FILESDIR}/ntpd.service" ntpd.service
	newinitd "${FILESDIR}/ntpd.rc-r1" "ntp"
	newconfd "${FILESDIR}/ntpd.confd" "ntp"

	mkdir -p "${ED}etc/"{logrotate,ntp}.d
	cp "${S}/etc/logrotate-config.ntpd" "${ED}etc/logrotate.d/ntpd"
	cp -R "${S}/etc/ntp.d/" "${ED}etc/"
	mv "${ED}etc/ntp.d/default.conf" "${ED}etc/ntp.conf"
	sed "s|includefile |includefile ntp-conf.d/|" -i "${ED}etc/ntp.conf"

}
