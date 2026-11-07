(* SPDX-License-Identifier: AGPL-3.0-only *)
(* SPDX-FileCopyrightText: 2026 The algorithm-cores project contributors *)
BeginPackage["AbjadRPC`"];
AbjadValue::usage = "AbjadValue[arabicString] gives the traditional Eastern Abjad total.";
Begin["`Private`"];
$values = AssociationThread[
  Characters["ابجدهوزحطيكلمنسعفصقرشتثخذضظغ"],
  {1,2,3,4,5,6,7,8,9,10,20,30,40,50,60,70,80,90,100,200,300,400,500,600,700,800,900,1000}
];
$aliases = <|"آ"->"ا","أ"->"ا","إ"->"ا","ٱ"->"ا","ى"->"ي","ة"->"ه"|>;
AbjadValue[s_String] := Module[{chars, nums},
  chars = Characters[StringReplace[s, $aliases]];
  nums = Lookup[$values, chars, 0];
  If[!AnyTrue[nums, Positive], -1, Total[nums]]
];
End[];
EndPackage[];
