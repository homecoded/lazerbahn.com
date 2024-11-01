% TITLE (DEV-TIP) Optimize a large amount of images on the command line.
% DESCRIPTION An oneliner can be used to easily optimize large image data on the command line.
% DATE 24.8.2022

[<< Back to Overview](../blog.html)

# Optimize a large amount of images on the command line. 

> How do I find large files on the command line under Linux?

With the command "find" not only files can be found by their name, but also by other
characteristics:

    # Find all ".jpg" files larger than 1 megabyte
    find ./foldername -name "*.jpg" -size +1M

This command finds all files in a directory and its subdirectories, which are
are larger than 1 megabyte.

> How can I resize large image files?

Most Linux systems have ImageMagick already installed. If not,

    sudo apt install imagemagick

will install it (if we have a system with apt support). The following command
resizes a file to a maximum edge length (1200px in the example):

    convert -resize "1200>" test.jpg

Combining both results in:

    find ./foldername -name "*.jpg" -size +1M | xargs convert -resize "1200>"

