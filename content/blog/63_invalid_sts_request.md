% TITLE (DEV-TIP) How to solve Microsoft's SSO error: Invalid STS Request (AADSTS90023) 
% DESCRIPTION While implementing Microsoft Entra SSO for a customer, I stumbled over this error. A real head-banger. Here's how I solved it. Microsoft Entra troubleshooting. AADSTS90023 fix. 
% DATE 26.01.2025

[<< Back to Overview](../blog.html)

# How to solve Microsoft's SSO error: Invalid STS Request (AADSTS90023)

#DATE#

While implementing the self-service password reset feature via Microsoft Entra, I encounter the infamous 
"Invalid STS Request" error. It’s a confusing issue because, for the longest time, I cannot for the life of me  
figure out a specific reason for the failures. It seems completely random and out of my control.

The internet is full of people describing the problem and no solutions in sight. For most cases I could find,
the issue solved itself.

## The Problem

Here’s what typically happens when we do Entra calls (example for self-service password reset):

The initial call to the endpoint `resetpassword/v1.0/start` works as expected. However, the subsequent 
call to `resetpassword/v1.0/challenge` randomly fails with the *"Invalid STS Request"* error. Strangely enough, 
retrying the entire process resolves the issue without any changes on my part.

Similarly, I’ve noticed another odd issue while creating new users in Entra. After receiving confirmation from 
Entra that the user creation was successful, any immediate login attempts often result in a `user_not_found` error. 
Again, retrying after a short wait resolves the problem.

## Investigation and Findings

In both cases, the root cause seems to be the reliability of Microsoft's Entra responses. It’s clear 
that some operations, especially those involving authentication or user provisioning, are not consistently processed 
in real time. I can only speculate why that is. Maybe there is a faulty node in a round-robin load balancing or 
Microsoft is using indexes that updates too slowly.ght be causing these errors.

Takeaway: You cannot trust Entra to reliable produce consistent responses.

## The Solution: Retry with Backoff

The only reliable solution I’ve found is to implement a retry mechanism. By retrying the failed operations, 
the system can work around these random errors. I admit, this is less than ideal. It clutters the code and makes
everything just a little more complicated. My idea was to encapsulate the retry mechanism so it conveniently hidden
away:

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

Happy Coding,
Manuel
