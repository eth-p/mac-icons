template_info() {
	echo "MacOS Big Sur Folder (Light Theme)"
	echo "Copyright (C) 2021 eth-p"
}

template_enabled() {
	[[ "$(sw_vers -productVersion | cut -d'.' -f1)" -eq 11 ]] || return $?
}

template_emboss() {
	magick convert "$1" \( -clone 0 -fill '#000000' -colorize 100 \) \
		-background none -compose Src -flatten \
		mask.bmp
		
	magick convert "$1" \( -clone 0 -fill '#45ace4' -colorize 100 \) \
		-background none -compose Src -flatten \
		overlay.bmp
		
	magick convert -compose Src_In "mask.bmp" \
		\( overlay.bmp -background '#45ace4' -shadow 10x2+0+0 -level 0,50% +channel \) \
		-alpha Set -composite \
		"shadow.bmp" 

	magick convert "overlay.bmp" \
		\( -clone 0 -background '#ffffff' -shadow 10x3+0+3 -channel A -level 0,50% +channel \) \
		-background none -compose DstOver -flatten \
		"glow.bmp"
		
	magick convert "glow.bmp" "shadow.bmp" \
		-background none -compose Screen -flatten \
		bmp:-
}

template_combine() {
	local geom=''
	case "${ICON_TYPE}" in
		'16x16')                geom='8x8+0+1' ;;
		'32x32'|'16x16@2x')     geom='16x16+0+2' ;;
		'32x32@2x')             geom='32x32+0+3' ;;
		'128x128')              geom='64x64+0+6' ;;
		'256x256'|'128x128@2x') geom='128x128+0+12' ;;
		'512x512'|'256x256@2x') geom='256x256+0+25' ;;
		'512x512@2x')           geom='512x512+0+50' ;;
	esac
	
	magick composite -gravity Center -compose ATop -geometry "$geom" "$1" "$2" png:-
}
