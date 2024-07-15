Fehler:

    error: patch failed: vendor/tubalmartin/cssmin/src/Minifier.php:298
    error: vendor/tubalmartin/cssmin/src/Minifier.php: patch does not apply


aber 

        git apply --reject --whitespace=fix

geht


    diff -Naur oldfile newfile

und dann links anpassen. Nicht im PHPStorm aufmachen!
