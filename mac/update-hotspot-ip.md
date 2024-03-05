How to update hotspot
============

To change the ip range that is used for hotspot you need to edit the file
`/Library/Preferences/SystemConfiguration/com.apple.nat.plist`

Go near the bottom and add the following inside the nested `dict` object.
```xml
<key>NAT</key>
<dict>
...
    <key>SharingNetworkMask</key>
    <string>255.255.255.0</string>
    <key>SharingNetworkNumberEnd</key>
    <string>192.168.137.50</string>
    <key>SharingNetworkNumberStart</key>
    <string>192.168.137.0</string>
</dic>
```

Change the content inside `&lt;string&gt;` for the values that you need.
