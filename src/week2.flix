// Exercise 02.01: rewrite the SQL query
//   SELECT C.CustomerName, O.OrderDate, P.ProductName
//   FROM Customers C JOIN Orders O ON C.CustomerID = O.CustomerID
//        JOIN Products P ON O.OrderID = P.OrderID
//   WHERE P.ProductPrice > 10
// as a Flix function using `inject` and `query`.
def exercise02_01(
    customers: List[(Int32, String)],
    orders: List[(Int32, Int32, String)],
    products: List[(Int32, Int32, String, Int32)]
): Vector[(String, String, String)] = {

    let db1 = inject customers into Customer/2;
    let db2 = inject orders into Order/3;
    let db3 = inject products into Product/4;

    query db1, db2, db3
        select (customerName, orderDate, productName)
        from Customer(customerId, customerName),
             Order(orderId, customerId, orderDate),
             Product(_, orderId, productName, productPrice)
        where productPrice > 10
}

def ex_02_01(): Unit \ IO = {
    println("\n\nExercise 02.01");
    let customers = List#{
        (1, "Alice"),
        (2, "Bob"),
        (3, "Charlie")
    };

    let orders = List#{
        (100, 1, "2026-08-01"),
        (101, 2, "2026-08-02"),
        (102, 1, "2026-08-03")
    };

    let products = List#{
        (1000, 100, "Keyboard", 50),
        (1001, 101, "Pen", 5),
        (1002, 102, "Mouse", 25)
    };

    let result = exercise02_01(customers, orders, products);

    println(result)
}

// Exercise 02.02: rewrite the SQL query
//   SELECT S.StudentName, C.CourseName, MAX(G.Grade) AS HighestGrade
//   FROM Students S JOIN Grades G ON S.StudentID = G.StudentID
//        JOIN Courses C ON G.CourseID = C.CourseID
//   GROUP BY S.StudentID, S.StudentName, C.CourseName
//   ORDER BY S.StudentName
// as a Flix function. Define a Grade type (-3, 00, 02, 4, 7, 10, 12) with a
// lattice on it, -3 as the smallest element.
enum StudentGrade with Eq, Order, ToString {
    case Minus3,
    case Zero,
    case Two,
    case Four,
    case Seven,
    case Ten,
    case Twelve
}

instance PartialOrder[StudentGrade] {
    pub def lessEqual(x: StudentGrade, y: StudentGrade): Bool = x <= y
}
instance LowerBound[StudentGrade] {
    pub def minValue(): StudentGrade = StudentGrade.Minus3
}
instance UpperBound[StudentGrade] {
    pub def maxValue(): StudentGrade = StudentGrade.Twelve
}
instance JoinLattice[StudentGrade] {
    pub def leastUpperBound(x: StudentGrade, y: StudentGrade): StudentGrade = if (x > y) x else y
}
instance MeetLattice[StudentGrade] {
    pub def greatestLowerBound(x: StudentGrade, y: StudentGrade): StudentGrade = if (x < y) x else y
}

def exercise02_02(
    students: List[(Int32, String)],
    courses: List[(Int32, String)],
    grades: List[(Int32, Int32, StudentGrade)]
): Vector[(String, String, StudentGrade)] = {
    let db1 = inject students into Student/2;
    let db2 = inject courses into Course/2;
    let db3 = inject grades into Grades/3;

    let p = #{
        BestGrade(studentId, courseId; grade) :-
            Grades(studentId, courseId, grade).
    };

    query db1, db2, db3, p
        select (studentName, courseName, grade)
        from Student(studentId, studentName),
             BestGrade(studentId, courseId; grade),
             Course(courseId, courseName)
}

def ex_02_02(): Unit \ IO = {
    println("\n\nExercise 02.02");
    let students = List#{
        (1, "Alice"),
        (2, "Bob"),
        (3, "Charlie")
    };

    let courses = List#{
        (101, "Math"),
        (102, "Science"),
        (103, "History")
    };

    let grades = List#{
        (1, 101, StudentGrade.Ten),
        (2, 102, StudentGrade.Seven),
        (3, 103, StudentGrade.Twelve),
        (1, 101, StudentGrade.Four),
        (2, 101, StudentGrade.Two)
    };

    let result = exercise02_02(students, courses, grades);

    println(result)
}

