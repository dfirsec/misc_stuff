param (
    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $true)]
    [string[]]$IpAddresses
)

# ApiKey for Ipinfo.io
$ApiKey = ""

if (-not $ApiKey) {
    Write-Host "Error: API key is not defined."
    Exit
}

if ($ApiKey.Trim().Length -eq 0) {
    Write-Host "Error: API key is empty."
    Exit
}


function Resolve-Dns {
    param (
        [string]$IpAddress,
        [string[]]$DnsServers
    )

    foreach ($dnsServer in $DnsServers) {
        $result = Resolve-DnsName -Name $IpAddress -Server $dnsServer -ErrorAction SilentlyContinue
        if ($result) {
            return $result.NameHost
        }
    }
}

function Get-GeolocationMap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [string[]]$IpAddresses,

        [string[]]$DnsServers = @("1.1.1.1", "9.9.9.9", "8.8.8.8")
    )

    if (-not $OutputFile) {
        Write-Host "Error: Output file is not defined."
        Exit
    }

    if ($OutputFile.Trim().Length -eq 0) {
        Write-Host "Error: Output file is empty."
        Exit
    }

    if (-not $IpAddresses) {
        Write-Host "Error: IP addresses are not defined."
        Exit
    }

    if ($IpAddresses.Count -eq 0) {
        Write-Host "Error: IP addresses array is empty."
        Exit
    }

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
            $geolocationUri = "https://ipinfo.io/$($ipAddress)?token=$($ApiKey)"
            $geolocation = Invoke-RestMethod -Uri $geolocationUri -ErrorAction Stop
        }
        catch {
            Write-Output "Error: Could not get geolocation information for IP address $ipAddress."
            continue
        }

        if ($hostname) {
            $popupText = "IP: $($ipAddress) <br>City: $($geolocation.city) <br>Country: $($geolocation.country) <br>$($hostname)"
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
    $html | Out-File -FilePath $OutputFile -Encoding UTF8
}

# Call the Get-GeolocationMap function with the required parameters
Get-GeolocationMap -OutputFile $OutputFile -IpAddresses $IpAddresses
