
# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python2_7 python3_{8..12} )
inherit python-single-r1

DESCRIPTION="pytogo is a fast, crude, incomplete Python-to-Go translator"
HOMEPAGE="http://catb.org/~esr/pytogo/"
if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/esr/pytogo.git/"
	KEYWORDS=""
else
	SRC_URI="http://www.catb.org/~esr/${PN}/${P}.tar.gz"
	RESTRICT="primaryuri"
	KEYWORDS="~arm64"
fi

LICENSE="BSD-2"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	dev-lang/python
	${PYTHON_DEPS}
"
DEPEND="app-text/asciidoc"

DOCS="README.md"

src_compile() {
	make pytogo.html pytogo.1 check
}

src_install() {
	dobin pytogo
	doman pytogo.1
	dodoc BUGS.adoc NEWS.adoc pytogo.html
}
