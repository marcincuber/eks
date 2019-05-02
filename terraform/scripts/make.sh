#!/usr/bin/env bash

function check_bash() {
find . -name "*.sh" | while IFS= read -d '' -r file;
do
  if [[ "$file" != *"bash -e"* ]];
  then
    echo "$file is missing shebang with -e";
    exit 1;
  fi;
done;
}

# This function makes sure that the required files
function basefiles() {
  echo "Checking for required files"
  test -f CONTRIBUTING.md || echo "Missing CONTRIBUTING.md"
  test -f README.md || echo "Missing README.md"
}

# This function runs 'terraform validate' against all
# files ending in '.tf'
function check_terraform() {
  echo "Running terraform validate"
  #shellcheck disable=SC2156
  find . -name "*.tf" -exec bash -c 'terraform validate --check-variables=false $(dirname "{}")' \;
}

# This function runs the shellcheck linter on every
# file ending in '.sh'
function check_shell() {
  echo "Running shellcheck"
  find . -name "*.sh" -exec shellcheck -x {} \;
}

# This function makes sure that there is no trailing whitespace
# in any files in the project.
# There are some exclusions
function check_trailing_whitespace() {
  echo "The following lines have trailing whitespace"
  grep -r '[[:blank:]]$' --exclude-dir="netaddr" --exclude-dir="akamai" --exclude-dir=".terraform" \
    --exclude="*.png" --exclude-dir=".git" --exclude-dir="dist" --exclude="*.pyc" .
  rc=$?
  if [[ ${rc} = 0 ]];
  then
    exit 1
  fi
}
