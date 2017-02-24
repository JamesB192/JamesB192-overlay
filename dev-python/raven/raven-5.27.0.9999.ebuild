# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="Raven is a client for Sentry"
HOMEPAGE="https://github.com/getsentry/raven-python"
EGIT_REPO_URI="https://github.com/getsentry/raven-python.git"

case "$PV" in
#https://github.com/getsentry/raven-python/commit/6ead8beb09d6d40b91be213580dd4d9d5bd72f37
#https://github.com/getsentry/raven-python/commit/c03fc27515f3370a185ccef17690a70204ea1d9d
#https://github.com/getsentry/raven-python/commit/00656eece4d44226788885d78574a272bfa6637a
#https://github.com/getsentry/raven-python/commit/a1f59164990b624dd895f0b60d3e342c9ba6060a
#https://github.com/getsentry/raven-python/commit/5274f5438ea9cacc9e15b07a7985698bb92146b1
#https://github.com/getsentry/raven-python/commit/92810f60f15e59d09e3a04e66d0b899f3cdf23fb

	"5.27.0.9999")	EGIT_COMMIT="833ffac3062abe23f3382e375b17f40030794673" ;;
esac
PYTHON_COMPAT=( python2_7 )

LICENSE="HPND"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
inherit git-2 distutils-r1
