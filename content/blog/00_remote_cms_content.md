% TITLE (DEV-TIP) Magento development environment: Reload images from CMS and products from remote server.
% DESCRIPTION In the local development environment, all images from the live environment are usually missing. With a small hack you can solve this problem.
% DATE 4.11.2021

# Download Missing Images in Magento Development Environment On-The-Fly

One common problem that we, software developers, often encounter is that our local 
development environment is missing some important assets.  
This can be especially frustrating when working with a team, as each person's local 
environment may look slightly different.

One solution to this problem is to simply load the assets on-the-fly from the live system. 
This means that we configure our development environment to fetch 
the assets from the live site when they are needed. We store them in the appropriate 
folder structure for later use. This ensures that we are always working with the most 
up-to-date visuals and can be confident that the site looks the same locally und on 
live/staging.

## Downloading CMS content

To reload images that are not locally available adhoc from a live system, we 
make the following adjustments in our code:

In `magento_root/pub/get.php` we look for the comment `//Serve file if it's materialized`. 
Shortly after that you'll find the variable initialization of `$fileRelativePath`. 
Immediately after this initialization (currently in Magento 2.4.7 this is
line 59) we insert the following snippet:

    $remoteServerUrl = 'https://example.com/'; 
    if (!is_readable($fileAbsolutePath)) {
        $remoteFile = file_get_contents($remoteServerUrl . $relativePath);
        mkdir(dirname($fileAbsolutePath), 0755, true);
        file_put_contents($fileAbsolutePath, $remoteFile);
    }

We have to replace the variable value of `$remoteServerUrl` with the URL of the live server, of course.

Now your local system simply loads missing files from the live system if they are not
available locally.

> *Attention:*
>
> - The files are stored locally and downloaded only once. So the impact on the remote server is minimal. 
> - Yet, this could fill your hard disk, eventually.
> - Also: This change MUST NOT be commited or pushed, if the `get.php` is managed in the version control system!

## Downloading product images

Product images can be downloaded in bulk using a shell script. We place this script in the folder `magento_root/pub/`.
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
URLs, we have to adjust the two constants `LOCAL_URL` and `REMOTE_URL` in the upper part of the file.
To run it, we have to start a shell in the Magento host system (local or container). In the target directory, we simply 
run:

    cd magento_root/pub/
    php downloadProductImages.php

> *Attention:*
>
> - It may happen that very many and large files are downloaded in the process. The hard disk space can become scarce.
> - This file should in no case be commited/pushed into the version control system or even rolled out on a live system! 

Happy coding,
Manuel
