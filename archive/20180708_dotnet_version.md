# Dotnet SDK and runtime version installed

To check your `dotnet` version  installed, use `dotnet --info`. This command will display the `SDKs` and `runtimes` installed on your system together with the path where they can be found.

For example on my Windows 10 development machine, `dotnet --info` will yield the following:

```sh
> dotnet --info
.NET Core SDK (reflecting any global.json):
 Version:   2.1.301
 Commit:    59524873d6

Runtime Environment:
 OS Name:     Windows
 OS Version:  10.0.17134
 OS Platform: Windows
 RID:         win10-x64
 Base Path:   C:\Program Files\dotnet\sdk\2.1.301\

Host (useful for support):
  Version: 2.1.1
  Commit:  6985b9f684

.NET Core SDKs installed:
  2.1.4 [C:\Program Files\dotnet\sdk]
  2.1.201 [C:\Program Files\dotnet\sdk]
  2.1.300 [C:\Program Files\dotnet\sdk]
  2.1.301 [C:\Program Files\dotnet\sdk]

.NET Core runtimes installed:
  Microsoft.AspNetCore.All 2.1.0 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All]
  Microsoft.AspNetCore.All 2.1.1 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All]
  Microsoft.AspNetCore.App 2.1.0 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App]
  Microsoft.AspNetCore.App 2.1.1 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 2.0.5 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]
  Microsoft.NETCore.App 2.0.7 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]
  Microsoft.NETCore.App 2.1.0 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]
  Microsoft.NETCore.App 2.1.1 [C:\Program Files\dotnet\shared\Microsoft.NETCore.App]

To install additional .NET Core runtimes or SDKs:
  https://aka.ms/dotnet-download
```

While on my Ubuntu 18.04 server running the application, `dotnet --info` will yield the following:

```
dotnet --info

Host (useful for support):
  Version: 2.1.1
  Commit:  6985b9f684

.NET Core SDKs installed:
  No SDKs were found.

.NET Core runtimes installed:
  Microsoft.AspNetCore.All 2.1.1 [/usr/share/dotnet/shared/Microsoft.AspNetCore.All]
  Microsoft.AspNetCore.App 2.1.1 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 2.1.1 [/usr/share/dotnet/shared/Microsoft.NETCore.App]

To install additional .NET Core runtimes or SDKs:
  https://aka.ms/dotnet-download
```

Note that the server running the application does not need the SDK, it only needs the runtime hence no SDK are installed.

Verifying the version of `dotnet` is also useful to fix the issue `.NET SDK does not support xyz` as this error means that one of the library your project is using requires a SDK version not installed on your machine. 