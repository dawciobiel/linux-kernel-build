# Instalacja niestandardowego jądra (custom kernel) na openSUSE Tumbleweed

Ta instrukcja przeprowadzi Cię przez proces instalacji niestandardowego jądra Linuksa na systemie openSUSE Tumbleweed, włączając w to generowanie `initrd` i aktualizację konfiguracji GRUB2.

## Wymagania wstępne

*   Skompilowany plik obrazu jądra (np. `vmlinuz-YOUR_CUSTOM_VERSION`).
*   Uprawnienia administratora (sudo).
*   Zainstalowane narzędzie `dracut` (zazwyczaj jest domyślnie w openSUSE).

---

## Krok 1: Skopiowanie pliku jądra (vmlinuz) do katalogu `/boot`

Skompilowany plik jądra musi znajdować się w katalogu `/boot`, aby GRUB mógł go wykryć.

```bash
sudo cp /ścieżka/do/twojego/vmlinuz-YOUR_CUSTOM_VERSION /boot/
```

**Pamiętaj:**
*   Zastąp `/ścieżka/do/twojego/vmlinuz-YOUR_CUSTOM_VERSION` rzeczywistą ścieżką do Twojego pliku jądra.
*   `YOUR_CUSTOM_VERSION` to unikalna nazwa/wersja Twojego niestandardowego jądra (np. `6.16.7-custom`).

---

## Krok 2: Generowanie Initial Ramdisk (initrd) za pomocą `dracut`

`initrd` (initial ramdisk) jest niezbędny do uruchomienia jądra, ponieważ zawiera sterowniki potrzebne do załadowania głównego systemu plików. Bez niego jądro może nie być w stanie prawidłowo się uruchomić.

```bash
sudo dracut -f /boot/initrd-YOUR_CUSTOM_VERSION.img YOUR_CUSTOM_VERSION
```

**Pamiętaj:**
*   Zastąp `YOUR_CUSTOM_VERSION` dokładnie taką samą nazwą/wersją, jakiej użyłeś dla pliku `vmlinuz`.
*   Polecenie to utworzy plik `initrd` w katalogu `/boot` o nazwie `initrd-YOUR_CUSTOM_VERSION.img`.

---

## Krok 3: Aktualizacja konfiguracji GRUB2

Po skopiowaniu jądra i wygenerowaniu `initrd`, musisz zaktualizować konfigurację GRUB2, aby system rozruchowy wiedział o nowym jądrze i dodał je do menu wyboru.

```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

To polecenie przeskanuje katalog `/boot` i automatycznie wygeneruje nową konfigurację GRUB-a, uwzględniając Twoje niestandardowe jądro.

---

## Krok 4: Weryfikacja (opcjonalnie)

Możesz sprawdzić, czy GRUB2 poprawnie wykrył Twoje niestandardowe jądro, przeglądając wygenerowany plik konfiguracyjny:

```bash
sudo grep "menuentry " /boot/grub2/grub.cfg | grep -i "YOUR_CUSTOM_VERSION"
```

Jeśli zobaczysz wpis zawierający `YOUR_CUSTOM_VERSION`, oznacza to, że jądro zostało pomyślnie dodane do GRUB-a.

**Ostatni krok:**
Uruchom ponownie system (`sudo reboot`) i podczas startu wybierz swoje niestandardowe jądro z menu GRUB-a.
