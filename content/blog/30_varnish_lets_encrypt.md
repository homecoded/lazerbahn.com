% TITLE (DEV-TIP) Making varnish, Apache and Let's Encrypt play nicely
% DESCRIPTION After installing varnish you may experience problems with Let's Encrypt renewal failures. Here's what you need to do.  
% DATE 28.3.2023

[<< Back to Overview](../blog.html)

# Making varnish, Apache and Let's Encrypt play nicely

After installing varnish all calls go to a nginx proxy. Certbot works on the Apache config to do verification
challenges, which fail after installing varnish. The challenges go to the nginx proxy and it doesn't know what
to do. The documentation ([here](https://docs.varnish-software.com/tutorials/hitch-letsencrypt/])) recommends to 
set up a pipe in varnish to pass the calls to Apache:

    backend certbot {
        .host = "127.0.0.1";
        .port = "8080";
    }

    sub vcl_recv {
        if (req.url ~ "^/\.well-known/acme-challenge/") {
            set req.backend_hint = certbot;
            return(pipe);
        }
    }
    
    sub vcl_pipe {
        if (req.backend_hint == certbot) {
            set req.http.Connection = "close";
            return(pipe);
        }
    }

While this won't hurt, this alone does not help in my case. So, I specified Apachess
new port in the certbot parameters, additionally. In my case that was 8080.

I change the cronjob to call renew with a port setting: 

    certbot renew -q -preferred-challenges http --http-01-port 8080

Now, the certificates are getting recreated as expected.

Happy coding,
Manuel
