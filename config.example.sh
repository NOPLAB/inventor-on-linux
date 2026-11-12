# Copy to config.local.sh (ignored by Git). Environment variables take precedence.
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-${WINEPREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/inventor-on-linux/prefix}}"
# Existing Bottles, Lutris or other Wine prefixes can be selected by absolute path.
# Optional: executable name or absolute path, without command-line arguments.
# export INVENTOR_BROWSER=firefox
