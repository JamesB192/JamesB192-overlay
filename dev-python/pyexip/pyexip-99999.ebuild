# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="EXI (Efficient XML Interchange) Python wrapper on EXIP"
HOMEPAGE="https://github.com/salarshad/pyexip/"
EGIT_REPO_URI="https://github.com/salarshad/pyexip.git"

PYTHON_COMPAT=( python2_7 )
DEPEND="dev-python/cython"

LICENSE="HPND"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
inherit git-r3 distutils-r1
