# Type Level Programming

* FP 
* Advanced FP
* Computations are performed on types themselves, rather than on runtime values (compile time over runtime)
* Types become first-class citizens (over values)

## Examples

Capital Case String
```typescript
type CapitalCase<S extends string> = S extends `${infer First}${infer Rest}`
  ? `${Uppercase<First>}${Rest}`
  : S;

export function resultsCapitalCase(){
    type Hello = CapitalCase<"hello">;
    type World = CapitalCase<"world">;
    
    // Works
    const hello: Hello = "Hello";
    const world: World = "World";
    console.log(hello);
    console.log(world);
    
    // Ts Errors
    //const wrongHello: Hello = "hello"; // Error: Type '"hello"' is not assignable to type '"Hello"'
    //const wrongWorld: World = "world"; // Error: Type '"world"' is not assignable to type '"World"'
    //console.log(wrongHello);
    //console.log(wrongWorld);
}
```

Allow only 18+ as value
```typescript
type Plus18<N extends number> = N extends 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17
  ? never 
  : N;

export function resultsPlus18(){
    type ValidAge = Plus18<25>;
    type InvalidAge = Plus18<16>;
    
    // Works
    const adult: ValidAge = 25;
    console.log(adult);
    
    // TS Error
    //const minor: InvalidAge = 16; // Error: Type '16' is not assignable to type 'never'
    //console.log(minor);
}
```

Not Null
```typescript
type NotNull<T> = T extends null | undefined ? never : T;

export function resultNotNull() {
    type ValidString = NotNull<string>;
    type InvalidString = NotNull<string | null | undefined>;

    // Works
    const str: ValidString = "Hello";
    console.log(str);

    // TS Error
    //const invalid: InvalidString = null; // Error: Type 'null' is not assignable to type 'never'
    //console.log(invalid);
}
```

Plus One
```Typescript
type Plus1<T extends readonly number[]> = {
  readonly [K in keyof T]: T[K] extends number ? [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11][T[K]] : never;
};

export function resultsPlusOne(){
    type Original = [0, 1, 2, 5, 9];
    type Incremented = Plus1<[0, 1, 2, 5, 9]>; // [1, 2, 3, 6, 10]
    
    // Works
    const original: Original = [0, 1, 2, 5, 9];
    const incremented: Incremented = [1, 2, 3, 6, 10];
    
    console.log("Original:", original);
    console.log("Plus1:", incremented);

    // Does not work - ES errors
    //const invalid: Incremented = [1, 2, 3, 6, 11]; //Type '11' is not assignable to type '10'.ts(2322)
    //console.log("Plus1 (invalid):", invalid);
}
```

Extract URL Path
```typescript
type ExtractPath<T extends string> = T extends `${string}://${string}/${infer Path}`
  ? Path extends `${infer First}/${infer Rest}`
    ? [First, ...ExtractPath<`https://example.com/${Rest}`>]
    : Path extends ""
    ? []
    : [Path]
  : [];

export function resultsExtract(){
    type SimpleUrl = ExtractPath<"https://api.example.com/users/123/posts">; // ["users", "123", "posts"]
    type DeepUrl = ExtractPath<"https://domain.com/api/v1/users/456/orders/789">; // ["api", "v1", "users", "456", "orders", "789"]
    
    // Works
    const simplePath: SimpleUrl = ["users", "123", "posts"];
    const deepPath: DeepUrl = ["api", "v1", "users", "456", "orders", "789"];
    
    console.log("Simple URL paths:", simplePath);
    console.log("Deep URL paths:", deepPath);
    
    // TS Error
    //const wrongPath: SimpleUrl = ["users", "123", "comments"]; // Error: Type '"comments"' is not assignable to type '"posts"'
    //console.log("Extract (invalid):", wrongPath);
}
```