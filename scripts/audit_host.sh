#!/bin/sh
# Universal Hardware/OS Audit Script
# Compatible with RHEL 6/7/8 and Solaris 10/11
# Usage: ./audit_host.sh

HOST=$(hostname)
OS_NAME=$(uname -s)
OS_VER="Unknown"
CPU_PHYS="Unknown"
MEM_GB="Unknown"

if [ "$OS_NAME" = "Linux" ]; then
    # --- RHEL Detection ---
    if [ -f /etc/redhat-release ]; then
        OS_VER=$(cat /etc/redhat-release | sed 's/,//g')
    else
        OS_VER=$(uname -sr)
    fi

    # --- Hardware (Linux) ---
    # CPU: Physical socket count (fallback to core count if socket not clear)
    if command -v lscpu >/dev/null 2>&1; then
        CPU_PHYS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
    elif [ -f /proc/cpuinfo ]; then
        CPU_PHYS=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
    fi
    
    # Memory: Convert KB to GB
    if [ -f /proc/meminfo ]; then
        MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        MEM_GB=$(expr $MEM_KB / 1024 / 1024)
    fi

elif [ "$OS_NAME" = "SunOS" ]; then
    # --- Solaris Detection ---
    if [ -f /etc/release ]; then
        # Extract first line, remove commas for CSV safety
        OS_VER=$(head -1 /etc/release | tr -d ',' | xargs)
    else
        OS_VER=$(uname -v)
    fi

    # --- Hardware (Solaris) ---
    # CPU: Physical processor count
    if [ -x /usr/sbin/psrinfo ]; then
        # -p reports physical processors
        CPU_PHYS=$(/usr/sbin/psrinfo -p 2>/dev/null)
        # Fallback for very old Solaris without -p flag
        if [ -z "$CPU_PHYS" ]; then
             CPU_PHYS=$(/usr/sbin/psrinfo | wc -l) 
             OS_VER="$OS_VER (Logic CPU Count)"
        fi
    fi

    # Memory: prtconf provides Memory size
    if [ -x /usr/sbin/prtconf ]; then
        MEM_MB=$(/usr/sbin/prtconf 2>/dev/null | grep "Memory size:" | awk '{print $3}')
        if [ ! -z "$MEM_MB" ]; then
            MEM_GB=$(expr $MEM_MB / 1024)
        fi
    fi
fi

# Output CSV Format: Hostname, OS, CPU_Physical, RAM_GB
echo "${HOST},${OS_VER},${CPU_PHYS},${MEM_GB}"