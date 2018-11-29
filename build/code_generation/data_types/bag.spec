% Author(s): Aad Mathijssen, Jeroen Keiren
% Copyright: see the accompanying file COPYING or copy at
% https://github.com/mCRL2org/mCRL2/blob/master/COPYING
%
% Distributed under the Boost Software License, Version 1.0.
% (See accompanying file LICENSE_1_0.txt or copy at
% http://www.boost.org/LICENSE_1_0.txt)
%
% Specification of the Bag data sort.

#using S
#include nat.spec
#include fbag.spec
#include fset.spec
#include set.spec
#supertypeof FBag

sort Bag(S) <"bag">;

cons @bag <"constructor">: (S -> Nat) <"left"> # FBag(S) <"right"> -> Bag(S)                 internal defined_by_rewrite_rules;
map @bagfbag <"bag_fbag">: FBag(S) <"arg"> -> Bag(S)                                         internal defined_by_rewrite_rules;
    @bagcomp <"bag_comprehension">: (S -> Nat) <"arg"> -> Bag(S)                             internal defined_by_rewrite_rules;
    count <"count">: S <"left"> # Bag(S) <"right"> -> Nat                                    external defined_by_rewrite_rules;
    in <"in">: S <"left"> # Bag(S) <"right"> -> Bool                                         external defined_by_rewrite_rules;
    + <"union_">: Bag(S) <"left"> # Bag(S) <"right"> -> Bag(S)                               external defined_by_rewrite_rules;
    * <"intersection">: Bag(S) <"left"> # Bag(S) <"right"> -> Bag(S)                         external defined_by_rewrite_rules;
    - <"difference">: Bag(S) <"left"> # Bag(S) <"right"> -> Bag(S)                           external defined_by_rewrite_rules;
    Bag2Set <"bag2set">: Bag(S) <"arg"> -> Set(S)                                            external defined_by_rewrite_rules;
    Set2Bag <"set2bag">: Set(S) <"arg"> -> Bag(S)                                            internal defined_by_rewrite_rules;
    @zero_ <"zero_function">: S <"arg"> -> Nat                                               internal defined_by_rewrite_rules;
    @one_ <"one_function">: S <"arg"> -> Nat                                                 internal defined_by_rewrite_rules;
    @add_ <"add_function">: (S -> Nat) <"left"> # (S -> Nat) <"right"> -> S -> Nat           internal defined_by_rewrite_rules;
    @min_ <"min_function">: (S -> Nat) <"left"> # (S -> Nat) <"right"> -> S -> Nat           internal defined_by_rewrite_rules;
    @monus_ <"monus_function">: (S -> Nat) <"left"> # (S -> Nat) <"right"> -> S -> Nat       internal defined_by_rewrite_rules;
    @Nat2Bool_ <"nat2bool_function">: (S -> Nat) <"arg"> -> S -> Bool                        internal defined_by_rewrite_rules;
    @Bool2Nat_ <"bool2nat_function">: (S -> Bool) <"arg"> -> S -> Nat                        internal defined_by_rewrite_rules;

var b: FBag(S);
    c: FBag(S);
    e: S;
    f: S -> Nat;
    g: S -> Nat;
    h: S -> Bool;
    s: FSet(S);
    x: Bag(S);
    y: Bag(S);

eqn @bagfbag(b)  =  @bag(@zero_, b);
    @bagcomp(f)  =  @bag(f, {:});
    count(e, @bag(f, b))  =  @swap_zero(f(e), count(e, b));
    in(e, x)  =  >(count(e, x), @c0);
    ==(@bag(f, b), @bag(g, c))  = if( ==(f,g), ==(b,c), forall(d:S, ==(count(d, @bag(f,b)), count(d, @bag(g,c)))));
    <(x, y)  =  &&(<=(x, y), !=(x, y));
    <=(x,y) = ==(*(x,y),x);
    +(@bag(f, b), @bag(g, c))  =  @bag(@add_(f, g), @fbag_join(f, g, b, c));
    *(x, x) = x;
    *(x, *(x, y)) = *(x, y);
    *(x, *(y, x)) = *(y, x);
    *(*(x, y), x) = *(x, y);
    *(*(y, x), x) = *(y, x);
    *(@bag(f, b), @bag(g, c))  =  @bag(@min_(f, g), @fbag_inter(f, g, b, c));
    -(@bag(f, b), @bag(g, c))  =  @bag(@monus_(f, g), @fbag_diff(f, g, b, c));
    Bag2Set(@bag(f, b))  =  @set(@Nat2Bool_(f), @fbag2fset(f, b));
    Set2Bag(@set(h, s))  =  @bag(@Bool2Nat_(h), @fset2fbag(s));
    @zero_(e)  =  @c0;
    @one_(e)  =  @cNat(@c1);
    ==(@zero_, @one_)  =  false;
    ==(@one_, @zero_)  =  false;
    @add_(f, g)(e)  =  +(f(e), g(e));
    @add_(f, @zero_)  =  f;
    @add_(@zero_, f)  =  f;
    @min_(f, g)(e)  =  min(f(e), g(e));
    @min_(f, f)  =  f;
    @min_(f, @zero_)  =  @zero_;
    @min_(@zero_, f)  =  @zero_;
    @monus_(f, g)(e)  =  @monus(f(e), g(e));
    @monus_(f, f)  =  @zero_;
    @monus_(f, @zero_)  =  f;
    @monus_(@zero_, f)  =  @zero_;
    @Nat2Bool_(f)(e)  =  >(f(e), @c0);
    @Nat2Bool_(@zero_)  =  @false_;
    @Nat2Bool_(@one_)  =  @true_;
    @Bool2Nat_(h)(e)  =  if(h(e), @cNat(@c1), @c0);
    @Bool2Nat_(@false_)  =  @zero_;
    @Bool2Nat_(@true_)  =  @one_;
