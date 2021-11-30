% TITLE (DEV-TIPP) Magento-Entwicklungsumgebung: Bilder aus CMS-Content von Remote-Server nachladen.
% DESCRIPTION In der lokalen Entwicklungsumgebung fehlen in der Regel alle Bilder aus der Live-Umgebung. Mit einem kleinen Hack kann man dieses Problem lösen.
% DATE 4.11.2021

# Trick zum Nachladen von Bild-Inhalten in Magento

## Bilder aus dem CMS

In einem lokalen Magento-Entwicklungssystem fehlen oft die gesamten Bildinhalte. Das macht die Weiterentwicklung 
schwierig, da alles anders aussieht als im Live-System. Um dieses Problem zu lösen, habe ich mir zwei kleine
Hacks einfallen lassen:

Um Bilder, die lokal nicht vorhanden sind, adhoc von einem Live-System nachzulanden, musst Du folgende 
Anpassung in deinem Code machen:

In `magento_root/pub/get.php` suchen wir nach dem Kommentar `// Serve file if it's materialized`. Kurz danach wird
die Variable `$fileRelativePath` initialisiert. Unmittelbar nach dieser Initialisierung (aktuell in Magento 2.4.3 ist das
Zeile 48) fügen wir folgendes Snippet ein:

    $remoteServerUrl = 'https://example.com/'; 
    if (!is_readable($fileAbsolutePath)) {
        $remoteFile = file_get_contents($remoteServerUrl . $relativePath);
        mkdir(dirname($fileAbsolutePath), 0755, true);
        file_put_contents($fileAbsolutePath, $remoteFile);
    }

Die Variable `$remoteServerUrl` muss Du mit der URL des Live-Servers ersetzen.

Nun lädt Dein lokales System fehlende Files einfach aus dem Live-System nach, wenn diese nicht lokal vorhanden sind.

> *Achtung:*
> 
> - Die Dateien werden lokal gespeichert und nur einmal heruntergelanden. Das entlastet das Live-System. könnte aber auf Dauer deine Festplatte füllen.
> - Diese Änderung darf, sofern die `get.php` im Versionskontrollsystem verwaltet wird, nicht eingecheckt werden!

## Produktbilder

Produktbilder können im Bulk mit einem Shell-Script heruntergeladen werden. Dieses Script muss im Ordner `magento_root/pub/`
abgelegt werden.

    // downloadProductImages.php
    // file: get product images
    <?php
    use Magento\Framework\App\Bootstrap;
    
    const LOCAL_URL = 'http://localhost';
    const REMOTE_URL = 'https://www.example.com';
     
    
    
    include('../app/bootstrap.php');
    
    $bootstrap = Bootstrap::create(BP, $_SERVER);
    
    $objectManager = $bootstrap->getObjectManager();
    $state = $objectManager->get('Magento\Framework\App\State');
    $state->setAreaCode('frontend');
    
    $objectManager = \Magento\Framework\App\ObjectManager::getInstance(); // instance of object manager
    
    // dependencies
    $productCollectionFactory = $objectManager->create('Magento\Catalog\Model\ResourceModel\Product\CollectionFactory');
    $fileSystem = $objectManager->create('\Magento\Framework\Filesystem');
    
    // product data
    $collection = $productCollectionFactory->create();
    $collection->addAttributeToFilter('status',\Magento\Catalog\Model\Product\Attribute\Source\Status::STATUS_ENABLED);
    $collection->addMediaGalleryData();
    
    $count = count($collection->getItems());
    
    echo "*****************************************" . PHP_EOL;
    echo "Getting missing images of $count products"  . PHP_EOL;
    echo "*****************************************"  . PHP_EOL;
    
    $counter = 0;
    /** @var \Magento\Catalog\Model\Product $product */
    
    $mediaPath = $fileSystem->getDirectoryRead(\Magento\Framework\App\Filesystem\DirectoryList::PUB)->getAbsolutePath();
    
    foreach ($collection->getItems() as $product) {
        $images = $product->getMediaGalleryImages();
    
        foreach ($images as $image) {
            $localUrl = $image->getUrl();
            $relativePath = str_replace(LOCAL_URL, '', $localUrl);
            $remoteServerUrl = REMOTE_URL . $relativePath;
            $fileAbsolutePath = $mediaPath . ltrim($relativePath, '/');
    
            if (!is_readable($fileAbsolutePath)) {
                echo "    downloading $relativePath" . PHP_EOL;
                $remoteFile = file_get_contents($remoteServerUrl);
                if (!is_dir(dirname($fileAbsolutePath))) {
                    mkdir(dirname($fileAbsolutePath), 0755, true);
                }
                file_put_contents($fileAbsolutePath, $remoteFile);
            }
        }
    
        $counter++;
        echo "$counter / $count " . PHP_EOL ;
    }

Dieses Script lädt automatisch alle Produktbilder von allen aktivierten Produkten herunter. Damit es mit den richtigen 
URLs arbeiten kann, muss im oberen Teil der Datei die beiden Konstanten `LOCAL_URL` und `REMOTE_URL` angepasst werden.
Zum Ausführen muss man sich auf einer Shell im Magento-Host-System einloggen. Das Script sollte direkt im Ziel-
Verzeichnis ausgeführt werden:

    cd magento_root/pub/
    php downloadProductImages.php

> *Achtung:*
>
> - Es kann passieren, dass hierbei sehr viele und große Dateien heruntergeladen werden. Der Festplattenspeicher kann knapp werden.
> - Diese Datei sollte auf keinen Fall in das Versionskontrollsystem eingecheckt werden oder sogar auf einem Live-System ausgerollt werden! 