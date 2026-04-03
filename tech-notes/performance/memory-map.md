# Memory-Mapped Files (mmap)

## 1. What is Memory Map?

Memory mapping (mmap) is a mechanism that maps a file or a portion of a file directly into a process's virtual address space. Instead of using traditional read/write system calls to access file data, the operating system maps the file contents into memory pages. The process can then access the file data as if it were regular memory using pointers, and the OS handles loading pages from disk and flushing changes back transparently.

The kernel manages the mapping between virtual memory pages and the underlying file on disk using the page table and the virtual memory subsystem. When a mapped page is accessed for the first time, a page fault occurs, and the kernel loads the data from disk into a physical memory frame.

## 2. PROS

- **Zero-copy access**: data is accessed directly in memory without copying between kernel and user space buffers
- **Lazy loading**: pages are loaded on demand (page faults), so only accessed portions consume physical memory
- **Shared memory**: multiple processes can map the same file and share physical pages, enabling efficient IPC
- **Simplified code**: file data can be accessed using pointer arithmetic instead of managing read/write buffers
- **Automatic caching**: the OS page cache manages caching, eviction, and writeback automatically
- **Large file handling**: files larger than available RAM can be mapped since only accessed pages need to be resident
- **Random access performance**: superior to sequential read/write calls for random access patterns

## 3. CONS

- **Page fault overhead**: initial access to each page triggers a page fault which has latency
- **No fine-grained error handling**: I/O errors on mapped regions raise signals (SIGBUS) instead of returning error codes
- **Address space limits**: on 32-bit systems, the virtual address space limits the maximum mapping size
- **Write ordering**: no guarantees on the order writes are flushed to disk without explicit msync calls
- **Fragmentation**: frequent map/unmap operations can fragment the virtual address space
- **Not ideal for sequential streaming**: traditional buffered I/O can outperform mmap for simple sequential reads
- **Complexity with resizing**: growing a mapped file requires remapping (mremap or unmap + map again)
- **TLB pressure**: large numbers of mappings can cause TLB thrashing

## 4. How it Works?

```
Process Virtual Address Space           Physical Memory            Disk
┌──────────────────────┐
│       Code           │
├──────────────────────┤
│       Heap           │
├──────────────────────┤
│                      │
│   Memory-Mapped      │──────────►  Page Frame  ◄──────────  File on Disk
│   Region             │              (loaded on                (source of
│   (virtual pages)    │               page fault)               truth)
│                      │
├──────────────────────┤
│       Stack          │
└──────────────────────┘
```

**Step-by-step flow:**

1. The process calls `mmap()` specifying the file descriptor, offset, length, and protection flags
2. The kernel creates a virtual memory area (VMA) in the process address space but does NOT load any data yet
3. When the process accesses an address in the mapped region, a **page fault** occurs
4. The kernel handles the fault by allocating a physical page frame and reading the file data from disk into it
5. The page table is updated to map the virtual page to the physical frame
6. Subsequent accesses to the same page hit physical memory directly (no fault)
7. Modified pages are marked dirty and flushed to disk by the kernel periodically or via explicit `msync()`
8. When `munmap()` is called, dirty pages are written back and the mapping is removed

**Mapping types:**

- `MAP_SHARED`: changes are visible to other processes and written back to the file
- `MAP_PRIVATE`: copy-on-write; changes are private to the process and not written to the file

## 5. How to Use it?

### C (POSIX)

```c
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

int main() {
    int fd = open("data.bin", O_RDWR);
    size_t length = 4096;

    char *mapped = mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);

    printf("First bytes: %.10s\n", mapped);

    memcpy(mapped, "HELLO", 5);
    msync(mapped, length, MS_SYNC);

    munmap(mapped, length);
    return 0;
}
```

### Java (NIO)

```java
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

public class MMapExample {
    public static void main(String[] args) throws Exception {
        RandomAccessFile file = new RandomAccessFile("data.bin", "rw");
        FileChannel channel = file.getChannel();

        MappedByteBuffer buffer = channel.map(FileChannel.MapMode.READ_WRITE, 0, channel.size());

        byte first = buffer.get(0);
        System.out.println("First byte: " + first);

        buffer.put(0, (byte) 'H');
        buffer.force();

        channel.close();
        file.close();
    }
}
```

### Python

```python
import mmap

with open("data.bin", "r+b") as f:
    mm = mmap.mmap(f.fileno(), 0)

    print(mm[:10])

    mm[0:5] = b"HELLO"
    mm.flush()

    mm.close()
```

### Rust

```rust
use std::fs::OpenOptions;
use memmap2::MmapMut;

fn main() {
    let file = OpenOptions::new().read(true).write(true).open("data.bin").unwrap();

    let mut mmap = unsafe { MmapMut::map_mut(&file).unwrap() };

    println!("First bytes: {:?}", &mmap[..10]);

    mmap[..5].copy_from_slice(b"HELLO");
    mmap.flush().unwrap();
}
```

### Go

```go
package main

import (
	"fmt"
	"os"
	"syscall"
)

func main() {
	f, _ := os.OpenFile("data.bin", os.O_RDWR, 0644)
	defer f.Close()

	info, _ := f.Stat()
	size := int(info.Size())

	data, _ := syscall.Mmap(int(f.Fd()), 0, size, syscall.PROT_READ|syscall.PROT_WRITE, syscall.MAP_SHARED)

	fmt.Printf("First bytes: %s\n", data[:10])

	copy(data[:5], "HELLO")
	syscall.Munmap(data)
}
```

### Common Use Cases

- **Database storage engines**: SQLite, LMDB, and RocksDB use mmap for efficient page management
- **Search engines**: Lucene maps index segments for fast random access lookups
- **Shared memory IPC**: processes communicate through shared mapped regions
- **Large file processing**: genomics, log analysis, and scientific data processing
- **JIT compilers**: map executable pages for generated machine code
