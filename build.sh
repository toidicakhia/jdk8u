TERMUX_PKG_HOMEPAGE=https://openjdk.java.net
TERMUX_PKG_DESCRIPTION="Java development kit and runtime"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="8u402"
TERMUX_PKG_SRCURL=https://github.com/openjdk/jdk8u/archive/refs/tags/jdk-${TERMUX_PKG_VERSION}-ga.tar.gz
TERMUX_PKG_DEPENDS="libandroid-shmem, libandroid-spawn, libiconv, libjpeg-turbo, zlib, littlecms, alsa-plugins"
TERMUX_PKG_BUILD_DEPENDS="cups, fontconfig, libxrandr, libxt, xorgproto, alsa-lib"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_HAS_DEBUG=false

termux_step_pre_configure() {
	unset JAVA_HOME

	# Replace @TERMUX_PREFIX@ placeholders with actual prefix
	find . -type f -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.hpp" \
		-o -name "*.h" -o -name "*.make" -o -name "*.gmk" -o -name "*.gcc" | \
		xargs -r sed -i "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g"
}

termux_step_configure() {
	local jdk_ldflags="-L${TERMUX_PREFIX}/lib \
		-Wl,-rpath=$TERMUX_PREFIX/lib/jvm/java-8-openjdk/lib \
		-Wl,-rpath=${TERMUX_PREFIX}/lib -Wl,--enable-new-dtags"
	bash ./configure \
		--disable-precompiled-headers \
		--disable-warnings-as-errors \
		--enable-option-checking=fatal \
		--with-jvm-variants=server \
		--with-debug-level=release \
		--openjdk-target=$TERMUX_HOST_PLATFORM \
		--with-toolchain-type=clang \
		--with-extra-cflags="$CFLAGS $CPPFLAGS -DLE_STANDALONE -D__ANDROID__=1 -D__TERMUX__=1" \
		--with-extra-cxxflags="$CXXFLAGS $CPPFLAGS -DLE_STANDALONE -D__ANDROID__=1 -D__TERMUX__=1" \
		--with-extra-ldflags="${jdk_ldflags} -Wl,--as-needed -landroid-shmem -landroid-spawn -liconv" \
		--with-cups-include="$TERMUX_PREFIX/include" \
		--with-fontconfig-include="$TERMUX_PREFIX/include" \
		--with-freetype-include="$TERMUX_PREFIX/include/freetype2" \
		--with-freetype-lib="$TERMUX_PREFIX/lib" \
		--with-alsa="$TERMUX_PREFIX" \
		--with-alsa-include="$TERMUX_PREFIX/include/alsa" \
		--with-alsa-lib="$TERMUX_PREFIX/lib" \
		--with-x="$TERMUX_PREFIX/include/X11" \
		--x-includes="$TERMUX_PREFIX/include/X11" \
		--x-libraries="$TERMUX_PREFIX/lib" \
		--with-giflib=system \
		--with-lcms=system \
		--with-libjpeg=system \
		--with-libpng=system \
		--with-zlib=system \
		--with-vendor-name="Termux" \
		--with-boot-jdk="$TERMUX_PREFIX/lib/jvm/java-17-openjdk" \
		AR="$AR" \
		NM="$NM" \
		OBJCOPY="$OBJCOPY" \
		OBJDUMP="$OBJDUMP" \
		STRIP="$STRIP" \
		BUILD_CC="$TERMUX_HOST_LLVM_BASE_DIR/bin/clang" \
		BUILD_CXX="$TERMUX_HOST_LLVM_BASE_DIR/bin/clang++" \
		BUILD_NM="$TERMUX_HOST_LLVM_BASE_DIR/bin/llvm-nm" \
		BUILD_AR="$TERMUX_HOST_LLVM_BASE_DIR/bin/llvm-ar" \
		BUILD_OBJCOPY="$TERMUX_HOST_LLVM_BASE_DIR/bin/llvm-objcopy" \
		BUILD_STRIP="$TERMUX_HOST_LLVM_BASE_DIR/bin/llvm-strip" \
		--with-jobs=$TERMUX_PKG_MAKE_PROCESSES
}

termux_step_make() {
	cd build/linux-${TERMUX_ARCH/i686/x86}-normal-server-release
	make images
}

termux_step_make_install() {
	rm -rf $TERMUX_PREFIX/lib/jvm/java-8-openjdk
	mkdir -p $TERMUX_PREFIX/lib/jvm/java-8-openjdk
	cp -r build/linux-${TERMUX_ARCH/i686/x86}-normal-server-release/images/j2sdk-image/* \
		$TERMUX_PREFIX/lib/jvm/java-8-openjdk/
	find $TERMUX_PREFIX/lib/jvm/java-8-openjdk/ -name "*.debuginfo" -delete

	mkdir -p $TERMUX_PREFIX/lib/jvm/java-8-openjdk/etc/profile.d
	echo "export JAVA_HOME=$TERMUX_PREFIX/lib/jvm/java-8-openjdk/" > \
		$TERMUX_PREFIX/lib/jvm/java-8-openjdk/etc/profile.d/java.sh
}
