FROM blacktop/volatility:2.6

LABEL maintainer "https://github.com/blacktop"

ARG DEFAULT_CUCKOO_UID=1000

ENV CUCKOO_VERSION 2.0.7
ENV CUCKOO_CWD /cuckoo
ENV CUCKOO_PACKAGE_PATH=/usr/lib/python2.7/site-packages/cuckoo
ENV CUCKOO_FORK_REPO=ilyaglow/cuckoo/remotevbox-machinery
ENV SSDEEP 2.14.1

# Install Cuckoo Sandbox Required Dependencies
COPY 2.0/requirements.txt /tmp/requirements.txt
COPY vbox/pydeep.tar.gz /tmp/pydeep.tar.gz
COPY vbox/ssdeep-2.14.1.tar.gz /tmp/ssdeep-2.14.1.tar.gz
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk add --update --no-cache tcpdump py-lxml py-chardet py-libvirt py-crypto curl \
  postgresql-dev \
  gcc \
  g++ \
  python-dev \
  libpq \
  py-pip \
  shadow \
  && pip install pip -U \
  && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
  && pip install --upgrade wheel \
  && pip install psycopg2 \
  && apk del --purge postgresql-dev \
  gcc \
  g++ \
  && apk add --no-cache -t .build-deps \
  linux-headers \
  openssl-dev \
  libxslt-dev \
  libxml2-dev \
  python-dev \
  libffi-dev \
  build-base \
  libstdc++ \
  zlib-dev \
  libc-dev \
  jpeg-dev \
  file-dev \
  automake \
  autoconf \
  libtool \
  py-pip \
  git \
  swig \
  && set -x \
  && echo "===> Install ssdeep..." \
  && cd /tmp \
  && tar xzf ssdeep-$SSDEEP.tar.gz \
  && cd ssdeep-$SSDEEP \
  && ./configure \
  && make \
  && make install \
  && echo "===> Install pydeep..." \
  && cd /tmp \
  && tar xvf pydeep.tar.gz \
  && cd pydeep \
  && python setup.py build \
  && python setup.py install \
  # && echo "===> Install mitmproxy..." \
  # && LDFLAGS=-L/lib pip install mitmproxy \
  && echo "===> Install Cuckoo Sandbox..." \
  && mkdir /cuckoo \
  && pip install cryptography==2.9.2 \
  && pip install m2crypto==0.24.0 \
  && pip install pyopenssl==0.15.1 \
  && adduser -D -h /cuckoo -u $DEFAULT_CUCKOO_UID cuckoo \
  && export PIP_NO_CACHE_DIR=off \
  && export PIP_DISABLE_PIP_VERSION_CHECK=on \
  && pip install --upgrade wheel setuptools \
  && python -m pip install -U pip \
  && pip install pip==9.0.3 remotevbox==0.2.0 \
  && pip install pyrsistent==0.16.1 \  
  && LDFLAGS=-L/lib pip install cuckoo==$CUCKOO_VERSION \
  && pip install werkzeug==0.16.1 \
  && cuckoo

RUN cuckoo community \
  && echo "===> Install additional dependencies..." \
  && pip install -r /tmp/requirements.txt \
  && echo "===> Clean up unnecessary files..." \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps

COPY 2.0/conf /cuckoo/conf
COPY 2.0/update_conf.py /update_conf.py
COPY vbox/docker-entrypoint.sh /entrypoint.sh

RUN chown -R cuckoo /cuckoo \
  && chmod +x /entrypoint.sh

WORKDIR /cuckoo

VOLUME ["/cuckoo/conf"]

EXPOSE 1337 31337

ADD https://raw.githubusercontent.com/$CUCKOO_FORK_REPO/cuckoo/machinery/virtualbox_websrv.py $CUCKOO_PACKAGE_PATH/machinery/virtualbox_websrv.py
ADD https://raw.githubusercontent.com/$CUCKOO_FORK_REPO/cuckoo/common/config.py $CUCKOO_PACKAGE_PATH/common/config.py

RUN chmod 644 $CUCKOO_PACKAGE_PATH/common/config.py \
  $CUCKOO_PACKAGE_PATH/machinery/virtualbox_websrv.py

ENTRYPOINT ["/entrypoint.sh"]
