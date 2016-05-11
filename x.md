# Deploy your WebSharper selfhosted webapp easily

## 1. Create default template websharper client server webhost

Go on github find the new release of WebSharper and get the vsix.
Install it and you will have access to all Websharper templates.
Create a default Selfhost client server application and run it.
If everything works well you should have a running webapp.

## 2. Bind to all interfaces

Find the entrypoint and change the url to the following:
```
let rootDirectory, url = "..", "http://+:9600/"
```
Now of you try to run the webapp, it will crash unless you started visual studio as administrator.
Either you can choose to always run as admin or you can reserve this url for your user account.
This can be done by adding a urlacl.

## 3. Add urlacl (optional)

```
netsh http 
add urlacl url="http://+:9600" user="username"
```

Build and go to your bin folder and you should be able to run the executable and it should launch the webapp.
At this point, we have the webapp ready for deployment.

## 4. Deploy to Azure

Go to the azure portal and select create VM.
Once created, RDP inot the VM and copy the binaries into a folder and run the executable.
It should run without issue but it will not be accessible from outside the vm.
We need to open the inbound port on your firewall to let others access this endpoint on your MV. 
The last point is to tell Azure about your public endpoint. 
This is set from the Azure portal.
Now your webapp should be accessible from anywhere on the internet.
Congratulation you have deployed your WebSharper selfhosted webapp!

## Conclusion

Today we saw how we could deploy a webapp built with WebSharper easily.
For webapps which handle a small amount of users, it seems very appropriate as it is easy and
cost efficient to have a single VM hosting multiple selfhosted webapps on different endpoints.
By showing you this I hope it completed the whole picture from developping to deploying webapps.
Let me know if you deploy some amazing webapps! If you have any comments, hit me on Twitter [@Kimserey_Lam]().
See you next time!
