Simple IPN script that will automatically process donations.
If you are trying to set-up my gamemodes with MySQL, this can be useful if you want donations and VIPs to work.


In the ipn.php file, set the MySQL details so that it can actually connect to an operational MySQL server.
If you want to use the original script (with GMOD donations), you can use the "Structure for database.sql" file from Gamemodes\Flow Network - All gamemodes\Flow Network - Bunny Hop\Database\MySQL (for master database)

To actally begin using it, go to your PayPal, hover over Profile, select More options. Click on a button that says "Webstore preferences" (Mine is in Dutch so I'm just translating here), then on the right click the link next to "Instant payment notifications".
Set the IPN URL to the ipn.php script on the page you've opened. Test it using the PayPal Sandbox: https://developer.paypal.com/webapps/developer/applications/ipn_simulator (If you want to use this, make sure to comment out line 45 and 63 about "IPNSandbox" with the die() function.
(NOTE: PayPal is changing their layout, so this might be located elsewhere. Just search for something with "Instant Payment Notification" or IPN)

Good luck with it!
Gravious