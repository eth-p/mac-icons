#!/usr/bin/env bash
# ----------------------------------------------------------------------------------------------------------------------
# mac-icons | Copyright (C) 2021 eth-p | MIT License
#
# Repository: https://github.com/eth-p/mac-icons
# Issues:     https://github.com/eth-p/mac-icons/issues
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Init:
# This section contains initialization variables.
# ----------------------------------------------------------------------------------------------------------------------
__ICON_TYPES=(
	"16x16" "16x16@2x"
	"32x32" "32x32@2x"
	"128x128" "128x128@2x"
	"256x256" "256x256@2x"
	"512x512" "512x512@2x"
)

# ----------------------------------------------------------------------------------------------------------------------
# Library:
# This section contains functions intended to be used by template scripts.
# ----------------------------------------------------------------------------------------------------------------------

# Gets the absolute path of the provided relative path.
#
# Arguments:
#     $1  -- The relative path.
#
# Output:
#     The absolute path.
path_abspath() {
	if [[ "${1:0:1}" == "/" ]]; then
		echo "$1"
		return 0
	fi

	echo "$(pwd)/$1"
}

# Gets the file extension from a file path.
#
# Arguments:
#     $1  -- The file path.
#
# Output:
#     The file extension, including leading dot.
path_extname() {
	local file="$1"
	echo ".${file##*.}"
}

# Converts a string to lower case.
#
# Arguments:
#     $1  -- The input string.
#
# Output:
#     The lower-case string.
str_tolower() {
	tr "[:upper:]" "[:lower:]" <<< "$1"
}

# Rasterizes an image.
#
# Arguments:
#     $1  -- The image to rasterize.
#     $2  -- The desired width.
#     $3  -- The desired height.
#
# Output:
#     The path to the rasterized image.
rasterize() {
	local input="$1"
	local width="$2"
	local height="$3"
	local output="${TMPDIR}/__${width}x${height}__$(basename -- "$input" "$(path_extname "$input")").bmp"
	
	if ! [[ -f "$output" ]]; then 
		progress DEBUG "Rasterizing: $1"
		case "$(str_tolower "$input")" in
			*.svg) rsvg-convert --width="$width" --height="$height" "$input" -o "$output" ;;
			*) convert -resize "${width}x${height}" "$input" "$output" ;;
		esac
	fi

	echo "$output"
}

# Prints a progress status update.
#
# Arguments:
#     $1  -- The progress type. (ERROR, UPDATE, DONE)
#     $2  -- The progress message.
progress() {
	case "$1" in
		DEBUG) : ;;
		*)     printf "%s: %s\n" "$1" "$2" 1>&3 ;;
	esac
}

if [[ -t 1 ]]; then
	progress() {
		if [[ "$1" = "DEBUG" ]]; then
			return 0
		fi
		
		printf "\x1B[G\x1B[K"
		case "$1" in
			UPDATE)   printf "\x1B[39m%s\x1B[0m" "$2" ;;
			COMPLETE) printf "\x1B[32m%s\x1B[0m\n" "$2" ;;
			ERROR)    printf "\x1B[1;31mError: \x1B[0;31m%s\x1B[0m\n" "$2" ;;
			*)        printf "\x1B[39m%s\x1B[0m\n" "$2" ;;
		esac
	}
fi

# ----------------------------------------------------------------------------------------------------------------------
# Script:
# This section contains functions intended to be used solely by this script.
# ----------------------------------------------------------------------------------------------------------------------

# Creates the iconset for a given template and input_engraving.
#
# Arguments:
#     $1  -- The path to the template iconset.
#     $2  -- The path to the input_engraving image.
#     $3  -- The path to the output iconset.
#
# [[INTERNAL]]
__create_icons() {
	local template="$1"
	local input_engraving="$2"
	local output="$3"

	if ! [[ -e "$template" ]]; then
		template="${template}.iconset"
	fi
	
	if ! [[ -e "$output" ]]; then
		mkdir -p "$output"	
	fi

	# Validate the template.
	if ! [[ -d "$template" ]]; then
		progress ERROR "template not found: $template"
		return 1
	fi

	if ! [[ -f "${template}/imio.sh" ]]; then
		progress ERROR "template not valid: $template"
		return 1
	fi
	
	# Load the template script.
	({
		source "${template}/imio.sh"
		
		# Print template information.
		printf "=> Using template '%s':\n" "${template}"
		template_info | sed 's/^/=> /'
		printf "\n"
		
		# Generate the icons.
		local pwd="$(pwd)"
		for ICON_TYPE in "${__ICON_TYPES[@]}"; do
			ICON_WIDTH="$(cut -d'x' -f1 <<< "${ICON_TYPE}")"
			ICON_HEIGHT="$(cut -d'x' -f2 <<< "${ICON_TYPE}" | cut -d'@' -f1)"
			ICON_VARIANT="@$(cut -d'@' -f2 <<< "${ICON_TYPE}")"
			
			case "$ICON_VARIANT" in
				'@') ICON_VARIANT='@1x' ;;
				'@2x') {
					ICON_WIDTH="$((ICON_WIDTH * 2))"
					ICON_HEIGHT="$((ICON_HEIGHT * 2))"
				} ;;
			esac
			
			progress UPDATE "Generating ${ICON_TYPE}"
			
			# Use a separate directory.
			[[ -d "${pwd}/${ICON_TYPE}" ]] || mkdir -p "${pwd}/${ICON_TYPE}"
			cd "${pwd}/${ICON_TYPE}"
			
			# Generate the icon.
			__create_icon \
				"${template}/icon_${ICON_TYPE}.png" "$input_engraving" "${output}/icon_${ICON_TYPE}.png" \
				"$ICON_WIDTH" "$ICON_HEIGHT"
		done
	})
}

