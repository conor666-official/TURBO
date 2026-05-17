# 🔥 TURBO - Professional IP Changer

**Advanced IP rotation tool for Termux using multi-instance Tor technology**

[![Version](https://img.shields.io/badge/version-3.0-red.svg)](https://github.com/conor666-official/TURBO)
[![Termux](https://img.shields.io/badge/Termux-Compatible-brightgreen.svg)](https://termux.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Proxy Setup](#proxy-setup)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **5x Tor Instances** | Multi-instance Tor for reliable rotation |
| **Real-time Display** | Live IP, location, and countdown timer |
| **Configurable Interval** | 3-60 seconds rotation speed |
| **Auto Logging** | All rotations saved to `~/turbo/turbo.log` |
| **Clean Shutdown** | Automatic cleanup of all processes |

---

## 📱 Requirements

| Requirement | Spec |
|-------------|------|
| Android | 7.0+ |
| RAM | 1GB+ |
| Storage | 50MB |
| App | Termux (F-Droid) |

---

## ⚡ Installation

### One-Line Install

```bash
pkg update -y && pkg install tor privoxy netcat-openbsd curl jq -y && curl -o $PREFIX/bin/turbo https://raw.githubusercontent.com/conor666-official/TURBO/main/turbo.sh && chmod +x $PREFIX/bin/turbo && mkdir -p ~/turbo && echo -e "\033[32m✅ TURBO Installed! Run: turbo -s 5\033[0m"
