(* SPDX-License-Identifier: AGPL-3.0-only *)
(* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors *)
BeginPackage["NeuroRegex`"];
BuildIndex::usage = "BuildIndex[documents] builds an immutable association of documents, term frequencies and deterministic cooccurrence edges.";
Search::usage = "Search[index, query, opts] ranks regex, token, and two-hop association signals.";
MagicTorsionSquare::usage = "MagicTorsionSquare[] returns a 3x3 grid in (Z/3Z)^2.";
MagicCertificate::usage = "MagicCertificate[square] checks distinctness and all eight line sums in (Z/3Z)^2.";
CurvePointQ::usage = "CurvePointQ[a,b,{x,y}] checks membership in y^2=x^3+a*x+b for exact numeric inputs.";
CurveNonsingularQ::usage = "CurveNonsingularQ[a,b] checks the discriminant for y^2=x^3+a*x+b.";
IntegralCurvePoints::usage = "IntegralCurvePoints[a,b,bound] exhaustively enumerates integral points with |x|,|y| <= bound.";
SquareSumsQ::usage = "SquareSumsQ[m] validates equal row, column, and diagonal sums in a 3x3 array.";
SquareOfSquaresQ::usage = "SquareOfSquaresQ[m] validates a 3x3 positive distinct square-valued magic square.";
Dispatch::usage = "Dispatch[operation, JSON payload] emits a JSON string for restricted WSTP RPC.";

