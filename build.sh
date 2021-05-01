#!/bin/bash
cd "$(dirname "$0")"

__notify () {
    echo " "
    echo "+-------------------------------------------------------------------+"
    echo "# $1"
    echo "+-------------------------------------------------------------------+"
}

__clearPub () {
    __notify "Clear up build folder"
    rm -rf pub/*
}

__prepareContent () {
    __notify "Building content ..."
    for file in content/* ; do
        if [ -d "$file" ]; then
            continue
        fi

        filename=${file//\.md}
        filename=${filename//content\/}
        echo "    > $filename"
        pandoc -B source/header.html -A source/footer.html -o "pub/$filename.html" "$file"
    done

    cp source/index.html pub/index.html
}

__prepareImages () {
    __notify "Preparing images assets ..."
    cp -r source/images pub
    echo "    > Optimize PNGs"
    find pub/images -name '*.png' | xargs optipng
    echo "    > Optimize JPGs"
    find pub/images -name '*.jpg' | xargs jpegoptim
}

__prepareFonts () {
    __notify "Preparing font assets ..."
    cp -r source/fonts pub
}

__prepareCSS () {
    __notify "Preparing CSS assets ..."
    echo "    > merge CSS files"
    mkdir pub/css
    ls -v source/css/*.css | xargs cat >> pub/css/styles.css
    echo "    > minify css"
    yui-compressor pub/css/styles.css -o  pub/css/styles.min.css
}

__prepareJS () {
    __notify "Preparing JS assets ..."
    echo "    > merge JS files"
    mkdir pub/js
    ls -v source/js/*.js | xargs cat >> pub/js/scripts.js

    if [ "$1" == "debug" ]; then
       cp pub/js/scripts.js pub/js/scripts.min.js
       echo "    > skip minify js"
    else
        echo "    > minify js"
        closure-compiler --accept_const_keyword  --language_in ECMASCRIPT5 --js pub/js/scripts.js --js_output_file pub/js/scripts.compiled.js
        regpack pub/js/scripts.compiled.js > pub/js/scripts.min.js
    fi
}

__clearPub
__prepareContent
__prepareImages
__prepareFonts
__prepareCSS
__prepareJS $1
