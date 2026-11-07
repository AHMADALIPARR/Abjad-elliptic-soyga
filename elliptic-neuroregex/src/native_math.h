/* SPDX-License-Identifier: AGPL-3.0-only
* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors
*/
#ifndef NATIVE_MATH_H
#define NATIVE_MATH_H
#include <stdint.h>
/* Exact integer helpers for the group-valued 3×3 square and for
   y^2 = x^3 + a x + b. This is the local stand-in used when the
   Wolfram engine is absent. Coefficients must fit in int64; the
   function returns -1 if a domain check or overflow fails.
   The 3×3 square is M(i,j) = (i+j, j) mod 3, the NeuroRegex formula,
   which is not the odd-order BQN square. */
int magic_cell(int i, int j, int *x, int *y);
int magic_certificate(int *distinct, int *lines_ok);
int discriminant_mod(int64_t p, int64_t a, int64_t b, int64_t *out);
int integral_points(int64_t a, int64_t b, int64_t bound,
                    int64_t *xy, int cap, int *count);
typedef struct { int inf; int64_t x, y; } AffinePoint;
int curve_add(int64_t p, int64_t a, AffinePoint u, AffinePoint v, AffinePoint *out);
int square_sums_ok(const int64_t m[9]);
int square_of_squares_ok(const int64_t m[9]);
#endif
