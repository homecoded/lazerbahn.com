#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# create array for files to clean up after building
declare -a filesToCleanUp

__notify () {
    echo " "
    echo "+-------------------------------------------------------------------+"
    echo "# $1"
    echo "+-------------------------------------------------------------------+"
}

__clearPub () {
    __notify "Clear up build folder ..."
    rm -rf pub/*
}

__prepareBlogNavigation () {
    __notify "Prapare blog navigation ..."

    echo "% TITLE Blog" > content/blog.md
    echo "% DESCRIPTION Übersicht über alle Blogposts in chronologischer Reihenfolge" >> content/blog.md

    cat content/blog/stubs/blog.md >> content/blog.md

    find content/blog -type f -print0 | xargs -0 ls -v | while read file
    do
        echo "blog post $file"
        title=$(__getMetaTagFromMarkdownFile $file "TITLE")
        description=$(__getMetaTagFromMarkdownFile $file "DESCRIPTION")
        date=$(__getMetaTagFromMarkdownFile $file "DATE")
        url=$(__getHtmlPathForMarkdownFile $file)

        echo "<div class=\"blog--entry\">" >> content/blog.md
        echo -e "### [ $title ]($url) \n" >> content/blog.md
        echo -e "$date\n" >> content/blog.md
        echo -e "$description\n" >> content/blog.md
        echo "</div>" >> content/blog.md
    done
    __addFileToCleanUpList "content/blog.md"
}

__getMetaTagFromMarkdownFile () {
    file=$1
    tag=$2
    title=$(grep "^\% $tag" "$file")
    title=$(echo "$title" | cut -d " " -f 3-255)
    echo $title
}

__getSlug () {
    title=$1
    # https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
    echo "$title" | sed -e 's/\Ä/\&Auml;/g' \
            -e 's/\ä/ae/g' \
            -e 's/\Ö/Oe/g' \
            -e 's/\ö/oe/g' \
            -e 's/\Ü/Ue/g' \
            -e 's/\ü/ue/g' \
            -e 's/\ß/ss/g' \
        | iconv -f utf-8 -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z
}

__addFileToCleanUpList () {
    filesToCleanUp+=($1)
}

__getHtmlPathForMarkdownFile () {
    file=$1
    filename=${file//\.md}
    filename=${filename//content\/}
    title=$(__getMetaTagFromMarkdownFile "$file" "TITLE")
    slug=$(__getSlug "$title")

    targetFilename="$filename.html"
    targetDirectory=$(dirname $targetFilename)
    targetFilename="$targetDirectory/$slug.html"
    echo $targetFilename
}

__prepareContent () {
    __notify "Building content ..."
    for file in $(find content -name "*.md" ) ; do
        if [ -d "$file" ]; then
            continue
        fi
        echo "    > ## $file"
        targetFilename="pub/$(__getHtmlPathForMarkdownFile $file)"
        targetDirectory=$(dirname $targetFilename)
        mkdir -p $targetDirectory

        if [ $(basename "$targetFilename") = ".html" ]; then
            echo "       > skipped. META tags missing!"
            continue
        fi
        echo "    > -> $targetFilename"
        filename=$(__getSlug $file)

        pandoc --output "pub/$filename-fragment.html" "$file"
        cat source/header.html > "$targetFilename"
        cat "pub/$filename-fragment.html" >> $targetFilename
        cat source/footer.html >> $targetFilename
        __addFileToCleanUpList "pub/$filename-fragment.html"
        __updateMetaTagsInHtmlFile "$file" "$targetFilename"
        __setCanonicalLink "$targetFilename"
    done

    # copy static files
    cp source/index.html pub/index.html
    cp source/robots.txt pub/robots.txt
    cp source/favicon.ico pub/favicon.ico
}

__setCanonicalLink () {
  htmlFile="$1"
  echo "        > updating CANONCAL link in $htmlFile"
  url=$(echo "$htmlFile" | sed -e "s/pub\///g")
  echo $url
  url=$(echo "$url" | sed -e "s/\.\///g")
  echo $url
  escapedHTML=$(printf '%s\n' "$url" | sed -e 's/[]\/$*.^[]/\\&/g');
  sed -i -e "s/#FILE_PATH#/$escapedHTML/" "$htmlFile"
}

__updateMetaTagsInHtmlFile () {
    markdownFile="$1"
    htmlFile="$2"
    echo "        > updating META tags in $htmlFile"
    grep '^\%' "$markdownFile" | while IFS= read -r line ;
    do
        metaTagName=$(echo "$line" | cut -d " " -f 2)
        metaTagValue=$(echo "$line" | cut -d " " -f 3-255)

        sed -i -e "s/#$metaTagName#/$metaTagValue/" "$htmlFile"
    done
}

__prepareAssetVersioning () {
    __notify "Do version stamping ..."
    for f in $(find pub/ -name '*.html');
    do
        echo "$f";
        sed -i -e "s/#VERSION#/$(date '+%Y%m%d%H%M%S')/" "$f"
    done
}

__prepareImages () {
    __notify "Preparing images assets ..."
    cp -r source/images pub
    echo "    > Optimize PNGs"
    find pub/images -name '*.png' | xargs optipng -o7 | true
    echo "    > Optimize JPGs"
    find pub/images -name '*.jpg' | xargs jpegoptim --strip-all -m76 || true
}

__prepareFonts () {
    __notify "Preparing font assets ..."
    cp -r source/fonts pub
}

__prepareCSS () {
    __notify "Preparing CSS assets ..."
    echo "    > merge CSS files"
    mkdir -p pub/css
    rm -rf pub/css/styles.css
    ls -v source/css/*.css | xargs cat >> pub/css/styles.css
    echo "    > minify css"
    uglifycss pub/css/styles.css > pub/css/styles.min.css
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
        echo "         > closure compiler"
        closure-compiler --accept_const_keyword  --language_in ECMASCRIPT5 --js pub/js/scripts.js --js_output_file pub/js/scripts.closured.js
        echo "         > regpack"
        regpack pub/js/scripts.closured.js > pub/js/scripts.min.js

        # clean up intermediate files
        __addFileToCleanUpList "pub/js/scripts.closured.js"
    fi
}

__prepareHtaccess () {
    cp source/.htaccess pub
}

__cleanUpFiles () {
    __notify "Cleaning up temporary files"

    echo "    > Deleting files ... "
    echo -ne "      "
    for file in "${filesToCleanUp[@]}";
    do
        echo -ne "#"
        rm $file
    done
    echo ""
    echo "    > ${#filesToCleanUp[@]} files deleted."
}

echo "build.sh: Command line options"
echo ""
echo " build.sh debug           creates debug build of the js"
echo " build.sh css-only        compile only css"
echo " build.sh content-only    compile only content"

if [ "$1" == "css-only" ]; then
    __prepareCSS
    __cleanUpFiles
    exit 0
fi

if [ "$1" == "content-only" ]; then
    __prepareBlogNavigation
    __prepareContent
    __prepareAssetVersioning
    __cleanUpFiles
    exit 0
fi

__clearPub
__prepareBlogNavigation
__prepareContent
__prepareAssetVersioning
__prepareImages
__prepareFonts
__prepareCSS
__prepareJS $1
__prepareHtaccess
__cleanUpFiles

