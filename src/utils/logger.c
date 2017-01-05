/**
 * @file logger.c
 *
 *copyright Copyright 2013 /Dev. All rights reserved.
 *license This project is released under MIT license.
 *
 * @author Ferdi van der Werf <efcm@slashdev.nl>
 */

#include "logger.h"

// Do we want logging?
#ifdef UTILS_LOGGER

const char logger_hello[]   = "USART Logger started";
const char logger_newline[] = "\r\n";
const char logger_dot[]     = ".";
const char logger_ok[]      = " [ok]\r\n";
const char logger_error[]   = " [error]\r\n";

void logger_string(char *s)
{
  while (*s) {
    logger_usart_queue(*s++);
  }
}

void logger_cstring(const char *s)
{
  while (*s) {
    logger_usart_queue(*s++);
  }
}

void logger_number_(uint32_t value, uint8_t base)
{
  /* Create buffer */
  char buffer[8*sizeof(uint32_t)+1];
  char *str = &buffer[sizeof(buffer)-1];
  /* Set ending0 */
  *str = '\0';
  uint32_t tmp;
  uint8_t c;

  /* Make sure we have a base larger than 1 */
  if (base < 2) {
    base = 10;
  }

  /* Iterate over value */
  do {
    tmp = value;            /* Set temp value */
    value /= base;          /* Calc divider */
    c = tmp - base * value; /* Get digit */
    *--str = c < 10 ? '0' + c : 'A' + c - 10;
  } while (value);

  /* Send string */
  logger_string(str);
}

#endif // UTILS_LOGGER
