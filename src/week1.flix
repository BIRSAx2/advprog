def runWeek1(): Unit \ IO =
    ex_01_01();
    ex_01_04();
    ex_01_11();
    ex_01_12();
    ex_01_13();
    ex_01_14();
    ex_01_17();
    ex_01_18();
    ()

// Exercise 01.01: given
//   Father(child, dad) :- Parent(child, dad), Male(dad).
//   Mother(child, mum) :- Parent(child, mum), Female(mum).
// (a) describe the program, (b) add facts, (c) extend with Brother/Sister,
// (d) extend with Uncle/Aunt.
def ex_01_01(): Unit \ IO =
    println("\n\nExercise 01.01");

    let db = #{
        Male("Abraham").
        Male("Homer").
        Male("Herb").
        Male("Bart").
        Female("Jackie").
        Female("Marge").
        Female("Lisa").
        Female("Maggie").
        Female("Patty").
        Female("Selma").
        Female("Ling").
        Male("Clancy").
        Female("Mona").

        Parent("Homer", "Abraham").
        Parent("Homer", "Mona").

        Parent("Bart", "Homer").
        Parent("Bart", "Marge").

        Parent("Lisa", "Homer").
        Parent("Lisa", "Marge").

        Parent("Maggie", "Homer").
        Parent("Maggie", "Marge").

        Parent("Herb", "Abraham").
        Parent("Herb", "Mona").

        Parent("Ling", "Selma").

        Parent("Patty", "Jackie").
        Parent("Selma", "Jackie").
    };

    let pr = #{
        Father(child, dad) :- Parent(child, dad), Male(dad).
        Mother(child, mum) :- Parent(child, mum), Female(mum).

        Brother(x, y) :-
            Father(x, dad),
            Father(y, dad),
            Male(x),
            if (x != y).

        Brother(x, y) :-
            Mother(x, mum),
            Mother(y, mum),
            Male(x),
            if (x != y).

        Sister(x, y) :-
            Father(x, dad),
            Father(y, dad),
            Female(x),
            if (x != y).

        Sister(x, y) :-
            Mother(x, mum),
            Mother(y, mum),
            Female(x),
            if (x != y).

        Uncle(x, y) :-
            Brother(x, dad),
            Father(y, dad).

        Uncle(x, y) :-
            Brother(x, mum),
            Mother(y, mum).

        Aunt(x, y) :-
            Sister(x, dad),
            Father(y, dad).

        Aunt(x, y) :-
            Sister(x, mum),
            Mother(y, mum).
    };

    let fathers = query db, pr select (x, y) from Father(x, y);
    let mothers = query db, pr select (x, y) from Mother(x, y);
    let brothers = query db, pr select (x, y) from Brother(x, y);
    let sisters = query db, pr select (x, y) from Sister(x, y);
    let uncles = query db, pr select (x, y) from Uncle(x, y);
    let aunts = query db, pr select (x, y) from Aunt(x, y);

    println("Father: ${fathers}");
    println("Mother: ${mothers}");
    println("Brother: ${brothers}");
    println("Sister: ${sisters}");
    println("Uncle: ${uncles}");
    println("Aunt: ${aunts}");
    ()

// Exercise 01.02: describe the difference between
//   Happy(person) :- Rich(person), Famous(person).
// and
//   Happy(person) :- Rich(person).
//   Happy(person) :- Famous(person).
//
// First: happy iff rich and famous (conjunction).
// Second: happy iff rich or famous (disjunction).

// Exercise 01.03: identify the syntactic categories of
//   Rich("Tom Hanks").
//   Famous("Tom Hanks").
//   Happy(person) :- Rich(person), Famous(person).
//
// "Tom Hanks" is a constant, which is a term.
// Rich, Famous, Happy are predicate symbols.
// person is a variable, which is a term.
// Rich("Tom Hanks") and Famous("Tom Hanks") are facts, which are constraints.
// Rich(person), Famous(person) are body atoms; Happy(person) is a head atom.
// Happy(person) :- Rich(person), Famous(person). is a rule, which is a constraint.
// The whole listing is a program.

