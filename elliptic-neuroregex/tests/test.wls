(* SPDX-License-Identifier: AGPL-3.0-only *)
(* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "..", "wl", "NeuroRegex.wl"}]];
assert[name_, p_] := If[! TrueQ[p], Print["FAIL: "<>name]; Exit[1], Print["PASS: "<>name]];
m = NeuroRegex`MagicTorsionSquare[];
assert["torsion magic certificate", TrueQ[NeuroRegex`MagicCertificate[m]["valid"]]];
assert["classic magic", NeuroRegex`SquareSumsQ[{{8,1,6},{3,5,7},{4,9,2}}]];
assert["not square of squares", !NeuroRegex`SquareOfSquaresQ[{{8,1,6},{3,5,7},{4,9,2}}]];
assert["curve nonsingular", NeuroRegex`CurveNonsingularQ[0,1]];
assert["curve point", NeuroRegex`CurvePointQ[0,1,{0,1}]];
assert["curve enumeration", MemberQ[NeuroRegex`IntegralCurvePoints[0,1,4],{0,1}]];
d = {<|"id"->"a","text"->"elliptic curve and magic square"|>,<|"id"->"b","text"->"Arabic abjad numerology"|>};
idx = NeuroRegex`BuildIndex[d];
assert["search ranking", NeuroRegex`Search[idx,"elliptic", "Hops"->0][[1,"id"]] === "a"];
assert["regex", NeuroRegex`Search[idx,"", "Regex"->"magic\\s+square"][[1,"id"]] === "a"];
assert["rpc JSON", StringContainsQ[NeuroRegex`Dispatch["magic","{}"],"valid"]];
Print["All assertions passed"];
