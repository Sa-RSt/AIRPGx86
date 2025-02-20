%ifndef COLORS_INC
%define COLORS_INC

section .data

; fonte: pygments.console.codes

color_reset: db 27, "[39;49;00m", 0
color_bold: db 27, "[01m", 0
color_faint: db 27, "[02m", 0
color_standout: db 27, "[03m", 0
color_underline: db 27, "[04m", 0
color_blink: db 27, "[05m", 0
color_overline: db 27, "[06m", 0
color_black: db 27, "[30m", 0
color_brightblack: db 27, "[90m", 0
color_red: db 27, "[31m", 0
color_brightred: db 27, "[91m", 0

color_green: db 27, "[32m", 0
color_brightgreen: db 27, "[92m", 0
color_yellow: db 27, "[33m", 0
color_brightyellow: db 27, "[93m", 0
color_blue: db 27, "[34m", 0
color_brightblue: db 27, "[94m", 0

color_magenta: db 27, "[35m", 0
color_brightmagenta: db 27, "[95m", 0
color_cyan: db 27, "[36m", 0
color_brightcyan: db 27, "[96m", 0
color_gray: db 27, "[37m", 0
color_white: db 27, "[01m", 0

%assign i 0
%rep 256

    color_by_id_%[i]: db 27, 91, 51, 56, 59, 53, 59, %str(i), 109, 0

    %assign i i + 1
%endrep
%undef i

%endif
