INTRODUCTION
------------

This installs a Lightning Web Component (LWC) that enables pop up messages on a Lightning Community. The following are included:

* A Custom Object (OSF_Customer_Message__c) that stores pop up messages.
* A LWC (osfCommunityPopUpMessage) that displays the message on the community.
* An Apex Controller (OSF_CommunityPopUpMessageController) that retrieves the records from the Custom Object.
* An Apex Test Class (OSF_CommunityPopUpMessageControllerTest) for the above controller.


POST DEPLOYMENT STEPS
---------------------

The following must be done for community users who need to see the pop up messages
* Add the Apex Controller (OSF_CommunityPopUpMessageController) to the Profile or Permission Set.
* Enable Object and Field read access to the Profile or Permission Set
* Enable Sharing on the Custom Object (OSF_Customer_Message__c).
* Place the LWC on the relevant Community
* Enable object and record access to the Custom Object for internal users