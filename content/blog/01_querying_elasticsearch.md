% TITLE (DEV-TIPP) Daten aus einer ElasticSearch-Instanz extrahieren
% DESCRIPTION Mit ein paar einfachen curl-Aufrufen in einer bash, können Daten aus einer ElasticSearch-Instanz extrahiert werden.
% DATE 6.7.2022

ElasticSearch kommt in immer mehr Webprojekten zum Einsatz. Es ist schnell und effektiv, aber es erschwert
auch das Debugging, da es eine weitere Technologie-Ebene in den Web-Stack hinzufügt. Magento, eines 
der verbreitesten e-Commerce-Systeme unterstützt ElasticSearch bereits seit Jahren und seit der Version
2.4 ist die Verwendung von ElasticSearch sogar zwingend erforderlich.

> Wie legt Magento Index-Daten ab?
> 
> Kann ich ElasticSearch-Index-Daten abrufen?
> 
> Wie debugge ich ElasticSearch-Daten?
> 
> Wie lese ich Produktdaten aus ElasticSearch in Magento2 aus?
> 

Magento legt beispielsweise seine Index-Daten in ElasticSearch ab. Gibt es Probleme bei der Darstellung
von Produkten im Frontend, weil die indizierten Daten falsch sind, ist das Rätselraten meist vorprogrammiert. 
Das passiert besonders schnell, wenn neue Produkt-Attribute hinzugefügt werden.

> Warum ist mein Produkt im Magento2 nicht sichtbar?
> 
> Warum ist mein Produkt nicht in der Kategorie sichtbar?
> 
> Warum ist mein neues Magento2-Produktattribut nicht sichtbar?

Es ist aber oft einfach, die Index-Daten aus der ElasticSearch-Instanz auszulesen oder zu löschen. 
Mit einigen einfachen curl-Requests auf der Kommandozeile können die indizierten Daten abgefragt werden. 

**Hinweis:** Sollte am ElasicSearch-Server eine Authententifizierung notwendig sein, dann empfehle ich folgenden
Link: https://www.elastic.co/guide/en/elasticsearch/reference/current/http-clients.html. Dieser erklärt, wie man
sich per curl ElasticSearch-Server anmeldet.

Der Befehl

    curl localhost:9200/_cat/indices?v

listet zunächst alle bekannten Indexes, die in ElasticSearch gespeichert sind. Im Beispiel gehen wir davon
aus, dass die ElasticSearch-Instanz lokal läuft. In einem docker-Setup würden wir statt "localhost" z.B. 
den docker-Hostname "elasticsearch" Nutzen. 

Der Befehl produziert eine Ausgabe wie diese:

    yellow open   magento_de_thesaurus_20220708_071129        SkZIa-TITaCAHf1s2Re2cg   1   2          0            0       226b           226b
    green  open   .geoip_databases                            jZnTTcWtR7SdcP_GVwLKNg   1   0         40           40     37.9mb         37.9mb
    yellow open   magento_de_catalog_category_20220708_071123 nA_GCdhsR4SeFSlG0qUoAw   1   2        121            0        1mb            1mb
    yellow open   magento_de_catalog_product_20220708_071115  wOBOlZKvRFSZhsfZ8FE0qw   1   2        106            0      130kb          130kb
 
Aus dieser Liste können wir den Index-Namen auslesen. Im Magento-Umfeld interessiert uns in der Regal der 
größten Index: "**magento_de_catalog_category_20220708_071123**".

Mit folgenden Aufruf können wir aus diesem Index die Daten eines bestimmten Produktes anhand der SKU auslesen.
Die SKU wird dabei als Parameter der "query" übergeben (im Beispiel unten "123456789").

    curl -XPOST -H 'Content-Type: application/json' localhost:9200/magento_de_catalog_category_20220708_071123/_search?pretty=true -d'
    {
        "query": {
            "query_string": {
                "query": "123456789"
            }
        }
    }'

> Wie setze ich den Index zurück?

Viele Probleme lassen sich durch das Zurücksetzen der Indizes lösen. Folgender Befehl weißt ElasticSearch an, alle
Indizes zu löschen:

    curl -XDELETE localhost:9200/*

