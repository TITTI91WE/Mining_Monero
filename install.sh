#!/usr/bin/env python3
"""
SETUP COMPLETO MINING MONERO
Script automatico per configurare tutto il necessario per il mining di Monero
"""

import os
import sys
import subprocess
import json
import time
import platform
import urllib.request
import zipfile
import shutil
from pathlib import Path
import psutil
import hashlib

class CompleteMoneroSetup:
    def __init__(self):
        self.system = platform.system().lower()
        self.wallet_address = "47DS5GeMMXf9wV8RqtU2QBKPLpwkWtAXKcpDdctrX2pqdSsdxQEVYr8jX626cgvYawHsRUpeELhs4P3vVC97iHMd6mSodRX"
        self.xmrig_path = None
        self.config_path = "config.json"
        self.setup_dir = Path("monero_mining_setup")
        
        # URLs per download XMRig
        self.xmrig_urls = {
            "windows": "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip",
            "linux": "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz",
            "darwin": "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-macos-x64.tar.gz"
        }
        
        # Configurazione ottimizzata
        self.config = None
        self.system_info = self.get_system_info()
        
    def print_banner(self):
        """Stampa il banner di benvenuto"""
        print("=" * 80)
        print("🪙  SETUP COMPLETO MINING MONERO")
        print("=" * 80)
        print("🚀 Questo script configurerà tutto automaticamente:")
        print("   ✅ Download e installazione XMRig")
        print("   ✅ Configurazione ottimizzata per il tuo hardware")
        print("   ✅ Setup pool di mining")
        print("   ✅ Ottimizzazioni sistema")
        print("   ✅ Avvio automatico mining")
        print("=" * 80)
        
    def get_system_info(self):
        """Ottiene informazioni dettagliate sul sistema"""
        try:
            info = {
                "os": platform.system(),
                "architecture": platform.architecture()[0],
                "cpu_count": psutil.cpu_count(logical=False),
                "cpu_threads": psutil.cpu_count(logical=True),
                "ram_total": psutil.virtual_memory().total // (1024**3),
                "ram_available": psutil.virtual_memory().available // (1024**3)
            }
            return info
        except:
            return {
                "os": platform.system(),
                "architecture": platform.architecture()[0],
                "cpu_count": os.cpu_count(),
                "cpu_threads": os.cpu_count(),
                "ram_total": 8,
                "ram_available": 6
            }
    
    def create_setup_directory(self):
        """Crea la directory per il setup"""
        print("📁 Creazione directory di setup...")
        self.setup_dir.mkdir(exist_ok=True)
        print(f"✅ Directory creata: {self.setup_dir}")
        
    def download_xmrig(self):
        """Scarica XMRig automaticamente"""
        print("📥 Download XMRig...")
        
        if self.system not in self.xmrig_urls:
            print(f"❌ Sistema {self.system} non supportato per download automatico")
            return False
        
        url = self.xmrig_urls[self.system]
        filename = url.split("/")[-1]
        filepath = self.setup_dir / filename
        
        try:
            print(f"   Scaricando da: {url}")
            urllib.request.urlretrieve(url, filepath)
            print(f"✅ Download completato: {filename}")
            
            # Estrai l'archivio
            print("📦 Estrazione archivio...")
            if filename.endswith('.zip'):
                with zipfile.ZipFile(filepath, 'r') as zip_ref:
                    zip_ref.extractall(self.setup_dir)
            elif filename.endswith('.tar.gz'):
                import tarfile
                with tarfile.open(filepath, 'r:gz') as tar_ref:
                    tar_ref.extractall(self.setup_dir)
            
            print("✅ Estrazione completata")
            
            # Trova l'eseguibile XMRig
            for root, dirs, files in os.walk(self.setup_dir):
                for file in files:
                    if file.startswith('xmrig') and (file.endswith('.exe') or not '.' in file):
                        self.xmrig_path = os.path.join(root, file)
                        print(f"✅ XMRig trovato: {self.xmrig_path}")
                        
                        # Rendi eseguibile su Linux/macOS
                        if self.system != 'windows':
                            os.chmod(self.xmrig_path, 0o755)
                        
                        return True
            
            print("❌ Eseguibile XMRig non trovato nell'archivio")
            return False
            
        except Exception as e:
            print(f"❌ Errore durante il download: {e}")
            return False
    
    def optimize_system(self):
        """Ottimizza il sistema per il mining"""
        print("⚡ Ottimizzazione sistema...")
        
        optimizations = []
        
        # Huge pages (Linux)
        if self.system == 'linux':
            try:
                # Controlla se huge pages sono disponibili
                with open('/proc/meminfo', 'r') as f:
                    meminfo = f.read()
                    if 'HugePages_Total' in meminfo:
                        optimizations.append("✅ Huge pages disponibili")
                    else:
                        optimizations.append("⚠️  Huge pages non disponibili")
            except:
                optimizations.append("⚠️  Impossibile verificare huge pages")
        
        # CPU affinity
        cpu_threads = self.system_info['cpu_threads']
        recommended_threads = max(1, cpu_threads - 2)  # Lascia 2 thread per il sistema
        optimizations.append(f"✅ Thread consigliati: {recommended_threads}/{cpu_threads}")
        
        # RAM check
        ram_needed = recommended_threads * 2  # 2GB per thread
        ram_available = self.system_info['ram_available']
        if ram_available >= ram_needed:
            optimizations.append(f"✅ RAM sufficiente: {ram_available}GB/{ram_needed}GB")
        else:
            optimizations.append(f"⚠️  RAM limitata: {ram_available}GB/{ram_needed}GB")
        
        for opt in optimizations:
            print(f"   {opt}")
        
        return recommended_threads
    
    def create_optimized_config(self, threads):
        """Crea configurazione ottimizzata"""
        print("⚙️  Creazione configurazione ottimizzata...")
        
        # Configurazione base ottimizzata
        self.config = {
            "api": {
                "id": None,
                "worker-id": None
            },
            "http": {
                "enabled": False,
                "host": "127.0.0.1",
                "port": 0,
                "access-token": None,
                "restricted": True
            },
            "autosave": True,
            "background": False,
            "colors": True,
            "title": True,
            "randomx": {
                "init": -1,
                "init-avx2": -1,
                "mode": "auto",
                "1gb-pages": False,
                "rdmsr": True,
                "wrmsr": True,
                "cache_qos": False,
                "numa": True,
                "scratchpad_prefetch_mode": 1
            },
            "cpu": {
                "enabled": True,
                "huge-pages": True,
                "huge-pages-jit": False,
                "hw-aes": None,
                "priority": 2,
                "memory-pool": False,
                "yield": True,
                "max-threads-hint": 100,
                "asm": True,
                "argon2-impl": None,
                "astrobwt-max-size": 550,
                "astrobwt-avx2": False,
                "cn/0": False,
                "cn-lite/0": False,
                "kawpow": False,
                "rx": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
                "rx/wow": [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                "cn/gpu": [0, 1, 2, 3, 4, 5, 6, 7],
                "cn-pico": [0, 1, 2, 3, 4, 5, 6, 7],
                "cn-pico/tlo": [0, 1, 2, 3, 4, 5, 6, 7],
                "argon2": [0, 1, 2, 3, 4, 5, 6, 7]
            },
            "opencl": {
                "enabled": False,
                "cache": True,
                "loader": None,
                "platform": "AMD",
                "adl": True,
                "cn/0": False,
                "cn-lite/0": False
            },
            "cuda": {
                "enabled": False,
                "loader": None,
                "nvml": True,
                "cn/0": False,
                "cn-lite/0": False
            },
            "donate-level": 1,
            "donate-over-proxy": 1,
            "log-file": None,
            "pools": [
                {
                    "algo": "rx/0",
                    "coin": "monero",
                    "url": "pool.supportxmr.com:443",
                    "user": self.wallet_address,
                    "pass": "x",
                    "rig-id": f"rig_{platform.node()}",
                    "nicehash": False,
                    "keepalive": True,
                    "enabled": True,
                    "tls": True,
                    "tls-fingerprint": None,
                    "daemon": False,
                    "socks5": None,
                    "self-select": None,
                    "submit-to-origin": False
                }
            ],
            "print-time": 60,
            "health-print-time": 60,
            "dmi": True,
            "retries": 5,
            "retry-pause": 5,
            "syslog": False,
            "tls": {
                "enabled": False,
                "protocols": None,
                "cert": None,
                "cert_key": None,
                "ciphers": None,
                "ciphersuites": None,
                "dhparam": None
            },
            "dns": {
                "ipv6": False,
                "ttl": 30
            },
            "user-agent": None,
            "verbose": 0,
            "watch": True,
            "pause-on-battery": False,
            "pause-on-active": False
        }
        
        # Ottimizza i thread CPU
        if threads < self.system_info['cpu_threads']:
            # Configurazione thread specifica
            thread_config = []
            for i in range(threads):
                thread_config.append({
                    "intensity": 1,
                    "threads": 1,
                    "affinity": i
                })
            self.config["cpu"]["rx"] = thread_config
        
        # Salva configurazione
        config_path = self.setup_dir / self.config_path
        with open(config_path, 'w') as f:
            json.dump(self.config, f, indent=2)
        
        print(f"✅ Configurazione salvata: {config_path}")
        return config_path
    
    def estimate_performance(self, threads):
        """Stima le performance di mining"""
        print("📊 Stima performance...")
        
        # Stima hash rate basata su CPU threads
        base_hashrate = 150  # H/s per thread medio
        estimated_hashrate = threads * base_hashrate
        
        # Stima guadagni (approssimativa)
        network_hashrate = 2800000000  # H/s (circa 2.8 GH/s)
        block_reward = 0.6  # XMR per blocco
        blocks_per_day = 720  # Circa 2 minuti per blocco
        
        daily_xmr = (estimated_hashrate / network_hashrate) * block_reward * blocks_per_day
        
        print(f"   💎 Hash rate stimato: {estimated_hashrate:,} H/s")
        print(f"   💰 Guadagno stimato: ~{daily_xmr:.6f} XMR/giorno")
        print(f"   🔥 Potenza stimata: ~{threads * 65}W")
        
        return estimated_hashrate
    
    def create_batch_files(self, config_path):
        """Crea file batch per avvio facile"""
        print("📄 Creazione file di avvio...")
        
        if self.system == 'windows':
            # Batch file Windows
            batch_content = f'''@echo off
title Monero Mining
cd /d "{self.setup_dir.absolute()}"
echo Starting Monero Mining...
echo Wallet: {self.wallet_address[:20]}...
echo Press Ctrl+C to stop
"{self.xmrig_path}" --config "{config_path}"
pause
'''
            batch_file = self.setup_dir / "start_mining.bat"
            with open(batch_file, 'w') as f:
                f.write(batch_content)
            print(f"✅ File batch creato: {batch_file}")
            
        else:
            # Script bash Linux/macOS
            bash_content = f'''#!/bin/bash
cd "{self.setup_dir.absolute()}"
echo "Starting Monero Mining..."
echo "Wallet: {self.wallet_address[:20]}..."
echo "Press Ctrl+C to stop"
"{self.xmrig_path}" --config "{config_path}"
'''
            bash_file = self.setup_dir / "start_mining.sh"
            with open(bash_file, 'w') as f:
                f.write(bash_content)
            os.chmod(bash_file, 0o755)
            print(f"✅ Script bash creato: {bash_file}")
    
    def create_monitoring_script(self):
        """Crea script di monitoraggio"""
        print("📈 Creazione script di monitoraggio...")
        
        monitor_content = f'''#!/usr/bin/env python3
import time
import psutil
import json
from datetime import datetime

def monitor_mining():
    print("🔍 Monitoraggio Mining Monero")
    print("=" * 50)
    
    while True:
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # RAM usage
            ram = psutil.virtual_memory()
            ram_percent = ram.percent
            
            # Temperature (se disponibile)
            temp = "N/A"
            try:
                temps = psutil.sensors_temperatures()
                if temps:
                    temp = f"{{list(temps.values())[0][0].current:.1f}}°C"
            except:
                pass
            
            # Timestamp
            timestamp = datetime.now().strftime("%H:%M:%S")
            
            print(f"[{{timestamp}}] CPU: {{cpu_percent:5.1f}}% | RAM: {{ram_percent:5.1f}}% | Temp: {{temp}}")
            
            time.sleep(30)
            
        except KeyboardInterrupt:
            print("\\n👋 Monitoraggio terminato")
            break
        except Exception as e:
            print(f"❌ Errore: {{e}}")
            time.sleep(5)

if __name__ == "__main__":
    monitor_mining()
'''
        
        monitor_file = self.setup_dir / "monitor.py"
        with open(monitor_file, 'w') as f:
            f.write(monitor_content)
        
        if self.system != 'windows':
            os.chmod(monitor_file, 0o755)
        
        print(f"✅ Script monitoraggio creato: {monitor_file}")
    
    def start_mining(self, config_path):
        """Avvia il mining"""
        print("\n🚀 AVVIO MINING")
        print("=" * 50)
        print(f"💰 Wallet: {self.wallet_address[:20]}...")
        print("🏊 Pool: SupportXMR")
        print("⚙️  Configurazione: Ottimizzata")
        print("=" * 50)
        print("📊 Statistiche in tempo reale:")
        print("   - Hash rate corrente")
        print("   - Shares accettate/rifiutate")
        print("   - Temperatura CPU")
        print("   - Utilizzo risorse")
        print("=" * 50)
        print("⏹️  Premi Ctrl+C per fermare il mining")
        print("=" * 50)
        
        input("Premi INVIO per iniziare il mining...")
        
        try:
            # Avvia XMRig
            command = [self.xmrig_path, "--config", str(config_path)]
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            # Mostra output in tempo reale
            for line in iter(process.stdout.readline, ''):
                print(line.rstrip())
            
            process.wait()
            
        except KeyboardInterrupt:
            print("\\n⏹️  Mining interrotto dall'utente")
            process.terminate()
            process.wait()
        except Exception as e:
            print(f"❌ Errore durante il mining: {e}")
    
    def run_complete_setup(self):
        """Esegue il setup completo"""
        self.print_banner()
        
        print("\\n🔍 ANALISI SISTEMA")
        print("-" * 40)
        print(f"OS: {self.system_info['os']} ({self.system_info['architecture']})")
        print(f"CPU: {self.system_info['cpu_count']} core, {self.system_info['cpu_threads']} thread")
        print(f"RAM: {self.system_info['ram_total']}GB totale, {self.system_info['ram_available']}GB disponibile")
        
        input("\\nPremi INVIO per continuare...")
        
        # 1. Crea directory
        self.create_setup_directory()
        
        # 2. Scarica XMRig
        if not self.download_xmrig():
            print("❌ Impossibile scaricare XMRig. Setup interrotto.")
            return
        
        # 3. Ottimizza sistema
        recommended_threads = self.optimize_system()
        
        # 4. Crea configurazione
        config_path = self.create_optimized_config(recommended_threads)
        
        # 5. Stima performance
        self.estimate_performance(recommended_threads)
        
        # 6. Crea file di avvio
        self.create_batch_files(config_path)
        
        # 7. Crea script monitoraggio
        self.create_monitoring_script()
        
        print("\\n✅ SETUP COMPLETATO!")
        print("=" * 50)
        print("📁 Tutti i file sono stati creati in:", self.setup_dir)
        print("🚀 Per avviare il mining:")
        if self.system == 'windows':
            print(f"   Doppio click su: {self.setup_dir}/start_mining.bat")
        else:
            print(f"   Esegui: {self.setup_dir}/start_mining.sh")
        print("📈 Per monitorare:")
        print(f"   Esegui: python {self.setup_dir}/monitor.py")
        print("=" * 50)
        
        # Chiedi se avviare subito
        start_now = input("\\nVuoi avviare il mining ora? (y/n): ").lower()
        if start_now == 'y':
            self.start_mining(config_path)

def main():
    """Funzione principale"""
    try:
        setup = CompleteMoneroSetup()
        setup.run_complete_setup()
    except KeyboardInterrupt:
        print("\\n👋 Setup interrotto dall'utente")
    except Exception as e:
        print(f"❌ Errore durante il setup: {e}")

if __name__ == "__main__":
    main()
