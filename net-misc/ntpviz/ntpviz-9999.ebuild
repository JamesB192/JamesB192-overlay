# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
KEYWORDS="~amd64 ~x86"
if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/NTPsec/ntpsec.git"
	BDEPEND=""
else
	SRC_URI="ftp://ftp.ntpsec.org/pub/releases/${PN}-${PV}.tar.gz"
	RESTRICT="mirror"
	BDEPEND=""
fi

inherit systemd

DESCRIPTION="The NTP reference implementation, refactored"
HOMEPAGE="https://www.ntpsec.org/"

LICENSE="MIT BSD-2 BSD CC-BY-SA-4.0"
SLOT="0"
IUSE=""

CDEPEND="
	${BDEPEND}
"
RDEPEND="${CDEPEND}
	!net-misc/ntpsec[-ntpviz]
"

DEPEND="${CDEPEND}
	app-text/asciidoc
	app-text/docbook-xsl-stylesheets
"

src_install() {
	elog "Please have sci-visualization/gnuplot and media-fonts/liberation-fonts installed"
	elog "these are not needed but provide graphs and prettier fonts for the graphs."

	for I in ntplog{gps,temp} ntpviz-{dai,week}ly; do
		systemd_newunit "${S}/etc/${I}.service" "${I}.service"
		systemd_newunit "${S}/etc/${I}.timer"   "${I}.timer"
	done
	doman "${S}/ntpclients/"ntp{loggps,logtemp,viz}.1
	dodoc "${S}/docs/asciidoc."{css,js} "${S}/docs/"ntp{loggps,viz}.html
	insinto "/usr/share/doc/${PN}-${PV}/pic"
	doins "${S}/docs/"pic/{pogocell,dogsnake}.gif
	newbin "${S}/ntpclients/ntploggps.py" ntploggps
	newbin "${S}/ntpclients/ntplogtemp.py" ntplogtemp
	newbin "${S}/ntpclients/ntpviz.py" ntpviz

}

src_compile() {
	for I in ntp{loggps,viz}; do
		/usr/bin/a2x -f manpage -a=--conf-file="${S}/docs/asciidoc.conf" "${S}/ntpclients/${I}-man.txt"
		/usr/bin/asciidoc -b html5 -a linkcss -f "${S}/docs/asciidoc.conf" -o "${S}/docs/${I}.html" "${S}/docs/${I}.txt"
	done
	/usr/bin/a2x -f manpage -a=--conf-file="${S}/docs/asciidoc.conf" "${S}/ntpclients/ntplogtemp-man.txt"
}
