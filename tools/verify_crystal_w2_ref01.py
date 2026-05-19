#!/usr/bin/env python3
"""W2-REF-01 reference replay (Python) — mirrors Gauss-Seidel W2a in PH_Mat_Plast_Crystal_Core."""
from __future__ import annotations

import sys

TOL = 1.0e-6
EXP_G1 = 0.003307009
EXP_S5 = 53.307009


def elastic_d(e: float, nu: float):
    lam = e * nu / ((1 + nu) * (1 - 2 * nu))
    mu = e / (2 * (1 + nu))
    d = [[0.0] * 6 for _ in range(6)]
    for i in range(3):
        d[i][i] = lam + 2 * mu
    for i in range(3):
        for j in range(3):
            if i != j:
                d[i][j] = lam
    for i in range(3, 6):
        d[i][i] = mu
    return d


def schmid(s, m):
    p = [0.0] * 6
    p[0] = s[0] * m[0]
    p[1] = s[1] * m[1]
    p[2] = s[2] * m[2]
    p[3] = s[0] * m[1] + s[1] * m[0]
    p[4] = s[0] * m[2] + s[2] * m[0]
    p[5] = s[1] * m[2] + s[2] * m[1]
    return p


def matvec(a, x):
    return [sum(a[i][j] * x[j] for j in range(6)) for i in range(6)]


def dot(a, b):
    return sum(ai * bi for ai, bi in zip(a, b))


def w2_ref01():
    e, nu = 200e3, 0.3
    tau_c0 = 50.0
    h = [[1000.0, 0.0], [0.0, 1000.0]]
    p1 = schmid([0, 0, 1], [1, 0, 0])
    p2 = schmid([0, 1, 0], [0, 0, 1])
    ps = [p1, p2]
    d = elastic_d(e, nu)
    dstran = [0.0] * 6
    dstran[4] = 0.004
    stress = matvec(d, dstran)
    gamma = [0.0, 0.0]
    small = 1e-12

    for _ in range(20):
        changed = False
        for alpha in range(2):
            tau = dot(ps[alpha], stress)
            tau_y = tau_c0 + sum(h[alpha][b] * max(gamma[b], 0.0) for b in range(2))
            if abs(tau) <= tau_y + small:
                continue
            dp = matvec(d, ps[alpha])
            denom = dot(ps[alpha], dp) + h[alpha][alpha]
            dg = (abs(tau) - tau_y) / denom
            sign = 1.0 if tau >= 0 else -1.0
            stress = [stress[i] - dg * sign * dp[i] for i in range(6)]
            gamma[alpha] += dg
            changed = True
        if not changed:
            break
    return gamma, stress


def main() -> int:
    gamma, stress = w2_ref01()
    if abs(gamma[0] - EXP_G1) > TOL:
        print(f"FAIL: gamma1={gamma[0]} expected {EXP_G1}")
        return 1
    if abs(gamma[1]) > TOL:
        print(f"FAIL: gamma2={gamma[1]} expected 0")
        return 1
    if abs(stress[4] - EXP_S5) > TOL:
        print(f"FAIL: stress5={stress[4]} expected {EXP_S5}")
        return 1
    print("PASS: W2-REF-01 (Python reference)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
