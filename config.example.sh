# Copy to config.local.sh (ignored by Git). Environment variables take precedence.
export INVENTOR_PREFIX="${INVENTOR_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/bottles/bottles/Inventor2027}"
# Optional: executable name or absolute path, without command-line arguments.
# export INVENTOR_BROWSER=firefox
