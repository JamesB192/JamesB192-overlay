# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit toolchain-funcs

MY_PV="${PV//_alpha/a}"
MY_PV="${MY_PV//_beta/b}"
MY_PV="${MY_PV//_rc/rc}"
MY_PV="${MY_PV//_p/-P}"
MY_P="${PN}-${MY_PV}"
DESCRIPTION="High-performance production grade DHCPv4 & DHCPv6 server"
HOMEPAGE="http://www.isc.org/kea/"
if [[ ${PV} = 9999* ]] ; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://github.com/isc-projects/kea.git"
else
	SRC_URI="ftp://ftp.isc.org/isc/kea/${MY_P}.tar.gz
		ftp://ftp.isc.org/isc/kea/${MY_PV}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="ISC BSD SSLeay GPL-2" # GPL-2 only for init script
SLOT="0"
IUSE="mysql openssl postgres samples"

DEPEND="
	dev-libs/boost:=
	dev-cpp/gtest
	dev-libs/log4cplus
	!openssl? ( dev-libs/botan:0= )
	openssl? ( dev-libs/openssl:= )
	mysql? ( virtual/mysql )
	postgres? ( dev-db/postgresql:* )
"
RDEPEND="${DEPEND}
	acct-group/dhcp
	acct-user/dhcp
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	default
	[[ ${PV} = *9999 ]] && eautoreconf
	# Brand the version with Gentoo
	sed -i \
		-e "/VERSION=/s:'$: Gentoo-${PR}':" \
		configure || die
}

src_configure() {
	local myeconfargs=(
		$(use_with openssl)
		$(use_with mysql)
		$(use_with postgres pgsql)
		$(use_enable samples install-configurations)
		--disable-static
		--without-werror
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	newconfd "${FILESDIR}"/${PN}-confd ${PN}
	newinitd "${FILESDIR}"/${PN}-initd ${PN}
	find "${ED}" \( -name "*.a" -o -name "*.la" \) -delete || die
}
