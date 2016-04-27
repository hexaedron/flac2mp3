#!/bin/bash

# Paths to binaries
LAME=lame
FLAC=flac
METAFLAC=metaflac

date

# Default LAME options.
# This is perfectly enough for me
DEFAULT_LAME_OPTS="--replaygain-accurate -q 0 --vbr-new -V 0 -b 56 -B 256"

# Let's parse medatada and make options for LAME
function get_id3_opts()
{
   flac_file="$1"

    $METAFLAC --export-tags-to - "$flac_file" | while read -d $'\n' tag; do
    tag_name=$(echo "$tag" | awk -F= '{ print $1 }')
    tag_value=$(echo "$tag" | awk -F= '{ print $2 }' | sed 's/"/\\"/g')

   case "$tag_name" in
      TITLE)
         echo -n "--tt \"$tag_value\" "
            ;;
      ARTIST)
         echo -n "--ta \"$tag_value\" "
            ;;
      ALBUM)
         echo -n "--tl \"$tag_value\" "
            ;;
      GENRE)
         echo -n "--tg \"$tag_value\" "
            ;;
      DATE)
            echo -n "--ty \"$tag_value\" "
            ;;
      TRACKNUMBER)
         echo -n "--tn \"$tag_value\" "
            ;;
   esac
 done
}

# Create the directories and make file name
function make_mp3_file_name()
{
   input_dir=$1
   output_dir=$2
   flac_file=$3

   album_dir=$(basename "$input_dir")
   mp3_file=${flac_file/%flac/mp3}
   mp3_file=${mp3_file/#${input_dir}/${output_dir}/${album_dir}/}
   mp3_dir=$(dirname "$mp3_file")
   $(mkdir -p "$mp3_dir")

   echo "$mp3_file"
}

# Recoursively convert FLAC files
# from input_dir to output_dir.
# output_dir is created automatically.
function main()
{
   input_dir=$1
   output_dir=$2
   lame_opts=$3

   if [[ -z "$input_dir" || -z "$output_dir" ]]; then
      echo "Usage: $0 <input_dir> <output_dir> [lame_opts]"
      echo "Example: $0 /tmp/my/flac/albums /tmp/my/mp3 \"-b 320 -h\""
      exit 1
   fi

   if [[ -z "$lame_opts" ]]; then
      lame_opts=$DEFAULT_LAME_OPTS
   fi

   OIFS=$IFS; IFS=$'\n'

   # Recoursive processing of FLAC files
   for flac_file in $(find "$input_dir" -name "*.flac" | sort); do
      flac_base=`basename "$flac_file"`
      echo "Processing '$flac_base'..."

      id3_opts=$(get_id3_opts "$flac_file")
      mp3_file=$(make_mp3_file_name "$input_dir" "$output_dir" "$flac_file")
      cmd="$FLAC -sdc \"$flac_file\" | $LAME --quiet $lame_opts $id3_opts - \"$mp3_file\""

      eval $cmd
   done
}

main "$@"

date
