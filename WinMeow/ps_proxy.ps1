# Meow Proxy Test Script for Windows PowerShell
# Usage: .\test_meow_proxy.ps1 [on|off|test]

param(
    [string]$Action = "test"
)

$proxy = "127.0.0.1:7890"
$sites = @{
    "Google" = "https://www.google.com"
    "GitHub" = "https://github.com"
    "YouTube" = "https://www.youtube.com"
    "Twitter" = "https://twitter.com"
    "OpenAI" = "https://openai.com"
    "HuggingFace" = "https://huggingface.co"
    "Aliyun" = "https://cn.aliyun.com/"
    "Baidu" = "https://www.baidu.com"
}

function Set-ProxyOn {
    Write-Host "Setting proxy ON..." -ForegroundColor Yellow
    $env:HTTP_PROXY = "http://$proxy"
    $env:HTTPS_PROXY = "http://$proxy"
    $env:ALL_PROXY = "http://$proxy"
    Write-Host "Proxy environment variables set:" -ForegroundColor Green
    Write-Host "  HTTP_PROXY  = $env:HTTP_PROXY" -ForegroundColor Cyan
    Write-Host "  HTTPS_PROXY = $env:HTTPS_PROXY" -ForegroundColor Cyan
    Write-Host "  ALL_PROXY   = $env:ALL_PROXY" -ForegroundColor Cyan
}

function Set-ProxyOff {
    Write-Host "Setting proxy OFF..." -ForegroundColor Yellow
    Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
    Remove-Item Env:ALL_PROXY -ErrorAction SilentlyContinue
    Write-Host "Proxy environment variables cleared." -ForegroundColor Green
}

function Get-ProxyStatus {
    $hasProxy = $env:HTTP_PROXY -or $env:HTTPS_PROXY -or $env:ALL_PROXY
    if ($hasProxy) {
        Write-Host "Current proxy status: ON" -ForegroundColor Green
        if ($env:HTTP_PROXY) { Write-Host "  HTTP_PROXY  = $env:HTTP_PROXY" -ForegroundColor Cyan }
        if ($env:HTTPS_PROXY) { Write-Host "  HTTPS_PROXY = $env:HTTPS_PROXY" -ForegroundColor Cyan }
        if ($env:ALL_PROXY) { Write-Host "  ALL_PROXY   = $env:ALL_PROXY" -ForegroundColor Cyan }
    } else {
        Write-Host "Current proxy status: OFF" -ForegroundColor Red
    }
    return $hasProxy
}

function Test-Site($url, $useProxy, $showError = $false) {
    try {
        if ($useProxy) {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 15 -Proxy "http://$proxy" -ErrorAction Stop
        } else {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 15 -ErrorAction Stop
        }
        return @{ Success = $true; StatusCode = $response.StatusCode; Error = $null }
    } catch {
        $errorMsg = $_.Exception.Message
        if ($showError) {
            Write-Host "    Error: $errorMsg" -ForegroundColor Red
        }
        return @{ Success = $false; StatusCode = $null; Error = $errorMsg }
    }
}

