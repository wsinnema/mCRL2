// Author(s): Wieger Wesselink
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
/// \file pbes_test.cpp
/// \brief Add your file description here.

#include <iostream>
#include <iterator>
#include <utility>
#include <boost/test/minimal.hpp>
#include <boost/algorithm/string.hpp>
#include "mcrl2/atermpp/make_list.h"
#include "mcrl2/data/utility.h"
#include "mcrl2/pbes/pbes.h"
#include "mcrl2/pbes/pbes_translate.h"
#include "mcrl2/pbes/lps2pbes.h"
#include "mcrl2/pbes/pbes_expression_builder.h"
#include "mcrl2/pbes/detail/quantifier_rename_builder.h"
#include "mcrl2/data/rewriter.h"
#include "mcrl2/pbes/rewriter.h"
#include "mcrl2/pbes/rewriter2.h"
#include "mcrl2/pbes/rename.h"
#include "mcrl2/pbes/complement.h"
#include "mcrl2/pbes/normalize.h"

using namespace std;
using namespace atermpp;
using namespace mcrl2::core;
using namespace mcrl2::data;
using namespace mcrl2::lps;
using namespace mcrl2::lps::detail;
using namespace mcrl2::modal;
using namespace mcrl2::modal::detail;
using namespace mcrl2::pbes_system;
using namespace mcrl2::pbes_system::detail;

const std::string SPECIFICATION =
"act a:Nat;                               \n"
"                                         \n"
"map smaller: Nat#Nat -> Bool;            \n"
"                                         \n"
"var x,y : Nat;                           \n"
"                                         \n"
"eqn smaller(x,y) = x < y;                \n"
"                                         \n"
"proc P(n:Nat) = sum m: Nat. a(m). P(m);  \n"
"                                         \n"
"init P(0);                               \n";

const std::string FORMULA = "forall m:Nat. [a(m)]false";

data_variable nat(std::string name)
{
  return data_variable(core::identifier_string(name) , sort_expr::nat());
}

data_variable bool_(std::string name)
{
  return data_variable(core::identifier_string(name) , sort_expr::bool_());
}

propositional_variable_instantiation prop_var(std::string name, data::data_expression_list parameters)
{
  return propositional_variable_instantiation(core::identifier_string(name), parameters);
}

template <typename Rewriter>
void test_expression(pbes_expression p, Rewriter r)
{
  std::cout << pp(p) << " -> " << pp(r(p)) << std::endl;
}

template <typename PbesRewriter>
void test_result(PbesRewriter& r, pbes_expression x, pbes_expression y)
{
  BOOST_CHECK(r(x) == y);
}

void test_builder()
{
  using namespace pbes_expr;

  data_variable b  = bool_("b");
  data_expression T = data_expr::true_();
  pbes_expression x = and_(b, T);
  pbes_expression y;
  data_expression z;
  specification spec = mcrl22lps(SPECIFICATION);
  data::rewriter datar(spec.data()); 

  pbes_rewrite_expression_builder<data::rewriter> builder1(datar, spec.data());   
  y = builder1.visit(x);

  pbes_rewrite_expression_builder<data::rewriter> builder2 = builder1;
  y = builder2.visit(x);

  pbes_simplify_expression_builder<data::rewriter> sbuilder1(datar, spec.data());   
  y = sbuilder1.visit(x);

  pbes_simplify_expression_builder<data::rewriter> sbuilder2 = sbuilder1;
  y = sbuilder2.visit(x);

  //z = sbuilder3.m_rewriter(T);
  //std::cerr << z << std::endl;
  //y = sbuilder3.visit(x);
}