// Exercise 02.03: given StarsWith(Actor, Actor), write a Flix function to
// compute the Bacon number of every actor.
def baconNumbers(starsWith: List[(String, String)]): Map[String, Int32] = {
    let edges = starsWith ++ List.map(match (x, y) -> (y, x), starsWith);
    let db = inject edges into StarsWith/2;
    let pr = #{
        Bacon("Kevin Bacon"; Down.Down(0)).
        Bacon(y; d + Down.Down(1)) :- Bacon(x; d), StarsWith(x, y).
    };
    let results = query db, pr select (actor, d) from Bacon(actor; d);
    results |> Vector.toList |> List.map(match (actor, d) -> match d {
        case Down.Down(n) => (actor, n)
    }) |> List.toMap
}

def ex_02_03(): Unit \ IO = {
    println("\n\nExercise 02.03");
    let starsWith = List#{
        ("Kevin Bacon", "Tom Hanks"),
        ("Tom Hanks", "Meg Ryan"),
        ("Meg Ryan", "Tom Cruise"),
        ("Kevin Bacon", "Elvis Presley")
    };
    println("Bacon numbers: ${baconNumbers(starsWith)}")
}

// Exercise 02.04: given
//   let p1 = #{ A(x, y) :- B(x, x), C(y). };
//   let p2 = #{ C(x) :- F(x, y), G(y, x). };
// what are the row types of p1 and p2?
//
// p1: #{ A(t1, t2), B(t1), C(t2) | r }
// p2: #{ C(t1), F(t1, t2), G(t2, t1) | r }

// Exercise 02.05: implement Ullman's Algorithm as
//   def ullman(g: List[(String, Bool, String)]): Map[String, Int32]
// where g is the precedence graph and the Bool marks a positive (true) or
// negative (false) edge. Return the stratum of each predicate symbol, or
// -1 for every symbol if the graph cannot be stratified.
def ullman(g: List[(String, Bool, String)]): Map[String, Int32] = {
    let preds = (List.map(match (a, _, _) -> a, g) ++ List.map(match (_, _, b) -> b, g)) |> List.toSet;
    let n = Set.size(preds);
    let seeds = preds |> Set.toList |> List.map(p -> (p, 0));
    let posEdges = g |> List.filterMap(match (a, positive, b) -> if (positive) Some((a, b)) else None);
    let negEdges = g |> List.filterMap(match (a, positive, b) -> if (not positive) Some((a, b)) else None);

    let dbSeeds = inject seeds into Seed/2;
    let dbPos = inject posEdges into Pos/2;
    let dbNeg = inject negEdges into Neg/2;
    let pr = #{
        Stratum(p; s) :- Seed(p, s).
        Stratum(a; s) :- Stratum(b; s), Pos(a, b).
        Stratum(a; Order.min(s + 1, n)) :- Stratum(b; s), Neg(a, b).
    };

    let results = query dbSeeds, dbPos, dbNeg, pr select (p, s) from Stratum(p; s);
    let strata = results |> Vector.toList |> List.toMap;
    if (strata |> Map.exists((_, s) -> s >= n))
        preds |> Set.toList |> List.map(p -> (p, -1)) |> List.toMap
    else
        strata
}

def ex_02_05(): Unit \ IO = {
    println("\n\nExercise 02.05");
    let stratified = List#{
        ("Undead", true, "Ghost"),
        ("Undead", true, "Vampire"),
        ("Alive", true, "Human"),
        ("Alive", false, "Undead"),
        ("Mortal", true, "Human"),
        ("Mortal", true, "Alive")
    };
    println("Stratifiable example: ${ullman(stratified)}");

    let notStratified = List#{
        ("Ghost", true, "Human"),
        ("Ghost", false, "Alive"),
        ("Ghost", false, "Vampire"),
        ("Vampire", true, "Human"),
        ("Vampire", false, "Ghost")
    };
    println("Non-stratifiable example: ${ullman(notStratified)}")
}

// Exercise 02.06: rewrite the SQL query
//   SELECT E.EmployeeName, D.DepartmentName, S.Amount AS LatestSalary, S.DateReceived
//   FROM Employees E JOIN Salaries S ON E.EmployeeID = S.EmployeeID
//        JOIN Departments D ON S.DepartmentID = D.DepartmentID
//   WHERE S.DateReceived = (SELECT MAX(S.DateReceived) FROM Salaries S
//                           WHERE E.EmployeeID = S.EmployeeID AND S.DepartmentID = D.DepartmentID)
// as a Flix function using lattice semantics.
enum LatestSalary with Eq, Order, ToString {
    case Salary(String, Int32), // (dateReceived, amount)
    case NoSalary
}

