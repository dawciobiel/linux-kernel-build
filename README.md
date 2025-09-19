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
