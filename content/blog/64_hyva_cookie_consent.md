% TITLE (DEV-TIP) Debugging Hyvä "Uncaught TypeError: hyva.alpineInitialized is not a function"
% DESCRIPTION When I debugged a strange Hyvä error telling me that the basic JavaScript functions weren't initialized (even though the code was clearly there) I went down a rabbit hole and found a surprising cause.  
% DATE 08.05.2025

[<< Back to Overview](../blog.html)

# (DEV-TIP) Debugging Hyvä <br/>"Uncaught TypeError: hyva.alpineInitialized is not a function"

It started with a seemingly trivial issue: a Hyvä-based Magento frontend throwing the following JavaScript error 
in the console:

    Uncaught TypeError: hyva.alpineInitialized is not a function
    Hyvä helpers are not loaded yet. Make sure they are included before this script
    
At first glance, it suggested a race condition or perhaps a missing script import. I double-checked the usual suspects:

- Hyvä's Alpine initialization script was loaded.
- The window.hyva object was present.
- The method in question was defined.

Yet, somehow, it was still undefined at runtime.

I inspected the rendered HTML and JavaScript output, but everything looked fine. The script tags were in place, 
the function was defined inline just like in other Hyvä projects. No minification issues, no broken imports. 
It simply didn't make sense. Yet!

I started to add alert-calls to the hyvä-initialization script at `vendor/hyva-themes/magento2-theme-module/src/view/frontend/templates/page/js/hyva.phtml`.
Only then I realized that the script is simply not executed. It's there but it's not executed.

## Suspicion: Something Was Silently Blocking Scripts

No errors, no warnings, just... silence. The HTML was there. The script was there. The function wasn't. 
That's when I started to suspect external interference. Was it a CSP issue? Some kind of browser extension? 
I disabled everything. Still no effect.

I started to comment out parts of the JavaScript in the `hyva.phtml` file until I found that this line is causing
the behavior:

    document.cookie = name + "=" + encodeURIComponent(value) +
        (expires && days !== sessionCookieMarker ? '; expires=' + expires.toGMTString() : '') +
        (path ? '; path=' + path : '') +
        (domain ? '; domain=' + domain : '') +
        (secure ? '; secure' : '') +
        (samesite ? '; samesite=' + samesite : 'lax');

I rewrote the line to use `document['cookie'] = ...`, which surprisingly worked. This does the trick as well:
`const d = document; d.cookie = ...` and any other variation that's not `document.cookie=`.

I started to suspect browser security rules, apparmor rules and/or snap sandbox restrictions. Yet, no amount of 
digging had brought anything up. 

Eventually, I got to talk to Willem Wigman, the founder of Hyvä, and he had a great tip: 

> "Do you have a cookie acceptance widget? it defers Javascript and breaks alpine initialisation." (Willem Wigman)

Consequently, I investigated the cookie consent manager I had recently added to my local dev environment.
In my case it was the one from consentmanager.net. I removed their script and suddenly, everything worked.

That was the breakthrough. Now, I just needed to figure out why.

## The Culprit: Naive Cookie Usage Detection

ConsentManager includes a script that evaluates inline scripts before allowing them to run. One part of that 
logic looks like this:

    this.blockinline = function(d) {
        if ("blockinlineCallback"in this.options && typeof (this.options.blockinlineCallback) == "function") {
            return this.options.blockinlineCallback(d)
        }
        return this.hasDocumentCookie(d)
    }
    ;
    this.hasDocumentCookie = function(d) {
        if (typeof (d) !== "string") {
            return false
        }
        d = d.split(" ").join("");
        d = d.split("\n").join("");
        d = d.split("\r").join("");
        d = d.split("\t").join("");
        return d.indexOf("document.cookie=") != -1
    }

Yes, that's right. Regardless of context. it performs a simple string match to check if your inline script contains 
"`document.cookie=`" and blocks it. Silently!

The idea is understandable: They want to prevent unauthorized cookie setting unless the user has given consent. 
But this approach is essentially using a sledgehammer to perform surgery. It introduces false positives, blocks 
legitimate scripts, and provides no useful diagnostics.

## The Consequence: Essential Scripts Blocked Without Warning

In my case, some inline logic in Hyvä's templates included code touching document.cookie. ConsentManager saw that 
and blocked the entire script. As a result, hyva.alpineInitialized was never defined, even though the script tag 
was in the DOM and looked perfectly fine.

## Workarounds & Fixes

**Avoid the literal string**

You can break up the offending string so it doesn't match:

    document["cookie"] = "..."; // this bypasses the naive filter

    const d = document; d.cookie = "..."; // not elegant, but it works.

**Use ConsentManager's whitelisting attributes**
   
ConsentManager allows you to mark inline scripts as safe:
    
    <script data-cmp-ab="1">
      window.cmp_block_inline = false;      //true = blocking of inline scripts
      window.cmp_block_ignoredomains = ["domain1.com","domain2.net","domain3.org"]; // list of domains that should not be blocked
     </script>

See <https://help.consentmanager.de/books/cmp/page/what-to-do-when-the-automatic-blocking-mode-is-blocking-too-much>

This lets them execute even if they contain `document.cookie` references.

## Final Thoughts

What made this bug so frustrating wasn't just the unexpected behavior. It was the absence of feedback:
No error. No blocked script warning. Just broken functionality and silence.

Consent tools are important. But when they rely on fragile heuristics like string-matching JavaScript source code, 
they introduce instability. And if you're a developer using ConsentManager.net, be warned: even a harmless 
"document.cookie" string can sink your entire frontend without leaving a trace.

Sometimes debugging means looking for what's missing, not what's broken.

Happy coding,
Manuel