# Creates an icon variant.
#
# Arguments:
#     $1  -- The source image.
#     $2  -- The source input_engraving.
#     $3  -- The destination image.
#     $4  -- The image width.
#     $5  -- The image height.
#
# [[INTERNAL]]
__create_icon() {
	local input_background="$1"
	local input_engraving="$2"
	local output_combined="$3"
	local output_engraving="embossed_engraving.bmp"
	local width="$4"
	local height="$5"

	# Rasterize the input_engraving.
	local input_engraving_bmp
	input_engraving_bmp="$(rasterize "${input_engraving}" "${width}" "${height}")"
	
	# Emboss the input_engraving.
	SOURCE_TEMPLATE="${input_background}"
	SOURCE_ENGRAVING="${input_engraving}"
	template_emboss "${input_engraving_bmp}" > "${output_engraving}"

	# Combine the template image and the input_engraving.
	template_combine "${output_engraving}" "${input_background}" > "${output_combined}"
}

# Exits if a command cannot be found.
#
# Arguments:
#     $1  -- The command.
#     $2  -- The source of the command.
#
# [[INTERNAL]]
__requires() {
	if ! command -v "$1" &>/dev/null; then
		progress ERROR "Missing dependency: $1 (from $2)"
		exit 1
	fi
}

# Cleans up the temporary working space.
#
# [[INTERNAL]]
__cleanup() {
	if [[ "$TMPDIR" != "${ORIGINAL_TMPDIR}" ]] && [[ -d "$TMPDIR" ]]; then
		progress DEBUG "Clearing temporary files..."
		rm -rf "$TMPDIR"
	fi
}

# Called whenever an error occurs.
#
# [[INTERNAL]]
__on_error() {
	local exit="$?"
	__cleanup
	
	if [[ "$exit" -ne 0 ]]; then
		exit "$exit"	
	fi
}

# ----------------------------------------------------------------------------------------------------------------------
# Main:
# 
# $1 -- Template
# $2 -- Engraving
# $3 -- Output
# ----------------------------------------------------------------------------------------------------------------------
set -eEo pipefail
exec 3>&1

# Check for dependencies.
__requires magick "imagemagick"
__requires rsvg-convert "librsvg"
__requires iconutil "MacOS"

# Validate arguments.
if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
	cat <<-EOF
		usage: $0 [template] [engraving] [output]
		
		Copyright (C) 2021 eth-p | MIT License
		Website: https://github.com/eth-p/mac-icons
	EOF
	exit 1	
fi

# Trap `set -e`.
trap '__on_error' ERR

# Replace TMPDIR with a subdirectory that is easy to clean.
ORIGINAL_TMPDIR="$TMPDIR"
TMPDIR="$(mktemp -d)"

({
	template="$1"
	input_engraving="$2"
	output="$3"
	format="icns"
	
	case "$(str_tolower "$(path_extname "$output")")" in
		".iconset") format="iconset" ;;
		".icns")    output="$(dirname -- "$output")/$(basename -- "$output" "$(path_extname "$output")").iconset" ;;
		*)          output="${output}.iconset" ;;
	esac

	# Get the full paths of the inputs.
	template="$(path_abspath "$template")"
	input_engraving="$(path_abspath "$input_engraving")"
	output="$(path_abspath "$output")"
	
	# Create the icons.
	cd "$TMPDIR"
	__create_icons "$template" "$input_engraving" "$output"
	
	# Convert to an icns.
	if [[ "$format" = "icns" ]]; then
		progress UPDATE "Converting to icns"
		iconutil --convert icns \
			--output "$(dirname -- "$output")/$(basename -- "$output" "$(path_extname "$output")").icns" \
			"$output"
		
		# Remove the iconset safely.
		for ICON_TYPE in "${__ICON_TYPES[@]}"; do
			rm "${output}/icon_${ICON_TYPE}.png"
		done
		rmdir "$output"
	fi
	
	progress COMPLETE "Created icon"
})

__cleanup
