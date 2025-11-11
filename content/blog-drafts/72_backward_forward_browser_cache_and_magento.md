Browser Cache, Cloudflare Cache and Hyva
I'm doing performance optimizations on one of our customer's hyva stores. This particular customer uses Cloudflare. I don't like Cloudflare too much, but it's their corporate decision to use it. So, I'm rolling with it.
If I have to use Cloudflare I may as well make use of all of the its capabilities. One of which is HTML caching. To my surprise, it's impossible with Magento because it ALWAYS sets the following header
Cache-Control: max-age=0, must-revalidate, no-cache, no-store
on all pages, even on non-logged-in catalog and cms pages. No exceptions!
I wrote a module that can change this behavior https://github.com/triplewood-de/magento2-cache-optimizer and I'm seeing good results (esp. TTFB) . Even without Cloudflare, the use of back/forward caching alone, makes navigating the page so much smoother (for guest users that is).
Now, I'm writing this for two reasons:
I want to share the result of my little research. Feel free to use the extension and/or extend on it.
I am really wondering if I'm missing some crucial detail: Is this browser-caching attempt a really bad idea after all?
The code is in review within our organization and as of now it's only rolled out on staging systems.
Thanks for any insights. :slightly_smiling_face:

\Magento\Framework\App\Response\Http::setNoCacheHeaders
is always called unconditionally from
\Magento\Framework\App\FrontController::processRequest
/**
* Process (validate and dispatch) the incoming request
*
* @param RequestInterface $request
     * @param ActionInterface $actionInstance
* @return ResponseInterface|ResultInterface
* @throws LocalizedException
*
* @throws NotFoundException
*/
private function processRequest(
RequestInterface $request,
ActionInterface $actionInstance
) {
$request->setDispatched(true);
$this->response->setNoCacheHeaders();
$result = null;
...
So, FPC works on those pages so cacheable="false" is not an issue.
Magento just always set the header in this way. (edited)

My extension explicitly allows only catalog/view and cms/view to be cached in the browser. Yes, it's possible that some developers put user-specific data in there, but in this case I think that's a mistake. The approach should work if everyone loads user-specific data properly and responsibly.
I'm pretty confident that this would work in our project. I wouldn't say it will work universally in all projects of course. I've seen some crazy stuff out there (like customer-specific prices loaded via Ajax, but the customer number is in the HTML file and thus in the FPC).
In the end, this works pretty much like an external FPC. If “my” approach causes problems, then the normal FPC most likely won't work either.
