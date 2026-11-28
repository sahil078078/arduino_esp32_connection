# Arduino & ESP32 Controller Project Guidelines

## Identity & Contact
- Developer: **Sahil Prajapati** (`sahil078078@gmail.com`)
- Repository: Arduino & ESP32 Multi-Board Controller (Flutter)

## Architecture Rules
1. **Typography**: Always use **Poppins** (`GoogleFonts.poppins`) for all typography.
2. **Colors**: Primary Orange `#FF7900`, Background `#F7F8FA`, Card `#FFFFFF`, Border `#E2E8F0`.
3. **Custom Widgets**:
   - Dropdowns: Use `CustomDropdownBtn<T>` from `lib/src/commons/custom_drop_down_btn.dart`.
   - Action Buttons: Use `CustomBtn` from `lib/src/commons/btn/custom_btn.dart`.
   - Modals / Sheets Close: Use `CustomCloseBtn` from `lib/src/commons/btn/custom_close_btn.dart`.
   - Toggles: Use `CustomSwitchTile` from `lib/src/commons/custom_switch_tile.dart`.
   - Input Fields: Use `CustomFormField` with `AppValidator`.
4. **AppBars**:
   - Keep AppBars clean, minimal, and decluttered.
   - Title must not exceed 18px and must avoid overflowing on mobile screens.
   - Use compact StatusBadges and subtle divider borders.
5. **WiFi & Connectivity**:
   - Support both **HTTP Web Server** (port 80) and **TCP Socket** (port 8080).
   - Support both **SoftAP Hotspot** (`192.168.4.1`) and **Station** router IP.
   - Provide in-app browser & live HTML inspector for viewing the ESP32 server interface.
6. **Hardware Pin Mappings**:
   - Follow the microcontroller definitions in `lib/models/board_model.dart` and the `arduino-esp32-architecture` skill.
