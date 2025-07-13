#!/bin/bash

# SCRIPT INSTALLAZIONE AUTOMATICA DIPENDENZE MONERO MINING
# Questo script installa tutto il necessario per il mining di Monero

set -e

echo "========================================"
echo "🪙  INSTALLAZIONE DIPENDENZE MONERO"
echo "========================================"

# Rileva il sistema operativo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    echo "❌ Sistema operativo non supportato: $OSTYPE"
    exit 1
fi

echo "🔍 Sistema rilevato: $OS"

# Funzione per installare dipendenze Linux
install_linux() {
    echo "🐧 Installazione dipendenze Linux..."
    
    # Rileva la distribuzione
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "❌ Impossibile rilevare la distribuzione Linux"
        exit 1
    fi
    
    echo "   Distribuzione: $DISTRO"
    
    case $DISTRO in
        ubuntu|debian)
            echo "   Aggiornamento repositories..."
            sudo apt update
            
            echo "   Installazione pacchetti..."
            sudo apt install -y python3 python3-pip wget curl build-essential cmake git
            
            # Huge pages
            echo "   Configurazione huge pages..."
            echo 'vm.nr_hugepages=128' | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            
            # Permessi CPU
            echo "   Configurazione permessi CPU..."
            sudo usermod -a -G sudo $USER
            ;;
            
        fedora|centos|rhel)
            echo "   Installazione pacchetti..."
            sudo dnf install -y python3 python3-pip wget curl gcc-c++ cmake git
            
            # Huge pages
            echo "   Configurazione huge pages..."
            echo 'vm.nr_hugepages=128' | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            ;;
            
        arch|manjaro)
            echo "   Installazione pacchetti..."
            sudo pacman -S --noconfirm python python-pip wget curl base-devel cmake git
            
            # Huge pages
            echo "   Configurazione huge pages..."
            echo 'vm.nr_hugepages=128' | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p
            ;;
            
        *)
            echo "⚠️  Distribuzione non riconosciuta. Installazione manuale richiesta."
            echo "   Installa: python3, python3-pip, wget, curl, build-essential, cmake, git"
            ;;
    esac
    
    echo "✅ Dipendenze Linux installate"
}

# Funzione per installare dipendenze macOS
install_macos() {
    echo "🍎 Installazione dipendenze macOS..."
    
    # Controlla se Homebrew è installato
    if ! command -v brew &> /dev/null; then
        echo "   Installazione Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "   Installazione pacchetti..."
    brew install python3 wget curl cmake git
    
    echo "✅ Dipendenze macOS installate"
}

# Funzione per installare dipendenze Windows
install_windows() {
    echo "🪟 Installazione dipendenze Windows..."
    
    # Controlla se Python è installato
    if ! command -v python &> /dev/null; then
        echo "❌ Python non trovato!"
        echo "   Scarica Python da: https://www.python.org/downloads/"
        echo "   Assicurati di selezionare 'Add Python to PATH'"
        exit 1
    fi
    
    # Controlla se Git è installato
    if ! command -v git &> /dev/null; then
        echo "❌ Git non trovato!"
        echo "   Scarica Git da: https://git-scm.com/download/win"
        exit 1
    fi
    
    echo "✅ Dipendenze Windows OK"
}

# Installa dipendenze Python
install_python_deps() {
    echo "🐍 Installazione dipendenze Python..."
    
    python3 -m pip install --upgrade pip
    python3 -m pip install psutil requests urllib3
    
    echo "✅ Dipendenze Python installate"
}

# Ottimizzazioni sistema
optimize_system() {
    echo "⚡ Ottimizzazioni sistema..."
    
    case $OS in
        linux)
            # Huge pages
            echo "   Configurazione huge pages..."
            sudo sh -c 'echo 128 > /proc/sys/vm/nr_hugepages'
            
            # CPU governor
            echo "   Configurazione CPU governor..."
            if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
                echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
            fi
            
            # Swappiness
            echo "   Configurazione swappiness..."
            echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
            ;;
            
        macos)
            echo "   Configurazione macOS..."
            # Disabilita App Nap per evitare throttling
            defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
            ;;
            
        windows)
            echo "   Configurazione Windows..."
            echo "   Configura manualmente:"
            echo "   - Disabilita risparmio energetico"
            echo "   - Imposta prestazioni elevate"
            echo "   - Disabilita Windows Defender per la cartella mining"
            ;;
    esac
    
    echo "✅ Ottimizzazioni applicate"
}

# Crea script di avvio
create_launcher() {
    echo "📄 Creazione script di avvio..."
    
    # Crea directory
    mkdir -p monero_mining_complete
    cd monero_mining_complete
    
    # Scarica lo script principale
    echo "   Download script principale..."
    curl -o complete_setup.py https://raw.githubusercontent.com/user/repo/main/complete_setup.py 2>/dev/null || {
        echo "   Creazione script locale..."
        cat > complete_setup.py << 'EOF'
# Il contenuto dello script Python principale va qui
# Per ora creiamo un placeholder
print("🪙 Script Monero Mining")
print("Esegui: python3 complete_setup.py")
EOF
    }
    
    # Crea launcher
    case $OS in
        linux|macos)
            cat > start_setup.sh << 'EOF'
#!/bin/bash
echo "🚀 Avvio setup Monero Mining..."
python3 complete_setup.py
EOF
            chmod +x start_setup.sh
            echo "✅ Launcher creato: ./start_setup.sh"
            ;;
            
        windows)
            cat > start_setup.bat << 'EOF'
@echo off
echo 🚀 Avvio setup Monero Mining...
python complete_setup.py
pause
EOF
            echo "✅ Launcher creato: start_setup.bat"
            ;;
    esac
    
    cd ..
}

# Controllo finale
final_check() {
    echo "🔍 Controllo finale..."
    
    # Verifica Python
    if python3 --version &> /dev/null; then
        echo "✅ Python3: $(python3 --version)"
    else
        echo "❌ Python3 non trovato"
        exit 1
    fi
    
    # Verifica pip
    if python3 -m pip --version &> /dev/null; then
        echo "✅ pip: $(python3 -m pip --version)"
    else
        echo "❌ pip non trovato"
        exit 1
    fi
    
    # Verifica psutil
    if python3 -c "import psutil; print('psutil:', psutil.__version__)" &> /dev/null; then
        echo "✅ psutil installato"
    else
        echo "❌ psutil non installato"
        exit 1
    fi
    
    echo "✅ Tutti i controlli superati"
}

# Esecuzione principale
main() {
    echo "🔧 Inizio installazione..."
    
    case $OS in
        linux)
            install_linux
            ;;
        macos)
            install_macos
            ;;
        windows)
            install_windows
            ;;
    esac
    
    install_python_deps
    optimize_system
    create_launcher
    final_check
    
    echo ""
    echo "========================================"
    echo "🎉 INSTALLAZIONE COMPLETATA!"
    echo "========================================"
    echo "📁 Directory: monero_mining_complete"
    echo "🚀 Per iniziare:"
    
    case $OS in
        linux|macos)
            echo "   cd monero_mining_complete"
            echo "   ./start_setup.sh"
            ;;
        windows)
            echo "   cd monero_mining_complete"
            echo "   start_setup.bat"
            ;;
    esac
    
    echo ""
    echo "💡 Consigli:"
    echo "   - Chiudi altri programmi pesanti"
    echo "   - Monitora le temperature"
    echo "   - Usa un UPS per evitare interruzioni"
    echo "   - Controlla regolarmente le statistiche"
    echo "========================================"
}

# Esegui solo se script chiamato direttamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
