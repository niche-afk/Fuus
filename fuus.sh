#!/usr/bin/fish

# update_fedora.fish - Update and upgrade Fedora packages
# Medium verbosity with error checking and restart prompts

function main
    echo "=== Fedora System Update Script ==="
    echo ""

    # Refresh repository metadata
    echo "Refreshing repository metadata..."
    dnf check-update --refresh
    set refresh_status $status
    
    if test $refresh_status -eq 100
        echo "Updates are available"
    else if test $refresh_status -ne 0
        echo "Error: Failed to refresh repository metadata"
        return 1
    else
        echo "No updates available. System is up to date."
        return 0
    end

    echo ""
    
    # Perform upgrade (includes built-in confirmation prompt)
    echo "Starting package upgrade..."
    dnf upgrade
    set upgrade_status $status
    
    if test $upgrade_status -ne 0
        echo ""
        echo "Error: Package upgrade failed with exit code $upgrade_status"
        return 1
    end

    echo ""
    echo "Package upgrade completed successfully"
    echo ""

    # Check and update Flatpaks
    echo "=== Checking for Flatpak updates ==="
    
    if command -v flatpak > /dev/null
        echo "Checking for Flatpak updates..."
        flatpak remote-ls --updates
        set flatpak_check_status $status
        
        if test $flatpak_check_status -eq 0
            set updates_available (flatpak remote-ls --updates 2>/dev/null)
            
            if test -n "$updates_available"
                echo ""
                echo "Starting Flatpak update..."
                flatpak update
                set flatpak_status $status
                
                if test $flatpak_status -ne 0
                    echo "Warning: Flatpak update encountered issues (exit code $flatpak_status)"
                else
                    echo "Flatpak updates completed successfully"
                end
            else
                echo "No Flatpak updates available"
            end
        else
            echo "No Flatpak updates available"
        end
    else
        echo "Flatpak is not installed, skipping Flatpak updates"
    end
    
    echo ""

    # Check what needs restarting
    echo "Checking for services/processes that need restarting..."
    dnf needs-restarting -r
    set reboot_status $status
    
    echo ""
    
    if test $reboot_status -eq 1
        # System reboot required
        echo "⚠ System reboot is required (kernel, systemd, or glibc updated)"
        echo ""
        read -p "echo 'Do you want to reboot now? [y/N]: '" -n 1 reboot_choice
        echo ""
        
        if string match -qi "y" $reboot_choice
            echo "Rebooting system in 5 seconds... (Ctrl+C to cancel)"
            sleep 5
            systemctl reboot
        else
            echo "Reboot cancelled. Please remember to reboot later."
        end
    else
        # Check for services that need restarting
        echo "Checking for services that need restarting..."
        dnf needs-restarting -s
        
        if test $status -eq 1
            echo ""
            echo "ℹ Some services need restarting, but system reboot is not required"
            echo "You may want to restart affected services or log out and back in"
        else
            echo "No restart required. System is ready to use."
        end
    end
    
    return 0
end

# Run main function
main
