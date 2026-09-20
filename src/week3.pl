% ---------------------------------------------------------------------------
% Exercise 03.01: enter the family program
%   parent(emma, magnus).
%   parent(emma, daniela).
%   parent(magnus, oscar).
%   parent(daniela, freja).
% Define grandparent(X, Y) and ask ?- grandparent(emma, X). Then ask
% ?- grandparent(X, freja).
parent(emma, magnus).
parent(emma, daniela).
parent(magnus, oscar).
parent(daniela, freja).

grandparent(X, Y) :- parent(X, Z), parent(Z, Y).
% ?- grandparent(emma, X).
% X = oscar ? ;
% X = freja ? ;
% no
% ?- grandparent(X, freja).
% X = emma ? ;
% no

% ---------------------------------------------------------------------------
% Exercise 03.02: enter the graph program
%   edge(a, b).
%   edge(b, c).
%   path(X, Y) :- edge(X, Y).
%   path(X, Z) :- edge(X, Y), path(Y, Z).
% Ask ?- path(a, X). and collect all solutions. Replace the second rule
% with path(X, Z) :- path(X, Y), edge(Y, Z). What happens, and why?
edge(a, b).
edge(b, c).

path(X, Y) :- edge(X, Y).
path(X, Z) :- edge(X, Y), path(Y, Z).
% ?- path(a, X).
% X = b ? ;
% X = c ? ;
% no

% path(X, Z) :- path(X, Y), edge(Y, Z).
% Still finds b then c on backtracking, since those are the real answers.
% But the recursive path/2 call now runs before edge/2, so once both are
% found Prolog keeps recursing on path(X, Y) looking for another one and
% hangs.

% ---------------------------------------------------------------------------
% Exercise 03.03: predict the answer to each query, then check it:
%   ?- X = 1 + 2.
%   ?- X is 1 + 2.
%   ?- 3 = 1 + 2.
%   ?- f(X, b) = f(a, Y).
%   ?- [H | T] = [1, 2, 3].
%   ?- X = f(X).
% What is the difference between = and is?
%
% X = 1 + 2.        -> X = 1+2 (unifies with the unevaluated term)
% X is 1 + 2.       -> X = 3 (evaluates the arithmetic expression)
% 3 = 1 + 2.        -> false (3 does not unify with the term 1+2)
% f(X, b) = f(a, Y). -> X = a, Y = b
% [H | T] = [1, 2, 3]. -> H = 1, T = [2, 3]
% X = f(X).         -> succeeds without the occurs check, building a cyclic term
%
% = unifies two terms without evaluating them; is evaluates the right-hand
% side as an arithmetic expression and unifies the result with the left.

% ---------------------------------------------------------------------------
% Exercise 03.04: write a Datalog program that does not terminate when run
% with Prolog.
ancestor(X, Y) :- ancestor(X, Z), parent(Z, Y).
ancestor(X, Y) :- parent(X, Y).
% ?- ancestor(emma, Y).
% never returns - loops forever expanding ancestor(X, Z) before parent(Z, Y)

% From now on, the Prolog programs you write should always terminate.

% ---------------------------------------------------------------------------
% Exercise 03.05: the natural numbers are defined as
%   nat(z).
%   nat(s(X)) :- nat(X).
% Implement +, -, *, <=, and min.
nat(z).
nat(s(X)) :- nat(X).

add(z, Y, Y) :- nat(Y).
add(s(X), Y, s(Z)) :- add(X, Y, Z).

sub(X, Y, Z) :- add(Y, Z, X).

mul(z, Y, z) :- nat(Y).
mul(s(X), Y, Z) :- mul(X, Y, Z1), add(Z1, Y, Z).

leq(z, Y) :- nat(Y).
leq(s(X), s(Y)) :- leq(X, Y).

min(X, Y, X) :- leq(X, Y).
min(X, Y, Y) :- leq(Y, X), X \== Y.
% ?- add(s(s(z)), s(z), R).            % R = s(s(s(z)))
% ?- sub(s(s(s(z))), s(z), R).         % R = s(s(z))
% ?- mul(s(s(z)), s(s(s(z))), R).      % R = s(s(s(s(s(s(z))))))
% ?- min(s(z), s(s(z)), R).            % R = s(z)

% ---------------------------------------------------------------------------
% Exercise 03.06: use Prolog to determine whether each equation/inequality
% has a solution: x = 1 + 2; x + 2 = 3; x * x + 1 = 5; x <= min(x, y),
% where x and y are natural numbers.
one(s(z)).
two(s(s(z))).
three(s(s(s(z)))).
% ?- one(O), two(T), add(O, T, X), three(X).                    % x = 3
% ?- two(T), three(Th), add(X, T, Th).                          % x = 1
% ?- two(T), mul(T, T, M), one(O), add(M, O, s(s(s(s(s(z)))))). % x = 2
% ?- leq(X, Y), min(X, Y, M), X == M.                           % e.g. x = z, y = z

