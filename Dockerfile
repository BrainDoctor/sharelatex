FROM sharelatex/sharelatex:latest

RUN     tlmgr update --self && \
	tlmgr option docfiles 0 && \
	tlmgr install scheme-full && \
	rm /usr/local/texlive/2016/texmf-var/web2c/tlmgr.log

VOLUME /var/lib/sharelatex