# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit cmake-multilib
DESCRIPTION="An RFC5297-compliant C implementation of AES-SIV"
HOMEPAGE="https://github.com/dfoxfranke/libaes_siv"
EGIT_REPO_URI="https://github.com/dfoxfranke/libaes_siv.git"

CMAKE_MAKEFILE_GENERATOR="emake"
if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	KEYWORDS="~amd64"
else
	KEYWORDS="~amd64"
	RESTRICT="primaryuri"
	SRC_URI="https://github.com/dfoxfranke/libaes_siv/archive/v${PV}.tar.gz"
	S="${WORKDIR}/lib${P}"
	PATCHES=(
		"${FILESDIR/}/${P}-include.patch"
	)

#	EGIT_COMMIT="v${PV}"
fi

LICENSE="Apache-2.0" ## double check that
SLOT="git"
IUSE="+test"

DEPEND="app-text/asciidoc
>=dev-libs/openssl-1.0.1:0
"

# Run-time dependencies. Must be defined to whatever this depends on to run.
# The below is valid if the same run-time depends are required to compile.
RDEPEND="${DEPEND}"

src_install() {
	doman "${S/}"/*.3
	doheader "${S/}/${PN}.h"
	dodoc "${S/}"/{CO,R}*

	multilib-minimal_abi_src_install() {
		debug-print-function ${FUNCNAME} "$@"

		pushd "${BUILD_DIR}" >/dev/null || die
		dolib.a "${BUILD_DIR}"/*.a
		dolib.so "${BUILD_DIR}"/*.so*

		multilib_prepare_wrappers
		multilib_check_headers
		popd >/dev/null || die
	}
	multilib_foreach_abi multilib-minimal_abi_src_install
}

src_test() {
	emake test
}
