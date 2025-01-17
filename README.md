# Comic Book Image Processor

## Description
This Bash script is designed to extract images from .cbr or .cbz files (popular comic book archive formats). Depending on your choice, it can either stack the images vertically using ImageMagick's `convert` command and output the final combined image as a .jpg or .png file, or generate an HTML file to view the images (also vertically) in a web browser.

This script can process either a single .cbr/.cbz file or an entire directory of them, making it a convenient tool for comic book readers and digital archivists. The script also provides the option to specify an output directory for the combined images or the HTML files.

## Purpose
Comic book archive files are essentially a collection of image files (pages of the comic) compressed into a single file. While there are many dedicated readers for these file types, sometimes users may want to convert these archives into a single image file or an HTML file for easier viewing or for use in other applications.

This script automates that process, handling the extraction, conversion, and cleanup operations automatically. By providing options for the input and output directories as well as the output format, the script offers a flexible solution for users dealing with comic book archives.

## Usage
To use the script, you will need to have the following installed on your system:

- ImageMagick (only required for png/jpeg output format)
- `unar` utility

On macOS, the requirements can be installed using `brew`:
```
brew install unar imagemagick
```

Once these requirements are satisfied, you can run the script from your terminal as follows:

```
./convert.sh <output_format> <input_directory_or_file> [output_directory]
```

- `<output_format>`: This argument is mandatory. Specify the format of the output. It can be either 'jpg', 'png', or 'html'.
- `<input_directory_or_file>`: This argument is mandatory. Specify the .cbr/.cbz file or directory containing .cbr/.cbz files that you want to process.
- `[output_directory]`: This argument is optional. Specify the directory where you want to save the combined images or HTML files. If not provided, the script will use the current directory.

Example usage:

```
./convert.sh jpg my_comics
```

In this example, the script will process all .cbr/.cbz files in the 'my_comics' directory and output the combined images as .jpg files in the current directory.

```
./convert.sh png my_comic.cbr output_directory
```

In this example, the script will process the 'my_comic.cbr' file and output the combined image as a .png file in the 'output_directory'.

```
./convert.sh html my_comic.cbz output_directory
```

In this example, the script will process the 'my_comic.cbz' file and output the HTML file in the 'output_directory'.

### HTML

You can view the generated HTML either by opening the html files in your browser or by setting up an nginx server to serve the files.
A Dockerfile is provided with the necessary nginx config to serve the files - just build it using the following command.
```
docker build -t nginx-dir .
```
Then subsequently use the image, by replacing `output_directory` with the path used above when converting:
```
docker run --name cbz-viewer -v 'output_directory:/usr/share/nginx/html:ro' -d -p 8080:80 nginx-dir
```


## Note
Please be aware that the script removes the temporary directories it creates during the extraction process, whether it finishes successfully, fails, or is interrupted. Make sure you do not manually use the same directories it uses for extraction, or your data could be lost.

Also, due to the nature of the operations it performs, the script might take a significant amount of time to process large .cbr/.cbz files or directories containing many such files.

JPEG has a maximum image size of 65,535×65,535 pixels. If your combined comic book pages exceed this size, consider using the PNG or HTML format instead.

## Troubleshooting
If you encounter any problems while using the script, please make sure that you have all the required software installed and that the paths you're providing do not contain any unusual or non-ASCII characters. If you continue to have issues, consider opening an issue with a detailed description of the problem and the exact error messages you're seeing.

## Credits
This script and accompanying documentation were generated with the help of ChatGPT-4, an advanced AI model developed by OpenAI.
