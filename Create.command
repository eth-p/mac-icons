#!/bin/bash
# ----------------------------------------------------------------------------------------------------------------------
# mac-icons | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/mac-icons
# Issues:     https://github.com/eth-p/mac-icons/issues
# ----------------------------------------------------------------------------------------------------------------------
set -eEo pipefail
shopt -s nullglob

HERE="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${HERE}/Icons"
cd "$HERE"

# Query terminal info for fancier display.
HEIGHT="$(stty size | cut -d' ' -f1)"
WIDTH="$(stty size | cut -d' ' -f2)"

# Clear the screen.
clear() {
	printf "\x1B[H\x1B[3J"
	for row in $(seq 0 "$HEIGHT"); do
		printf "\x1B[L\x1B[B"
	done
	printf "\x1B[H"
}

# Print a small terminal UI.
tui_hr() {
	printf "\x1B[1;37;45m%s\x1B[0m\n" "$(printf "%$((WIDTH))s" | tr ' ' '-')"
}

tui_template() {
	printf "\x1B[1;97;46m %s \x1B[0;36m \x1B[1m%s \x1B[0;36m%s\x1B[0m\n" ">" "Template:" "$1"
}

tui_template_info() {
	local message="$1"
	while [[ -n "$message" ]]; do
		printf "\x1B[1;97;46m %s \x1B[0;39m %s\x1B[0m\n" " " "${message:0:$((WIDTH-4))}"
		message="${message:$((WIDTH-4))}"
	done
}

tui_progress() {
	local color="3"
	local suffix=""
	local mark="..."
	local message="$3"
	
	case "$1" in
		'=>'|'')   return 0 ;; # Just template information.
		ERROR:)    color="1"; mark=' ! '; suffix="\n" ;;
		COMPLETE:) color="2"; mark=' + '; suffix="\n" ;;
		UPDATE:)   : ;;
		*)         color="2"; suffix="\n"; message="$1 $3" ;;
	esac
	
	printf "\x1B[G\x1B[K\x1B[4${color};97m%s\x1B[0;3${color}m %s - %s\x1B[0m${suffix}" "$mark" "$2.icns" "$message"
	
	if [[ "$suffix" = "\n" ]]; then
		PROGRESS_NL=true
	else
		PROGRESS_NL=false
	fi
}

clear
tui_hr
printf "\x1B[1;97;45m|%-$((WIDTH-2))s|\x1B[0m\n" " Creating Icons - https://github.com/eth-p/mac-icons "
tui_hr

# Process each combination of template and engraving.
for template in "${HERE}/Create/Templates"/*.iconset; do
	
	# Create the output directory for the template.
	template_name="$(basename -- "$template" .iconset)"
	template_output="${OUTPUT}/${template_name}"
	[[ -d "${template_output}" ]] || mkdir -p "$template_output"
	
	# Print the template name.
	tui_template "$template_name"
	
	# Print the template info.
	({
		source "${template}/imio.sh"
		while read -r line; do
			tui_template_info "$line"
		done < <(template_info) 
	})
	
	# Process for each engraving.
	for engraving in "${HERE}/Create/Engravings"/*.svg; do
		engraving_name="$(basename -- "$engraving" .svg)"
		tui_progress 'UPDATE:' "$engraving_name" "Creating icon"
		
		# Print the status updates.
		while read -r status message; do
			tui_progress "$status" "$engraving_name" "$message"
		done < <(bash "${HERE}/generate.sh" "$template" "$engraving" "${template_output}/${engraving_name}.icns")

		if [[ "$PROGRESS_NL" = "false" ]]; then
			printf "\n"
		fi
	done
	
	printf "\n"
done

tui_hr
printf "\n"
printf "\x1B[1;32mDone! Look at the Icons folder to see the generated icons.\x1B[0m\n"
