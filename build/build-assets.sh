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

    total=$(ls content/blog/*.md | wc -l)
    kinds=$(for file in content/blog/*.md; do __getPostKind "$file"; done | sort -u)

    echo '<div class="blog-filter" hidden>' >> content/blog.md
    echo '<fieldset class="speed"><legend class="label">Type</legend>' >> content/blog.md
    echo '<label><input type="radio" name="kind" value="" checked><span>All</span></label>' >> content/blog.md
    for kind in $kinds
    do
        echo "<label><input type=\"radio\" name=\"kind\" value=\"$kind\"><span>$kind</span></label>" >> content/blog.md
    done
    echo '</fieldset>' >> content/blog.md
    echo '</div>' >> content/blog.md

    echo '<table class="parts__table blog-index">' >> content/blog.md
    echo '<thead><tr><th scope="col">No.</th><th scope="col">Date</th><th scope="col">Title</th></tr></thead>' >> content/blog.md
    echo '<tbody>' >> content/blog.md
    sheet=$total
    __sortedBlogPosts | while read file
    do
        echo "blog post $file"
        title=$(__getPostTitle "$file")
        kind=$(__getPostKind "$file")
        description=$(__getMetaTagFromMarkdownFile "$file" "DESCRIPTION" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g')
        date=$(__getPostDate "$file")
        updated=$(__getPostUpdated "$file")
        url=$(__getHtmlPathForMarkdownFile "$file")
        dateHtml="$date"
        if [ -n "$updated" ]; then
            dateHtml="$date <span class=\"parts__upd\">upd. $updated</span>"
        fi
        printf '<tr data-kind="%s"><td class="parts__pos">%02d</td><td class="parts__date">%s</td><td><a href="/%s">%s</a> <span class="parts__kind">%s</span><span class="blog-index__desc">%s</span></td></tr>\n' \
            "$kind" "$sheet" "$dateHtml" "$url" "$title" "$kind" "$description" >> content/blog.md
        sheet=$((sheet - 1))
    done
    echo '</tbody>' >> content/blog.md
    echo '</table>' >> content/blog.md
    __addFileToCleanUpList "content/blog.md"
}

# all blog posts, newest publication date first (first date in "% DATE dd.mm.yyyy ...")
__sortedBlogPosts () {
    for file in content/blog/*.md
    do
        __getPostDate "$file" | awk -F. -v f="$file" '{ printf "%04d%02d%02d %s\n", $3, $2, $1, f }'
    done | sort -r | cut -d " " -f 2-
}

# "(DEV-TIP) Some title" -> "DEV-TIP"
__getPostKind () {
    __getMetaTagFromMarkdownFile "$1" "TITLE" | sed -n -e 's/^(\([^)]*\)).*/\1/p'
}

# "(DEV-TIP) Some title" -> "Some title", HTML-escaped, with break hints in long identifiers
__getPostTitle () {
    __getMetaTagFromMarkdownFile "$1" "TITLE" | sed -e 's/^([^)]*) *//' -e 's/&/\&amp;/g' -e 's/</\&lt;/g' \
        -e 's/\([a-z]\)\([A-Z]\)/\1<wbr>\2/g' -e 's/\.\([A-Za-z]\)/.<wbr>\1/g'
}

# "29.10.2024 - update: 11.11.2025" -> "29.10.2024"
__getPostDate () {
    __getMetaTagFromMarkdownFile "$1" "DATE" | cut -d " " -f 1
}

# "29.10.2024 - update: 11.11.2025" -> "11.11.2025"
__getPostUpdated () {
    __getMetaTagFromMarkdownFile "$1" "DATE" | sed -n -e 's/.*update: *\([0-9.]*\).*/\1/p'
}

# turn a built post into a drawing sheet (title block, contents, code details)
__enhanceBlogPost () {
    file="$1"
    htmlFile="$2"
    total=$(ls content/blog/*.md | wc -l)
    newestFirst=$(__sortedBlogPosts | grep -n -x "$file" | cut -d ":" -f 1)
    sheet=$((total - newestFirst + 1))
    node build/enhance-post.js "$htmlFile" "$(__getPostKind "$file")" "$(__getPostDate "$file")" \
        "$(__getPostUpdated "$file")" "$sheet" "$total"
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
        __setActiveNavigation "$targetFilename"
        case "$file" in
            content/blog/*.md) __enhanceBlogPost "$file" "$targetFilename" ;;
            content/blog.md) sed -i -e 's/<html lang="de">/<html lang="en">/' "$targetFilename" ;;
        esac
    done

    # copy static files
    cp source/index.html pub/index.html
    cp source/robots.txt pub/robots.txt
    cp source/favicon.ico pub/favicon.ico
}

__setActiveNavigation () {
  htmlFile="$1"
  current=' aria-current="page"'
  about=""
  blog=""
  case "$htmlFile" in
    pub/ueber-manuel-ruelke.html) about="$current" ;;
    pub/blog.html|pub/blog/*) blog="$current" ;;
  esac
  sed -i -e "s/#NAV_ABOUT#/$about/" -e "s/#NAV_BLOG#/$blog/" "$htmlFile"
}

__prepareLatestPosts () {
    __notify "Adding latest blog posts to start page ..."
    latestPosts=$(mktemp)
    position=1
    __sortedBlogPosts | head -n 5 | while read file
    do
        title=$(__getPostTitle "$file")
        kind=$(__getPostKind "$file")
        date=$(__getPostDate "$file")
        updated=$(__getPostUpdated "$file")
        url=$(__getHtmlPathForMarkdownFile "$file")
        if [ -n "$updated" ]; then
            date="$date <span class=\"parts__upd\">akt. $updated</span>"
        fi
        kindHtml=""
        if [ -n "$kind" ]; then
            kindHtml=" <span class=\"parts__kind\">$kind</span>"
        fi
        printf '          <tr><td class="parts__pos">%02d</td><td class="parts__date">%s</td><td><a href="/%s">%s</a>%s</td></tr>\n' \
            "$position" "$date" "$url" "$title" "$kindHtml" >> "$latestPosts"
        position=$((position + 1))
    done
    sed -i -e "/<!-- LATEST_POSTS -->/r $latestPosts" -e "/<!-- LATEST_POSTS -->/d" pub/index.html
    rm "$latestPosts"
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
        sed -i -e "s/#VERSION#/$(date '+%Y%m%d%H%M%S')/" -e "s/#BUILD_DATE#/$(date '+%d.%m.%Y')/" "$f"
    done
}

__prepareImages () {
    __notify "Preparing images assets ..."
    cp -r source/images pub
    # editor source files are not meant to be published
    rm -f pub/images/*.pspimage
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

    rm -rf pub/blog-drafts
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
    __prepareLatestPosts
    __prepareAssetVersioning
    __cleanUpFiles
    exit 0
fi

__clearPub
__prepareBlogNavigation
__prepareContent
__prepareLatestPosts
__prepareAssetVersioning
__prepareImages
__prepareFonts
__prepareCSS
__prepareJS $1
__prepareHtaccess
__cleanUpFiles

