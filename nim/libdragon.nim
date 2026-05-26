##
##  @file libdragon.h
##  @author Jennifer Taylor <dragonminded@dragonminded.com>
##  @author Giovanni Bajo <giovannibajo@gmail.com>
##  @brief Main include file for programs seeking to link against libdragon
##  @ingroup libdragon
##

##
##  @defgroup libdragon libdragon
##  @brief Low level runtime for homebrew development on the N64 platform.
##
##  libdragon handles the hardware interfaces to the various systems in the N64.
##  The audio interface is handled by the @ref audio.  The controller interface,
##  controller peripheral interface and EEPROM interface are handled by the
##  @ref controller.  The display interface and RDP rasterizer are handled by
##  the @ref display.  System timers are handled by the @ref timer.
##  Low level interfaces such as interrupts, caching operations, exceptions and
##  the DMA controller are handled by the @ref lowlevel.
##
##  Easy include wrapper

import
  n64types, fmath, fgeom, fgeom2d, audio, entropy, console, emux, debug, fat, joybus,
  joybus_accessory, pixelfx, joypad, controller, rtc, bio_sensor, mempak, cpak, cpakfs,
  vi, eia608, tpak, display, dma, dragonfs, asset, pifile, eeprom, eepromfs, graphics, mi,
  interrupt, kernel, kirq, kqueue, ksemaphore, n64sys, vaddr64, dd, backtrace, rdp, rsp,
  timer, exception, dir, yuv, subtitles, fmv, video, mpeg1, h264, mixer, samplebuffer,
  wav64, xm64, ym64, rspq, rdpq, rdpq_tri, rdpq_rect, rdpq_attach, rdpq_mode, rdpq_tex,
  rdpq_sprite, rdpq_text, rdpq_paragraph, rdpq_font, rdpq_debug, rdpq_macros,
  rdpq_mat, rdpq_xform, surface, sprite, debugcpp, dlfcn, model64, skc, nand, bbfs, ioctl,
  a3d, profile, coroutine
