/*

Defines a fusion law and the necessary functions to use it.

version 2 (version 1 was a FusTab)

A fusion law is a set F together with a map *: F x F -> 2^F

There is also an evalutaion map eval: F -> eigs to some eigenvalues

*/
declare type FusLaw[FusLawElt];

declare attributes FusLaw:
  set,           // a SetIndx of elements
  law,           // table of values for the fusion law  
  name,          // the name of the fusion law
  directory,     // a name to use as a directory to save under
  evaluation,    // a map from set to eigenvalues
  eigenvalues,   // a SetIndx of eigenvalues
  useful,        // a SetIndx of tuples of the useful fusion rules
  group,         // a Grp which is the grading on the table, if finite then a GrpPerm, if not then a GrpAb
  grading;       // a map from the values to the group giving the grading

// NB the evaluation is stored internally as a map from the set, but is converted to a map from fusion law elements when the evaluation map is asked for.  Otherwise, if it were stored in the correct form, when checking equality of FusLaws, it produces a circular argument, having to check the Domains of the maps are equal.

declare attributes FusLawElt:
  parent,        // the parent
  elt;           // an element

//
//
// =========== Properties of FusLaws ===========
//
//
intrinsic Elements(T::FusLaw) -> SetIndx
  {
  Returns the set of elements of the fusion law.
  }
  return ChangeUniverse(T`set, T);
end intrinsic;

intrinsic '#'(T::FusLaw) -> RngIntElt
  {
  Returns the size of the fusion law.
  }
  return #Elements(T);
end intrinsic;

intrinsic Print(T::FusLaw)
  {
  Prints a fusion law.
  }
  if assigned T`name then
    printf "%o fusion law.\n\n", T`name;
  end if;

  obj := T`set;
  if not Type(Universe(obj)) in { RngInt, FldRat} then
    function Name(x)
      return Position(obj, x);
    end function;
    relabel := true;
  else
    function Name(x)
      return x;
    end function;
    relabel := false;
  end if;

  L := [[ {@ Name(x) : x in S@} : S in r ] : r in T`law];

  top := [ " " cat Sprint(Name(x)) cat " " : x in obj ];
  width1st := Max([#t : t in top]);
  table := [ [Sprintf("%*o|", width1st, top[i])] cat [Substring(Sprint(L[i,j]), 3, #Sprint(L[i,j])-4) : j in [1..#L[i]]] : i in [1..#L]];
  widths := [ Max([#table[i,j] : i in [1..#table]] cat [j eq 1 select 0 else #top[j-1]]) : j in [1..#table+1]];
  top_table := [[ " "^(widths[1]-1) cat "|"] cat top] cat [[ "-"^widths[i] : i in [1..#widths] ]] cat table;
  for j in [1..#top_table] do
    for i in [1..#widths] do
      printf "%*o", widths[i], top_table[j,i];
    end for;
    printf "\n";
  end for;

  if relabel then
    print "\nWhere we use the labelling\n";
    printf Join([ Sprintf("%*o:-> %o", width1st, top[i], obj[i]) : i in [1..#obj]], "\n");
  end if;

  if assigned T`evaluation then
    printf "\nWhere the evaluation is\n";
    printf Join([ Sprintf("%*o:-> %o", width1st, top[i], obj[i]@T`evaluation) : i in [1..#obj]], "\n");
  end if;
end intrinsic;

intrinsic Directory(T::FusLaw) -> MonStgElt
  {
  Returns the directory associated with the fusion law.
  }
  return T`directory;
end intrinsic;

intrinsic Hash(T::FusLaw) -> RngIntElt
  {
  Returns the hash value of T.
  }
  return Hash(<T`set, T`law>);
end intrinsic

intrinsic IsSymmetric(T::FusLaw) -> BoolElt
  {
  Checks whether a fusion law is symmetric.
  }
  return forall{<x,y> : x,y in Elements(T) | x*y eq y*x};
end intrinsic;

intrinsic 'eq'(A::FusLaw, B::FusLaw) -> BoolElt
  {
  Checks whether the set and table are the same.
  }
  so := A`set eq B`set and A`law eq B`law;
  if not so then
    return false;
  end if;
  
  soA := assigned A`evaluation;
  soB := assigned B`evaluation;
  
  if soA or soB then
    if not soA and soB then
      return false;
    end if;
    return [ a@A`evaluation : a in A`set] eq [ b@B`evaluation : b in B`set];
  end if;
  
  return true; // neither has an evaluation
end intrinsic;

intrinsic IsIsomorphic(A::FusLaw, B::FusLaw) -> BoolElt, GrpPermElt
  {
  Checks whether the two fusion laws are isomorphic and if so returns an isomorphism from one set to the other.
  }
  // Not yet implemented.
end intrinsic;

intrinsic '+'(A::FusLaw, B::FusLaw) -> FusLaw
  {
    Compute the coproduct (disjoint union) of two fusion laws.
  }
  setA := A`set;
  setB := B`set;
  if IsEmpty(setA meet setB) then
    addIdx := false;
    setAB := setA join setB;
    law :=
      [[ A`law[i,j] : j in [1..#setA] ] cat [ {@@} : j in [1..#setB] ]
        : i in [1..#setA] ] cat
      [[{@@} : j in [1..#setA]] cat [ B`law[i,j] : j in [1..#setB] ]
        : i in [1..#setB] ];
  else
    addIdx := true;
    setAB := IndexedSet([<1, a> : a in setA] cat
                        [<2, b> : b in setB ]);
    law :=
      [[ IndexedSet([ <1,a> : a in A`law[i,j]]) : j in [1..#setA] ] cat [ {@@} : j in [1..#setB] ]
        : i in [1..#setA] ] cat
      [[{@@} : j in [1..#setA]] cat [ IndexedSet([ <2,b> : b in B`law[i,j]]) : j in [1..#setB] ]
        : i in [1..#setB] ];
  end if;

  T := New(FusLaw);
  T`set := setAB;
  T`law := law;
  hasA, evA := HasEvaluation(A);
  hasB, evB := HasEvaluation(B);
  if hasA and hasB then
    hasCover, cod := ExistsCoveringStructure(Codomain(evA), Codomain(evB));
    if not hasCover then
      print "Failed to merge evaluations: can't find cover of structures.";
      return T;
    end if;
    if addIdx then
      mp := map< setAB -> cod | i :-> i[1] eq 1 select i[2]@evA else i[2]@evB >;
    else
      mp := map< setAB -> cod | i :-> i in setA select i@evA else i@evB >;
    end if;
    AssignEvaluation(~T, mp);
  end if;
  return T; 
end intrinsic;

intrinsic 'join'(A::FusLaw, B::FusLaw) -> FusLaw
  {
    Merge the fusions laws of A and B. A and B must have identitcal fusion law 
      elements.
  }
  setA := A`set;
  setB := B`set;
  require setA eq setB: "A and B must have the same fusion law elements.";
  law :=
    [ [ A`law[i,j] join B`law[i,j] : j in [1..#setA] ] : i in [1..#setA] ];
  T := New(FusLaw);
  T`set := setA;
  T`law := law;
  hasA, evA := HasEvaluation(A);
  hasB, evB := HasEvaluation(B);
  if hasA and not hasB then
    AssignEvaluation(~T, evA);
  elif not hasA and hasB then
    AssignEvaluation(~T, evB);
  elif hasA and hasB then
    require forall{ x : x in setA | x@evA eq x@evB }: "Evaluations must match.";
    AssignEvaluation(~T, evA);
  end if;
  return T;
end intrinsic;

/*

======= Evaluation maps =======

*/
intrinsic HasEvaluation(T::FusLaw) -> BoolElt, Map
  {
  Does the fusion law have an evaluation map?  If so, also returns the map.
  }
  if assigned T`evaluation then
    return true, map< T -> Codomain(T`evaluation) | x:-> (x`elt)@T`evaluation,
      y :-> y@@T`evaluation >;
  else
    return false, _;
  end if;
end intrinsic;

intrinsic Evaluation(T::FusLaw) -> Map
  {
  Returns the evaluation map if it the fusion law has one.  Else returns an error.
  }
  so, eval_map := HasEvaluation(T);
  require so: "This fusion law has no evaluation map.";
  return eval_map;
end intrinsic;

intrinsic Eigenvalues(T::FusLaw) -> SetIndx
  {
  If the fusion law has an evaluation, return the image of the evaluation map.  Else returns an error.
  }
  so, eval_map := HasEvaluation(T);
  require so: "This fusion law has no evaluation map.";
  assert assigned T`eigenvalues;
  return T`eigenvalues;
end intrinsic;

intrinsic AssignEvaluation(~T::FusLaw, f::Map: check:=true)
  {
  Assigns the evaluation map f to the fusion law.  check is an optional parameter whether to check if it already has a evaluation map.
  }
  if check then
    require not assigned T`evaluation: "The fusion law already has an assigned evaluation map.";
  end if;
  
  if forall{ t : t in T`set | IsCoercible(Domain(f), t)} then
    T`evaluation := f;
  else
    require Domain(f) cmpeq T: "The fusion law is not a subset of the domain of the given map.";
    T`evaluation := map< T`set -> Codomain(f) | x:-> (T!x)@f>;
  end if;
  
  T`eigenvalues := T`set@T`evaluation;
end intrinsic;

intrinsic AssignEvaluation(T::FusLaw, f::Map: check:=true) -> FusLaw
  {
  Assigns the evaluation map f to the fusion law.  check is an optional parameter whether to check if it already has a evaluation map.
  }
  Tnew := New(FusLaw);
  for attr in GetAttributes(FusLaw) do
    if assigned T``attr then
      Tnew``attr := T``attr;
    end if;
  end for;

  AssignEvaluation(~Tnew, f: check:=check);
  return Tnew;
end intrinsic;
//
//
// =========== Properties of FusLawElts ===========
//
//
intrinsic Parent(x::FusLawElt) -> FusLaw
  {
  Parent of x.
  }
  return x`parent;
end intrinsic;

intrinsic Print(x::FusLawElt)
  {
  Print x.
  }
  printf "%o", x`elt;
end intrinsic;

intrinsic 'eq'(x::FusLawElt, y::FusLawElt) -> BoolElt
  {
  Equality of elements.
  }
  require Parent(x) eq Parent(y): "The two elements are not in the same fusion law.";
  return x`elt eq y`elt;
end intrinsic;

intrinsic 'in'(x::FusLawElt, T::FusLaw) -> BoolElt
  {
  Returns whether x is in T.
  }
  return Parent(x) eq T;
end intrinsic;

function CreateElement(T, x)
  xx := New(FusLawElt);
  xx`parent := T;
  xx`elt := (T`set)!x;

  return xx;
end function;

intrinsic IsCoercible(T::FusLaw, x::.) -> BoolElt, .
  {
  Returns whether x is coercible into T and the result if so.
  }
  if Type(x) eq FusLawElt and Parent(x) eq T then
    return true, x;
  end if;

  so, xx := IsCoercible(T`set, x);
  if so then
    return true, CreateElement(T, xx);
  else
    return false, "Illegal coercion";
  end if;
end intrinsic;

intrinsic Hash(x::FusLawElt) -> RngIntElt
  {
  Returns the hash value of x.
  }
  return Hash(x`elt);
end intrinsic;
//
//
// ============ Operations and predicates for elements ==============
//
//
intrinsic '*'(x::FusLawElt, y::FusLawElt) -> SetIndx[FusLawElt]
  {
  Returns the product of x and y.
  }
  T := Parent(x);
  require T eq Parent(y): "x and y are not in the same fusion law.";

  return ChangeUniverse(T`law[Position(T`set, x`elt), Position(T`set, y`elt)], T);
end intrinsic;

intrinsic '*'(x::FusLawElt, Y::{@FusLawElt@}) -> SetIndx[FusLawElt]
  {
  Returns the product of x with Y.
  }
  require Parent(x) eq Universe(Y): "x and Y are not in the same fusion law.";

  return &join{@ x*y : y in Y@};
end intrinsic;

intrinsic '*'(X::{@FusLawElt@}, y::FusLawElt) -> SetIndx[FusLawElt]
  {
  Returns the product of X and y.
  }
  require Universe(X) eq Parent(y): "X and y are not in the same fusion law.";

  return &join{@ x*y : x in X@};
end intrinsic;

intrinsic '*'(X::{@FusLawElt@}, Y::{@FusLawElt@}) -> SetIndx[FusLawElt]
  {
  Returns the product of X and Y.
  }
  require Universe(X) eq Universe(Y): "X and Y are not in the same fusion law.";

  return &join{@ x*y : x in X, y in Y@};
end intrinsic;

intrinsic IsUnit(x::FusLawElt) -> BoolElt
  {
  Returns whether x is a unit.  That is, if x*y and y*x are subsets of \{y\}, for all y.
  }
  return forall{ y : y in Elements(Parent(x)) | x*y subset {@y@} and y*x subset {@y@}};
end intrinsic;

intrinsic IsAnnihilating(x::FusLawElt) -> BoolElt
  {
  Returns whether x is annihilating.  That is, if x*y and y*x are empty, for all y.
  }
  return forall{ y : y in Elements(Parent(x)) | x*y eq {@@} and y*x eq {@@}};
end intrinsic;

intrinsic IsAbsorbing(x::FusLawElt) -> BoolElt
  {
  Returns whether x is absorbing.  That is, if x*y and y*x are subsets of \{x\}, for all y.
  }
  return forall{ y : y in Elements(Parent(x)) | x*y subset {@x@} and y*x subset {@x@}};
end intrinsic;
//
//
// ============ Changes ring ==============
//
//
/*

Changes the field for the fusion law.

*/
intrinsic ChangeField(T::FusLaw, F::Fld) -> FusLaw
  {
  If the fusion law has an evaluation map, changes its field of definition.
  }
  return ChangeRing(T, F);
end intrinsic;

intrinsic ChangeField(T::FusLaw, F::Fld, f::Map) -> FusLaw
  {
  If the fusion law has an evaluation map, changes its field of definition.

  Note that we need to be able to coerce any scalars into the new field.  For example, the rationals to a finite field is ok, but not the other way.
  }
  if not assigned T`evaluation then
    print "No evaluation map assigned.";
    return T;
  end if;
  
  // Need the setseq in case it is not bijective
  im := Setseq(T`set)@(T`evaluation*f);
  return AssignEvaluation(T, map<T`set -> im | [<i, im[i]> : i in T`set]>: check := false);
end intrinsic;

intrinsic ChangeRing(T::FusLaw, R::Rng) -> FusLaw
  {
  If the fusion law has an evaluation map, changes its ring of definition.

  Note that we need to be able to coerce any scalars into the new field.  For example, the rationals to a finite field is ok, but not the other way.
  }
  if not assigned T`evaluation then
    print "No evaluation map assigned.";
    return T;
  end if;

  // Need the setseq in case it is not bijective
  im := ChangeUniverse(Setseq(T`set)@T`evaluation, R);
  return AssignEvaluation(T, map<T`set -> im | [<i, im[i]> : i in T`set]>: check := false);
end intrinsic;
//
//
// ============ Functions on a FusLaw ============
//
//
/*

Permute the entries of a fusion law

*/
intrinsic Permute(T::FusLaw, g::GrpPermElt) -> FusLaw
  {
  Reorder the elements of the Fusion Law T according to the permutation g.
  }
  Tnew := New(FusLaw);
  require IsCoercible(Sym(#T), g): "The permutation must be on the fusion law";
  
  Tnew`set := IndexedSet(PermuteSequence(Setseq(T`set), g));
  Tnew`law := PermuteSequence([ PermuteSequence([ S : S in t], g) : t in T`law ], g);
  
  for attr in [ "name", "directory"] do
    if assigned T``attr then
      Tnew``attr := T``attr;
    end if;
  end for;
  
  if assigned T`evaluation then
    AssignEvaluation(~Tnew, T`evaluation);
  end if;

  // implement these too!
  /*
  useful,        // a SetIndx of tuples of the useful fusion rules
  group,         // a Grp which is the grading on the table
  grading;       // a map from the values to the group giving the grading
  */
  
  return Tnew;
end intrinsic;
/*

A sub fusion law

*/
// NB no inclusion map defined here
intrinsic SubConstructor(T::FusLaw, X::.) -> FusLaw
  {
  Return the sub fusion law table generated by elements of X.
  }
  XX := {@T | @};
  // X is a tuple
  for x in X do
    if ISA(Type(x), MakeType("Set")) then
      so, xx := CanChangeUniverse(x, T);
      require so: "Not all the elements in the second argument are coercible into the fusion law.";
      XX := XX join xx;  // join:= doesn't seem to work here.
    else
      so, xx := IsCoercible(T, x);
      require so: "Not all the elements in the second argument are coercible into the fusion law.";
      XX := XX join {@ xx @};  // join:= doesn't seem to work here.
    end if;
  end for;
  
  // We find the subfusion law generated by X
  size := 0;
  extras := XX;
  while #XX ne size do
    size := #XX;
    new := &join{@ x*y : x in XX, y in extras @};
    extras := new diff XX;
    XX := XX join extras;
  end while;
    
  XX := {@ x`elt : x in XX @};
  
  Sort(~XX, func<x,y|Position(T`set, x) - Position(T`set, y)>);
  
  Tnew := New(FusLaw);
  Tnew`set := XX;
  Tnew`law := [[ T`law[x,y] : y in XX] : x in XX];

  if assigned T`evaluation then
    Tnew`evaluation := T`evaluation;
    Tnew`eigenvalues := Tnew`set @ Tnew`evaluation;
  end if;

  return Tnew;
end intrinsic;
/*

Calculates the grading for the fusion law.

*/
intrinsic FinestAdequateGrading(T::FusLaw) -> Grp, Map
  {
  Calculates the finest adequate grading group G and the grading function gr:F -> G. If the grading is finite a permutation group is returned, otherwise an abelian group is returned.
  }
  if assigned T`group then
    return T`group, T`grading;
  end if;
  
  require IsSymmetric(T): "This function is currently restricted to symmetric fusion laws.";
  // We form a group whose generators are the elements of the set and relations given by the table to find the grading.
  // Any elements which are in a set which is an entry in the fusion law must have the same grading
  // Can define a graph on the fusion law with edges if the two elements are contained in some entry in the fusion law
  set := T`set;
  edges := &join { Subsets(Set(S),2) : S in Flat(T`law)};
  grph := Graph<set|edges>;
  
  // Graph vertices are indexed the same as the set they come from.
  gens := {@ {@ set[Index(v)] : v in C @} : C in ConnectedComponents(grph)@};

  d := #gens;
  // We set up a function to give the generator number of an eigenvalue
  genno := map<set -> [1..d] | Flat([ [<e, i> : e in gens[i]] : i in [1..d]])>;

  F := FreeAbelianGroup(d);
  rels := [];
  
  // We build some relations
  for i in [1..#set] do
    for j in [i..#set] do
      for prod in T`law[i, j] do
        Append(~rels, F.(set[i]@genno) + F.(set[j]@genno) - F.(prod@genno));
       end for;
    end for;
  end for;

  G, map := quo<F|rels>;
  
  if IsFinite(G) then
    assert Order(G) le #set; // Not true if there is an infinite grading
    GG, iso := PermutationGroup(G);
    T`group := GG;
    T`grading := map< Elements(T) -> GG | i:-> (F.(i`elt@genno)@map)@@iso>;
  else
    T`group := G;
    T`grading := map< Elements(T) -> G | i:-> F.(i`elt@genno)@map>;
  end if;

  return T`group, T`grading;
end intrinsic;

intrinsic Grading(T::FusLaw) -> GrpPerm, Map
  {
  "
  }
  return FinestAdequateGrading(T);
end intrinsic;

/*

Calculates the useful fusion rules.

*/
intrinsic UsefulFusionRules(T::FusLaw) -> SetIndx
  {
  Returns those fusion rules which are useful.  That is, triples of pure subsets I, J, K such that  I*J = K, where K is not a maximal pure subset and there does not exist I' containing I, or J' containing J with I'*J = K, or I*J' = K.
  }
  require IsSymmetric(T): "The fusion law is not symmetric";
  if assigned T`useful then
    return T`useful;
  end if;
  set := Elements(T);
  G, grad := FinestAdequateGrading(T);
  
  // We just need to consider the pure subsets - those subsets which are fully contained in a graded piece
  graded_pieces := {@ {@ i : i in set | i @ grad eq g @} : g in Image(grad)@};
  subsets := &join{@ Sort({@ S : S in Subsets(Set(piece)) | S ne {} @}, func< x,y | #y-#x>) : piece in graded_pieces @};
  // We have sorted these so the largest subsets are first in each graded collonade
  
  // We create a larger fusion law on the set of all pure subsets
  FT := [ [] : i in [1..#subsets]];
  for i in [1..#subsets] do
    for j in [1..i] do
      FT[i,j] := &join { T`law[Position(set,k), Position(set,l)] : k in subsets[i], l in subsets[j] };
      FT[j,i] := FT[i,j];
    end for;
  end for;

  T`useful := {@ @};
  for i in [1..#subsets] do
    row := Set(FT[i]);
    for S in row do
      if S in graded_pieces then
        continue;
      end if;
      pos := Position(FT[i], S);  // find the first position it appears in the row
      assert exists(j){ j : j in [1..i] | FT[j,pos] eq FT[i,pos]};  // Look for an earlier column
      if not subsets[j] in graded_pieces or not subsets[pos] in graded_pieces then
        if i le pos then // only want to add a rule once
          Include(~T`useful, < subsets[pos], subsets[j], Set(FT[j,pos])>);
        else
          Include(~T`useful, < subsets[j], subsets[pos], Set(FT[j,pos])>);
        end if;
      end if;
    end for;
  end for;

  return T`useful;
end intrinsic;
//
//
// ============ Some Examples ============
//
//
intrinsic SingletonFusionLaw(:empty := true, label := false, 
                   evaluation := false) -> FusLaw
  {
  Returns a fusion law with a single element. Optional arguments specify if the x * x is empty or x. Also a label and/or evaluation can be specified.
  }
  T := New(FusLaw);
  if Type(label) eq BoolElt then
    label := 1;
  end if;
  T`set := {@ label @};
  T`law := empty select [[{@@}]] else [[{@label@}]];
  if Type(evaluation) ne BoolElt then
  AssignEvaluation(~T,  
        map< T`set -> Parent(evaluation) |
          i:-> evaluation, j:-> label>);
  end if;
  return T;
end intrinsic;

intrinsic AssociativeFusionLaw() -> FusLaw
  {
  Returns the associative fusion law.
  }
  T := New(FusLaw);
  T`name := "Associative";
  T`directory := "Associative_1_0";
  T`set := {@ 1, 2 @};
  T`law := [[ {@1@}, {@@}], [ {@@}, {@2@}]];
  
  evals := [1, 0];
  f := map< T`set -> Rationals() | i:->evals[i], j:-> Position(evals,j)>;
  AssignEvaluation(~T, f);
  _ := UsefulFusionRules(T);
  
  return T;
end intrinsic;
/*

Returns the Jordan type fusion law.

*/
intrinsic JordanFusionLaw(: evaluation:=true) -> FusLaw
  {
  Returns the fusion law of Jordan type eta.  Optionally with an evaluation to the function field Q(eta).
  }
  T := New(FusLaw);
  T`name := "Jordan";
  T`directory := "Jordan_eta";
  T`set := {@ 1, 2, 3 @};
  T`law := [[ {@1@}, {@@}, {@3@}], [ {@@}, {@2@}, {@3@}], [ {@3@}, {@3@}, {@1,2@}]];
  
  if evaluation then
    F<eta> := FunctionField(Rationals());
    evals := [1, 0, eta];
    f := map< T`set -> F | i:->evals[i], j:-> Position(evals,j)>;
    AssignEvaluation(~T, f);
  end if;
  
  _ := UsefulFusionRules(T);

  return T;
end intrinsic;

intrinsic JordanFusionLaw(eta) -> FusLaw
  {
  Returns the Jordan type fusion law.
  }
  require eta notin {1,0}: "The parameter may not be 0, or 1.";
  T := New(FusLaw);
  T`name := "Jordan";
  T`directory := Join(Split(Sprintf("Jordan_%o", eta), "/"), ",");
  T`set := {@ 1, 2, 3 @};
  T`law := [[ {@1@}, {@@}, {@3@}], [ {@@}, {@2@}, {@3@}], [ {@3@}, {@3@}, {@1,2@}]];
  
  evals := [1, 0, eta];
  f := map< T`set -> Parent(eta) | i:->evals[i], j:-> Position(evals,j)>;
  AssignEvaluation(~T, f);
  _ := UsefulFusionRules(T);

  return T;
end intrinsic;
/*

Returns the Monster fusion law.

*/
intrinsic MonsterFusionLaw(: evaluation:=true) -> FusLaw
  {
  Returns the fusion law of Monster type alpha, beta.  Optionally with an evaluation to the function field Q(al, bt).
  }
  T := New(FusLaw);
  T`name := "Monster";
  T`directory := "Monster_al_bt";
  T`set := {@ 1, 2, 3, 4 @};
  T`law := [[ {@1@}, {@@}, {@3@}, {@4@}], [ {@@}, {@2@}, {@3@}, {@4@}], [ {@3@}, {@3@}, {@1,2@}, {@4@}], [ {@4@}, {@4@}, {@4@}, {@1,2,3@}]];
  
  if evaluation then
    F<al, bt> := FunctionField(Rationals(), 2);
    evals := [1, 0, al, bt];
    f := map< T`set -> F | i:->evals[i], j:-> Position(evals,j)>;
    AssignEvaluation(~T, f);
  end if;

  _ := UsefulFusionRules(T);

  return T;
end intrinsic;

intrinsic MonsterFusionLaw(alpha::RngElt, beta::RngElt) -> FusLaw
  {
  Returns the fusion law of Monster type alpha, beta.
  }
  require #({alpha, beta} meet {1,0}) eq 0 : "The parameters may not be 0, or 1.";
  T := New(FusLaw);
  T`name := "Monster";
  T`directory := Join(Split(Sprintf("Monster_%o_%o", alpha, beta), "/"), ",");
  T`set := {@ 1, 2, 3, 4 @};
  T`law := [[ {@1@}, {@@}, {@3@}, {@4@}], [ {@@}, {@2@}, {@3@}, {@4@}], [ {@3@}, {@3@}, {@1,2@}, {@4@}], [ {@4@}, {@4@}, {@4@}, {@1,2,3@}]];
  
  evals := [1, 0, alpha, beta];
  R := Universe(evals);
  if alpha ne beta then
    f := map< T`set -> R | i:->evals[i], j:-> Position(evals,j)>;
  else
    f := map< T`set -> R | i:->evals[i]>;
  end if;
  AssignEvaluation(~T, f);
  _ := UsefulFusionRules(T);

  return T;
end intrinsic;
/*

Returns the extended Jordan-type law.

*/
intrinsic HyperJordanFusionLaw(eta::FldRatElt) -> FusLaw
  {
  Returns the fusion law of extended Jordan-type eta.
  }
  return MonsterFusionLaw(2*eta, eta);
end intrinsic;
/*

Creates the representation fusion law

*/
intrinsic RepresentationFusionLaw(G::Grp) -> FusLaw
  {
  Returns the representation fusion law for the group G.
  }
  return RepresentationFusionLaw(CharacterTable(G));
end intrinsic;

intrinsic RepresentationFusionLaw(CT::SeqEnum[AlgChtrElt]) -> FusLaw
  {
  Returns the representation fusion law for the group G.
  }
  T := New(FusLaw);
  T`set := IndexedSet(CT);
  T`law := [[ {@ C : C in CT | InnerProduct(XY, C) ne 0 where XY := CT[i]*CT[j] @} : j in [1..i]] : i in [1..#CT]];
  // Now symmetrise
  for i in [1..#CT] do
    for j in [i+1..#CT] do
      T`law[i,j] := T`law[j,i];
    end for;
  end for;

  if assigned Universe(CT)`Group then
    T`name := Sprintf("Representation fusion law for %o", GroupName(Group(Universe(CT))));
    T`directory := Sprintf("Rep_fusion_law_%o", DirectoryGroupName(Group(Universe(CT))));
  end if;
  return T;
end intrinsic;

intrinsic RepresentationFusionLaw(D::LieRepDec) -> FusLaw
  {
  Returns the representation fusion law for the irreducible representations occuring in D
  }
  T := New(FusLaw);
  T`set := Weights(D);
  T`law := [[ {@ C : C in T`set | Multiplicity(T,C) ne 0 where T := TensorProduct(RootDatum(D),T`set[i],T`set[j])@} : j in [1..i]] : i in [1..#D]];
  // Now symmetrise
  for i in [1..#D] do
    for j in [i+1..#D] do
      T`law[i,j] := T`law[j,i];
    end for;
  end for;
  T`name := Sprintf("Lie Representation fusion law for %o", RootDatum(D));
  return T;
end intrinsic;
//-----------------------------------------------------------
//
// Code to convert a FusTab (old object) to a FusLaw
//
//-----------------------------------------------------------
intrinsic FusionLaw(T::FusTab) -> FusLaw
  {
  Converts a fusion table to a fusion law.  Old version to new version.
  }

  if T`name in {"Monster", "Ising", "Jordan"} then
    if T`name eq "Monster" then
      params := "1/4, 1/32";
    else
      params := [ al : al in T`eigenvalues | al notin {0,1} ];
      params := Join([Sprintf("%o", al) : al in params], ",");
    end if;
    return eval(Sprintf("%oFusionLaw(%o)", T`name, params));
  end if;
  
  Tnew := New(FusLaw);
  Tnew`name := T`name;
  Tnew`directory := T`directory;
  Tnew`set := T`eigenvalues;
  Tnew`law := T`table;
  f := map< Tnew`set -> Tnew`set | i:->i, j:->j>;
  AssignEvaluation(~Tnew, f);
  _ := UsefulFusionRules(Tnew);

  return Tnew;
end intrinsic;
//-----------------------------------------------------------
//
// Code to load and save a fusion law in the json format
//
//-----------------------------------------------------------
/*

Code to serialise a fusion law

*/
intrinsic FusLawToList(T::FusLaw) -> List
  {
  Transform a fusion law to a List prior to serialising as a JSON.
  }
  L := [* *];
  Append(~L, <"class", "Fusion law">);

  if assigned T`name then
    Append(~L, <"name", T`name>);
    Append(~L, <"directory", Directory(T)>);
  end if;

  set := Setseq(T`set);
  Append(~L, <"set", set>);
  Append(~L, <"law", [ [ Setseq(S) : S in t] : t in T`law]>);

  if assigned T`evaluation then
    Append(~L, <"evaluation", set@T`evaluation>);
  end if;

  return L;
end intrinsic;
/*

Code to load a fusion law.

*/
intrinsic FusionLaw(A::Assoc) -> FusLaw
  {
  Create a fusion law T from an associative array.  We assume that the associative array represents T stored in json format.
  }
  keys := Keys(A);
  require "class" in keys and A["class"] eq "Fusion law": "The file given does not have a valid fusion law.";
  T := New(FusLaw);
  T`set := IndexedSet(Numbers(A["set"]));
  T`law := [ [ IndexedSet(Numbers(S)) : S in row ] : row in A["law"]];

  if "name" in keys then
    T`name := A["name"];
    T`directory := A["directory"];
  end if;

  if "evaluation" in keys then
    evals := Numbers(A["evaluation"]);
    T`eigenvalues := IndexedSet(evals);
    T`evaluation := map< T`set -> T`eigenvalues | [ <i, evals[i]> : i in T`set]>;
  end if;

  return T;
end intrinsic;
