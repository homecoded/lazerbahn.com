% TITLE (DEV-TIP) Magento development environment: Reload images from CMS and products from remote server.
% DESCRIPTION In the local development environment, all images from the live environment are usually missing. With a small hack you can solve this problem.
% DATE 4.11.2021

# Download Missing Images in Magento On-The-Fly

One common problem that software developers may encounter when working on a website 
or web application is that their local development environment may not have all of the 
assets, such as images, that are needed to properly render the site. 
This can be especially frustrating when working with a team, as each person's local 
environment may be slightly different and may not have all of the necessary assets.

One solution to this problem is to load the assets on-the-fly from the live system. 
This means that the developer can configure their development environment to fetch 
the assets from the live site when the are needed and store them in the appropriate 
folder structure. This ensures that the developer is always working with the most 
up-to-date visuals and can be confident that their code will work as intended when 
it is deployed to the live site.

## Downloading CMS content

To reload images that are not locally available adhoc from a live system, you need 
to make the following adjustment in your code:

In `magento_root/pub/get.php` we look for the comment `//Serve file if it's materialized`. 
Shortly after that you'll find the variable initialization of `$fileRelativePath`. 
Immediately after this initialization (currently in Magento 2.4.3 this is
line 48) we insert the following snippet:

    $remoteServerUrl = 'https://example.com/'; 
    if (!is_readable($fileAbsolutePath)) {
        $remoteFile = file_get_contents($remoteServerUrl . $relativePath);
        mkdir(dirname($fileAbsolutePath), 0755, true);
        file_put_contents($fileAbsolutePath, $remoteFile);
    }

You have to replace the variable value of `$remoteServerUrl` with the URL of the live server.

Now your local system simply loads missing files from the live system if they are not
available locally.

> *Attention:*
>
> - The files are stored locally and downloaded only once. This relieves the live system. but could fill your hard disk in the long run.
> - This change must not be checked in, if the `get.php` is managed in the version control system!

## Downloading product images

Product images can be downloaded in bulk using a shell script. This script must be placed in the folder `magento_root/pub/`.
folder. Replace LOCAL_URL and REMOTE_URL accordingly.

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

This script automatically downloads all product images from all activated products. So that it can work with the correct
URLs, the two constants `LOCAL_URL` and `REMOTE_URL` must be adjusted in the upper part of the file.
To run it, you have to log in to a shell in the Magento host system. The script should be executed directly in the target
directory:

    cd magento_root/pub/
    php downloadProductImages.php

> *Attention:*
>
> - It may happen that very many and large files are downloaded in the process. The hard disk space can become scarce.
> - This file should in no case be checked into the version control system or even rolled out on a live system! 
