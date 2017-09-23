FROM sharelatex/sharelatex:latest

RUN     tlmgr update --self && \
	tlmgr option docfiles 0 && \
	tlmgr install scheme-full && \
	rm /usr/local/texlive/*/texmf-var/web2c/tlmgr.log

VOLUME /var/lib/sharelatex