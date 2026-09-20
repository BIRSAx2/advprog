@Test
def testUllmanStratified(): Unit \ Assert =
    let g = List#{
        ("Undead", true, "Ghost"),
        ("Undead", true, "Vampire"),
        ("Alive", true, "Human"),
        ("Alive", false, "Undead")
    };
    let result = ullman(g);
    Assert.assertEq(expected = Some(0), Map.get("Ghost", result))

@Test
def testUllmanNotStratified(): Unit \ Assert =
    let g = List#{
        ("Ghost", true, "Human"),
        ("Ghost", false, "Alive"),
        ("Ghost", false, "Vampire"),
        ("Vampire", true, "Human"),
        ("Vampire", false, "Ghost")
    };
    let result = ullman(g);
    Assert.assertEq(expected = Some(-1), Map.get("Ghost", result))

@Test
def testBaconNumbers(): Unit \ Assert =
    let starsWith = List#{
        ("Kevin Bacon", "Tom Hanks"),
        ("Tom Hanks", "Meg Ryan")
    };
    let result = baconNumbers(starsWith);
    Assert.assertEq(expected = Some(2), Map.get("Meg Ryan", result))

@Test
def testReachableAgree(): Unit \ Assert =
    let g = cyclicGraph();
    let a = reachableDatalog(g, 0, 3);
    let b = reachableFunctional(g, 0, 3);
    let c = reachableImperative(g, 0, 3);
    Assert.assertEq(expected = (true, true, true), (a, b, c))

@Test
def testReachableUnreachable(): Unit \ Assert =
    let g = cyclicGraph();
    Assert.assertEq(expected = false, reachableFunctional(g, 3, 0))

@Test
def testFollowTheMoney(): Unit \ Assert =
    let result = followTheMoney("acme-holdings", "offshore-trust-x");
    Assert.assertEq(expected = 4, Vector.length(result))

@Test
def testConvertDkkToUsd(): Unit \ Assert =
    Assert.assertEq(expected = Some(144.72000000000003), convert(1000.0, "DKK", "USD"))

@Test
def testConvertNoChain(): Unit \ Assert =
    Assert.assertEq(expected = None, convert(1000.0, "DKK", "KRW"))
