-- ---------------------------------------------------------------------
-- Exercise 04.01: create process : []i32 -> []i32 -> i32 that takes two
-- equal-length i32 arrays and computes the maximum absolute pointwise
-- difference, without using loop. Return 0 for two empty signals.
--
-- let s1 = [23,45,-23,44,23,54,23,12,34,54,7,2, 4,67]
-- let s2 = [-2, 3,  4,57,34, 2, 5,56,56, 3,3,5,77,89]
-- process s1 s2 = 73
def process [n] (s1: [n]i32) (s2: [n]i32) : i32 =
  map2 (\a b -> i32.abs (a - b)) s1 s2
  |> reduce i32.max 0

-- ---------------------------------------------------------------------
-- Exercise 04.02: benchmark process with futhark bench, using
--   -- ==
--   -- entry: process
--   -- random input { [1000000]i32 [1000000]i32 }
-- How does the program scale for different inputs? Does it scale as
-- predicted by the work-span cost model, even for very small or very
-- large inputs?
--
-- Work O(n), span O(log n). Runtime scales close to linearly once n is
-- big enough to use the available parallelism. Small n is dominated by
-- launch overhead, very large n by memory bandwidth - neither shows up
-- in the work-span model, which ignores constant factors.
entry process_bench [n] (s1: [n]i32) (s2: [n]i32) : i32 = process s1 s2
-- ==
-- entry: process_bench
-- random input { [1000000]i32 [1000000]i32 }

-- ---------------------------------------------------------------------
-- Exercise 04.03: create process_idx : []i32 -> []i32 -> (i32,i64) that
-- also returns the index of the largest absolute difference.
--
-- process_idx s1 s2 = (73, 12)
def process_idx [n] (s1: [n]i32) (s2: [n]i32) : (i32, i64) =
  let diffs = map2 (\a b -> i32.abs (a - b)) s1 s2
  let pairs = zip diffs (iota n)
  let best (d1, i1) (d2, i2) = if d1 >= d2 then (d1, i1) else (d2, i2)
  in reduce best (0, 0) pairs

-- ---------------------------------------------------------------------
-- Exercise 04.04: finish
--   def partition [n] 'a (p: a -> bool) (as: [n]a) : ([]a, []a) = ???
-- separating elements that satisfy p from those that do not, by being
-- clever about indices rather than using two filters.
--
-- partition (\x -> x % 2 == 0) [0,1,2,3,4,5,6,7] = ([0,2,4,6], [1,3,5,7])
-- Work O(n), span O(log n): work-efficient.
def partition [n] 'a (p: a -> bool) (as: [n]a) : ([]a, []a) =
  let flags = map p as
  let is_true = map (\f -> if f then 1i64 else 0i64) flags
  let is_false = map (\f -> if f then 0i64 else 1i64) flags
  let idxs_true = scan (+) 0 is_true
  let idxs_false = scan (+) 0 is_false
  let num_true = if n == 0 then 0 else idxs_true[n - 1]
  let target = map3 (\f it if_ -> if f then it - 1 else num_true + if_ - 1)
                     flags idxs_true idxs_false
  let result = scatter (copy as) target as
  in (result[0:num_true], result[num_true:n])

-- ---------------------------------------------------------------------
-- Exercise 04.05: finish
--   def segreduce [n] 't (op: t -> t -> t) (ne: t)
--                        (fs: [n]bool) (vs: [n]t): []t = ???
-- via a segmented scan, then extracting the last element of every
-- segment.
--
-- segreduce (+) 0 [true,false,false,true,false] [1,2,3,4,5] = [6, 9]
-- Work O(n), span O(log n): work-efficient.
def segscan [n] 't (op: t -> t -> t) (ne: t) (fs: [n]bool) (vs: [n]t) : [n]t =
  let pairs = zip fs vs
  let lifted (f1, v1) (f2, v2) = (f1 || f2, if f2 then v2 else op v1 v2)
  let (_, vs') = unzip (scan lifted (false, ne) pairs)
  in vs'

def segreduce [n] 't (op: t -> t -> t) (ne: t) (fs: [n]bool) (vs: [n]t) : []t =
  let scanned = segscan op ne fs vs
  let is_last = tabulate n (\i -> i == n - 1 || fs[i + 1])
  in zip scanned is_last
     |> filter (\(_, l) -> l)
     |> map (\(v, _) -> v)

-- ---------------------------------------------------------------------
-- Exercise 04.06: implement
--   def histogram [n] (k: i64) (xs: [n]u32) : [k]i64 = ???
-- where H[i] counts occurrences of i in xs; values outside [0,k-1] are
-- ignored. Use a sort followed by a segmented reduction.
--
-- histogram 5 [0u32,1u32,1u32,3u32,3u32,3u32,9u32] = [1,2,0,3,0]
-- Work O(n), span O(log n): work-efficient, dominated by the 32-pass
-- radix sort.
def radix_step [n] (bit: i32) (xs: [n]u32) : [n]u32 =
  let bit_of = map (\x -> (x >> u32.i32 bit) & 1u32) xs
  let is0 = map (\b -> if b == 0u32 then 1i64 else 0i64) bit_of
  let is1 = map (\b -> if b == 1u32 then 1i64 else 0i64) bit_of
  let idxs0 = scan (+) 0 is0
  let idxs1 = scan (+) 0 is1
  let num0 = if n == 0 then 0 else idxs0[n - 1]
  let target = map3 (\b i0 i1 -> if b == 0u32 then i0 - 1 else num0 + i1 - 1)
                     bit_of idxs0 idxs1
  in scatter (copy xs) target xs

def radix_sort_u32 [n] (xs: [n]u32) : [n]u32 =
  loop xs' = xs for bit < 32i32 do radix_step bit xs'

def histogram [n] (k: i64) (xs: [n]u32) : [k]i64 =
  let valid = filter (\x -> x < u32.i64 k) xs
  let sorted = radix_sort_u32 valid
  let is_start = map2 (\i cur -> i == 0 || cur != sorted[i - 1]) (indices sorted) sorted
  let combine (k1, c1) (_, c2) = (k1, c1 + c2)
  let keyed = map (\x -> (x, 1i64)) sorted
  let counts_with_keys = segreduce combine (0u32, 0i64) is_start keyed
  in scatter (replicate k 0i64)
             (map (\(key, _) -> i64.u32 key) counts_with_keys)
             (map (\(_, c) -> c) counts_with_keys)
