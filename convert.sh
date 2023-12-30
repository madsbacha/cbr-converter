#!/bin/bash

set -e

function cleanup() {
    rm -rf "$uncompress_dir"
}

function process_file() {
    local file="$1"
    local extension="${file##*.}"
    local base_name="$(basename "$file" ."$extension")"
    local uncompress_dir_img="${base_name}_uncompress"
    local uncompress_dir_html="$output_dir/${base_name}"
    local html_file="$output_dir/${base_name}/index.html"
    local final_image="$output_dir/${base_name}.$output_format"

    local uncompress_dir="$uncompress_dir_img"
    if [[ "$output_format" == "html" ]]; then
        uncompress_dir="$uncompress_dir_html"
    fi

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
    done < <(find "$uncompress_dir" \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0 | sort -g)

    # Check if images were found
    if [[ ${#images[@]} -eq 0 ]]; then
        printf "No images found in file %s. Skipping...\n" "$file"
        cleanup
        return
    fi

    if [[ "$output_format" == "html" ]]; then
        # Prepare images for HTML
        images_html=""
        for img in "${images[@]}"; do
            # Escape any special characters in the uncompress_dir
            escaped_uncompress_dir=$(printf '%s\n' "$uncompress_dir" | sed 's:[\\/\.\^\$\*\(\)]:\\&:g')
            # Get the relative path to the image
            relative_img_path=$(echo "$img" | perl -pe "s#^$escaped_uncompress_dir/##")
            # Replace / with \/ for compatibility with sed command
            escaped_img=${relative_img_path//\//\\/}
            images_html+="<img src=\"$escaped_img\">"
        done
        # Replace placeholder in template with images
        sed "s/{{images}}/$images_html/g" template.html > "$html_file"
        printf "HTML folder has been created: %s\n" "$uncompress_dir"
    else
        # Convert/stack images
        if ! convert "${images[@]}" -append "$final_image"; then
            printf "Failed to convert images from file %s. Skipping...\n" "$file"
            cleanup
            return
        fi
        printf "Final image has been created: %s\n" "$final_image"
        cleanup
    fi
}

# Check if the output_format and directory/file name are provided
if [[ "$#" -lt 2 ]]; then
    printf "Usage: %s output_format directory_or_file [output_directory]\n" "$0"
    exit 1
fi

output_format="$1"  # Make output_format the first argument
path="$2"
output_dir="${3:-.}"  # Use current directory as default

# Check if output format is valid
if [[ "$output_format" != "jpg" && "$output_format" != "png" && "$output_format" != "html" ]]; then
    printf "Invalid output format %s. Use 'jpg', 'png' or 'html'.\n" "$output_format"
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
