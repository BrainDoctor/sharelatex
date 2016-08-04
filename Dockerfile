FROM sharelatex/sharelatex

RUN tlmgr option docfiles 0 && \
    tlmgr install scheme-full && \
	rm /usr/local/texlive/2016/texmf-var/web2c/tlmgr.log

EXPOSE 80
VOLUME /var/lib/sharelatex
WORKDIR /

ENTRYPOINT ["/sbin/my_init"]