void test_rewriter()
{
  using namespace pbes_expr;

  specification spec = mcrl22lps(SPECIFICATION);
  data::rewriter datar(spec.data());
  pbes_system::rewriter<data::rewriter> pbesr(datar, spec.data());
  pbes_system::simplify_rewriter1 simp_rewr(spec.data());
  pbes_system::substitute_rewriter subst_rewr(datar, spec.data());

  //state_formula formula = mcf2statefrm(FORMULA, spec);
  //bool timed = false;
  //pbes<> p = lps2pbes(spec, formula, timed);
  
  //for (atermpp::vector<pbes_equation>::iterator i = p.equations().begin(); i != p.equations().end(); ++i)
  //{
  //  pbes_expression e = i->formula();
  //  //std::cout << pp(e) << " -> " << pp(pbesr(e)) << std::endl;
  //  pbes_expression f = pbes_expression_substitute_and_rewrite(e, spec.data(), datar.get_rewriter());
  //  std::cout << pp(e) << " -> " << pp(f) << std::endl;
  //}

  data_variable b  = bool_("b");
  data_variable b1 = bool_("b1");
  data_variable b2 = bool_("b2");
  data_variable b3 = bool_("b3");

  data_variable n  = nat("n");
  data_variable n1 = nat("n1");
  data_variable n2 = nat("n2");
  data_variable n3 = nat("n3");

  data_expression T = data_expr::true_();
  data_expression F = data_expr::false_();

  test_expression(T, pbesr);
  test_expression(F, pbesr);
  test_expression(and_(T, T), pbesr);
  test_expression(and_(T, F), pbesr);
  test_expression(and_(F, F), pbesr);
  test_expression(imp(T, b), pbesr);

  pbes_expression x = and_(b, T);
  test_expression(x, pbesr);
  test_expression(x, simp_rewr);
  test_expression(x, subst_rewr);

  //BOOST_CHECK(pbesr(and_(T, T)) == T);
  //BOOST_CHECK(pbesr(forall(make_list(n), and_(T, T)) == T));
  
  // copy a rewriter
  pbes_system::rewriter<data::rewriter> pbesr1 = pbesr;
  test_expression(x, pbesr1);
}

void test_simplify_rewriter()
{
  using namespace pbes_expr;

  specification spec    = mcrl22lps(SPECIFICATION);
  data::rewriter datar(spec.data());
  pbes_system::simplify_rewriter<data::rewriter> pbesr(datar, spec.data());

  data_variable b  = bool_("b");
  data_variable b1 = bool_("b1");
  data_variable b2 = bool_("b2");
  data_variable b3 = bool_("b3");

  data_variable n  = nat("n");
  data_variable n1 = nat("n1");
  data_variable n2 = nat("n2");
  data_variable n3 = nat("n3");

  data_expression dT = data_expr::true_();
  data_expression dF = data_expr::false_();
  pbes_expression T = true_();
  pbes_expression F = false_();

  propositional_variable_instantiation X  = prop_var("X", make_list(n));
  propositional_variable_instantiation X1 = prop_var("X1", make_list(n));
  propositional_variable_instantiation X2 = prop_var("X2", make_list(n));
  propositional_variable_instantiation X3 = prop_var("X3", make_list(n));

  BOOST_CHECK(pbesr(and_(T, T)) == T);
  BOOST_CHECK(pbesr(and_(T, F)) == F);
  BOOST_CHECK(pbesr(and_(F, F)) == F);
  BOOST_CHECK(pbesr(imp(T, b))  == b);
  BOOST_CHECK(pbesr(and_(and_(T, T), T)) == T);
  BOOST_CHECK(pbesr(and_(X, T)) == X);
  BOOST_CHECK(pbesr(and_(T, X)) == X);
  BOOST_CHECK(pbesr(and_(X, F)) == F);
  BOOST_CHECK(pbesr(and_(F, X)) == F);
  BOOST_CHECK(pbesr(and_(X, and_(F, X))) == F);
}

int test_main(int argc, char** argv)
{
  MCRL2_ATERM_INIT(argc, argv)

  test_builder();
  //test_rewriter();
  //test_simplify_rewriter();

  return 0;
}
