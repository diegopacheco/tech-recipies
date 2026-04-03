# JVM Flag: -XX:+UseStringDeduplication

The -XX:+UseStringDeduplication flag was introduced in Java 8u20 (2014) for the G1 garbage collector.

Benefits, String deduplication reduces memory footprint by:
- Identifying duplicate String objects that have identical character arrays
- Keeping only one copy of the underlying char/byte array
- Making duplicate Strings point to the same underlying array
- Typical memory savings: 10-15% in Java applications, sometimes up to 25%



Why Not Default? Several reasons it remains opt-in:

Performance Trade-offs:
- Adds CPU overhead during GC cycles to identify and deduplicate strings
- Young generation collections become slightly slower
- The deduplication process itself consumes CPU cycles

Memory vs CPU Balance:
- Not all applications have significant string duplication
- Applications with unique strings would pay CPU cost with no benefit
- JVM team prefers conservative defaults that work well for most cases

Compatibility & Predictability:
- Changing default behavior could surprise existing applications
- Some applications are CPU-bound rather than memory-bound
- Opt-in gives users explicit control over the trade-off

Modern Alternatives:
- Java 9+ has compact strings (enabled by default) which reduces string memory usage differently
- This addressed much of the memory concern without CPU overhead

The flag is most useful when:
- You have many duplicate strings in memory
- Memory is more constrained than CPU
- You're using G1GC (required until Java 18, where it became available for other collectors)