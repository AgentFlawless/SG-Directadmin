#!/usr/bin/env bash
########################################################################
## Script: SourceGuardian Installer                                    ##
## Code By: m.saleh                                                    ##
## Repository: https://github.com/AgentFlawless/extension-php          ##
########################################################################

clear

echo "Welcome to SourceGuardian Installer"
echo -e "\E[0m\E[01;31m\033[5m###############################################################################\E[0m"

# Show an error and exit
abort() {
  echo -e "\E[0m\E[01;31m\033[5mPlease check log and run scripts with -x.\E[0m"
  echo -e "\E[0m\E[01;31m\033[5m$1\E[0m"
  exit 1
}

SOURCE_GUARDIAN_FILE_NAME=SourceGuardian-loaders.linux-x86_64-14.0.2.zip
SOURCE_GUARDIAN_FILE_URL=https://github.com/AgentFlawless/extension-php/raw/main/$SOURCE_GUARDIAN_FILE_NAME

TMPDIR=$(mktemp -d)
SG_PATH=/usr/local/lib/sourcegurdian

# Create SourceGuardian path and clear any existing files
mkdir -p $SG_PATH
rm -f $SG_PATH/*

# Download and extract all SourceGuardian files into $SG_PATH
echo "Downloading and extracting all SourceGuardian files to $SG_PATH"
wget --tries=0 --retry-connrefused --timeout=180 -x --no-cache --no-check-certificate -O $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME $SOURCE_GUARDIAN_FILE_URL >/dev/null 2>&1
unzip -o $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME -d $SG_PATH >/dev/null 2>&1
rm -rf $TMPDIR

# Verify if the SourceGuardian files are properly extracted
if [[ ! -f $SG_PATH/ixed.7.4.lin ]]; then
  abort "SourceGuardian files were not properly extracted. Please check the zip file and path."
fi

for PHP_VERSION in $(grep -e php[1234]_release /usr/local/directadmin/custombuild/options.conf | cut -d "=" -f "2" | grep -v no)
do
  # Convert dot version to no dot version (e.g., 7.4 => 74)
  PHP_VERSION_NO_DOT=${PHP_VERSION//./}

  EXTENSION_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/extensions.ini
  PHP_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.ini
  DIRECTADMIN_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/10-directadmin.ini
  WEBAPPS_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/50-webapps.ini

  touch $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI

  # Remove any existing SourceGuardian extension references
  sed -i -r '/ixed/d' $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI >/dev/null 2>&1

  # Check and add the extension if not already added
  if ! grep -q "ixed.$PHP_VERSION.lin" $EXTENSION_INI; then
    echo "Adding extension=$SG_PATH/ixed.$PHP_VERSION.lin to $EXTENSION_INI"
    echo "extension=$SG_PATH/ixed.$PHP_VERSION.lin" >> $EXTENSION_INI
  fi
done

echo "Done, restarting handler and web server"
echo -e "\E[0m\E[01;31m\033[5m###############################################################################\E[0m"
