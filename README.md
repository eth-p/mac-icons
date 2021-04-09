# mac-icons

An assortment of custom MacOS folder icons designed to match the native look and feel.


## Screenshots
![image](https://user-images.githubusercontent.com/32112321/114133617-2a3ed800-98bb-11eb-80b5-3aa783c650a2.png)



## Installation

**Step 1: Download the icons.**  
Download the zip for your version of MacOS from the [latest release](https://github.com/eth-p/mac-icons/releases/latest).

**Step 2: Find a folder.**  
In Finder, right-click on the folder you want to apply an icon to and choose "Get Info".

**Step 3: Copy the icon.**  
In Finder, copy the icon you want to apply to the folder.

**Step 4: Apply the icon.**  
Inside the "Get Info" window, click on the folder icon and press `Command + V`.

**Step 5: You're done!**  
Enjoy your new folder icon.

**ALTERNATE INSTRUCTIONS:**  
https://support.apple.com/en-ca/guide/mac-help/mchlp2313/mac


## DIY Instructions

If you want to build your own icon engravings, you'll need to install a couple of things:

- A computer running MacOS.
- A SVG editor of your choice.
- ImageMagick (`brew install imagemagick`)
- librsvg (`brew install librsvg`)

Once everything is installed, you're ready to go!  

1. Create a `512x512` monochrome SVG file and save it under `Create/Engravings`.
2. Double-click the `Create.command` file (or run it with `bash Create.command`).

If you're familiar with the command line, you can create individual images like so:

```bash
bash generate.sh "Create/Templates/(Template)" "Create/Engravings/(Engraving).svg" "Icon.icns"
```


## DIY Pro Instructions

**If you want to build your own folder templates, you'll need to know how to use the ImageMagick command line to manipulate images.**

A template is a MacOS `.iconset` with an extra `imio.sh` file inside.
The `imio.sh` file is a bash script that contains functions used to create the embossed engraving and apply it to the template folder icons:

```bash
template_info() {
	echo "My First Template"
}

# This function will emboss the icon engraving.
#
# Input:
#   $1             -- The engraving image.
#   $ICON_HEIGHT   -- The icon height in pixels.
#   $ICON_WIDTH    -- The icon width in pixels.
#   $ICON_TYPE     -- The icon type (i.e. iconset suffix)
#   $ICON_VARIANT  -- The icon variant (e.g. '@1x' or '@2x')
# 
# Output:
#   The raw BMP-format image data for the embossed engraving.
#   You can use `bmp:-` as the ImageMagick output file for that.
template_emboss() {
	
	# This command will turn the engraving red.
	# More advanced commands will be needed to create an emboss effect.
	magick convert "$1" \( -clone 0 -fill '#ff0000' -colorize 100 \) \
		-background none -compose Src -flatten \
		bmp:-
	
}

# This function will combine the engraving and the template folder icon.
# 
# Input:
#   $1             -- The engraving image.
#   $ICON_HEIGHT   -- The icon height in pixels.
#   $ICON_WIDTH    -- The icon width in pixels.
#   $ICON_TYPE     -- The icon type (i.e. iconset suffix)
#   $ICON_VARIANT  -- The icon variant (e.g. '@1x' or '@2x')
# 
# Output:
#   The raw PNG-format image data for the combined image.
#   You can use `png:-` as the ImageMagick output file for that.
template_combine() {
	
	# Find the best placement geometry for the icon size.
	# The following values are for Big Sur.
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
	
	# Composite the images.
	magick composite -gravity Center \
	    -compose ATop \
	    -geometry "$geom" \
	    "$1" "$2" \
	    png:-
}
```
