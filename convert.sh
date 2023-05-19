#!/bin/bash

set -e

function cleanup() {
    rm -rf "$uncompress_dir"
}

function process_file() {
    local file="$1"
    local extension="${file##*.}"
    local base_name="$(basename "$file" ."$extension")"
    local uncompress_dir="${base_name}_uncompress"
    local final_image="$output_dir/${base_name}.$output_format"

    trap cleanup EXIT  # Ensures cleanup happens on script exit

    # Create directory to extract the files
    mkdir -p "$uncompress_dir"

    # Extract the cbr or cbz file
    if [[ "$extension" == "cbr" || "$extension" == "cbz" ]]; then
        if ! unar -o "$uncompress_dir" "$file"; then
            printf "Failed to extract file %s. Skipping...\n" "$file"
            cleanup
            return
        fi
    else
        printf "Unknown file extension for file %s. Use .cbr or .cbz files. Skipping...\n" "$file"
        cleanup
        return
    fi

    # Create an array with found image files
    images=()
    while IFS=  read -r -d $'\0'; do
        images+=("$REPLY")
    done < <(find "$uncompress_dir" \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0 | sort -z)

    # Check if images were found
    if [[ ${#images[@]} -eq 0 ]]; then
        printf "No images found in file %s. Skipping...\n" "$file"
        cleanup
        return
    fi


    # Convert/stack images
    if ! convert "${images[@]}" -append "$final_image"; then
        printf "Failed to convert images from file %s. Skipping...\n" "$file"
        cleanup
        return
    fi

    cleanup

    printf "Final image has been created: %s\n" "$final_image"
}

# Check if the directory/file name is provided
if [[ "$#" -lt 1 ]]; then
    printf "Usage: %s directory_or_file [output_directory] [output_format]\n" "$0"
    exit 1
fi

path="$1"
output_dir="${2:-.}"  # Use current directory as default
output_format="${3:-jpg}"  # Use jpg as default output format

# Check if output format is valid
if [[ "$output_format" != "jpg" && "$output_format" != "png" ]]; then
    printf "Invalid output format %s. Use 'jpg' or 'png'.\n" "$output_format"
    exit 1
fi


# Check if output directory is valid
if [[ ! -d "$output_dir" ]]; then
    printf "The output path %s does not point to a valid directory.\n" "$output_dir"
    exit 1
fi


# Check if it's a directory or a file
if [[ -d "$path" ]]; then
    # It's a directory, process all .cbr and .cbz files in it
    for file in "$path"/*.{cbr,cbz}; do
        if [[ -f "$file" ]]; then  # Avoids issue when no files of a type exist
            process_file "$file"
        fi
    done
elif [[ -f "$path" ]]; then
    # It's a file, process it
    process_file "$path"
else
    printf "The path %s does not point to a valid file or directory.\n" "$path"
    exit 1
fi
