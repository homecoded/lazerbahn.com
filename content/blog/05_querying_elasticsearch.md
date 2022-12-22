% TITLE (DEV-TIP) Verifying Data From an ElasticSearch Instance Working With Magento 2
% DESCRIPTION With a few simple curl calls in a bash, data can be extracted from an ElasticSearch instance.
% DATE 6.7.2022

# Verifying Data From an ElasticSearch Instance Working With Magento 2

Elasticsearch is a powerful search engine and database that is often used in web development to 
provide fast and accurate search results. It is built on top of the Apache Lucene library, and is 
known for its ability to handle large volumes of data and provide fast search performance.

In Magento 2, Elasticsearch is used as the default search engine for the e-commerce platform. 
It provides advanced search capabilities, including full-text search, faceted search, and geospatial 
search, and can be easily integrated into Magento 2 using the Elasticsearch module.

One of the main benefits of using Elasticsearch in Magento 2 is its ability to handle large volumes 
of data efficiently. This is especially important for e-commerce websites, which often have large 
catalogs of products and need to provide fast and accurate search results to customers. Elasticsearch 
also offers powerful features like faceted search and geospatial search, which can be useful for 
e-commerce websites that need to provide customers with advanced search options.

> How does Magento store index data?
>
> Can I retrieve ElasticSearch index data?
>
> How do I debug ElasticSearch data?
>
> How do I read product data from ElasticSearch in Magento2?
>

Magento uses Elasticsearch to store index data, which is used to power the search function on the e-commerce 
system. If the indexed data is incorrect, it can cause problems with the display of products in the frontend, 
such as missing or incorrect information being shown. This can be especially frustrating for customers and 
can negatively impact their shopping experience.

One common reason for indexed data to be incorrect is when new product attributes are added to the website. 
If these attributes are not properly indexed, they may not be included in the search results, leading to 
incomplete or inaccurate search results. In this case, it can be difficult to pinpoint the cause of the problem 
without properly analyzing the indexed data and the search function itself. This process of troubleshooting 
and identifying the root cause of an issue pretty much amounts to "guesswork."

> Why is my product not visible in Magento2?
>
> Why is my product not visible in the category?
>
> Why is my new Magento2 product attribute not visible?

However, it is easy to read or delete the indexed data from the ElasticSearch instance.
With some simple curl requests on the command line you can query the indexed data.

**Note:** If authentication is required on the ElasicSearch server, then I recommend the following.
link: [https://www.elastic.co/guide/en/elasticsearch/reference/current/http-clients.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/http-clients.html). This explains how to
log in to the ElasticSearch server via curl.

The command

    curl localhost:9200/_cat/indices?v

first lists all known indexes stored in ElasticSearch. In the example we assume
that the ElasticSearch instance is running locally. In a docker setup, instead of "localhost", we would use e.g.
the docker hostname "elasticsearch".

The command produces output like this:

    yellow open magento_en_thesaurus_20220708_071129 SkZIa-TITaCAHf1s2Re2cg 1 2 0 0 226b 226b
    green open .geoip_databases jZnTTcWtR7SdcP_GVwLKNg 1 0 40 40 37.9mb 37.9mb
    yellow open magento_en_catalog_category_20220708_071123 nA_GCdhsR4SeFSlG0qUoAw 1 2 121 0 1mb 1mb
    yellow open magento_en_catalog_product_20220708_071115 wOBOlZKvRFSZhsfZ8FE0qw 1 2 106 0 130kb 130kb

From this list we can read the index names. Depending on where you think the problem is you have to look
at either category ("catalog_category") or product ("catalog_product") data. We're debugging the search
functionality, so we're looking at the category data. 

With the following call we can read the data of a specific product from this index based on the SKU.
The SKU is passed as a parameter of the "query" (in the example below "123456789").

    curl -XPOST -H 'Content-Type: application/json' localhost:9200/magento_en_catalog_category_20220708_071123/_search?pretty=true -d'
    {
        "query": {
            "query_string": {
                "query": "123456789"
            }
        }
    }'

Now, you see all the data Elasticsearch uses for category display and search. You can check if the data is 
complete. If it's not, you found your problem. If everything is there, you probably have a problem with some
custom code in the webshop.

> How do I reset the index?

You can re-create the indexes by calling

    bin/magento indexer:reindex

on the command line. Strangely, that did not always solve my problems. In that case it's necessary to go 
"nucular" on the index. 

Getting rid of an index can be done via curl as well. The following command tells ElasticSearch to delete 
all indexes:

    curl -XDELETE localhost:9200/*

After that you need to do

    bin/magento indexer:reindex

and now all the data should be there.
