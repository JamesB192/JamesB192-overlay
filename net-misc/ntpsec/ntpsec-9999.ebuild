# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 python3_{6,7,8} )
PYTHON_REQ_USE='threads(+)'

inherit flag-o-matic python-r1 waf-utils systemd

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/NTPsec/ntpsec.git"
	BDEPEND=""
	KEYWORDS=""
else
	SRC_URI="ftp://ftp.ntpsec.org/pub/releases/${PN}-${PV}.tar.gz"
	RESTRICT="mirror"
	BDEPEND=""
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

NTPSEC_REFCLOCK=(
	oncore trimble truetime gpsd jjy generic spectracom
	shm pps hpgps zyfer arbiter nmea modem local
)

IUSE_NTPSEC_REFCLOCK=${NTPSEC_REFCLOCK[@]/#/+rclock-}

LICENSE="HPND MIT BSD-2 BSD CC-BY-SA-4.0"
SLOT="0"
IUSE="${IUSE_NTPSEC_REFCLOCK} debug doc early gdb samba seccomp smear" #ionice
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# net-misc/pps-tools oncore,pps
CDEPEND="${PYTHON_DEPS}
	${BDEPEND}
	sys-libs/libcap
	dev-python/psutil[${PYTHON_USEDEP}]
	dev-libs/openssl:*
	seccomp? ( sys-libs/libseccomp )
"
RDEPEND="${CDEPEND}
	!net-misc/ntp
	!net-misc/openntpd
	acct-group/ntp
	acct-user/ntp
"
DEPEND="${CDEPEND}
	app-text/asciidoc
	app-text/docbook-xsl-stylesheets
	sys-devel/bison
	rclock-oncore? ( net-misc/pps-tools )
	rclock-pps? ( net-misc/pps-tools )
"

WAF_BINARY="${S}/waf"

src_prepare() {
	default
	# Remove autostripping of binaries
	sed -i -e '/Strip binaries/d' wscript
	python_copy_sources
}

src_configure() {
	is-flagq -flto* && filter-flags -flto* -fuse-linker-plugin

	local string_127=""
	local CLOCKSTRING=""

	for refclock in ${NTPSEC_REFCLOCK[@]} ; do
		if use rclock-${refclock} ; then
			string_127+="$refclock,"
		fi
	done
	CLOCKSTRING="`echo ${string_127}|sed 's|,$||'`"
	local epoch="`date +%s`"

	local myconf=(
		--build-epoch="${epoch}"
		--refclock="${CLOCKSTRING}"
		$(use doc	&& echo "--enable-doc")
		$(use early	&& echo "--enable-early-droproot")
		$(use gdb	&& echo "--enable-debug-gdb")
		$(use samba	&& echo "--enable-mssntp")
		$(use seccomp	&& echo "--enable-seccomp")
		$(use smear	&& echo "--enable-leap-smear")
		$(use debug	&& echo "--enable-debug")
	)

	python_configure() {
		waf-utils_src_configure "${myconf[@]}"
	}
	python_foreach_impl run_in_build_dir python_configure
}

src_compile() {
	unset MAKEOPTS
	python_compile() {
		waf-utils_src_compile
	}
	python_foreach_impl run_in_build_dir python_compile
}

src_install() {
	python_install() {
		waf-utils_src_install
	}
	python_foreach_impl run_in_build_dir python_install

	# Install heat generating scripts
	dosbin "${S}"/contrib/ntpheat{,usb}

	# Install the openrc files
	newinitd "${FILESDIR}"/ntpd.rc-r2 ntp
	newconfd "${FILESDIR}"/ntpd.confd ntp

	# Install the systemd unit file
	systemd_newunit "${FILESDIR}"/ntpd.service ntpd.service
	for I in ntp-wait.service \
		ntplogtemp.{service,timer} \
		ntpviz-{dai,week}ly.{service,timer} ;do
		systemd_newunit "${S}-python${USE_PYTHON}/build/main/etc/${I}" "$I";
	done
	for I in ntploggps.{service,timer} ;do
		systemd_newunit "${S}-python${USE_PYTHON}/etc/${I}" "$I";
	done

	# Prepare a directory for the ntp.drift file
	mkdir -pv "${ED}"/var/lib/ntp
	chown ntp:ntp "${ED}"/var/lib/ntp
	chmod 770 "${ED}"/var/lib/ntp
	keepdir /var/lib/ntp

	# Install a log rotate script
	insinto /etc/logrotate.d
	doins "${S}"/etc/logrotate-config.ntpd

	# Install the configuration file and sample configuration
	insinto /etc
	doins "${FILESDIR}"/ntp.conf
	doins -r "${S}"/etc/ntp.d/
}
