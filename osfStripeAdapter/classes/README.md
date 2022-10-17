INTRODUCTION
------------

This is an updated version of the Stripe Adapter provided by Salesforce.

As of writing on 17 October 2022, this only works for B2B2C.

POST DEPLOYMENT STEPS
---------------------

After deploying the classes, you must perform the following steps (taken from SF directly):

CREATE A NAMED CREDENTIAL
1. Navigate to Setup > Security > Named Credentials
2. Click the *New Named Credential* button
3. Input the follow information (example):
    1. *Label*: StripeAdapter_NC
    2. *Name*: StripeAdapter_NC
    3. *URL*: https://api.stripe.com
    4. *Certificate*: <Leave Blank>
    5. *Identity Type*: Named Principal
    6. *Authentication Protocol*: Password Authentication
    7. *Username*: sk_test_51HJhwOEYJlmrexwWgay72VtD7zb0wINDqPtTxFsfQEW3ShjsTzOq4lKMLtswCKJfmlCSFSfS62ZzciM1goWQEII100L3GNkfqd
    8. *Password*: test1234
    9. *Generate Authorization Header*: Checked
    10. *Allow Merge Fields in HTTP Header*: Checked
    11. *Allow Merge Fields in HTTP Body*: Unchecked
4. Click the *Save* button

CREATE PAYMENT GATEWAY PROVIDER VIA WORKBENCH
1. Navigate to Workbench (https://workbench.developerforce.com/restExplorer.php)
2. Select *queries > SOQL Query* and *Object: ApexClass*
3. Input the following SOQL Query: Select Id, Name from ApexClass where Name like 'StripeAdapt%'
4. Click *Query*
5. Make note of the ID for the newly created StripeAdapter Apex Class which will be unique to your environment
6. Select *Data > Insert* from the Workbench Menu
7. Select *Object Type:* PaymentGatewayProvider
8. Click *Next*
9. Insert following information:
    1. *ApexAdapterID*: <Apex Class ID from query result>
    2. *DeveloperName*: Stripe_Adapter
    3. *IdempotencySupported*: Yes
    4. *MasterLabel*: Stripe Adapter
10. Click *Confirm Insert* and you should receive confirmation of the insert:

CREATE PAYMENT GATEWAY
1. Click on the Lightning App Launcher
2. Search for and select *Payment Gateways*
3. Click the *New* button (top right)
4. Enter the following information:
    1. *Payment Gateway Name:* Stripe
    2. *Payment Gateway Provider:* Stripe Adapter
    3. *Merchant Credential:* Select StripeAdapter_NC in the lookup
    4. *Status:* Active
5. Click *Save*

MAP PAYMENT INTEGRATION TO STOREFRONT
1. Navigate to your Store in the Commerce app
2. Click on the *Administration* tile
3. Click the *Card Payment Gateway* ribbon (at left)
4. Click *Link Integration* 
5. Select *Stripe Adapter*
6. Click *Next*
7. Click *Confirm* to see the resulting Card Payment Gateway mapping:

