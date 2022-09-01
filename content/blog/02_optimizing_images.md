% TITLE (DEV-TIPP) Eine große Menge an Bildern auf der Kommandozeile optimieren
% DESCRIPTION Mit einem Oneliner kann man große Bild-Daten leicht auf der Kommandozeile optimieren. 
% DATE 24.8.2022

> Wie finde ich große Dateien unter Linux auf der Kommandozeile?

Mit dem Befehl "find" können nicht nur Dateien anhand ihres Namens, sondern auch anhand anderer
Merkmale gefunden werden:

    # Suche alle ".jpg-Dateien, die größer als 1 Megabyte sind
    find ./foldername -name "*.jpg" -size +1M

Dieser Befehl findet alle Dateien in einem Verzeichnis und dessen Unterverzeichnissen, die 
größer als 1 Megabyte sind.

> Wie kann ich große Bildaten verkleinern?

Die meisten Linux-Systeme haben ImageMagick bereits installiert. Wenn nicht, 

    sudo apt install imagemagick

installiert es (sofern wir ein System mit apt-Unterstütung vorliegen haben). Folgender Befehl
verkleinert eine Datei auf eine maximale Kantenlänge (im Beispiel 1200px):  

    convert -resize "1200>" test.jpg

Beides zusammen kombiniert ergibt:

    find ./foldername -name "*.jpg" -size +1M | xargs convert -resize "1200>"