// Exercise 01.04: roads, bridges, flights.
def ex_01_04(): Unit \ IO =
    println("\n\nExercise 01.04");

    let db = #{
        Road("Aarhus", "Vejle").
        Road("Aarhus", "Aalborg").
        Road("Aalborg", "Skagen").
        Road("Billund", "Vejle").
        Road("Odense", "Vejle").
        Road("Odense", "Nyborg").
        Road("Helsingør", "København").
        Road("Helsingborg", "Malmø").
        Road("Korsør", "Nyborg").
        Road("Korsør", "Roskilde").
        Road("København", "Roskilde").
        Road("Rønne", "Nexø").

        Bridge("Storebælt", "Korsør", "Nyborg").
        Bridge("Øresund", "København", "Malmø").
        Bridge("Nivå", "Helsingborg", "Helsingør").

        Flight("Aalborg", "København").
        Flight("Aarhus", "København").
        Flight("Billund", "København").
        Flight("København", "Rønne").
    };

    let pr = #{
        Drivable(x, y) :- Road(x, y).
        Drivable(x, y) :- Road(y, x).
        Drivable(x, z) :- Drivable(x, y), Drivable(y, z).

        FromOdense(x) :- Drivable(x, "Odense").

        DrivableWithBridges(x, y) :- Road(x, y).
        DrivableWithBridges(x, y) :- Road(y, x).
        DrivableWithBridges(x, y) :- Bridge(_, x, y).
        DrivableWithBridges(x, y) :- Bridge(_, y, x).
        DrivableWithBridges(x, z) :- DrivableWithBridges(x, y), DrivableWithBridges(y, z).

        FromSkagen(x) :- DrivableWithBridges("Skagen", x).

        Reachable(x, y) :- DrivableWithBridges(x, z), Flight(z, y).
        Reachable(x, y) :- DrivableWithBridges(x, z), Flight(y, z).
    };

    let drivable = query db, pr select (x, y) from Drivable(x, y);
    let fromOdense = query db, pr select x from FromOdense(x);
    let drivableWithBridges = query db, pr select (x, y) from DrivableWithBridges(x, y);
    let fromSkagen = query db, pr select x from FromSkagen(x);
    let reachable = query db, pr select (x, y) from Reachable(x, y);
    let nexoToAalborg = query db, pr select (x, y) from Reachable(x, y) where x == "Nexø" and y == "Aalborg";
    let aalborgToNexo = query db, pr select (x, y) from Reachable(x, y) where x == "Aalborg" and y == "Nexø";

    println("Drivable: ${drivable}");
    println("Can drive to Odense from: ${fromOdense}");
    println("Drivable with bridges: ${drivableWithBridges}");
    println("Drivable with bridges from Skagen: ${fromSkagen}");
    println("Reachable: ${reachable}");
    println("Nexø -> Aalborg reachable: ${not Vector.isEmpty(nexoToAalborg)}");
    println("Aalborg -> Nexø reachable: ${not Vector.isEmpty(aalborgToNexo)}");
    ()

// Exercise 01.05: determine if each constraint is ground.
//   Father("Luke Skywalker", "Darth Vader").  -- ground
//   Fruit("Apple", color).                    -- not ground
//   Fruit("Apple", "Red").                    -- ground
//   Tasty(food) :- Flavor(food, "sweet").     -- not ground

// Exercise 01.06: determine if each constraint is safe or unsafe.
//   Vegetable("Potato", color).                       -- unsafe
//   Sage(person) :- Wise(person), Old(person).        -- safe
//   Imperium(person) :- Consul(person, year).         -- safe
//   Manager(boss, employee) :- Worker(employee).      -- unsafe

// Exercise 01.07: Herbrand Universe and Herbrand Base of
//   Fruit("Apple", "Green").
//   Fruit("Banana", "Yellow").
//   Fruit("Strawberry", "Red").
//   Vegetable("Tomato", "Red").
//
// Herbrand Universe: { Apple, Banana, Strawberry, Tomato, Green, Yellow, Red } (7 constants)
// Herbrand Base: Fruit/2 and Vegetable/2, each 7*7 = 49 ground atoms, |B| = 98
// Excerpt: Fruit("Apple", "Green"), Fruit("Apple", "Yellow"), ..., Vegetable("Tomato", "Red")

