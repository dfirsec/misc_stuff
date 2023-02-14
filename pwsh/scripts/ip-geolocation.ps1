# Set the API key for IPInfo.io
$apiKey = ""

function Resolve-Dns {
    param (
        [string]$IpAddress,
        [string[]]$DnsServers
    )

    $dnsServers = @("1.1.1.1", "9.9.9.9", "8.8.8.8")
    foreach ($dnsServer in $DnsServers) {
        $result = Resolve-DnsName -Name $IpAddress -Server $dnsServer -ErrorAction SilentlyContinue
        if ($result) {
            return $result.NameHost
        }
    }
}

function Get-GeolocationMap {
    param (
        [string]$OutputFile,
        [string]$ApiKey,
        [string[]]$IpAddresses,
        [string[]]$DnsServers
    )

    # Create a hash table to store resolved hostnames
    $resolvedHostnames = @{}

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Geolocation Map</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css"
          integrity="sha512-xodZBNTC5n17Xt2atTPuE1HxjVMSvLVW9ocqUKLsCC5CXdbqCmblAshOMAS6/keqq/sMZMZ19scR4PsZChSR7A=="
          crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"
            integrity="sha512-XQoYMqMTK8LvdxXYG3nZ448hOEQiglfqkJs1NOQV44cWnUrBc8PkAOcXy20w0vlaXaVUearIOBhiXZ5V3ynxwA=="
            crossorigin=""></script>
    <style>
        html, body {
        height: 100%;
    }
        #map {
            height: 100%;
            width: 100%;
        }
    </style>
</head>
<body>
<div id="map"></div>
<script>
    // Initialize the map
    var map = L.map('map').setView([0, 0], 2);

    // Add the OpenStreetMap tiles to the map
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

"@

    foreach ($ipAddress in $IpAddresses) {
        try {
            # Resolve the IP address to a hostname
            $dnsResult = Resolve-DnsName -Name $ipAddress -Server $DnsServers -ErrorAction Stop
            $hostname = $dnsResult.NameHost
            $resolvedHostnames.Add($ipAddress, $hostname)
        }
        catch {
            Write-Output "Error: Could not resolve hostname for IP address $ipAddress."
            $hostname = $null
        }

        try {
            # Get the geolocation information for the IP address
            $geolocationUri = "https://ipinfo.io/$($ipAddress)?token=$($apiKey)"
            $geolocation = Invoke-RestMethod -Uri $geolocationUri -ErrorAction Stop
        }
        catch {
            Write-Output "Error: Could not get geolocation information for IP address $ipAddress."
            continue
        }

        if ($hostname) {
            $popupText = "IP: $($ipAddress) <br>City: $($geolocation.city) <br>Country: $($geolocation.country) $($hostname)"
        }
        else {
            $popupText = "IP: $($ipAddress) <br>City: $($geolocation.city) <br>Country: $($geolocation.country)"
        }

        $html += @"
        var marker = L.marker([$($geolocation.loc.Split(",")[0]), $($geolocation.loc.Split(",")[1])]);
        marker.addTo(map);
        marker.bindPopup("$popupText").openPopup();

"@
    }

    $html += @"
</script>
</body>
</html>
"@

    # Write HTML to output file
    $html | Out-File $OutputFile -Encoding UTF8
}

$ips = Read-Host "Enter IP addresses separated by commas"
$ipAddresses = $ips.Split(",")
Get-GeolocationMap -ApiKey $apiKey -OutputFile "map.html" -IpAddresses $ipAddresses
