# iis-bluegreen-powershell

Powershell scripts for doing blue/green deployments with IIS

Populate the section in `deploy.ps1` about deploying your files, then run:

```
.\deploy.ps1 -machines "machine1,machine2" -username myUser -password myPassword -serverFarmName myFarm -bluePath "c:\inetpub\wwwroot\myapp.blue" -greenPath "c:\inetpub\wwwroot\myapp.green" -bluePort 8888 -greenPort 9999 -warmUpPath "/index.html"
```

Blog post coming soon
