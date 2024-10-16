% TITLE (DEV-TIP) CLI-Script for creating Sitemap XML
% DESCRIPTION How to create  Magento sitemap programmatically: The Magento2 sitemap can only be created through cron-jobs. I wrote a little script that makes it possible to start sitemap creation at will, which is very useful for debugging.   
% DATE 15.10.2024

# How to create Magento2 sitemap programmatically

I need to write a filter function for the sitemap for one of my clients. They are using a "private catalog" extension
that hides certain parts of a store for certain customer groups. Unfortunately, that extension does not adapt 
Magento's sitemap-creation functionality. All products are in the sitemap regardless of visibility.

To properly test any changes I do the sitemap creation, I need something to conveniently trigger it. For this I use
this little script

    <?php
    // create-sitemap.php
    use Magento\Framework\App\Bootstrap;
    include('app/bootstrap.php');
    
    $bootstrap = Bootstrap::create(BP, $_SERVER);
    
    $objectManager = $bootstrap->getObjectManager();
    $state = $objectManager->get('Magento\Framework\App\State');
    $state->setAreaCode('frontend');
    
    $objectManager = \Magento\Framework\App\ObjectManager::getInstance();
    
    $sitemap = $objectManager->create('Magento\Sitemap\Model\Sitemap');
    $sitemap->setSitemapFilename('debug-sitemap.xml');
    $sitemap->generateXml();

Put this script inside the Magento root folder and run it like this:

    php create-sitemap.php

This will trigger the sitemap generation immediately.

Happy coding,
Manuel
