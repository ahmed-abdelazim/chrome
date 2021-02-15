FROM python:3.7-stretch

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>"

ENV VNC_SCREEN_SIZE 1024x768
# Define custom function directory
ARG FUNCTION_DIR="/var/task"

# Install aws-lambda-cpp build dependencies

RUN apt-get update && \
  apt-get install -y \
  g++ \
  make \
  cmake \
  unzip \
  libcurl4-openssl-dev

RUN pip install \
    --target ${FUNCTION_DIR} \
        awslambdaric

RUN pip install --target ${FUNCTION_DIR} pypdf2 \
    pip install --target ${FUNCTION_DIR} boto3 

COPY copyables /

RUN apt update \
	&& apt install -y --no-install-recommends \
	gdebi \
	gnupg2 \
	fonts-noto-cjk \
	pulseaudio \
	supervisor \
	x11vnc \
	fluxbox \
	xz-utils \
	eterm \
	libgbm-dev \
	&& mkdir -p /var/task

ADD https://dl.google.com/linux/linux_signing_key.pub \
	https://www.slimjetbrowser.com/chrome/files/79.0.3945.88/google-chrome-stable_current_amd64.deb \
	# https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb \
	/tmp/

RUN apt-key add /tmp/linux_signing_key.pub \
	&& gdebi --non-interactive /tmp/google-chrome-stable_current_amd64.deb 
	#&& gdebi --non-interactive /tmp/chrome-remote-desktop_current_amd64.deb


RUN apt-get clean \
	&& rm -rf /var/cache/* /var/log/apt/* /var/lib/apt/lists/* /tmp/* \
	#&& useradd -m -G chrome-remote-desktop,pulse-access chrome \
	#&& usermod -s /bin/bash chrome \
	&& ln -s /crdonly /usr/local/sbin/crdonly \
	&& ln -s /update /usr/local/sbin/update \
	&& mkdir -p /home/chrome/.config/chrome-remote-desktop \
	&& mkdir -p /home/chrome/.fluxbox \
	&& echo ' \n\
		session.screen0.toolbar.visible:        false\n\
		session.screen0.fullMaximization:       true\n\
		session.screen0.maxDisableResize:       true\n\
		session.screen0.maxDisableMove: true\n\
		session.screen0.defaultDeco:    NONE\n\
	' >> /home/chrome/.fluxbox/init 
	#&& chown -R chrome:chrome /home/chrome/.config /home/chrome/.fluxbox
RUN sed -i 's+\$HOME+/tmp+g' /usr/bin/google-chrome
RUN sed -i 's+\$HOME+/tmp+g' /opt/google/chrome/google-chrome
RUN apt update
RUN apt install -y software-properties-common
RUN add-apt-repository contrib && apt update
RUN apt install -y ttf-mscorefonts-installer

WORKDIR ${FUNCTION_DIR}
RUN wget -O chrome.zip "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F793098%2Fchrome-linux.zip?generation=1596104713241153&alt=media"
RUN unzip chrome.zip

WORKDIR ${FUNCTION_DIR}


#ENTRYPOINT [/usr/bin/python3.7,/var/task/index.py]
ENTRYPOINT ["/usr/local/bin/python3.7","-m", "awslambdaric"]

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
CMD [ "index.handler" ]
