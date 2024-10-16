% TITLE (DEV-TIP) Debugging and Customizing Order Success Page in Magento2
% DESCRIPTION Accessing the order success page requires a successful order. Here is a shortcut to skip the order process.  
% DATE 2.3.2023

# Debugging and Customizing Order Success Page in Magento 2

The order success page only shows after completing a successful order. Without that order the page redirects, 
and you won't be able to see it. Yet, doing a 'quick order' over and over just to check if the order success 
page finally looks the way it should is an incredible waste of time.  

Here's what I do instead:

First, I pick a line in `sales_order` table and extract columns `quote_id`, `increment_id`, and `entity_id`. 
The following mySQL-statement will get the latest order from the DB. (Adjust to your needs!)

    SELECT
        quote_id,
        increment_id,
        entity_id
    FROM
        sales_order
    ORDER BY
        entity_id
    DESC
    LIMIT 1;

This will give you something like this:

    +----------+--------------+-----------+
    | quote_id | increment_id | entity_id |
    +----------+--------------+-----------+
    |      146 | 000000104    |        91 |
    +----------+--------------+-----------+
    1 row in set (0.000 sec)

Now, I hardcode the following in lines into the `__construct()`-function 
of `vendor/magento/module-checkout/Model/Session.php` in my local development environment: 

    $this->setLastSuccessQuoteId(146); // sales_order.quote_id
    $this->setLastQuoteId(146); // sales_order.quote_id    
    $this->setLastRealOrderId("000000104"); // sales_order.increment_id
    $this->setLastOrderId(91); // sales_order.entity_id

Now calling `//<local-magento-host>/checkout/onepage/success/` will always show a success page.

Happy coding,
Manuel
