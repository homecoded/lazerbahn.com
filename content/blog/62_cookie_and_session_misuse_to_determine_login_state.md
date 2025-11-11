% TITLE (DEV-TIP) How to determine if a user is logged in without facing a PHPMD.CookieAndSessionMisuse in Magento2
% DESCRIPTION To determine if a user is logged in I usually use the customer-session object. Yet, this leads to an error in PHP Mess Detector: CookieAndSessionMisuse. Here's how to avoid that.
% DATE 29.10.2024 / update: 11.11.2025

[<< Back to Overview](../blog.html)

# How to determine if a user is logged in without facing a PHPMD.CookieAndSessionMisuse in Magento 2

#DATE#

Sometimes, I need to check if I'm dealing with a logged-in user in Magento 2. If I rely on 
the familiar `Magento\Customer\Model\Session::isLoggedIn` method, though, PHPMD (PHP Mess Detector) 
greets me with an error, since the code I'm working on is rarely part of the "HTML presentation layer."
Making PHPMD happy is in itself a good goal, but in this case not following it may create a security
hazard.

## The Issue with 'Session::isLoggedIn'

The `isLoggedIn` method effectively detects whether a session belongs to a logged-in user, but it 
triggers the following error during code-quality checks:

> The class uses sessions or cookies while not being a part of HTML Presentation layer

Sure, I could hide the error by using a suppression annotation in the header: 

     /** @SuppressWarnings(PHPMD.CookieAndSessionMisuse) **/

But suppressing the error is just hiding the problem and waiting for disaster. Disaster? Yes!
In cached contexts the session should never be initialized. So, if Full Page Cache is active, starting a 
session may put sensitive data into the cache for other users to discover it.

## HTTP-Context to the rescue!

To avoid this error and ensure adherence to Magento's standards, I better use an instance of 
`Magento\Customer\Model\Context`, added via dependency injection through the constructor.

Here's how to set it up:

    // ..
    use Magento\Customer\Model\Context as ContextModel;
    use Magento\Framework\App\Http\Context;

    // ...

    public function __construct(
        private readonly Context $httpContext,
    ) {
    }

Then, to check the login status, I use this line wherever needed:

    $isLoggedIn = $this->httpContext->getValue(ContextModel::CONTEXT_AUTH);

The `getValue` function returns `false` if a customer is logged out and `true` if logged in.
This function provides the same functionality as `isLoggedIn` but avoids triggering the Mess Detector error.

## There is another contestant: UserContextInterface

Not in all contexts `Magento\Customer\Model\Context` gets initialized. E.g. Rest-API is not initializing it.
In the Rest-API context you may use `Magento\Authorization\Model\UserContextInterface` in this way:

    // ..
    use Magento\Authorization\Model\UserContextInterface;

    // ...

    public function __construct(
        private readonly UserContextInterface $userContext,
    ) {
    }

    // ...

    public function isLoggedIn(): bool {
        return $this->userContext->getUserType() === UserContextInterface::USER_TYPE_CUSTOMER
    }

Cool thing about `UserContextInterface` is that it can also provide the user id, if a customer is logged in:

    public function getCustomerId(): int {
        if ($this->isLoggedIn()) {
            return (int) $this->userContext->getUserId();
        }
        return 0;
    }

So, I'm now using HTTP und User context to keep Mess Detector happy - and you should, too.

Happy Coding,
Manuel