Begin["`Private`"];
Clear[cleanWords];
cleanWords[s_String] := ToLowerCase /@ StringCases[s, RegularExpression["[\\p{L}\\p{N}]+"]];
validDocsQ[docs_] := ListQ[docs] && Length[docs] <= 10000 && AllTrue[docs, AssociationQ[#] && StringQ[Lookup[#, "id", None]] && StringQ[Lookup[#, "text", None]] && StringLength[#["text"]] <= 100000 &] && DuplicateFreeQ[Lookup[docs, "id"]];
BuildIndex[docs_] := Module[{tokens, terms, edges, ids},
  If[! validDocsQ[docs], Return[$Failed]];
  ids = Lookup[docs, "id"];
  tokens = cleanWords /@ Lookup[docs, "text"];
  terms = Counts /@ tokens;
  edges = Association[];
  Do[
    With[{uniq = DeleteDuplicates[tokens[[i]]]},
      Do[
        If[j != k,
          edges[uniq[[j]]] = Append[Lookup[edges, uniq[[j]], {}], uniq[[k]]]
        ], {j, Length[uniq]}, {k, Length[uniq]}]
    ], {i, Length[tokens]}];
  edges = Association@KeyValueMap[#1 -> Counts[#2] &, edges];
  <|"Documents" -> docs, "Tokens" -> terms, "Edges" -> edges, "IDs" -> ids|>
];
Options[Search] = {"Limit" -> 20, "Regex" -> "", "Hops" -> 2};
Search[index_Association, query_String, OptionsPattern[]] := Module[
  {docs, terms, edges, q, pattern, limit, hops, candidates, weights, matched, regexHit, score, results, w, n, hit},
  docs = Lookup[index, "Documents", {}];
  terms = Lookup[index, "Tokens", {}];
  edges = Lookup[index, "Edges", <||>];
  q = DeleteDuplicates[cleanWords[query]];
  limit = OptionValue["Limit"];
  hops = OptionValue["Hops"];
  pattern = OptionValue["Regex"];
  If[! IntegerQ[limit] || limit < 1 || limit > 100 || ! MemberQ[{0,1,2}, hops] || ! StringQ[pattern] || StringLength[pattern] > 256, Return[$Failed]];
  (* Bounded, user-controlled regex; malicious or invalid patterns cannot terminate the daemon forever. *)
  weights = AssociationThread[q, ConstantArray[1., Length[q]]];
  If[hops >= 1,
    Do[KeyValueMap[(If[! KeyExistsQ[weights,#1], weights[#1] = Max[Lookup[weights,#1,0.], .35 Min[1., N[#2]/3]]]) &, Lookup[edges,w,<||>]], {w,q}]
  ];
  If[hops >= 2,
    candidates = Keys[weights];
    Do[
      KeyValueMap[(If[! MemberQ[q,#1], weights[#1] = Max[Lookup[weights,#1,0.], .12 Min[1.,N[#2]/3]]]) &, Lookup[edges,w,<||>]],
      {w, Complement[candidates,q]}]
  ];
  results = Table[
    matched = Intersection[Keys[terms[[n]]], q];
    score = Total[KeyValueMap[(#2 * Min[Lookup[terms[[n]], #1, 0], 3]) &, weights]];
    regexHit = If[pattern === "", False,
      TrueQ[Quiet@Check[TimeConstrained[StringContainsQ[docs[[n,"text"]], RegularExpression[pattern], IgnoreCase -> True], 0.05, False], False]]
    ];
    If[regexHit, score += 4.];
    If[score <= 0., Nothing,
      <|"id" -> docs[[n,"id"]], "score" -> N[score], "matched" -> matched,
        "regex" -> regexHit, "text" -> StringTake[docs[[n,"text"]], UpTo[240]]|>
    ],
    {n, Length[docs]}];
  Take[SortBy[results, {(-#score)&, (#id)&}], UpTo[limit]]
];

(* Each cell is a distinct element of E[3] as an abstract group (Z/3Z)^2.
   The column order makes both diagonals sum to 0 too. *)
MagicTorsionSquare[] := Table[Mod[{i+j, j}, 3], {i, 0, 2}, {j, 0, 2}];
MagicCertificate[m_] := Module[{lines, sums, cells},
  If[Dimensions[m] =!= {3,3,2} || ! VectorQ[Flatten[m], IntegerQ], Return[<|"valid"->False|>]];
  lines = Join[Table[m[[i]], {i,3}], Table[m[[All,j]], {j,3}], {Table[m[[i,i]], {i,3}], Table[m[[i,4-i]], {i,3}]}];
  sums = Mod[Total /@ lines, 3];
  cells = Flatten[m,1];
  <|"valid" -> (Length[DeleteDuplicates[Mod[cells,3]]] == 9 && AllTrue[sums, # == {0,0} &]),
    "lineSums" -> sums, "distinct" -> Length[DeleteDuplicates[Mod[cells,3]]] == 9|>
];
CurveNonsingularQ[a_Integer,b_Integer] := 4 a^3 + 27 b^2 != 0;
CurvePointQ[a_Integer,b_Integer,{x_Integer,y_Integer}] := CurveNonsingularQ[a,b] && y^2 == x^3 + a x + b;
IntegralCurvePoints[a_Integer,b_Integer,bound_Integer] /; 0 <= bound <= 10000 := Module[{x, v, r},
  If[!CurveNonsingularQ[a,b], Return[$Failed]];
  Flatten[Table[v = x^3+a x+b; If[v < 0, {}, r = IntegerPart[Sqrt[v]]; If[r^2 == v && r <= bound, If[r==0,{{x,0}},{{x,r},{x,-r}}], {}]], {x,-bound,bound}], 1]
];
SquareSumsQ[m_] := Module[{s},
  If[Dimensions[m] =!= {3,3} || !MatrixQ[m, IntegerQ], Return[False]];
  s = Join[Total /@ m, Total /@ Transpose[m], {Tr[m], Tr[Reverse[m,2]]}];
  SameQ @@ s
];
SquareOfSquaresQ[m_] := SquareSumsQ[m] && AllTrue[Flatten[m], IntegerQ[#] && # > 0 && IntegerPart[Sqrt[#]]^2 == # &] && DuplicateFreeQ[Flatten[m]];

(* Persistent in-kernel index: operations serialized by the C daemon. *)
$Corpus = <||>;
(* Only allow named operations with JSON scalar/list data, never arbitrary WL source evaluation. *)
Dispatch[op_String, payload_String] := Module[{args, result, docs, idx, a, b, bound},
  args = Quiet@Check[ImportString[payload, "RawJSON"], $Failed];
  If[! AssociationQ[args], Return[ExportString[<|"error" -> "invalid JSON object"|>, "RawJSON"]]];
  result = Switch[op,
    "magic", MagicCertificate[MagicTorsionSquare[]],
    "magicSquare", MagicTorsionSquare[],
    "checkMagic", SquareSumsQ[Lookup[args,"square",{}]],
    "checkSquares", SquareOfSquaresQ[Lookup[args,"square",{}]],
    "curvePoints",
      {a,b,bound} = Lookup[args,{"a","b","bound"},Missing["required"]];
      If[And@@(IntegerQ /@ {a,b,bound}) && 0 <= bound <= 1000,
        IntegralCurvePoints[a,b,bound], <|"error"->"invalid curve arguments"|>],
    "loadCorpus",
      docs = Lookup[args,"documents",{}];
      If[validDocsQ[docs], $Corpus = BuildIndex[docs]; <|"indexed"->Length[docs]|>, <|"error"->"invalid corpus"|>],
    "query",
      If[!StringQ[Lookup[args,"query",None]] || !KeyExistsQ[$Corpus,"Documents"], <|"error"->"load corpus first"|>,
        Search[$Corpus,args["query"],"Regex"->Lookup[args,"regex",""],"Limit"->Lookup[args,"limit",20],"Hops"->Lookup[args,"hops",2]]],
    "search",
      docs = Lookup[args,"documents",{}];
      If[! validDocsQ[docs] || !StringQ[Lookup[args,"query",None]],
        <|"error"->"invalid search arguments"|>,
        idx = BuildIndex[docs];
        Search[idx,args["query"],"Regex"->Lookup[args,"regex",""],"Limit"->Lookup[args,"limit",20],"Hops"->Lookup[args,"hops",2]]
      ],
    _, <|"error"->"unknown operation"|>
  ];
  ExportString[If[result === $Failed, <|"error"->"operation rejected"|>, result], "RawJSON"]
];
End[];
EndPackage[];
