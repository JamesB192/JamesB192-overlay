# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

DESCRIPTION="a FUSE file system that fully integrates with git"
HOMEPAGE="https://www.presslabs.com/gitfs/"
#SRC_URI"https://github.com/PressLabs/gitfs/archive/0.4.5.1.tar.gz"

RESTRICT="mirror"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

EGIT_REPO_URI="https://github.com/PressLabs/gitfs.git"
EGIT_COMMIT="2e9595290e7bf8954f5fc6834293de8d2a7cadb5"

REALNAME="gitfs"
REALVERSION="0.3.1"
REPO_URI="http://pypi.python.org/packages/source/${REALNAME:0:1}/${REALNAME}/"
SOURCEFILE="${REALNAME}-${REALVERSION}.tar.gz"
PYTHON_COMPAT=( python2_7 python3_{4,5,6} )

DESCRIPTION="Version controlled file system."
HOMEPAGE="http://www.presslabs.com/gitfs/"

inherit git-r3 distutils-r1
