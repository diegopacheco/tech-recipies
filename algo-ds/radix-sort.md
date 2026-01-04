# Radix Sort

## What is it?

Radix Sort is a non-comparative sorting algorithm that sorts integers by processing individual digits. It sorts numbers digit by digit, starting from the least significant digit (LSD) to the most significant digit (MSD), or vice versa. Unlike comparison-based algorithms like quicksort or mergesort, radix sort exploits the structure of the keys being sorted.

## How it works?

1. Find the maximum number to know the number of digits
2. Do counting sort for every digit, starting from the least significant digit
3. Instead of comparing elements, it distributes elements into buckets according to their radix (base)
4. After processing all digits, the array becomes sorted
5. Uses a stable sorting algorithm (usually counting sort) as a subroutine

The algorithm processes each digit position and groups numbers by that digit, then reassembles them in order. This process repeats for each digit position until all positions have been processed.

## Use cases?

- Sorting large datasets of integers or strings with fixed-length keys
- Sorting phone numbers, social security numbers, or ZIP codes
- Database indexing operations
- Sorting IP addresses
- Processing fixed-length record keys
- Suffix array construction in string algorithms
- Sorting playing cards by suit and rank

## Code Sample (Rust)

```rust
fn get_max(arr: &[u32]) -> u32 {
    *arr.iter().max().unwrap_or(&0)
}

fn counting_sort(arr: &mut [u32], exp: u32) {
    let n = arr.len();
    let mut output = vec![0u32; n];
    let mut count = [0usize; 10];

    for &num in arr.iter() {
        let digit = ((num / exp) % 10) as usize;
        count[digit] += 1;
    }

    for i in 1..10 {
        count[i] += count[i - 1];
    }

    for i in (0..n).rev() {
        let digit = ((arr[i] / exp) % 10) as usize;
        count[digit] -= 1;
        output[count[digit]] = arr[i];
    }

    arr.copy_from_slice(&output);
}

fn radix_sort(arr: &mut [u32]) {
    if arr.is_empty() {
        return;
    }

    let max = get_max(arr);
    let mut exp = 1u32;

    while max / exp > 0 {
        counting_sort(arr, exp);
        exp *= 10;
    }
}

fn main() {
    let mut arr = vec![170, 45, 75, 90, 802, 24, 2, 66];
    println!("Original: {:?}", arr);
    radix_sort(&mut arr);
    println!("Sorted: {:?}", arr);
}
```

## Pros and Cons

### Pros
- O(nk) time complexity where k is the number of digits, can be faster than O(n log n) comparison sorts
- Stable sorting algorithm
- Efficient for sorting large numbers of integers
- Linear time complexity when k is constant
- No comparisons between elements needed

### Cons
- Only works with integers or data that can be represented as integers
- Requires additional memory for counting sort buckets
- Not efficient when the range of digits (k) is large
- Performance depends on the distribution of data
- Not suitable for floating-point numbers without modification

## Frameworks or libraries using it

- **Rust**: `rdxsort` crate, `voracious_radix_sort` crate
- **C++**: Boost.Sort library includes spreadsort (hybrid radix sort)
- **Java**: Arrays.sort() uses radix sort for certain primitive arrays internally
- **Intel TBB**: Parallel radix sort implementation
- **CUDA**: CUB library provides GPU-accelerated radix sort
- **Apache Spark**: Uses radix sort for certain shuffle operations
- **Redis**: Uses radix trees (related data structure) for sorted sets
