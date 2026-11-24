$proxyUrl = "http://localhost:10809"
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxyUrl)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials