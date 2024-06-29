# Maintainer: NOBODY

pkgname=ztnet
pkgver=0.6.6
pkgrel=1
pkgdesc="ZeroTier Web UI for Private Controllers with Multiuser and Organization Support."
arch=('x86_64')
url="https://github.com/sinamics/ztnet"
license=('GPL-3.0')

depends=(
	'zerotier-one'
	'postgresql'
	'nodejs'
	'npm'
	'libvips'
)

optdepends=(
	'imagemagick: for libvips magick module'
	'libheif: for libvips heif module'
	'libjxl: for libvips jxl module'
	'openslide: for libvips openslide module'
	'poppler-glib: for libvips poppler module'
)

options=('!strip' '!debug')

install=$pkgname.install

source=(
	"$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz"
	"$pkgname.service"
	"env_setup.sh"
)

sha512sums=(
	"ca0e755c5761708d1737224eefe9e055ab153d163d5b81b354c66a64f7a94e61e49d10a79d6596647f4d4659880ea09e8fc5a893a045b1f5feccb6d48be26c1b"
	"68fadcc063f530c11c50ffaec083a062faa673eeff821277d9d86ce41ea732437dbe0365baa921f1eefb0e43e0c5e3bb31bedfa63ce7f2bd19e126d7978d666f"
	"6fe4324949212669c57c34f2ae1ddb1c8afa88284690f0c0cb7d1746b60eb8d0d09ffce897a26431e109b55c1893a145d5d58c4f0a786686eaa4496bf3bbec15"
)

prepare(){
	cd "$pkgname-$pkgver"
	# Set NPM cache directory, otherwise it will write to $HOME/.npm
	export NPM_CONFIG_CACHE=$srcdir/.npm
	# Install dependencies
	npm install
	# Append the PKG version to ztnet.service NEXT_PUBLIC_APP_VERSION variable
	sed -i "s/^\(Environment=NEXT_PUBLIC_APP_VERSION=\)/\1v$pkgver/" "$srcdir/ztnet.service"
}

build() {
	cd "$pkgname-$pkgver"
	# Set NPM cache directory, otherwise it will write to $HOME/.npm
	export NPM_CONFIG_CACHE=$srcdir/.npm
	# ZTNET release
	export NEXT_PUBLIC_APP_VERSION=v$pkgver
	# Node.js environment
	export NODE_ENV=production
	# Disable Next.js telemetry
	export NEXT_TELEMETRY_DISABLED=1
	# Bypass environment checks
	export SKIP_ENV_VALIDATION=1
	# Build ZTNET
	npm run build
	# Install dependencies for seeding the database into Next.js modules
	cd $srcdir/"$pkgname-$pkgver"/.next/standalone
	# Ensure that 'ts-node' is installed, otherwise database seeding will fail.
	npm install ts-node
	# Remove the NPM cache
	rm -r $srcdir/.npm
}

package() {
	# Create target directories
	mkdir -p $pkgdir/opt/sinamics/ztnet
	mkdir -p $pkgdir/opt/sinamics/ztnet/.next
	# Copy project metadata
	cp "$pkgname-$pkgver"/package.json $pkgdir/opt/sinamics/ztnet/
	# Copy icon
	cp -r "$pkgname-$pkgver"/public $pkgdir/opt/sinamics/ztnet/public
	# Copy Next.js config
	cp "$pkgname-$pkgver"/next.config.mjs $pkgdir/opt/sinamics/ztnet/
	# Copy Next.js build artifacts
	cp -a "$pkgname-$pkgver"/.next/standalone/. $pkgdir/opt/sinamics/ztnet/
	cp -r "$pkgname-$pkgver"/.next/static $pkgdir/opt/sinamics/ztnet/.next/static
	# Copy Prisma
	cp -r "$pkgname-$pkgver"/prisma $pkgdir/opt/sinamics/ztnet
	# Copy ztmkworld binary
	mkdir -p $pkgdir/usr/bin
	cp "$pkgname-$pkgver"/ztnodeid/build/linux_amd64/ztmkworld $pkgdir/usr/bin/ztmkworld
	# Install env_setup script
	install -Dm 0744 "env_setup.sh" "$pkgdir/opt/sinamics/ztnet/env_setup.sh"
	# Install ZTNET service
	install -Dm 0644 "$pkgname.service" "$pkgdir/usr/lib/systemd/system/$pkgname.service"
}