instance PartialOrder[LatestSalary] {
    pub def lessEqual(x: LatestSalary, y: LatestSalary): Bool = match (x, y) {
        case (LatestSalary.NoSalary, _)                              => true
        case (_, LatestSalary.NoSalary)                              => false
        case (LatestSalary.Salary(d1, _), LatestSalary.Salary(d2, _)) => d1 <= d2
    }
}
instance LowerBound[LatestSalary] {
    pub def minValue(): LatestSalary = LatestSalary.NoSalary
}
instance JoinLattice[LatestSalary] {
    pub def leastUpperBound(x: LatestSalary, y: LatestSalary): LatestSalary =
        if (PartialOrder.lessEqual(x, y)) y else x
}
instance MeetLattice[LatestSalary] {
    pub def greatestLowerBound(x: LatestSalary, y: LatestSalary): LatestSalary =
        if (PartialOrder.lessEqual(x, y)) x else y
}

def amountOf(s: LatestSalary): Int32 = match s {
    case LatestSalary.Salary(_, amount) => amount
    case LatestSalary.NoSalary          => 0
}
def dateOf(s: LatestSalary): String = match s {
    case LatestSalary.Salary(date, _) => date
    case LatestSalary.NoSalary        => ""
}

def exercise02_06(
    employees: List[(Int32, String)],
    departments: List[(Int32, String)],
    salaries: List[(Int32, Int32, Int32, String)] // (employeeId, departmentId, amount, dateReceived)
): Vector[(String, String, Int32, String)] = {
    let db1 = inject employees into Employee/2;
    let db2 = inject departments into Department/2;
    let db3 = inject salaries into SalaryFact/4;

    let p = #{
        Latest(employeeId, departmentId; LatestSalary.Salary(date, amount)) :-
            SalaryFact(employeeId, departmentId, amount, date).
    };

    query db1, db2, db3, p
        select (employeeName, departmentName, amountOf(salary), dateOf(salary))
        from Employee(employeeId, employeeName),
             Latest(employeeId, departmentId; salary),
             Department(departmentId, departmentName)
}

def ex_02_06(): Unit \ IO = {
    println("\n\nExercise 02.06");
    let employees = List#{ (1, "Alice"), (2, "Bob") };
    let departments = List#{ (10, "Engineering"), (20, "Sales") };
    let salaries = List#{
        (1, 10, 5000, "2026-01-01"),
        (1, 10, 5500, "2026-06-01"),
        (2, 20, 4000, "2026-02-01"),
        (2, 20, 4200, "2026-03-01")
    };
    println("Latest salary per employee: ${exercise02_06(employees, departments, salaries)}")
}

// Exercise 02.07: consider the Datalog program
//   Edge(1, 2). Edge(2, 4). Edge(1, 3). Edge(3, 5). Edge(5, 4).
//   R1: Path(x, y) :- Edge(x, y).
//   R2: Path(x, z) :- Path(x, y), Edge(y, z).
// Draw two distinct provenance trees for Path(1, 4), label each internal
// node with the rule used, and write down the provenance path w.r.t.
// {Edge} for each. Which tree does pquery return?
//
// Tree A: R2(R1(Edge(1,2)), Edge(2,4)), height 2, path {Edge(1,2), Edge(2,4)}
// Tree B: R2(R2(R1(Edge(1,3)), Edge(3,5)), Edge(5,4)), height 3, path {Edge(1,3), Edge(3,5), Edge(5,4)}
def ex_02_07(): Unit \ IO = {
    println("\n\nExercise 02.07");
    let db = #{
        Edge(1, 2). Edge(2, 4). Edge(1, 3). Edge(3, 5). Edge(5, 4).
    };
    let pr = #{
        Path(x, y) :- Edge(x, y).
        Path(x, z) :- Path(x, y), Edge(y, z).
    };
    let pp = pquery db, pr select Path(1, 4) with {Edge};
    let edges = Vector.map(v -> ematch v { case Edge(x, y) => (x, y) }, pp);
    println("pquery returns the minimal-height tree A: ${edges}")
}

