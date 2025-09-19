# Custom Linux Kernel Build

Automatyczne budowanie custom kernel Linux 6.12 dla:
- AMD FX-8350
- NVIDIA GTX 1050 Ti
- Gaming + Programming (Wine, Docker)

## Konfiguracja
- Timer frequency: 1000 HZ
- CPU governor: performance
- Wyłączone niepotrzebne sterowniki GPU
- Optymalizacje dla FX-8350

## Build
Kernel buduje się automatycznie na GitHub Actions przy każdym pushu.

## Instalacja na openSUSE Tumbleweed:

### 1. Pobierz wszystkie artefakty i rozpakuj:
```bash
cd ~/Downloads
unzip kernel-bzImage.zip
unzip kernel-modules.zip
unzip build-info.zip
```

### 2. Zainstaluj jądro:
```bash
# Skopiuj główne pliki jądra
sudo cp bzImage /boot/vmlinuz-6.12-github
sudo cp System.map /boot/System.map-6.12-github
sudo cp config /boot/config-6.12-github

# Stwórz katalog dla modułów
sudo mkdir -p /lib/modules/6.12.0-github

# Rozpakuj i zainstaluj moduły
sudo tar -xf modules.tar -C /lib/modules/6.12.0-github/
```

### 3. Wygeneruj initramfs:
```bash
# openSUSE używa dracut
sudo dracut --force /boot/initrd-6.12-github 6.12.0-github
```

### 4. Aktualizuj bootloader:
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 5. Sprawdź czy jądro jest w menu GRUB:
```bash
grep "6.12-github" /boot/grub2/grub.cfg
```
