#!/usr/bin/env bash
set -e

ask() {
	# http://djm.me/ask
	while true; do

		if [ "${2:-}" = "Y" ]; then
			prompt="Y/n"
			default=Y
		elif [ "${2:-}" = "N" ]; then
			prompt="y/N"
			default=N
		else
			prompt="y/n"
			default=
		fi

		# Ask the question
		read -r -p "$1 [$prompt] " REPLY

		# Default?
		if [ -z "$REPLY" ]; then
			REPLY=$default
		fi

		# Check if the reply is valid
		case "$REPLY" in
			Y*|y*) return 0 ;;
			N*|n*) return 1 ;;
		esac

	done
}

APP=$(node -p "require('./package.json').name")
PKG_FOLDER="pkg"

echo "Destination folder: $PKG_FOLDER"
echo "App-name: $APP"

VERSION=$(node -p "require('./package.json').version")
echo "Version: $VERSION"

NODE_MAJOR=$(node -v | grep -E -o '[0-9].' | head -n 1)

echo "## Clear $PKG_FOLDER folder"
rm -rf ${PKG_FOLDER:?PKG_FOLDER not defined}/*

if [ -n "$1" ]; then
	echo "## Building application..."
	echo ''
	yarn run build

	npx pkg . --target "node$NODE_MAJOR-linux-x64" --output "$PKG_FOLDER/linux-amd64/$APP"
	npx pkg . --target "node$NODE_MAJOR-linux-arm64" --output  "$PKG_FOLDER/linux-arm64/$APP"
	npx pkg . --target "node$NODE_MAJOR-win-x64" --output "$PKG_FOLDER/win-x64/$APP.exe"

else

	if ask "Re-build $APP?"; then
		echo "## Building application"
		yarn run build
	fi

	echo '###################################################'
	echo '## Choose architecture to build'
	echo '###################################################'
	echo ' '
	echo 'Your architecture is' "$(arch)"
	PS3="Architecture: >"
	options=(
		"x64"
		"armv7"
		"armv6"
		"x86"
		"alpine"
		"arm64"
	)
	echo ''
	select _ in "${options[@]}"; do
		case "$REPLY" in
			1)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-linux-x64" --out-path $PKG_FOLDER
				break
				;;
			2)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-linux-armv7" --out-path $PKG_FOLDER --public-packages=*
				break
				;;
			3)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-linux-armv6" --out-path $PKG_FOLDER --public-packages=*
				break
				;;
			4)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-linux-x86" --out-path $PKG_FOLDER
				break
				;;
			5)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-alpine-x64" --out-path $PKG_FOLDER
				break
				;;
			6)
				echo "## Creating application package in $PKG_FOLDER folder"
				npx pkg package.json -t "node$NODE_MAJOR-linux-arm64" --out-path $PKG_FOLDER
				break
				;;
			*)
				echo '####################'
				echo '## Invalid option ##'
				echo '####################'
				exit
		esac
	done
fi

cd $PKG_FOLDER

if [ -n "$1" ]; then
	tar -C win-x64 -cvzf "$APP-v$VERSION-win-x64.tgz" "$APP.exe"
	tar -C linux-amd64 -cvzf "$APP-v$VERSION-linux-amd64.tgz" "$APP"
	tar -C linux-arm64 -cvzf "$APP-v$VERSION-linux-arm64.tgz" "$APP"

	# Backwards compat zip files
	cp "win-x64/$APP.exe" "$APP-win.exe"
	cp "linux-amd64/$APP" "$APP-linux"

	zip "$APP-v$VERSION-win.zip" "$APP-win.exe"
	zip "$APP-v$VERSION-linux.zip" "$APP-linux"
else
	echo "## Create zip file $APP-v$VERSION"
	zip -r "$APP-v$VERSION.zip" "$APP"
fi
