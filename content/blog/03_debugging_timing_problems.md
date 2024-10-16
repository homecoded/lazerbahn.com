% TITLE (DEV-TIP) Debugging Racing Conditions in Magento In JavaScript
% DESCRIPTION Racing conditions are hard to debug because they often cannot be recreated consistently. Here is how I tackled one of those cases.  
% DATE 12.12.2021

# Debugging Racing Conditions in Magento In JavaScript

Racing conditions in web development refer to scenarios where the outcome of a task depends on the 
timing or order in which certain events occur. These events could be related to server-side or 
client-side processing, and can impact the functionality or performance of a website or web application.

One common example of a racing condition in web development is when JavaScript files are loaded 
asynchronously without honoring their dependencies. This means that certain scripts may be loaded 
and executed before other scripts that they depend on have finished loading. This can cause errors or 
unexpected behavior, as the dependent scripts may not have the necessary resources or information 
available to execute correctly.

To prevent racing conditions and ensure that your website or web application functions as intended, 
it's important to carefully manage the loading and execution of your scripts. This may involve using 
techniques like lazy loading or module bundling to control the order in which scripts are loaded, or 
using tools like Promises or async/await to manage the flow of execution. By proactively addressing 
racing conditions, you can improve the reliability and performance of your web applications and provide 
a better experience for your users.

## What was my problem?

At one of my customer's websites, there were occasional instances where some JavaScript on the site 
would fail. This happened infrequently, but when it did, it negatively impacted the usability of the 
webshop for some customers. From what I could tell, the issue seemed to be related to a module in 
the merged JavaScript that would crash because jQuery was not available at the time. Strangely, this 
issue never occurred in any local development environments, so I had to figure out a way to replicate 
the problem locally in order to find a solution.

## How can a JavaScript loading racing condition be triggered in Magento2?

I had an idea to try and cause the JavaScript loading issue to occur in my local development environment 
by delaying the loading of the jQuery source file. I didn't want to modify the webserver directly, 
so I looked for ways to manipulate how the file was being loaded without altering the internal workings of the 
web server. 
I discovered that I could use the .htaccess files to achieve this, which of course only works if you 
use Apache for your local development environment. 

First, I checked the path to the jQuery file. In this case, it was `static/frontend/shop/theme/de_DE/jquery.js`. 
In the `.htaccess` file, there was a general rewrite rule that redirected all requests to files that could not be found
directly to the `pub/static.php` file. So, I added the following line just before that RewriteRule:

    //...
    RewriteCond %{REQUEST_FILENAME} static/frontend/shop/theme/de_DE/jquery.js

    RewriteRule .* ../static.php?resource=$0 [L]
    // ...

This makes sure that all requests to the jQuery source file go through `pub/static.php`, now.

I added the following lines to the file `pub/static.php` right after the opening PHP tag.

    if ($_REQUEST['resource'] == 'frontend/shop/theme/de_DE/jquery.js') {
        sleep(5);
    }

By delaying the loading of (only) jQuery, I was able to ensure that any plugins with faulty dependencies would immediately 
fail. This also works with other files. By causing the issue to occur every time, I was able to debug and fix the 
dependency declaration, confident that it would work consistently on the live system.

Happy coding,
Manuel
