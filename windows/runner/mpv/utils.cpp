#include "utils.h"

namespace mpv {

#include <dwmapi.h>

void SetWindowComposition(HWND window, int32_t accent_state,
                          int32_t gradient_color) {
  // If accent_state == 2 (ACCENT_ENABLE_TRANSPARENTGRADIENT), we want transparency.
  // Instead of using the undocumented SetWindowCompositionAttribute, we use
  // the officially supported DwmExtendFrameIntoClientArea to create a glass 
  // effect across the entire window. When the surface renders black (0,0,0,0),
  // DWM will make it fully transparent, revealing the MPV window underneath.
  if (accent_state == 2) {
    MARGINS margins = {-1, -1, -1, -1}; // Extend frame across entire client area
    DwmExtendFrameIntoClientArea(window, &margins);
  } else {
    // Reset standard margins
    MARGINS margins = {0, 0, 0, 0};
    DwmExtendFrameIntoClientArea(window, &margins);
  }
}

}  // namespace mpv
