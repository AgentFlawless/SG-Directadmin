#!/usr/bin/env bash
########################################################################
## Scripts: SourceGuardian installer                                  ##
## Code By: m.saleh                                                   ##
## Repository: https://github.com/AgentFlawless/extension-php         ##
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
SG_PATH=/usr/local/lib/sourceguardian

mkdir -p $SG_PATH
rm -f $SG_PATH/*

# Download and extract SourceGuardian files
echo "Downloading and extracting SourceGuardian files to $SG_PATH"
wget --tries=0 --retry-connrefused --timeout=180 -x --no-cache --no-check-certificate -O $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME $SOURCE_GUARDIAN_FILE_URL >/dev/null 2>&1
unzip -o $TMPDIR/$SOURCE_GUARDIAN_FILE_NAME -d $SG_PATH >/dev/null 2>&1
rm -rf $TMPDIR

for PHP_VERSION in $(grep -e php[1234]_release /usr/local/directadmin/custombuild/options.conf | cut -d "=" -f "2" | grep -v no)
do
  # Convert version from dot to no dot format (e.g., 7.4 -> 74)
  PHP_VERSION_NO_DOT=$(echo "$PHP_VERSION" | tr -d '.')

  EXTENSION_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/extensions.ini
  PHP_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.ini
  DIRECTADMIN_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/10-directadmin.ini
  WEBAPPS_INI=/usr/local/php$PHP_VERSION_NO_DOT/lib/php.conf.d/50-webapps.ini

  # Create ini files if they don't exist
  touch $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI

  # Remove existing ixed entries from ini files
  sed -i -r '/ixed/d' $EXTENSION_INI $PHP_INI $DIRECTADMIN_INI $WEBAPPS_INI >/dev/null 2>&1

  # Check if the loader file exists for this PHP version
  SG_LOADER_FILE="$SG_PATH/ixed.$PHP_VERSION.lin"
  if [[ ! -f "$SG_LOADER_FILE" ]]; then
    abort "SourceGuardian loader not found for PHP version $PHP_VERSION. Expected file: $SG_LOADER_FILE"
  fi

  # Add the extension to ini files
  if ! grep -q "ixed.$PHP_VERSION.lin" $EXTENSION_INI; then
    echo "Adding extension=$SG_LOADER_FILE to $EXTENSION_INI"
    echo "extension=$SG_LOADER_FILE" >> $EXTENSION_INI
  fi
done

echo "Installation complete. Restarting handler and webserver."
echo -e "\E[0m\E[01;31m\033[5m###############################################################################\E[0m"