// Exercise 02.08: given the Wire/Cash/Crypto transaction log, write
//   def followTheMoney(src: String, dst: String): Vector[String]
// documenting how money flowed from src to dst as human-readable strings.
// The transfers must form an unbroken chain with strictly increasing
// timestamps. Test by tracing acme-holdings to offshore-trust-x.
def followTheMoney(src: String, dst: String): Vector[String] = {
    let db = #{
        Wire("acme-holdings", "Cayman National Bank", "shellcorp-7", 100).
        Wire("shellcorp-7", "Banco General", "tropical-imports", 110).
        Cash("tropical-imports", "shellcorp-7", 120).
        Wire("nordic-ventures", "LGT Bank", "offshore-trust-x", 150).
        Wire("pelican-trading", "Banco General", "shellcorp-12", 210).
        Crypto("shellcorp-7", "Binance", "shellcorp-12", 250).
        Wire("acme-holdings", "Danske Bank", "nordic-ventures", 300).
        Crypto("shellcorp-12", "Kraken", "riviera-estates", 320).
        Wire("nordic-ventures", "Danske Bank", "acme-holdings", 350).
        Wire("riviera-estates", "HSBC", "luxe-yachts", 380).
        Wire("shellcorp-12", "Julius Baer", "alpine-invest", 400).
        Cash("alpine-invest", "offshore-trust-x", 550).
    };
    let pr = #{
        Moved(a, b, t) :- Wire(a, _, b, t).
        Moved(a, b, t) :- Cash(a, b, t).
        Moved(a, b, t) :- Crypto(a, _, b, t).
        Moved(a, c, t2) :- Moved(a, b, t1), Wire(b, _, c, t2), if (t2 > t1).
        Moved(a, c, t2) :- Moved(a, b, t1), Cash(b, c, t2), if (t2 > t1).
        Moved(a, c, t2) :- Moved(a, b, t1), Crypto(b, _, c, t2), if (t2 > t1).
    };
    let arrivals = query db, pr select t from Moved(a, b, t) where a == src and b == dst;
    match Vector.head(arrivals) {
        case None => Vector#{}
        case Some(t) =>
            let pp = pquery db, pr select Moved(src, dst, t) with {Wire, Cash, Crypto};
            pp
            |> Vector.map(v -> ematch v {
                   case Wire(a, bank, b, tt)   => (tt, "${a} wired money to ${b} via ${bank}")
                   case Cash(a, b, tt)         => (tt, "${a} handed cash to ${b}")
                   case Crypto(a, exch, b, tt) => (tt, "${a} swapped crypto to ${b} on ${exch}")
               })
            |> Vector.toList
            |> List.sortBy(fst)
            |> List.map(snd)
            |> List.toVector
    }
}

def ex_02_08(): Unit \ IO = {
    println("\n\nExercise 02.08");
    Vector.forEach(println, followTheMoney("acme-holdings", "offshore-trust-x"))
}

// Exercise 02.09: given currency exchange Rate facts, write
//   def convert(amount: Float64, src: String, dst: String): Option[Float64]
// which converts amount from src to dst through a chain of rates (their
// product), or None if no chain exists. Test 1,000 DKK to USD and to KRW.
def convert(amount: Float64, src: String, dst: String): Option[Float64] = {
    let db = #{
        Rate("DKK", "EUR", 0.134).
        Rate("DKK", "SEK", 1.55).
        Rate("SEK", "NOK", 0.98).
        Rate("EUR", "USD", 1.08).
        Rate("EUR", "GBP", 0.85).
        Rate("GBP", "USD", 1.27).
        Rate("USD", "JPY", 155.0).
        Rate("USD", "CHF", 0.88).
        Rate("CHF", "EUR", 1.06).
        Rate("KRW", "USD", 0.00072).
    };
    let pr = #{
        Reaches(a, b) :- Rate(a, b, _).
        Reaches(a, c) :- Reaches(a, b), Rate(b, c, _).
    };
    let reachable = query db, pr select (a, b) from Reaches(a, b) where a == src and b == dst;
    if (Vector.isEmpty(reachable))
        None
    else {
        let pp = pquery db, pr select Reaches(src, dst) with {Rate};
        let rate = Vector.foldLeft((acc, v) -> acc * ematch v { case Rate(_, _, r) => r }, 1.0, pp);
        Some(amount * rate)
    }
}

def ex_02_09(): Unit \ IO = {
    println("\n\nExercise 02.09");
    let dkkToUsd = convert(1000.0, "DKK", "USD");
    let dkkToKrw = convert(1000.0, "DKK", "KRW");
    println("1000 DKK -> USD: ${dkkToUsd}");
    println("1000 DKK -> KRW: ${dkkToKrw}");
    ()
}

