% TITLE (DEV-TIPP) Debuggen von Racing-Conditions \/ Timing-Problemen beim Laden von Resourcen in Magento
% DESCRIPTION Mit einem Oneliner kann man große Bild-Daten leicht auf der Kommandozeile optimieren.
% DATE 24.8.2022

In der pub/static/.htaccess die folgenden Zeilen nach de <IfModule mod_rewrite.c> - Block einfügen:

<IfModule mod_rewrite.c>
    RewriteEngine On

    ## you can put here your pub/static folder path relative to web root
    #RewriteBase /magento/pub/static/

    # Remove signature of the static files that is used to overcome the browser cache
    RewriteRule ^version.+?/(.+)$ $1 [L]

    RewriteCond %{REQUEST_FILENAME} static/frontend/Dodenhof/anniversary/de_DE/jquery.js

    RewriteRule .* ../static.php?resource=$0 [L]
    # Detects if moxieplayer request with uri params and redirects to uri without params
    <Files moxieplayer.swf>
     	RewriteCond %{QUERY_STRING} !^$
     	RewriteRule ^(.*)$ %{REQUEST_URI}? [R=301,L]
     </Files>
</IfModule>
dann in der pub/static.php oben folgenden Zeilen einfügen

    [if ($_REQUEST['resource'] == 'frontend/Dodenhof/anniversary/de_DE/jquery.js') {
    sleep(2);
    }]()
Nun braucht jQuery so lange, dass das Plugin ohne Dependency-Info zu schnell ist. Der Fehler ist nun 100% nachstellbar.