// Exercise 01.08: all interpretations of
//   Loves("Rose", "Jack").
//   Loves("Jack", "Rose").
//   Loves("Caledon", "Rose").
//   Happy(x) :- Loves(x, y), Loves(y, x).
//
// Constants: { Rose, Jack, Caledon }
// Herbrand Base: Loves/2 (9 atoms) + Happy/1 (3 atoms) = 12 ground atoms
// 2^12 = 4096 possible interpretations, e.g. {}, { Loves("Rose","Jack") }, ..., B

// Exercise 01.09: given
//   I = { Loves("Rose", "Jack"), Loves("Caledon", "Caledon"), Happy("Rose") }
// which ground atoms/rules are true under I?
//
// Happy("Rose")? TRUE
// Happy("Jack")? FALSE
// Happy("Caledon")? FALSE
// Loves("Rose", "Jack")? TRUE
// Loves("Jack", "Caledon")? FALSE
// Happy("Rose") :- Loves("Rose","Jack"), Loves("Jack","Rose")? TRUE (body false)
// Happy("Jack") :- Loves("Rose","Jack"), Loves("Caledon","Caledon")? FALSE
// Happy("Caledon") :- Loves("Caledon","Caledon"), Loves("Caledon","Caledon")? FALSE

// Exercise 01.10: given the program from 01.08, which interpretations are
// models, and which model is minimal?
//
// I1 = { Loves("Rose","Jack") } -- not a model
// I2 = I1 + { Loves("Jack","Rose"), Loves("Caledon","Rose") } -- not a model
// I3 = I2 + { Happy("Rose") } -- not a model
// I4 = I2 + { Happy("Rose"), Happy("Jack") } -- minimal model
// I5 = I4 + { Happy("Caledon") } -- a model, not minimal

// Exercise 01.11: compute the minimal model of
//   God("Odin").
//   Son("Odin", "Thor").
//   Son("Odin", "Baldr").
//   Son("Thor", "Mothi").
//   Son("Thor", "Magni").
//   DemiGod(x) :- Son(y, x), God(y).
//   Mortal(x)  :- Son(y, x), DemiGod(y).
// using the immediate consequence operator Tp, showing each iteration.
//
// I1 = { God("Odin"), Son("Odin","Thor"), Son("Odin","Baldr"), Son("Thor","Mothi"), Son("Thor","Magni") }
// I2 = I1 + { DemiGod("Thor"), DemiGod("Baldr") }
// I3 = I2 + { Mortal("Mothi"), Mortal("Magni") }  -- fixpoint
def ex_01_11(): Unit \ IO =
    println("\n\nExercise 01.11");
    let db = #{
        God("Odin").
        Son("Odin", "Thor").
        Son("Odin", "Baldr").
        Son("Thor", "Mothi").
        Son("Thor", "Magni").
    };
    let pr = #{
        DemiGod(x) :- Son(y, x), God(y).
        Mortal(x)  :- Son(y, x), DemiGod(y).
    };
    let demiGods = query db, pr select x from DemiGod(x);
    let mortals = query db, pr select x from Mortal(x);
    println("DemiGod: ${demiGods}");
    println("Mortal: ${mortals}");
    ()

// Exercise 01.12: given road facts, compute all pairs of cities connected
// by a route that passes through Rome.
def ex_01_12(): Unit \ IO =
    println("\n\nExercise 01.12");
    let db = #{
        Road("Brundisium", "Capua").
        Road("Brundisium", "Tarentum").
        Road("Capua", "Tarentum").
        Road("Capua", "Rome").
        Road("Genua", "Massilia").
        Road("Genua", "Pisae").
        Road("Genua", "Parma").
        Road("Messana", "Syracuse").
        Road("Ostia", "Rome").
        Road("Parma", "Ravenna").
        Road("Pisae", "Ravenna").
        Road("Pisae", "Rome").
    };
    let pr = #{
        Drivable(x, y) :- Road(x, y).
        Drivable(x, y) :- Road(y, x).
        Drivable(x, z) :- Drivable(x, y), Drivable(y, z).
        ThroughRome(s, t) :- Drivable(s, "Rome"), Drivable("Rome", t).
    };
    let throughRome = query db, pr select (s, t) from ThroughRome(s, t);
    println("Pairs connected via a route through Rome: ${throughRome}");
    ()