% ---------------------------------------------------------------------------
% Exercise 03.07: implement odd(X) and even(X).
even(z).
even(s(X)) :- odd(X).
odd(s(X)) :- even(X).
% ?- even(s(s(z))).   % yes
% ?- odd(s(z)).       % yes

% ---------------------------------------------------------------------------
% Exercise 03.08: implement the Fibonacci function. A list can be defined
% as
%   list([]).
%   list([_ | Xs]) :- list(Xs).
list([]).
list([_ | Xs]) :- list(Xs).

fib(z, z).
fib(s(z), s(z)).
fib(s(s(X)), F) :-
    fib(s(X), F1),
    fib(X, F2),
    add(F1, F2, F).
% ?- fib(s(s(s(s(s(z))))), F).   % F = s(s(s(s(s(z)))))

% ---------------------------------------------------------------------------
% Exercise 03.09: implement prefix(Xs, Ys) and suffix(Xs, Ys).
prefix([], _).
prefix([X | Xs], [X | Ys]) :- prefix(Xs, Ys).

suffix(Xs, Xs).
suffix(Xs, [_ | Ys]) :- suffix(Xs, Ys).
% ?- prefix([1, 2], [1, 2, 3]).   % yes
% ?- suffix([2, 3], [1, 2, 3]).   % yes

% ---------------------------------------------------------------------------
% Exercise 03.10: implement prefix and suffix in terms of append.
append_([], Ys, Ys).
append_([X | Xs], Ys, [X | Zs]) :- append_(Xs, Ys, Zs).

prefixApp(Xs, Ys) :- append_(Xs, _, Ys).
suffixApp(Xs, Ys) :- append_(_, Xs, Ys).
% ?- prefixApp([1, 2], [1, 2, 3]).   % yes
% ?- suffixApp([2, 3], [1, 2, 3]).   % yes

% ---------------------------------------------------------------------------
% Exercise 03.11: implement memberOf in terms of append.
memberOf(X, Ys) :- append_(_, [X | _], Ys).
% ?- memberOf(2, [1, 2, 3]).   % yes

% ---------------------------------------------------------------------------
% Exercise 03.12: implement two versions of reverse, one using append and
% one using an accumulator. Draw the proof trees produced by each on a
% small list.
reverseApp([], []).
reverseApp([X | Xs], Ys) :- reverseApp(Xs, RevXs), append_(RevXs, [X], Ys).

reverseAcc(Xs, Ys) :- reverseAcc(Xs, [], Ys).
reverseAcc([], Acc, Acc).
reverseAcc([X | Xs], Acc, Ys) :- reverseAcc(Xs, [X | Acc], Ys).

% Proof tree for reverseApp([1,2,3], Ys):
%   reverseApp([1,2,3], Ys)
%     reverseApp([2,3], R1),  append_(R1, [1], Ys)
%       reverseApp([3], R2),  append_(R2, [2], R1)
%         reverseApp([], R3), append_(R3, [3], R2)
%           reverseApp([], [])
%           append_([], [3], [3])
%         append_([3], [2], [3, 2])
%     append_([3, 2], [1], [3, 2, 1])
%
% Proof tree for reverseAcc([1,2,3], Ys):
%   reverseAcc([1,2,3], [], Ys)
%     reverseAcc([2,3], [1], Ys)
%       reverseAcc([3], [2,1], Ys)
%         reverseAcc([], [3,2,1], Ys)

% ---------------------------------------------------------------------------
% Exercise 03.13: implement substitute(A, B, Xs, Ys), which relates Xs to
% Ys such that every occurrence of A in Xs is replaced by B in Ys.
substitute(_, _, [], []).
substitute(A, B, [A | Xs], [B | Ys]) :- substitute(A, B, Xs, Ys).
substitute(A, B, [X | Xs], [X | Ys]) :- X \== A, substitute(A, B, Xs, Ys).
% ?- substitute(b, z, [a, b, c, b], R).   % R = [a, z, c, z]

% ---------------------------------------------------------------------------
% Exercise 03.14: a binary tree of natural numbers can be defined as
%   tree(leaf).
%   tree(node(X, N, Y)) :- nat(N), tree(X), tree(Y).
% - containsUnsorted(T, N): T is unsorted, does it contain N?
% - containsSorted(T, N): T is sorted, does it contain N, visiting at most
%   one subtree per node?
% - minHeight(T, N) and maxHeight(T, N): shortest/longest root-to-leaf path.
% - sum(T, N): N is the sum of T's elements.
% - preOrder(T, Xs), inOrder(T, Xs), postOrder(T, Xs): T's elements as a
%   list, in that traversal order.
tree(leaf).
tree(node(X, N, Y)) :- nat(N), tree(X), tree(Y).