// Exercise 02.10: given
//   def reachable(g: Set[(Int32, Int32)], src: Int32, dst: Int32): Bool
// write three implementations: first-class Datalog, functional, imperative.
// Test on a non-trivial graph with cycles.
def reachableDatalog(g: Set[(Int32, Int32)], src: Int32, dst: Int32): Bool = {
    let db = inject Set.toList(g) into Edge/2;
    let pr = #{
        Reach(x, y) :- Edge(x, y).
        Reach(x, z) :- Reach(x, y), Edge(y, z).
    };
    let results = query db, pr select (x, y) from Reach(x, y) where x == src and y == dst;
    not Vector.isEmpty(results)
}

def reachableFunctional(g: Set[(Int32, Int32)], src: Int32, dst: Int32): Bool = {
    def go(visited: Set[Int32], frontier: Set[Int32]): Set[Int32] =
        if (Set.isEmpty(frontier))
            visited
        else {
            let visited1 = Set.union(visited, frontier);
            let next = frontier |> Set.flatMap(n -> g |> Set.filterMap(match (a, b) -> if (a == n) Some(b) else None));
            let frontier1 = Set.difference(next, visited1);
            go(visited1, frontier1)
        };
    Set.memberOf(dst, go(Set#{}, Set#{src}))
}

def reachableImperative(g: Set[(Int32, Int32)], src: Int32, dst: Int32): Bool = region rc {
    let visited = MutSet.empty(rc);
    let queue = MutDeque.empty(rc);
    MutSet.add(src, visited);
    MutDeque.pushBack(src, queue);
    def loop(): Unit \ rc =
        match MutDeque.popFront(queue) {
            case None => ()
            case Some(n) =>
                foreach ((a, b) <- g)
                    if (a == n and not MutSet.memberOf(b, visited)) {
                        MutSet.add(b, visited);
                        MutDeque.pushBack(b, queue)
                    } else ();
                loop()
        };
    loop();
    MutSet.memberOf(dst, visited)
}

def cyclicGraph(): Set[(Int32, Int32)] =
    Set#{(0, 1), (1, 2), (2, 0), (2, 3)}

def ex_02_10(): Unit \ IO = {
    println("\n\nExercise 02.10");
    let g = cyclicGraph();
    println("Datalog:    0 -> 3 is ${reachableDatalog(g, 0, 3)}, 3 -> 0 is ${reachableDatalog(g, 3, 0)}");
    println("Functional: 0 -> 3 is ${reachableFunctional(g, 0, 3)}, 3 -> 0 is ${reachableFunctional(g, 3, 0)}");
    println("Imperative: 0 -> 3 is ${reachableImperative(g, 0, 3)}, 3 -> 0 is ${reachableImperative(g, 3, 0)}")
}

// Exercise 02.11: reflect on Exercise 02.10 - fastest to write, most
// elegant, and how to parallelize the functional and imperative versions.
//
// Fastest to write: Datalog. Most elegant: Datalog.
// Parallel functional: map/reduce over each round's frontier.
// Parallel imperative: shard visited/queue per thread, or run BFS layers
// concurrently with a barrier.

// Exercise 02.12: benchmark the three implementations from Exercise 02.10.
def lineGraph(size: Int32): Set[(Int32, Int32)] =
    List.range(0, size) |> List.map(i -> (i, i + 1)) |> List.toSet

def benchmark(name: String, f: Unit -> Bool \ ef): Unit \ (ef + Time.Clock + IO) = {
    let t0 = Time.Clock.now();
    let result = f();
    let t1 = Time.Clock.now();
    println("${name}: result = ${result}, elapsed = ${t1 - t0}ms")
}

def ex_02_12(): Unit \ IO = {
    println("\n\nExercise 02.12");
    let g = lineGraph(2000);
    Time.Clock.runWithIO(() -> {
        benchmark("Datalog",    () -> reachableDatalog(g, 0, 2000));
        benchmark("Functional", () -> reachableFunctional(g, 0, 2000));
        benchmark("Imperative", () -> reachableImperative(g, 0, 2000))
    })
}

def runWeek2(): Unit \ IO =
    ex_02_01();
    ex_02_02();
    ex_02_03();
    ex_02_05();
    ex_02_06();
    ex_02_07();
    ex_02_08();
    ex_02_09();
    ex_02_10();
    ex_02_12();
    ()
