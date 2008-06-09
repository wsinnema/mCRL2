// Author(s): Luc Engelen
// Copyright: see the accompanying file COPYING or copy at
// https://svn.win.tue.nl/trac/MCRL2/browser/trunk/COPYING
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//
/// \file mcrl2/data/prover/bdd_simplifier.h
/// \brief Abstract interface for BDD simplifiers

#ifndef BDD_SIMPLIFIER_H
#define BDD_SIMPLIFIER_H

#include "aterm2.h"

  /// \brief A base class for classes that simplify binary decision diagrams. These classes take
  /// \brief a BDD as input and try to simplify this BDD.
  /// The method BDD_Simplifier::simplify receives a BDD as parameter a_bdd and tries to find an equivalent BDD that is
  /// smaller. It returns the reduced BDD if such a BDD is found. If a reduced BDD is not found, the original BDD is returned.

class BDD_Simplifier {
  protected:
    /// \brief An integer representing the moment in time when the maximal amount of seconds has been spent on simplifying
    /// \brief the BDD.
    int f_deadline;
  public:
    /// \brief Destructor without any additional functionality.
    virtual ~BDD_Simplifier() {
    }

    /// \brief Sets the attribute BDD_Simplifier::f_deadline.
    void set_time_limit(int a_time_limit);

    /// \brief Returns a simplified BDD, equivalent to the bdd a_bdd.
    /// precondition: The argument passed as parameter a_bdd is a data expression in internal mCRL2 format with the
    /// following restrictions: It either represents the constant true or the constant false, or it is an if-then-else
    /// expression with an expression of sort Bool  as guard, and a then-branch and an else-branch that again follow these
    /// restrictions
    virtual ATermAppl simplify(ATermAppl a_bdd) {
      return a_bdd;
    }
};

#endif