function Test-Connectivity {
    Write-Host "Meow Proxy Connection Test" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "Site           Direct Proxy  Status"
    Write-Host "-------------- ------ ------ ------"

    $proxyWorksCount = 0
    $totalSites = $sites.Count
    $failedSites = @()

    foreach ($name in $sites.Keys) {
        $url = $sites[$name]
        $directResult = Test-Site $url $false
        $proxyResult = Test-Site $url $true
        
        $d = if ($directResult.Success) { "OK" } else { "X" }
        $p = if ($proxyResult.Success) { "OK" } else { "X" }
        
        if ($proxyResult.Success) {
            $status = "Proxy Works"
            $color = "Green"
            $proxyWorksCount++
        } elseif ($directResult.Success) {
            $status = "Direct Only"
            $color = "Yellow"
        } else {
            $status = "Both Failed"
            $color = "Red"
            $failedSites += @{
                Name = $name
                Url = $url
                DirectError = $directResult.Error
                ProxyError = $proxyResult.Error
            }
        }
        
        Write-Host ("{0,-14} {1,-6} {2,-6} " -f $name, $d, $p) -NoNewline
        Write-Host $status -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "Summary: $proxyWorksCount/$totalSites sites work via proxy" -ForegroundColor $(if ($proxyWorksCount -gt ($totalSites/2)) { "Green" } elseif ($proxyWorksCount -gt 0) { "Yellow" } else { "Red" })
    
    # Show detailed error analysis for failed sites
    if ($failedSites.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed Sites Analysis:" -ForegroundColor Yellow
        Write-Host "=====================" -ForegroundColor Yellow
        
        foreach ($site in $failedSites) {
            Write-Host ""
            Write-Host "$($site.Name) ($($site.Url)):" -ForegroundColor Cyan
            
            # Analyze common error patterns
            $proxyError = $site.ProxyError
            if ($proxyError -match "timeout|timed out") {
                Write-Host "  • Issue: Connection timeout" -ForegroundColor Red
                Write-Host "  • Possible causes: Slow proxy server, network congestion" -ForegroundColor White
            } elseif ($proxyError -match "SSL|certificate|TLS") {
                Write-Host "  • Issue: SSL/TLS certificate problem" -ForegroundColor Red
                Write-Host "  • Possible causes: Proxy SSL handling, certificate validation" -ForegroundColor White
            } elseif ($proxyError -match "403|Forbidden") {
                Write-Host "  • Issue: Access forbidden (403)" -ForegroundColor Red
                Write-Host "  • Possible causes: IP blocked, geo-restriction, rate limiting" -ForegroundColor White
            } elseif ($proxyError -match "502|503|504") {
                Write-Host "  • Issue: Server error ($($proxyError -replace '.*(\d{3}).*','$1'))" -ForegroundColor Red
                Write-Host "  • Possible causes: Target server issues, proxy server overload" -ForegroundColor White
            } elseif ($proxyError -match "DNS|resolve") {
                Write-Host "  • Issue: DNS resolution failed" -ForegroundColor Red
                Write-Host "  • Possible causes: DNS blocking, proxy DNS issues" -ForegroundColor White
            } else {
                Write-Host "  • Direct error: $($site.DirectError)" -ForegroundColor Gray
                Write-Host "  • Proxy error: $($site.ProxyError)" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "Common Solutions:" -ForegroundColor Green
        Write-Host "• Check if Meow is using the correct proxy nodes" -ForegroundColor White
        Write-Host "• Try switching to different proxy servers in Meow" -ForegroundColor White
        Write-Host "• Verify Meow rules are not blocking these domains" -ForegroundColor White
        Write-Host "• Some services may have additional IP/region restrictions" -ForegroundColor White
    }
}

# Main logic
Write-Host "Meow Proxy Manager" -ForegroundColor Magenta
Write-Host "===================" -ForegroundColor Magenta
Write-Host ""

switch ($Action.ToLower()) {
    "on" {
        Set-ProxyOn
        Write-Host ""
        Write-Host "Testing connectivity after enabling proxy..." -ForegroundColor Yellow
        Write-Host ""
        Test-Connectivity
    }
    "off" {
        Set-ProxyOff  
        Write-Host ""
        Write-Host "Testing connectivity after disabling proxy..." -ForegroundColor Yellow
        Write-Host ""
        Test-Connectivity
    }
    "test" {
        Get-ProxyStatus
        Write-Host ""
        Test-Connectivity
    }
    default {
        Write-Host "Usage: .\test_meow_proxy.ps1 [on|off|test]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  on    - Enable proxy environment variables and test" -ForegroundColor White
        Write-Host "  off   - Disable proxy environment variables and test" -ForegroundColor White  
        Write-Host "  test  - Test current proxy status (default)" -ForegroundColor White
        Write-Host ""
        Get-ProxyStatus
        Write-Host ""
        Test-Connectivity
    }
}