// Exercise 01.13: compilers and interpreters.
def ex_01_13(): Unit \ IO =
    println("\n\nExercise 01.13");
    let db = #{
        Machine("x86").
        Machine("x64").

        Interpreter("JavaScript", "C++").
        Interpreter("JVM", "C++").
        Interpreter("WASM", "C++").

        Compiler("C", "x86", "C").
        Compiler("C", "x64", "C").
        Compiler("C++", "x86", "C").
        Compiler("C++", "x64", "C").
        Compiler("Flix", "JVM", "Scala").
        Compiler("Java", "JVM", "Java").
        Compiler("Rust", "x64", "Rust").
        Compiler("Rust", "x86", "Rust").
        Compiler("Rust", "WASM", "Rust").
        Compiler("Scala", "JVM", "Scala").
        Compiler("Scala", "JavaScript", "Scala").

        Compiler("C", "x86", "x86").
        Compiler("OCaml", "x86", "C").
        Compiler("Java", "JVM", "C").
        Compiler("Scala", "JVM", "Pizza").
        Compiler("Pizza", "JVM", "Java").
        Compiler("Rust", "x86", "OCaml").
    };
    let pr = #{
        Runnable(m)    :- Machine(m).
        Runnable(lang) :- Interpreter(lang, host), Runnable(host).
        Runnable(lang) :- Compiler(lang, target, impl), Runnable(target), Runnable(impl).

        CompilesTo(src, dst) :- Compiler(src, dst, _).
        CompilesTo(src, dst) :- CompilesTo(src, mid), CompilesTo(mid, dst).

        RunnableOnWeb(lang) :- Compiler(lang, "JavaScript", _).
        RunnableOnWeb(lang) :- Compiler(lang, "WASM", _).
    };
    let runnable = query db, pr select x from Runnable(x);
    let compilesTo = query db, pr select (x, y) from CompilesTo(x, y);
    let scalaOnWeb = query db, pr select x from RunnableOnWeb(x) where x == "Scala";
    let jvmOnWeb = query db, pr select x from RunnableOnWeb(x) where x == "JVM";
    println("(a) Runnable languages: ${runnable}");
    println("(b) Compiles-to pairs: ${compilesTo}");
    println("(c) Can we run the Flix compiler on the web? ${not Vector.isEmpty(scalaOnWeb)}");
    println("(d) Can we run Flix programs on the web? ${not Vector.isEmpty(jvmOnWeb)}");
    ()

// Exercise 01.14: the buggy program
//   Orphan(c) :- Person(c), Person(p), not Parent(c, p).
// (a) give facts that break it, (b) describe the bug, (c) fix it.
def ex_01_14(): Unit \ IO =
    println("\n\nExercise 01.14");
    let db = #{
        Person("Bart").
        Person("Homer").
        Person("Marge").
        Person("Lisa").
        Parent("Bart", "Homer").
        Parent("Bart", "Marge").
    };
    let buggyPr = #{
        Orphan(c) :- Person(c), Person(p), not Parent(c, p).
    };
    let buggyOrphans = query db, buggyPr select x from Orphan(x);
    println("(a) Buggy result - Orphan: ${buggyOrphans}");
    println("(b) Bug: tests against one arbitrary person p instead of every person.");

    let fixedPr = #{
        HasParent(c) :- Parent(c, _).
        Orphan(c)    :- Person(c), not HasParent(c).
    };
    let fixedOrphans = query db, fixedPr select x from Orphan(x);
    println("(c) Fixed result - Orphan: ${fixedOrphans}");
    ()

// Exercise 01.15: determine if the following program is stratified.
//   Undead(x)  :- Ghost(x).
//   Undead(x)  :- Vampire(x).
//   Alive(x)   :- Human(x), not Undead(x).
//   Mortal(x)  :- Human(x), Alive(x).
//   Ghost(x)   :- Human(x), not Alive(x), not Vampire(x).
//   Vampire(x) :- Human(x), Bitten(x, y), Vampire(y), not Ghost(x).
//
// Not stratified: Ghost and Vampire depend negatively on each other (a
// cycle through negation).

