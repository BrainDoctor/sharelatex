# braindoctor/sharelatex
This is based on the official sharelatex image. However, I required some modifications to the installation and needed a portable image for use in a cluster (which means a read-only image).

This 4 GB-ish image contains the following:
* sharelatex, git clone from 2016-07-30
* Texlive scheme-full, but without docs
* Optimizations of the Dockerfile to reduce image layers (apt-get clean etc.)
* Spell check contains just en, de, de-alt and fr.


I mainly did this for myself, but feel free to use
