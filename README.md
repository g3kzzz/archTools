# 📦 archTools  

Instalador automático de herramientas de **hacking, pentesting y CTFs** en **Arch Linux** y derivados.  
Este script configura repositorios, instala dependencias, añade herramientas esenciales y prepara wordlists y exploits para que tengas un entorno listo para la acción.  

---

## ⚙️ Características  

✅ Configura el repositorio de **BlackArch**  
✅ Instala **yay** para manejar paquetes del AUR  
✅ Instala herramientas de **reconocimiento, explotación y post-explotación**  
✅ Configura librerías de **Ruby** y dependencias de **Responder**  
✅ Descarga y organiza **SecLists** y wordlists adicionales  
✅ Clona repositorios personales de **g3tools** y **g3web**  
✅ Añade binarios al `PATH` automáticamente  

---

## 🛠️ Herramientas instaladas  

### 🔎 Reconocimiento y enumeración  
- [arp-scan](https://linux.die.net/man/1/arp-scan) – Escaneo de red vía ARP  
- [net-tools](https://wiki.archlinux.org/title/Net-tools) – ifconfig, netstat, etc.  
- [whois](https://linux.die.net/man/1/whois) – Información de dominios/IP  
- [bind-tools](https://wiki.archlinux.org/title/BIND) – Incluye `dig` y `nslookup`  
- [finalrecon](https://github.com/thewhiteh4t/FinalRecon) – Información de sitios web  
- [ffuf](https://github.com/ffuf/ffuf) – Fuzzing de directorios y parámetros  
- [nmap-git](https://nmap.org/) – Escaneo avanzado de red  
- [whatweb](https://github.com/urbanadventurer/WhatWeb) – Detección de tecnologías web  
- [subfinder](https://github.com/projectdiscovery/subfinder) – Descubrimiento de subdominios  
- [enum4linux](https://github.com/CiscoCXSecurity/enum4linux) – Enumeración de servidores Windows  
- [smtp-user-enum](https://pentestmonkey.net/tools/user-enumeration/smtp-user-enum) – Enumeración de usuarios vía SMTP  
- [gobuster](https://github.com/OJ/gobuster) – Descubrimiento de directorios/archivos  

### 📡 Análisis de tráfico y red  
- [Wireshark](https://www.wireshark.org/) – Análisis de tráfico de red  
- [netcat](http://nc110.sourceforge.net/) – Conexiones TCP/UDP simples  
- [socat](http://www.dest-unreach.org/socat/) – Redirección avanzada de tráfico  

### 🔐 Acceso remoto y VPN  
- [OpenSSH](https://www.openssh.com/) – Conexiones seguras SSH  
- [FreeRDP](https://www.freerdp.com/) – RDP a sistemas Windows  
- [OpenVPN](https://openvpn.net/) – VPN segura  

### 🔑 Cracking y ataques  
- [hashcat](https://hashcat.net/hashcat/) – Cracking de contraseñas con GPU  
- [john the ripper](https://www.openwall.com/john/) – Cracking en CPU  
- [medusa](https://github.com/jmk-foofus/medusa) – Ataques de fuerza bruta  
- [hydra](https://github.com/vanhauser-thc/thc-hydra) – Fuerza bruta contra múltiples servicios  
- [hash-identifier](https://github.com/blackploit/hash-identifier) – Identificación de hashes  
- [responder](https://github.com/lgandx/Responder) – Captura hashes y ataques NTLM  

### 💣 Explotación y post-explotación  
- [Metasploit](https://www.metasploit.com/) – Framework de explotación  
- [ExploitDB (searchsploit)](https://www.exploit-db.com/) – Búsqueda de exploits locales  
- [Evil-WinRM](https://github.com/Hackplayers/evil-winrm) – Conexión a Windows via WinRM  
- [Crowbar](https://github.com/galkan/crowbar) – Ataques de fuerza bruta a RDP/SSH/VNC  
- [proxychains-ng](https://github.com/haad/proxychains) – Redirección de tráfico por proxies  
- [netexec](https://github.com/Pennyw0rth/NetExec) – Ejecución remota de comandos en Windows/Linux  
- [Powershell (binario Linux)](https://github.com/PowerShell/PowerShell)  

### 🗄️ Bases de datos  
- [mssql-tools](https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility) – Cliente MSSQL  
- [go-sqlcmd](https://github.com/microsoft/go-sqlcmd) – Cliente SQL moderno  

---

## 📂 Wordlists y SecLists  

El instalador clona y organiza automáticamente:  
- [SecLists](https://github.com/danielmiessler/SecLists)  
- [Wordlists g3](https://github.com/g333k/wordlists)  
- Descompresión automática de wordlists comunes (rockyou, dirbuster, nmap.lst, etc.)  

📌 Se almacenan en:  
```bash
/usr/share/wordlists
/usr/share/SecLists

🚀 Instalación

git clone https://github.com/g333k/archTools.git
cd archTools
chmod +x install.sh
./install.sh

    ⚠️ Debes ejecutarlo como usuario normal (no root).

🧩 Repositorios adicionales

    g3tools – Scripts auxiliares Linux/Windows

    g3web – Webshells y payloads web

📝 Notas

    El script añade automáticamente al PATH las rutas necesarias.

    Se corrigen dependencias de Ruby (para WhatWeb y Evil-WinRM).

    Responder se ajusta con dependencias de pip.

📖 Documentación recomendada

    ArchWiki - Pacman

    BlackArch Linux

    Offensive Security ExploitDB

    Kali Tools List
