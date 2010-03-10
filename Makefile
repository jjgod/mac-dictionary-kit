default:
	xcodebuild -configuration Release

install:
	sudo xcodebuild install -configuration Release DSTROOT=/ INSTALL_PATH=/Applications DEPLOYMENT_LOCATION=YES
