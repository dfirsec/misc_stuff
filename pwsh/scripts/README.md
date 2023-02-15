# IP Geolocation

PowerShell script that resolves the geolocation of a set of IP addresses and generates an HTML map displaying the geolocations.

The script contains two functions, `Resolve-Dns` and `Get-GeolocationMap`.

The `Resolve-Dns` function takes an IP address and an array of DNS servers as input and returns the hostname for the IP address by iterating through the DNS servers until a successful resolution is achieved.

The `Get-GeolocationMap` function is the main function of the script. It takes the output file path, an array of IP addresses to be resolved, and an optional array of DNS servers as input.

1. The function first validates the inputs and then resolves the IP addresses to hostnames using the `Resolve-Dns` function. 

2. It then calls the `ipinfo.io` API to obtain the geolocation information for each IP address and generates an HTML map using the Leaflet JavaScript library. 

3. Finally, the function writes the HTML map to the output file path.

## Usage

The script takes the output file path and the array of IP addresses as command-line arguments and generates an HTML map file at the specified location.

```
.\ip-geolocation.ps1 -OutputFile "C:\Users\<USERNAME>\map.html" -IpAddresses 8.8.8.8, 1.1.1.1, 4.4.4.4
```
