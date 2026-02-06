#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure Windows Firewall for OpenClaw Gateway
.DESCRIPTION
    Creates firewall rules to allow OpenClaw Gateway connections
.NOTES
    Run this script as Administrator
#>

param(
    [int]$Port = 18789,
    [switch]$RestrictToTailscale,
    [string]$TailscaleNetwork = "100.0.0.0/8"
)

Write-Host "🔧 OpenClaw Windows Firewall Configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Please right-click and select 'Run as Administrator'."
    exit 1
}

# Remove existing rules
Write-Host "🧹 Removing existing OpenClaw firewall rules..." -ForegroundColor Yellow
$existingRules = Get-NetFirewallRule -DisplayName "OpenClaw*" -ErrorAction SilentlyContinue
if ($existingRules) {
    $existingRules | Remove-NetFirewallRule
    Write-Host "✅ Removed existing rules" -ForegroundColor Green
}

# Create new rule
Write-Host ""
Write-Host "🛡️  Creating new firewall rule..." -ForegroundColor Yellow

if ($RestrictToTailscale) {
    # Restrict to Tailscale network only
    Write-Host "   Port: $Port" -ForegroundColor Gray
    Write-Host "   Access: Tailscale network only ($TailscaleNetwork)" -ForegroundColor Gray
    Write-Host "   Protocol: TCP" -ForegroundColor Gray
    
    New-NetFirewallRule `
        -DisplayName "OpenClaw-Tailscale" `
        -Description "Allow OpenClaw Gateway connections from Tailscale network" `
        -Direction Inbound `
        -LocalPort $Port `
        -Protocol TCP `
        -RemoteAddress $TailscaleNetwork `
        -Action Allow `
        -Profile Any
} else {
    # Allow from any network (LAN)
    Write-Host "   Port: $Port" -ForegroundColor Gray
    Write-Host "   Access: Any network (LAN)" -ForegroundColor Gray
    Write-Host "   Protocol: TCP" -ForegroundColor Gray
    
    New-NetFirewallRule `
        -DisplayName "OpenClaw" `
        -Description "Allow OpenClaw Gateway connections from local network" `
        -Direction Inbound `
        -LocalPort $Port `
        -Protocol TCP `
        -Action Allow `
        -Profile Private,Domain
}

Write-Host ""
Write-Host "✅ Firewall rule created successfully!" -ForegroundColor Green
Write-Host ""

# Display current rules
Write-Host "📋 Current OpenClaw firewall rules:" -ForegroundColor Cyan
Get-NetFirewallRule -DisplayName "OpenClaw*" | Format-Table DisplayName, Direction, Action, Enabled -AutoSize
