# Design Principles &amp; GoF Patterns

Ten principles that keep code cheap to change, each shown as the wrong shape next to the right shape in Python, plus every Gang of Four pattern written as small as it can be written.

Interactive version with tabs and side-by-side panels: [design-patterns.html](design-patterns.html)

- [KISS](#kiss)
- [DRY](#dry)
- [YAGNI](#yagni)
- [SoC](#soc)
- [Law of Demeter](#law-of-demeter)
- [SRP](#srp)
- [OCP](#ocp)
- [LSP](#lsp)
- [ISP](#isp)
- [DIP](#dip)
- [GoF patterns](#gof-patterns)
- [Comparison](#comparison)

---

## KISS

Keep It Simple, Stupid.

Pick the plainest construct that solves the problem in front of you. Complexity has to be paid for by a requirement, not by a hunch. Indirection you cannot justify in one sentence is cost with no return. The reader, not the writer, decides whether code is simple.

**Bad**

```python
class EvenChecker:
    def __init__(self, strategy):
        self.strategy = strategy

    def check(self, n):
        return self.strategy.apply(n)

class ModuloStrategy:
    def apply(self, n):
        return n % 2 == 0

def is_even(n):
    return EvenChecker(ModuloStrategy()).check(n)
```

Two classes and an injection point to hide one operator. Nothing here can ever vary.

**Good**

```python
def is_even(n):
    return n % 2 == 0
```

The whole behaviour is visible in one line and needs no navigation to understand.

---

## DRY

Don't Repeat Yourself.

Every piece of knowledge should have one authoritative home in the system. Duplication is dangerous because copies drift apart when only one is fixed. It is about duplicated *decisions*, not about text that happens to look alike. Two rules that merely coincide today should stay separate.

**Bad**

```python
def create_user(name, email):
    if not name or len(name) > 50:
        raise ValueError("bad name")
    if "@" not in email:
        raise ValueError("bad email")
    return {"name": name, "email": email}

def update_user(user, name, email):
    if not name or len(name) > 50:
        raise ValueError("bad name")
    if "@" not in email:
        raise ValueError("bad email")
    user.update({"name": name, "email": email})
    return user
```

Raise the name limit to 80 and one of the two paths keeps rejecting valid users.

**Good**

```python
def validate(name, email):
    if not name or len(name) > 50:
        raise ValueError("bad name")
    if "@" not in email:
        raise ValueError("bad email")

def create_user(name, email):
    validate(name, email)
    return {"name": name, "email": email}

def update_user(user, name, email):
    validate(name, email)
    user.update({"name": name, "email": email})
    return user
```

The rule lives in one place, so it changes in one place.

---

## YAGNI

You Aren't Gonna Need It.

Build the feature when the requirement arrives, not when you first imagine it. Speculative options still cost tests, docs, bugs and review time today. Guessed abstractions usually guess wrong and then block the real requirement. Deleting unused flexibility is far harder than adding it later.

**Bad**

```python
class Report:
    def __init__(self, rows, fmt="csv", compress=False,
                 encrypt=False, plugins=None):
        self.rows = rows
        self.fmt = fmt
        self.compress = compress
        self.encrypt = encrypt
        self.plugins = plugins or []

    def render(self):
        if self.fmt == "csv":
            out = "\n".join(",".join(r) for r in self.rows)
        elif self.fmt == "xml":
            out = "<todo/>"
        elif self.fmt == "pdf":
            raise NotImplementedError
        for p in self.plugins:
            out = p(out)
        return out
```

Four knobs nobody asked for, two formats that do not work, one plugin hook with no plugins.

**Good**

```python
def render_csv(rows):
    return "\n".join(",".join(r) for r in rows)
```

CSV was the requirement. XML gets its own function on the day someone needs XML.

---

## SoC

Separation of Concerns.

Different kinds of decisions belong in different units of code. Business rules, persistence and presentation change for unrelated reasons and at different speeds. Keeping them apart lets you test the rules with no database and swap the output with no rewrite. Tangled concerns force you to touch everything to change anything.

**Bad**

```python
import sqlite3

def handle_order(payload):
    conn = sqlite3.connect("shop.db")
    total = sum(i["price"] * i["qty"] for i in payload["items"])
    conn.execute("insert into orders values (?, ?)",
                 (payload["id"], total))
    conn.commit()
    print(f"Order {payload['id']} total {total:.2f}")
```

Pricing cannot be tested without a database and a captured stdout.

**Good**

```python
def total_of(items):
    return sum(i["price"] * i["qty"] for i in items)

def save_order(conn, order_id, total):
    conn.execute("insert into orders values (?, ?)",
                 (order_id, total))
    conn.commit()

def format_order(order_id, total):
    return f"Order {order_id} total {total:.2f}"
```

Three concerns, three functions, each testable and replaceable on its own.

---

## Law of Demeter

Talk to friends, not to strangers.

An object should only call methods on itself, its own fields, its parameters and things it created. Long chains like `a.b.c.d()` hard-code the shape of objects you do not own. Ask the neighbour for the answer instead of reaching through it for the data. The payoff is that internal structure can change without breaking distant callers.

**Bad**

```python
def label(order):
    return order.customer.address.city.name.upper()
```

One function now depends on four classes. Any of them can break it by renaming a field.

**Good**

```python
class Address:
    def city_name(self):
        return self.city.name

class Customer:
    def city_name(self):
        return self.address.city_name()

class Order:
    def city_name(self):
        return self.customer.city_name()

def label(order):
    return order.city_name().upper()
```

Each object answers for its own neighbour, so the caller knows only `Order`.

---

## SRP

Single Responsibility Principle.

A class should have one reason to change, meaning one stakeholder driving its changes. Accounting, the web team and the mailing system are three reasons, so they belong in three classes. When one class serves several audiences, every release risks breaking someone else's need. The test is simple: who asks for this to change?

**Bad**

```python
class Invoice:
    def __init__(self, lines):
        self.lines = lines

    def total(self):
        return sum(self.lines)

    def to_html(self):
        return f"<b>{self.total()}</b>"

    def save(self, path):
        open(path, "w").write(self.to_html())

    def email(self, smtp, to):
        smtp.send(to, self.to_html())
```

A styling tweak, a storage change and a tax change all edit the same class.

**Good**

```python
class Invoice:
    def __init__(self, lines):
        self.lines = lines

    def total(self):
        return sum(self.lines)

class InvoiceView:
    def to_html(self, invoice):
        return f"<b>{invoice.total()}</b>"

class InvoiceStore:
    def save(self, path, html):
        open(path, "w").write(html)
```

Money rules, rendering and storage each move on their own schedule.

---

## OCP

Open/Closed Principle.

Code should be open to new behaviour but closed to modification of what already works. Adding a case should mean adding code, not editing a switch that ships with every other case. Polymorphism and registries turn a growing conditional into an extension point. Fewer edits to proven code means fewer regressions.

**Bad**

```python
def area(shape):
    if shape["kind"] == "circle":
        return 3.14159 * shape["r"] ** 2
    if shape["kind"] == "square":
        return shape["side"] ** 2
    raise ValueError("unknown shape")
```

Every new shape reopens a function that already works for circles and squares.

**Good**

```python
class Circle:
    def __init__(self, r):
        self.r = r

    def area(self):
        return 3.14159 * self.r ** 2

class Square:
    def __init__(self, side):
        self.side = side

    def area(self):
        return self.side ** 2

def area(shape):
    return shape.area()
```

A triangle is a new file. Nothing that already passes its tests gets touched.

---

## LSP

Liskov Substitution Principle.

A subtype must be usable anywhere its base type is expected, with no surprises. Subclasses may not strengthen what callers must provide or weaken what callers are promised. Inheriting only to reuse code is how substitutability quietly breaks. If a caller has to ask which subclass it holds, the hierarchy is wrong.

**Bad**

```python
class Rectangle:
    def set_width(self, w):
        self.w = w

    def set_height(self, h):
        self.h = h

    def area(self):
        return self.w * self.h

class Square(Rectangle):
    def set_width(self, w):
        self.w = self.h = w

    def set_height(self, h):
        self.w = self.h = h

def grow(r):
    r.set_width(2)
    r.set_height(3)
    assert r.area() == 6
```

`grow` holds for every rectangle and fails for a square. The subclass broke the contract.

**Good**

```python
class Shape:
    def area(self):
        raise NotImplementedError

class Rectangle(Shape):
    def __init__(self, w, h):
        self.w, self.h = w, h

    def area(self):
        return self.w * self.h

class Square(Shape):
    def __init__(self, side):
        self.side = side

    def area(self):
        return self.side ** 2
```

They share the promise they can both keep, `area`, and nothing else.

---

## ISP

Interface Segregation Principle.

No client should be forced to depend on methods it does not use. Fat interfaces push implementers into writing stubs that raise or return nothing. Several small role interfaces let each caller depend on exactly what it calls. Stubbed-out methods are the visible symptom of the violation.

**Bad**

```python
class Worker:
    def work(self):
        raise NotImplementedError

    def eat(self):
        raise NotImplementedError

    def sleep(self):
        raise NotImplementedError

class Robot(Worker):
    def work(self):
        return "welding"

    def eat(self):
        raise NotImplementedError("robots do not eat")

    def sleep(self):
        raise NotImplementedError("robots do not sleep")
```

Two thirds of the interface is a lie the robot has to keep telling.

**Good**

```python
from typing import Protocol

class Workable(Protocol):
    def work(self): ...

class Feedable(Protocol):
    def eat(self): ...

class Robot:
    def work(self):
        return "welding"

class Human:
    def work(self):
        return "coding"

    def eat(self):
        return "lunch"
```

A shift scheduler takes `Workable`; a canteen takes `Feedable`. Neither over-asks.

---

## DIP

Dependency Inversion Principle.

High-level policy should not depend on low-level detail; both depend on an abstraction. The abstraction is owned by the policy, so the database plugs into the domain and not the reverse. Constructing your own collaborators welds the two layers together permanently. Injecting them makes the policy testable with a five-line fake.

**Bad**

```python
class MySQLUsers:
    def all(self):
        return [{"id": 1}]

class UserReport:
    def __init__(self):
        self.repo = MySQLUsers()

    def run(self):
        return len(self.repo.all())
```

Reporting cannot run, or be tested, without MySQL being reachable.

**Good**

```python
from typing import Protocol

class Users(Protocol):
    def all(self): ...

class UserReport:
    def __init__(self, repo: Users):
        self.repo = repo

    def run(self):
        return len(self.repo.all())

class FakeUsers:
    def all(self):
        return [{"id": 1}]
```

The report knows only the port. MySQL, Postgres or a fake all satisfy it.

---

## GoF patterns

The original catalogue names **23** patterns across three families: creational patterns decide how objects are made, structural patterns decide how they are composed, behavioural patterns decide how they collaborate. Object Pool is not in the book but is the pattern most often counted as the 24th, so it is included and marked.

### Creational

**01. Singleton** — one instance for the whole process, reachable from a single access point.

```python
class Config:
    _inst = None

    def __new__(cls):
        if cls._inst is None:
            cls._inst = super().__new__(cls)
        return cls._inst
```

**02. Factory Method** — a base class defines the workflow and lets subclasses choose the concrete product.

```python
class HtmlButton:
    def paint(self):
        return "<button>"

class Dialog:
    def create_button(self):
        raise NotImplementedError

    def render(self):
        return self.create_button().paint()

class WebDialog(Dialog):
    def create_button(self):
        return HtmlButton()
```

**03. Abstract Factory** — create whole families of related products without naming their concrete classes.

```python
class DarkFactory:
    def button(self):
        return "dark button"

    def checkbox(self):
        return "dark checkbox"

class LightFactory:
    def button(self):
        return "light button"

    def checkbox(self):
        return "light checkbox"

def build_ui(factory):
    return factory.button(), factory.checkbox()
```

**04. Builder** — assemble a complex object step by step so the same steps can yield different results.

```python
class Pizza:
    def __init__(self):
        self.parts = []

class PizzaBuilder:
    def __init__(self):
        self.pizza = Pizza()

    def add(self, part):
        self.pizza.parts.append(part)
        return self

    def build(self):
        return self.pizza

pizza = PizzaBuilder().add("cheese").add("basil").build()
```

**05. Prototype** — produce new objects by copying an existing one instead of constructing from scratch.

```python
import copy

class Node:
    def __init__(self, tags):
        self.tags = tags

    def clone(self):
        return copy.deepcopy(self)
```

**06. Object Pool** (not GoF) — reuse expensive instances from a pool instead of creating and destroying them.

```python
class Pool:
    def __init__(self, factory, size):
        self.free = [factory() for _ in range(size)]

    def acquire(self):
        return self.free.pop()

    def release(self, item):
        self.free.append(item)
```

### Structural

**07. Adapter** — wrap an incompatible interface so a client can use it unchanged.

```python
class LegacyPrinter:
    def print_text(self, s):
        return f"legacy:{s}"

class PrinterAdapter:
    def __init__(self, legacy):
        self.legacy = legacy

    def send(self, s):
        return self.legacy.print_text(s)
```

**08. Bridge** — split abstraction from implementation so the two hierarchies vary independently.

```python
class SvgRenderer:
    def draw(self, name):
        return f"<svg:{name}>"

class Shape:
    def __init__(self, renderer):
        self.renderer = renderer

class Circle(Shape):
    def render(self):
        return self.renderer.draw("circle")
```

**09. Composite** — treat a single object and a tree of objects through the same interface.

```python
class File:
    def __init__(self, size):
        self.size = size

    def total(self):
        return self.size

class Folder:
    def __init__(self, children):
        self.children = children

    def total(self):
        return sum(c.total() for c in self.children)
```

**10. Decorator** — add behaviour by wrapping an object that keeps the same interface.

```python
class Text:
    def render(self):
        return "hello"

class Bold:
    def __init__(self, inner):
        self.inner = inner

    def render(self):
        return f"<b>{self.inner.render()}</b>"
```

**11. Facade** — offer one simple entry point over a complicated set of subsystems.

```python
class Computer:
    def __init__(self, cpu, disk, ram):
        self.cpu, self.disk, self.ram = cpu, disk, ram

    def start(self):
        self.cpu.boot()
        self.ram.load(self.disk.read())
        return "running"
```

**12. Flyweight** — share immutable state between many objects to cut memory use.

```python
class Glyph:
    def __init__(self, char):
        self.char = char

class GlyphFactory:
    def __init__(self):
        self.cache = {}

    def get(self, char):
        if char not in self.cache:
            self.cache[char] = Glyph(char)
        return self.cache[char]
```

**13. Proxy** — stand in for another object to control access, defer cost or add caching.

```python
class Image:
    def __init__(self, path):
        self.path = path

    def show(self):
        return f"pixels:{self.path}"

class LazyImage:
    def __init__(self, path):
        self.path = path
        self.real = None

    def show(self):
        if self.real is None:
            self.real = Image(self.path)
        return self.real.show()
```

### Behavioural

**14. Chain of Responsibility** — pass a request along a chain until one handler deals with it.

```python
class Handler:
    def __init__(self, nxt=None):
        self.nxt = nxt

    def handle(self, req):
        return self.nxt.handle(req) if self.nxt else "ok"

class Auth(Handler):
    def handle(self, req):
        if not req.get("user"):
            return "401"
        return super().handle(req)
```

**15. Command** — turn a request into an object so it can be queued, logged or undone.

```python
class Light:
    def on(self):
        return "on"

class OnCommand:
    def __init__(self, light):
        self.light = light

    def execute(self):
        return self.light.on()

class Remote:
    def __init__(self):
        self.history = []

    def run(self, command):
        self.history.append(command)
        return command.execute()
```

**16. Interpreter** — represent a small language as a tree of nodes that evaluate themselves.

```python
class Num:
    def __init__(self, v):
        self.v = v

    def eval(self):
        return self.v

class Add:
    def __init__(self, left, right):
        self.left, self.right = left, right

    def eval(self):
        return self.left.eval() + self.right.eval()

Add(Num(2), Num(3)).eval()
```

**17. Iterator** — walk a collection element by element without exposing how it is stored.

```python
class Countdown:
    def __init__(self, n):
        self.n = n

    def __iter__(self):
        while self.n > 0:
            yield self.n
            self.n -= 1
```

**18. Mediator** — route communication through one hub so peers never reference each other.

```python
class ChatRoom:
    def __init__(self):
        self.users = []

    def join(self, user):
        user.room = self
        self.users.append(user)

    def send(self, sender, msg):
        return [u.receive(sender, msg)
                for u in self.users if u is not sender]

class User:
    def __init__(self, name):
        self.name = name

    def receive(self, sender, msg):
        return f"{self.name} got {msg} from {sender.name}"
```

**19. Memento** — capture and restore an object's state without exposing its internals.

```python
class Editor:
    def __init__(self):
        self.text = ""

    def save(self):
        return self.text

    def restore(self, snapshot):
        self.text = snapshot
```

**20. Observer** — notify any number of subscribers whenever the subject changes.

```python
class Subject:
    def __init__(self):
        self.observers = []

    def subscribe(self, fn):
        self.observers.append(fn)

    def emit(self, event):
        return [fn(event) for fn in self.observers]
```

**21. State** — let an object change its behaviour by swapping the state object it delegates to.

```python
class Published:
    def publish(self, doc):
        return "already published"

class Draft:
    def publish(self, doc):
        doc.state = Published()
        return "published"

class Document:
    def __init__(self):
        self.state = Draft()

    def publish(self):
        return self.state.publish(self)
```

**22. Strategy** — make interchangeable algorithms selectable at runtime behind one interface.

```python
def by_price(items):
    return sorted(items, key=lambda i: i["price"])

def by_name(items):
    return sorted(items, key=lambda i: i["name"])

class Catalog:
    def __init__(self, strategy):
        self.strategy = strategy

    def list(self, items):
        return self.strategy(items)
```

**23. Template Method** — fix the skeleton of an algorithm and let subclasses fill in the steps.

```python
class Report:
    def run(self):
        return self.render(self.fetch())

    def fetch(self):
        raise NotImplementedError

    def render(self, data):
        return ",".join(data)

class UsersReport(Report):
    def fetch(self):
        return ["ana", "bob"]
```

**24. Visitor** — add new operations to a stable object structure without editing its classes.

```python
class Circle:
    def accept(self, visitor):
        return visitor.circle(self)

class Square:
    def accept(self, visitor):
        return visitor.square(self)

class AreaVisitor:
    def circle(self, c):
        return "pi r squared"

    def square(self, s):
        return "side squared"
```

Python collapses several of these. Strategy, Command and Template Method are often a plain function or a default argument; Iterator is a generator; Decorator overlaps with the `@` syntax; Singleton is usually just a module. Reach for the class-based form only when the pattern needs state or several methods.

---

## Comparison

| Principle | Core idea | Smell it fights | Unit it applies to | Overdone it produces |
|---|---|---|---|---|
| KISS | Pick the plainest thing that works | Unjustified indirection | Any code | Naive code that ignores real constraints |
| DRY | One home per piece of knowledge | Copy-paste drift | Rules and decisions | Coupling of things that only looked alike |
| YAGNI | Build it when it is required | Speculative options and hooks | Features | Painful retrofits of the genuinely foreseeable |
| SoC | Split unrelated kinds of decisions | Rules tangled with I/O | Modules and layers | Layer sprawl and pass-through code |
| Law of Demeter | Ask a neighbour, do not reach through it | Long `a.b.c.d()` chains | Calls between objects | Delegation methods that only forward |
| SRP | One reason to change per class | God classes | Classes and modules | Anemic one-method classes everywhere |
| OCP | Extend without editing what works | Growing type switches | Extension points | Plugin machinery with one plugin |
| LSP | Subtypes must honour the contract | Overrides that break callers | Type hierarchies | Flat hierarchies with duplicated code |
| ISP | Depend only on what you call | Stubs that raise NotImplemented | Interfaces and protocols | A swarm of single-method interfaces |
| DIP | Policy owns the abstraction | Domain importing the driver | Dependencies between layers | Interfaces with exactly one implementation |

SRP, OCP, LSP, ISP and DIP are the five SOLID principles and pull in the same direction: keep a unit small, keep its promises, and let it depend on ideas rather than on details. KISS and YAGNI are the counterweight that stops the other eight from turning into architecture for its own sake.