// Exercise 01.16: determine if the following program is stratified.
//   A(x) :- B(x), C(x), D(x), E(x).
//   B(x) :- C(x).
//   C(x) :- A(x), E(x).
//   E(x) :- D(x), not D(x).
//   D(x) :- A(x).
//
// Not stratified: cycle E -> D (-), D -> A (+), A -> E (+) contains a
// negative edge.

// Exercise 01.17: movies, starring, directing.
def ex_01_17(): Unit \ IO =
    println("\n\nExercise 01.17");
    let db = #{
        Movie("Reservoir Dogs", "Action").
        Movie("Pulp Fiction", "Action").
        Movie("Apocalypse Now", "War").
        Movie("The Godfather", "Crime").

        StarringIn("Reservoir Dogs", "Steve Buscemi").
        StarringIn("Reservoir Dogs", "Michael Madsen").
        StarringIn("Reservoir Dogs", "Harvey Keitel").
        StarringIn("Reservoir Dogs", "Quentin Tarantino").

        StarringIn("Pulp Fiction", "John Travolta").
        StarringIn("Pulp Fiction", "Samuel L. Jackson").
        StarringIn("Pulp Fiction", "Uma Thurman").
        StarringIn("Pulp Fiction", "Bruce Willis").
        StarringIn("Pulp Fiction", "Quentin Tarantino").

        StarringIn("Apocalypse Now", "Martin Sheen").
        StarringIn("Apocalypse Now", "Marlon Brando").
        StarringIn("Apocalypse Now", "Francis Ford Coppola").

        StarringIn("The Godfather", "Al Pacino").
        StarringIn("The Godfather", "Marlon Brando").
        StarringIn("The Godfather", "Robert De Niro").

        DirectedBy("Reservoir Dogs", "Quentin Tarantino").
        DirectedBy("Pulp Fiction", "Quentin Tarantino").
        DirectedBy("Apocalypse Now", "Francis Ford Coppola").
        DirectedBy("The Godfather", "Francis Ford Coppola").
    };
    let pr = #{
        Director(director) :- DirectedBy(_, director).

        DirectorAppears(movie) :- DirectedBy(movie, director), StarringIn(movie, director).

        DirectorAbsent(movie) :- DirectedBy(movie, director), not StarringIn(movie, director).

        DirectorAbsentSomewhere(director) :- DirectedBy(movie, director), not StarringIn(movie, director).
        DirectorAlwaysAppears(director)   :- Director(director), not DirectorAbsentSomewhere(director).
    };
    let directorAppears = query db, pr select x from DirectorAppears(x);
    let directorAbsent = query db, pr select x from DirectorAbsent(x);
    let directorAlwaysAppears = query db, pr select x from DirectorAlwaysAppears(x);
    println("(a) Movies where the director appears: ${directorAppears}");
    println("(b) Movies where the director does not appear: ${directorAbsent}");
    println("(c) Directors that appear in every movie they made: ${directorAlwaysAppears}");
    ()

// Exercise 01.18 (The Drinkers Problem).
def ex_01_18(): Unit \ IO =
    println("\n\nExercise 01.18 (The Drinkers Problem)");
    let db = #{
        Drinks("Homer", "Duff").
        Drinks("Barney", "Duff").
        Drinks("Moe", "Duff").
        Drinks("Lisa", "RootBeer").

        Frequents("Homer", "MoesTavern").
        Frequents("Barney", "MoesTavern").
        Frequents("Lisa", "MoesTavern").

        Serves("MoesTavern", "Duff").
        Serves("MoesTavern", "Fudd").
    };
    let pr = #{
        Happy(p) :- Frequents(p, b), Serves(b, beer), Drinks(p, beer).

        Unhappy(p) :- Frequents(p, b), Serves(b, beer), not Drinks(p, beer).

        ServesLikedBeer(p, b) :- Frequents(p, b), Serves(b, beer), Drinks(p, beer).
        Miserable(p)          :- Frequents(p, b), not ServesLikedBeer(p, b).
    };
    let happy = query db, pr select x from Happy(x);
    let unhappy = query db, pr select x from Unhappy(x);
    let miserable = query db, pr select x from Miserable(x);
    println("(a) Happy: ${happy}");
    println("(b) Unhappy: ${unhappy}");
    println("(c) Miserable: ${miserable}");
    ()
