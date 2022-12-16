FROM alpine:3.16 as builder

ARG TARGETOS
ARG TARGETARCH
RUN echo "Building for $TARGETOS/$TARGETARCH"

RUN set -eux; \
	apk add --no-cache \
		bzip2 \
		ca-certificates \
		gmp-dev \
		libffi-dev \
		procps \
		yaml-dev \
		zlib-dev \
	;

# skip installing gem documentation
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV LANG C.UTF-8
ENV RUBY_TAG v3_2_0_rc1
ENV RUBY_SHA256SUM e419d4f535ff0ad15e3bbec8f995ebb3f5724d4709520c01269993482bf29610
ENV JYIT_COMMIT 8323839edf40da8c2652a599641ef15957edcbc5

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -eux; \
	\
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
	apk add --no-cache --virtual .ruby-builddeps \
		autoconf \
		bison \
		bzip2 \
		bzip2-dev \
		ca-certificates \
		cargo \
		coreutils \
		dpkg-dev dpkg \
		g++ \
		gcc \
		gdbm-dev \
		git \
		glib-dev \
		libc-dev \
		libffi-dev \
		libxml2-dev \
		libxslt-dev \
		linux-headers \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
		patch \
		procps \
		readline-dev \
		rust \
		ruby \
		sqlite-dev \
		tar \
		xz \
		yaml-dev \
		zlib-dev

RUN mkdir -p /build && \
	wget -O /tmp/ruby.tgz https://github.com/ruby/ruby/archive/refs/tags/${RUBY_TAG}.tar.gz && \
	echo "${RUBY_SHA256SUM} /tmp/ruby.tgz" | sha256sum --check --strict && \
	tar -xzf /tmp/ruby.tgz -C /build --strip-components=1

WORKDIR /build

# https://github.com/docker-library/ruby/issues/196
# https://bugs.ruby-lang.org/issues/14387#note-13 (patch source)
# https://bugs.ruby-lang.org/issues/14387#note-16 ("Therefore ncopa's patch looks good for me in general." -- only breaks glibc which doesn't matter here)
RUN	wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch' && \
	echo '3ab628a51d92fdf0d2b5835e93564857aea73e0c1de00313864a94a6255cb645 *thread-stack-fix.patch' | sha256sum --check --strict && \
	patch -p1 -i thread-stack-fix.patch && \
	rm thread-stack-fix.patch 

# the configure script does not detect isnan/isinf as macros
RUN	export ac_cv_func_isnan=yes ac_cv_func_isinf=yes && \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new && \
	mv file.c.new file.c && \
	autoreconf --install && \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
	./configure --build="$gnuArch" --disable-install-doc --enable-YJIT_COMMIT

RUN make -j $(nproc)
# uncomment this to limit number of threads when testing. Useful when building using an emulated platform as tests may timeout
#RUN N=$(nproc); \
#if [ "$TARGETARCH" = "arm64" ]; then N=2; fi && \
#make -j ${N} test RUN_OPTS="--yjit"
RUN make -j $(nproc) test RUN_OPTS="--yjit"

RUN	make install && \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" 

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH

# TODO - should probably be managed in a Gemfile...
RUN mkdir -p "$GEM_HOME" && \
	chmod 777 "$GEM_HOME" && \
	\
	git clone https://github.com/Shopify/yjit-bench.git /yjit-bench && \
	cd /yjit-bench && \
	git reset --hard ${YJIT_COMMIT} && \
	\
	for i in $(find . -name Gemfile -type f -print); do (BUNDLE_GEMFILE=$i bundle install); done && \
	\
	apk add --no-network --virtual .ruby-rundeps $runDeps && \
	apk del --no-network .ruby-builddeps && \
	cd / && \
	rm -rf /build && \
# verify we have no "ruby" packages installed
	if \
		apk --no-network list --installed \
			| grep -v '^[.]ruby-rundeps' \
			| grep -i ruby \
	; then \
		exit 1; \
	fi; \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]

WORKDIR /

# yjit-bench
FROM alpine:3.16

WORKDIR /
RUN set -eux; \
	apk add --no-cache \
		bzip2 \
		ca-certificates \
		git \
		libgcc \
		gdbm \
		gmp \
		libffi \
		libsass \
		libxml2 \
		libxslt \
		patch \
		procps \
		sqlite-dev \
		su-exec \
		util-linux \
		yaml \
	;

COPY --from=builder /usr/local/ /usr/local/
ADD patch-05-tzinfo-data /tmp/
ADD patch-06-tzinfo-data /tmp/

RUN git clone https://github.com/Shopify/yjit-bench.git /yjit-bench && \
	cd /yjit-bench \
	git reset --hard ${YJIT_COMMIT} && \
	\
	patch -p1 < /tmp/patch-05-tzinfo-data && \
	patch -p1 < /tmp/patch-06-tzinfo-data

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH

WORKDIR /yjit-bench
CMD [ "./run_benchmarks.rb" ]
