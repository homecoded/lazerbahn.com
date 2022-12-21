% TITLE (DEV-TIP) Extract data from an ElasticSearch instance.
% DESCRIPTION With a few simple curl calls in a bash, data can be extracted from an ElasticSearch instance.
% DATE 6.7.2022

ElasticSearch is being used in more and more web projects. It is fast and effective, but it also complicates
debugging, as it adds another layer of technology to the web stack. Magento, one
of the most widespread e-commerce systems, has supported ElasticSearch for years, and since version
2.4, the use of ElasticSearch is even mandatory.

> How does Magento store index data?
>
> Can I retrieve ElasticSearch index data?
>
> How do I debug ElasticSearch data?
>
> How do I read product data from ElasticSearch in Magento2?
>

For example, Magento stores its index data in ElasticSearch. Are there problems with the display of
of products in the frontend because the indexed data is wrong, the guesswork is usually pre-programmed.
This happens especially quickly when new product attributes are added.

> Why is my product not visible in Magento2?
>
> Why is my product not visible in the category?
>
> Why is my new Magento2 product attribute not visible?

However, it is often easy to read or delete the index data from the ElasticSearch instance.
With some simple curl requests on the command line you can query the indexed data.

**Note:** If authentication is required on the ElasicSearch server, then I recommend the following.
link: [https://www.elastic.co/guide/en/elasticsearch/reference/current/http-clients.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/http-clients.html). This explains how to
log in to the ElasticSearch server via curl.

The command

    curl localhost:9200/_cat/indices?v

first lists all known indexes stored in ElasticSearch. In the example we assume
that the ElasticSearch instance is running locally. In a docker setup, instead of "localhost", we would use e.g.
Use the docker hostname "elasticsearch".

The command produces output like this:

    yellow open magento_en_thesaurus_20220708_071129 SkZIa-TITaCAHf1s2Re2cg 1 2 0 0 226b 226b
    green open .geoip_databases jZnTTcWtR7SdcP_GVwLKNg 1 0 40 40 37.9mb 37.9mb
    yellow open magento_en_catalog_category_20220708_071123 nA_GCdhsR4SeFSlG0qUoAw 1 2 121 0 1mb 1mb
    yellow open magento_en_catalog_product_20220708_071115 wOBOlZKvRFSZhsfZ8FE0qw 1 2 106 0 130kb 130kb

From this list we can read the index name. In the Magento environment we are interested in the shelf of the
größten Index: "**magento_de_catalog_category_20220708_071123**".

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

> How do I reset the index?

Many problems can be solved by resetting the indexes. The following command tells ElasticSearch to clear all the
to delete all indexes:

    curl -XDELETE localhost:9200/*
