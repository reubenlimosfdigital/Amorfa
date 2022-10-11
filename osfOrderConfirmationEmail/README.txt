INTRODUCTION
------------

This enables an org to send Order Confirmation emails. This is based on the Amorfa B2B template.


POST DEPLOYMENT STEPS
---------------------

* Add the Order Confirmation Apex Class to the autoproc user. Without this, no confirmation emails will be sent out.
* Add automation (e.g. Flow) to send the email out upon the creation of an Order Summary Object. Make sure this is set to async and sent out later as the Salesforce workflow is to create it blank initially, then populate it with Products. You need the Products for the Order Confirmation Email.