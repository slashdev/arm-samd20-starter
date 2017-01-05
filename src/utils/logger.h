/**
 * @file logger.h
 * @brief Log over usart functionality
 *
 * \copyright Copyright 2017 /Dev. All rights reserved.
 * \license This project is released under MIT license.
 *
 * The logger can work with any of the SERCOM interfaces. To build
 * `logger_init` you call `LOGGER_BUILD` with the parameters how
 * you want use the SERCOM interface. The `LOGGER_BUILD` is
 * structured as follows:
 * LOGGER_BUILD(sercom, tx_port, tx_pin, rx_port, rx_pin, rx_pad)
 * - sercom:  the SERCOM interface number you'd like to use (e.g. 3)
 * - tx_port: the PORT of the TX output (e.g. A)
 * - tx_pin:  the PIN of the TX output (e.g. 14)
 * - rx_port: the PORT of the RX input (e.g. A)
 * - rx_pin:  the PIN of the RX input (e.g. 15)
 * - rx_pad:  the PAD to use for RX input on the SERCOM interface
 *     (e.g. 1, see datasheet)
 *
 *  Before you can use the logger functions, initialize the logger
 *  using `logger_init(baudrate);`.
 *
 * @author Ferdi van der Werf <ferdi@slashdev.nl>
 */

#ifndef _UTILS_LOGGER_H_
#define _UTILS_LOGGER_H_

// Do we want logging?
#ifdef UTILS_LOGGER

#include <stdint.h>

#define LOGGER_BUILD(sercom, tx_port, tx_pin, rx_port, rx_pin, rx_pad) \
  HAL_GPIO_PIN(LOGGER_TX, tx_port, tx_pin); \
  HAL_GPIO_PIN(LOGGER_RX, rx_port, rx_pin); \
  \
  void logger_usart_queue(char c) \
  { \
    while (!(SERCOM##sercom->USART.INTFLAG.reg & SERCOM_USART_INTFLAG_DRE)); \
    SERCOM##sercom->USART.DATA.reg = c; \
  } \
  \
  static inline void logger_init(uint32_t baud) \
  { \
    /* Set TX as output */ \
    HAL_GPIO_LOGGER_TX_out(); \
    HAL_GPIO_LOGGER_TX_pmuxen(PORT_PMUX_PMUXE_C_Val); \
    /* Set RX as input */ \
    HAL_GPIO_LOGGER_RX_in(); \
    HAL_GPIO_LOGGER_RX_pmuxen(PORT_PMUX_PMUXE_C_Val); \
    \
    /* Enable clock for peripheral, without prescaler */ \
    PM->APBCMASK.reg |= PM_APBCMASK_SERCOM##sercom; \
    GCLK->CLKCTRL.reg = \
      GCLK_CLKCTRL_ID(SERCOM##sercom##_GCLK_ID_CORE) | \
      GCLK_CLKCTRL_CLKEN | \
      GCLK_CLKCTRL_GEN(0); \
    \
    SERCOM##sercom->USART.CTRLA.reg = \
      SERCOM_USART_CTRLA_DORD | \
      SERCOM_USART_CTRLA_MODE_USART_INT_CLK | \
      SERCOM_USART_CTRLA_TXPO | \
      SERCOM_USART_CTRLA_RXPO(rx_pad); \
    \
    SERCOM##sercom->USART.CTRLB.reg = \
      SERCOM_USART_CTRLB_RXEN | \
      SERCOM_USART_CTRLB_TXEN | \
      SERCOM_USART_CTRLB_CHSIZE(0/*8 bits*/); \
    \
    uint64_t br = (uint64_t)65536 * (F_CPU - 16 * baud) / F_CPU; \
    SERCOM##sercom->USART.BAUD.reg = (uint16_t)br; \
    \
    /* Enable the peripheral */ \
    SERCOM##sercom->USART.CTRLA.reg |= SERCOM_USART_CTRLA_ENABLE; \
    \
    /* Send hello message */ \
    logger_cstring(logger_newline); \
    logger_cstring(logger_hello);   \
    logger_cstring(logger_newline); \
    logger_cstring(logger_newline); \
  } \
  \

extern const char logger_hello[];
extern const char logger_newline[];
extern const char logger_dot[];
extern const char logger_ok[];
extern const char logger_error[];

extern void logger_usart_queue(char c);
#define logger_char(x) logger_usart_queue(x)
extern void logger_string(char *string);
extern void logger_cstring(const char *string);
extern void logger_number_(uint32_t value, uint8_t base);
#define logger_number(x) logger_number_(x, 10)
#define logger_number_as_hex(x) logger_number_(x, 16)
#define logger_newline() logger_cstring(logger_newline)
#define logger_ok() logger_cstring(logger_ok)
#define logger_error() logger_cstring(logger_error)

#else // UTILS_LOGGER

#define LOGGER_BUILD(...)
#define logger_usart_queue(...) do {} while (0)
#define logger_init(...) do {} while (0)
#define logger_char(...) do {} while (0)
#define logger_string(...) do {} while (0)
#define logger_cstring(...) do {} while (0)
#define logger_number_(...) do {} while (0)
#define logger_number(...) do {} while (0)
#define logger_number_as_hex(...) do {} while (0)
#define logger_newline(...) do {} while (0)
#define logger_ok(...) do {} while (0)
#define logger_error(...) do {} while (0)

#endif // UTILS_LOGGER

#endif // _UTILS_LOGGER_H_
