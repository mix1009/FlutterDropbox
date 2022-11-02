# What have I changed?
- updated the dependency on the Dropbox SDK to 4.0.1 to use the new PKCE authorization functionality
- updated gradle version used to 7.1.2
- added new function authorizePKCE to use instead of authorize - this uses the new short-lived token PKCE authorization
- added new function authorizeWithCredentials to use instead of authorizeWithAccessToken
- added new function getCredentials - to get authorization credentials instead of access token

- implemented the necessary groundwork in Dropbox.java to enable above functions on Android

**NOTE:**: only implemented for Android - needs implementation for other platforms, especially iOS