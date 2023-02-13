This is a refactored version of the Stripe Capture class.

Major changes from the previous version below:
1. Now takes a Payment record to process a payment. Previously uses the Payment Authorization record then generates a Payment Record. Breaks the life cycle previously.
2. Set up more information capture on the Payment record.
3. The flow now creates the Payment record then calls the invocable. 
4. This design allows the the invocable to be called if an auth has been done previously.
