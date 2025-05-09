% TITLE (DEV-TIP) How to solve Microsoft's SSO error: Invalid STS Request (AADSTS90023) 
% DESCRIPTION While implementing Microsoft Entra SSO for a customer, I stumbled over this error. A real head-banger. Here's how I solved it. Microsoft Entra troubleshooting. AADSTS90023 fix. 
% DATE 26.01.2025

[<< Back to Overview](../blog.html)

# How to solve Microsoft's SSO error: Invalid STS Request (AADSTS90023)

#DATE#

While implementing a self-service password-reset flow using Microsoft Entra, I keep stumbling over strange issues.
One of them is an error called "Invalid STS Request". You can find it all over the internet: 
Microsoft forums, reddit, blogs. It's a weird issue because in most cases nobody found a clear explanation 
and the issue solved itself after some time all by itself.

The internet is full of people describing the problem. Yet, there seems no clear solution path.

## The Problem

Here's what typically happens when I do the corresponding Entra calls (example for self-service password reset):

The initial call to the endpoint `resetpassword/v1.0/start` works as expected. However, the subsequent 
call to `resetpassword/v1.0/challenge` randomly fails with *"Invalid STS Request"*. Strangely enough, 
retrying the request resolves the issue without any changes on my part.

Similarly, I've noticed an odd issue while creating new users in Entra, too. After receiving confirmation from 
Entra that the user creation was successful, any immediate login attempts sometimes result in a `user_not_found` error. 
Again, retrying after a short wait resolves the problem. 

## Investigation and Findings

In both cases, the root cause seems to be a reliability issue on Microsoft's side. It's clear 
that some operations, are not processed consistently. I can only speculate why that is. 
Maybe there is a faulty node in a round-robin load balancing or 
Microsoft is using internal indexes that update too slowly? I don't know.

Takeaway: You cannot trust Entra to reliably produce consistent responses.

## The Solution: Retry with Backoff

The only reliable solution I've found is to implement a retry mechanism. By retrying the failed operations, 
the random errors become less of a nuisance. I admit, this is less than ideal. It clutters the code and makes
everything just a little more complicated. 

To not make matters any worse, I try to encapsulate the retry mechanism as best as I can:

1. **Initial Retry**
   When an error is encountered, the system retries the operation immediately.
2. **Incremental Wait Times**
   If the first retry fails, the system waits for an increasing amount of time before each subsequent attempt. 
   This ensures that any backend delays or synchronization issues have more time to resolve.
3. **Fail Gracefully**
   To avoid infinite loops, the system gives up after three retries and logs the error for further investigation.

Here's how you can pull this off:

      <?php
      
      /**
       * @param callable $operation   closure to call
       * @param int $maxRetries       how may times do we ant to try
       * @param int $initialWait      how long we want to wait after first failure
       * @return mixed                return value of $operation
       * @throws Exception            if all fails
       */
      function performOperationWithRetries(callable $operation, int $maxRetries = 3, int $initialWait = 2): mixed
      {
          $attempt = 0;
          $waitTime = $initialWait;
      
          while ($attempt < $maxRetries) {
              try {
                  // Attempt the operation
                  return $operation();
              } catch (Exception $e) {
                  // Log the failure
                  echo('Attempt ' . ($attempt + 1) . ' failed: ' . $e->getMessage() . PHP_EOL);
              }
      
              $attempt++;
              // Wait before retrying
              if ($attempt < $maxRetries) {
                  sleep($waitTime);
                  $waitTime *= 2; // Exponential backoff
              }
          }
      
          // If all retries fail, throw an exception
          throw new Exception('Operation failed after ' . $maxRetries . ' retries.');
      }
      
      // Example usage
      try {
          $result = performOperationWithRetries(function () {
              // Replace with the actual operation, e.g., an API call
              if (random_int(0, 6) < 4) {
                  throw new Exception('Random failure!');
              }
              return 'Success!';
          });
      
          echo 'Operation result: ' . $result . PHP_EOL;
      } catch (Exception $e) {
          echo 'Final error: ' . $e->getMessage() . PHP_EOL;
      }

You may want to update the logging calls: Echo calls are not suitable for server logging i
n web-site environments. Please replace or remove as you see fit.  

Happy Coding,
Manuel
