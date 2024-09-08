#!/usr/bin/env bash
########################################################################
## Scipts: sourcegurdian installer                               ##
## Code By: m.saleh                                              ##
## Repository: https://github.com/AgentFlawless/extension-php    ##
########################################################################

clear

echo "Welcome to SourceGurdian Installer"
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

mkdir -p $SG_PATH
rm -f $SG_PATH/*

# Download and extract SourceGuardian files to $SG_PATH
echo "Downloading and extracting SourceGuardian files to $SG_PATH"
wget --tries=0 --retry-connrefused --timeout=180 -x --no-cache --no-check-certificate -O $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME $SOURCE_GUARDIAN_FILE_URL >/dev/null 2>&1
unzip -o $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME -d $TMPDIR/sourceguardian >/dev/null 2>&1

# Copy all files to $SG_PATH
echo "Copying files to $SG_PATH"
cp -r $TMPDIR/sourceguardian/* $SG_PATH/

# Clean up temporary directory
rm -rf $TMPDIR

for PHP_VERSION in $(grep -e php[1234]_release /usr/local/directadmin/custombuild/options.conf | cut -d "=" -f "2" | grep -v no)
do
  # Convert dot version to no dot version (e.g., 7.4 => 74)
  A=${PHP_VERSION//\./}
  PHP_VERSION_NO_DOT="${A[@]}"

  EXTENSION_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/extensions.ini
  PHP_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.ini
  DIRECTADMIN_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/10-directadmin.ini
  WEBAPPS_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/50-webapps.ini

  touch $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI

  # Remove previous entries from ini files
  sed -i -r '/ixed/d' $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI >/dev/null 2>&1

  # Add SourceGuardian extension if not present
  if [[ ! "$(grep -P "ixed.\d+\.\d+.lin" $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI >/dev/null 2>&1)" ]]; then
    INI=$EXTENSION_INI
    echo "Adding extension=$SG_PATH/ixed.$PHP_VERSION.lin to $INI"
    echo "extension=$SG_PATH/ixed.$PHP_VERSION.lin" >> $INI
  fi
done

echo "Done. Restarting handler and webserver."
echo -e "\E[0m\E[01;31m\033[5m###############################################################################\E[0m"