containsUnsorted(node(_, N, _), N).
containsUnsorted(node(X, _, _), N) :- containsUnsorted(X, N).
containsUnsorted(node(_, _, Y), N) :- containsUnsorted(Y, N).

containsSorted(node(_, N, _), N).
containsSorted(node(X, M, _), N) :- leq(N, M), N \== M, containsSorted(X, N).
containsSorted(node(_, M, Y), N) :- leq(M, N), N \== M, containsSorted(Y, N).

minHeight(leaf, z).
minHeight(node(X, _, Y), s(H)) :-
    minHeight(X, HX), minHeight(Y, HY), min(HX, HY, H).

maxHeight(leaf, z).
maxHeight(node(X, _, Y), s(H)) :-
    maxHeight(X, HX), maxHeight(Y, HY),
    ( leq(HX, HY) -> H = HY ; H = HX ).

sum(leaf, z).
sum(node(X, N, Y), S) :-
    sum(X, SX), sum(Y, SY),
    add(SX, N, S1), add(S1, SY, S).

preOrder(leaf, []).
preOrder(node(X, N, Y), L) :-
    preOrder(X, LX), preOrder(Y, LY),
    append_([N], LX, L1), append_(L1, LY, L).

inOrder(leaf, []).
inOrder(node(X, N, Y), L) :-
    inOrder(X, LX), inOrder(Y, LY),
    append_(LX, [N], L1), append_(L1, LY, L).

postOrder(leaf, []).
postOrder(node(X, N, Y), L) :-
    postOrder(X, LX), postOrder(Y, LY),
    append_(LX, LY, L1), append_(L1, [N], L).
% ?- inOrder(node(node(leaf, z, leaf), s(z), node(leaf, s(s(z)), leaf)), L).
% L = [z, s(z), s(s(z))]

% ---------------------------------------------------------------------------
% Exercise 03.15: the following definition of remove for lists is
% incorrect. Fix it:
%   remove(x, [], []).
%   remove(x, [x | ys], rs) :- remove(x, ys, rs).
%   remove(x, [y | ys], rs) :- remove(x, ys, rs).
remove(_, [], []).
remove(X, [X | Ys], Rs) :- remove(X, Ys, Rs).
remove(X, [Y | Ys], [Y | Rs]) :- X \== Y, remove(X, Ys, Rs).
% ?- remove(b, [a, b, c, b, d], R).   % R = [a, c, d]

% ---------------------------------------------------------------------------
% Exercise 03.16: for each pair of terms, compute a unifying substitution,
% or report if unification is impossible.
%
% 1.  unify(42, 42)                                    -> {}
% 2.  unify(21, 42)                                    -> FAIL
% 3.  unify(X, 42)                                     -> {X/42}
% 4.  unify(42, X)                                     -> {X/42}
% 5.  unify(X, Y)                                      -> {X/Y}
% 6.  unify(X, X)                                      -> {}
% 7.  unify(leaf, leaf)                                -> {}
% 8.  unify(X, node(X, 21, X))                         -> FAIL
% 9.  unify(X, node(Y, 21, Z))                         -> {X/node(Y, 21, Z)}
% 10. unify(node(leaf, X, leaf), node(leaf, 42, leaf)) -> {X/42}
% 11. unify(node(X, Y, leaf), node(leaf, Z, leaf))     -> {X/leaf, Y/Z}
% 12. unify(node(X, Y, X), node(node(leaf, 42, leaf), 21, leaf))          -> FAIL
% 13. unify(node(X, Y, Z), node(node(leaf, 42, leaf), 21, Z))             -> {X/node(leaf, 42, leaf), Y/21}
% 14. unify([X], [1, 2, 3])                            -> FAIL
% 15. unify([X, Y, Z], [Z, X, Y])                      -> {X/Z, Y/Z}
% 16. unify([[X], Y], [Y, [2, 3]])                     -> FAIL
% 17. unify([X, Y], [1, [2, 3]])                       -> {X/1, Y/[2, 3]}
% 18. unify([X, Y], [1, [X, 3]])                       -> {X/1, Y/[1, 3]}
% 19. unify([X, [Y]], [1, [X, [Y]]])                   -> FAIL

% ---------------------------------------------------------------------------
% Exercise 03.17: describe why the occurs check is necessary in the
% unification algorithm.
%
% Without it, unify(X, f(X)) binds X to f(X) - a term containing itself.
% Printing or walking that binding later loops forever.

% ---------------------------------------------------------------------------
% Exercise 03.18: when would you use Datalog to solve a programming
% problem? And when would you use Prolog?
%
% Datalog: querying a finite set of facts (reachability, graph queries,
% program analysis) where guaranteed termination and order-independent
% semantics matter.
% Prolog: general recursive data structures and search with backtracking
% (parsers, symbolic computation, planning), at the cost of termination
% depending on clause order.
