const fs = require('fs');
const path = require('path');

const categories = {
  "Dart Programming": [
    {
      q: "Which keyword is used in Dart to declare a variable whose type is inferred at compile time and cannot change?",
      options: ["var", "final", "const", "dynamic"],
      correct: 1,
      exp: "final variables can only be set once and their type is inferred or explicitly declared at compile time."
    },
    {
      q: "What is the return type of a function in Dart that does not return any value?",
      options: ["null", "nil", "void", "empty"],
      correct: 2,
      exp: "In Dart, 'void' represents the absence of a value returned by a function."
    },
    {
      q: "Which symbol is used for null-aware navigation in Dart?",
      options: ["?.", "??", "!", "?:"],
      correct: 0,
      exp: "The '?.' operator performs a property or method access only if the receiver is not null."
    },
    {
      q: "What does the '??' operator do in Dart?",
      options: ["Null assertion", "If-null fallback", "Logical OR", "Null-aware indexing"],
      correct: 1,
      exp: "The '??' operator returns the left-hand expression if not null, otherwise returns the right-hand operand."
    },
    {
      q: "Which collection in Dart contains unique, unordered elements?",
      options: ["List", "Map", "Set", "Queue"],
      correct: 2,
      exp: "A Set in Dart is an unordered collection of unique items."
    },
    {
      q: "How do you specify a private variable or method in Dart?",
      options: ["private keyword", "Prefix with underscore (_)", "# symbol", "protected keyword"],
      correct: 1,
      exp: "Dart does not have public/private keywords; library-level privacy is denoted by prefixing the identifier with an underscore (_)."
    },
    {
      q: "What keyword is used to handle asynchronous programming returning a single future value?",
      options: ["async/await", "yield", "sync*", "isolate"],
      correct: 0,
      exp: "async and await are used in Dart to write clean asynchronous code working with Future objects."
    },
    {
      q: "Which factory constructor keyword is used to implement a singleton or return a cached instance?",
      options: ["factory", "static", "const", "get"],
      correct: 0,
      exp: "The 'factory' keyword allows a constructor to return an existing cached instance or an instance of a subtype."
    },
    {
      q: "What is the base class for all objects in Dart except Null?",
      options: ["Class", "Object", "Dynamic", "Type"],
      correct: 1,
      exp: "Object is the root of the non-nullable Dart class hierarchy."
    },
    {
      q: "Which keyword allows a class to reuse code without using multi-inheritance?",
      options: ["implements", "extends", "with (mixins)", "abstract"],
      correct: 2,
      exp: "Mixins (using the 'with' keyword) allow sharing code across multiple class hierarchies without multiple inheritance."
    },
    {
      q: "What is the purpose of the 'late' keyword in Dart null safety?",
      options: [
        "Makes a variable asynchronous",
        "Declares a non-nullable variable initialized after declaration",
        "Delays garbage collection",
        "Marks a method as deprecated"
      ],
      correct: 1,
      exp: "The 'late' keyword indicates a non-nullable variable that will be initialized before it is read."
    },
    {
      q: "Which constructor syntax initializes fields before the constructor body runs?",
      options: ["Initializer list (:)", "Factory constructor", "Named constructor", "Redirecting constructor"],
      correct: 0,
      exp: "The initializer list (separated by a colon after constructor parameters) runs before the constructor body."
    },
    {
      q: "What stream generator keyword yields values sequentially in an asynchronous generator?",
      options: ["yield", "yield*", "return", "await for"],
      correct: 0,
      exp: "In an async* generator function, 'yield' delivers a value to the output Stream."
    },
    {
      q: "What is the difference between 'const' and 'final' in Dart?",
      options: [
        "const is compile-time constant; final is runtime constant",
        "final is compile-time constant; const is runtime",
        "There is no difference",
        "const is only for numbers"
      ],
      correct: 0,
      exp: "'const' values must be known at compile time, whereas 'final' variables are set once at runtime."
    },
    {
      q: "Which operator is used to cast an object to a specific type in Dart?",
      options: ["to", "as", "is", "cast"],
      correct: 1,
      exp: "The 'as' operator casts an expression to a specific type, throwing an exception if the cast is invalid."
    },
    {
      q: "What does the 'is!' operator check in Dart?",
      options: ["Negation of equality", "Object is NOT of a specified type", "Null check", "Bitwise NOT"],
      correct: 1,
      exp: "The 'is!' operator returns true if an object is not an instance of the specified type."
    },
    {
      q: "What is the extension method feature in Dart used for?",
      options: [
        "Inheriting from final classes",
        "Adding new functionality to existing libraries/classes without subclassing",
        "Extending memory limits",
        "Making classes public"
      ],
      correct: 1,
      exp: "Extension methods allow developers to add methods and getters to existing types without modifying the original source."
    },
    {
      q: "Which Dart type is used to represent an error or unexpected condition that should be caught?",
      options: ["Error", "Exception", "Fault", "Problem"],
      correct: 1,
      exp: "Exception is intended for conditions that a reasonable program might want to catch and handle."
    },
    {
      q: "What is the output of [1, 2, 3].fold(0, (prev, elem) => prev + elem)?",
      options: ["0", "5", "6", "Error"],
      correct: 2,
      exp: "The fold method accumulates elements starting from 0: 0 + 1 + 2 + 3 = 6."
    },
    {
      q: "Which package provides immutable collections and functional utilities for Dart?",
      options: ["collection", "dart:io", "dart:math", "dart:html"],
      correct: 0,
      exp: "package:collection provides advanced data structures, queue implementations, and collection equality utilities."
    },
    {
      q: "How does Dart execute asynchronous code concurrently without thread locks?",
      options: [
        "Event loop with single-threaded execution and microtask queue",
        "Preemptive multi-threading with mutexes",
        "Thread pools with shared memory",
        "Synchronous hardware interrupts"
      ],
      correct: 0,
      exp: "Dart runs in an isolate with an event loop processing the microtask queue and event queue sequentially."
    },
    {
      q: "What is an Isolate in Dart?",
      options: [
        "A private class",
        "An independent worker with its own memory heap and event loop",
        "A static singleton",
        "A widget lifecycle state"
      ],
      correct: 1,
      exp: "An isolate is an independent thread of execution with its own memory heap; isolates communicate via message passing."
    },
    {
      q: "Which Dart operator allows chaining method calls on the same object (cascade notation)?",
      options: ["..", "->", "::", ">>"],
      correct: 0,
      exp: "Cascade notation (..) allows performing a sequence of operations on members of the same object."
    },
    {
      q: "What keyword is used to prevent a class from being subclassed outside its library?",
      options: ["final class", "sealed class", "base class", "All of these (Dart 3 class modifiers)"],
      correct: 3,
      exp: "Dart 3 introduced class modifiers (final, sealed, base, interface) to control inheritance and implementation."
    },
    {
      q: "What is the return type of an async* generator function in Dart?",
      options: ["Future", "Stream", "Iterable", "List"],
      correct: 1,
      exp: "An async* function produces a Stream of values emitted over time using yield."
    }
  ],
  "Flutter Development": [
    {
      q: "Which widget is the root configuration widget for Material Design applications in Flutter?",
      options: ["Scaffold", "MaterialApp", "Container", "Theme"],
      correct: 1,
      exp: "MaterialApp wraps several widgets that are commonly required for Material Design applications."
    },
    {
      q: "What is the primary difference between a StatelessWidget and a StatefulWidget?",
      options: [
        "StatelessWidget cannot have children",
        "StatefulWidget maintains mutable state across rebuilds",
        "StatelessWidget cannot use themes",
        "StatefulWidget renders faster"
      ],
      correct: 1,
      exp: "A StatefulWidget creates a mutable State object that persists over the lifetime of the widget across multiple rebuilds."
    },
    {
      q: "Which method in a State object is called exactly once when the widget enters the tree?",
      options: ["build()", "initState()", "didUpdateWidget()", "dispose()"],
      correct: 1,
      exp: "initState() is invoked once when the State object is inserted into the element tree."
    },
    {
      q: "What is the purpose of the 'BuildContext' object passed to build methods?",
      options: [
        "Stores device battery level",
        "Represents the widget's location in the element tree",
        "Contains HTTP network interceptors",
        "Manages database transactions"
      ],
      correct: 1,
      exp: "BuildContext is a handle to the location of a widget in the widget and element trees."
    },
    {
      q: "Which widget provides the standard visual layout structure including AppBar, Drawer, and FloatingActionButton?",
      options: ["MaterialApp", "Scaffold", "SafeArea", "Stack"],
      correct: 1,
      exp: "Scaffold implements the basic Material Design visual layout structure."
    },
    {
      q: "How does Flutter achieve high rendering performance across Android and iOS?",
      options: [
        "Translates Dart to native OEM platform widgets",
        "Renders widgets directly to a canvas via its own graphics engine (Impeller/Skia)",
        "Runs inside a platform Webview",
        "Uses JavaScript bridge"
      ],
      correct: 1,
      exp: "Flutter uses its own rendering engine (Impeller/Skia) to paint pixels directly on the screen at 60/120fps."
    },
    {
      q: "Which widget is used to place child widgets on top of each other (overlapping)?",
      options: ["Row", "Column", "Stack", "Flex"],
      correct: 2,
      exp: "Stack places its children relative to the edges of its box, allowing overlapping layers."
    },
    {
      q: "Which widget must be used inside a Row or Column to make a child expand to fill available space?",
      options: ["Expanded", "Padding", "Align", "FittedBox"],
      correct: 0,
      exp: "Expanded forces a child of a Row, Column, or Flex to expand to fill the available space along the main axis."
    },
    {
      q: "What widget builder is recommended for displaying large or infinite scrollable lists efficiently?",
      options: ["ListView()", "ListView.builder()", "SingleChildScrollView", "Column()"],
      correct: 1,
      exp: "ListView.builder creates items on demand only as they scroll into view, conserving memory."
    },
    {
      q: "Which Flutter method causes a StatefulWidget to schedule a rebuild of its interface?",
      options: ["rebuild()", "setState()", "refresh()", "update()"],
      correct: 1,
      exp: "setState() notifies the framework that the internal state of the object has changed, triggering a rebuild."
    },
    {
      q: "What does the 'SafeArea' widget do?",
      options: [
        "Encrypts input data",
        "Insets child with padding to avoid notches, status bars, and navigation bars",
        "Restricts user permissions",
        "Prevents app crashes"
      ],
      correct: 1,
      exp: "SafeArea insets its child by sufficient padding to avoid intrusions by the operating system (notches, status bar)."
    },
    {
      q: "Which Flutter package is a modern, reactive, compile-time safe state management library?",
      options: ["Riverpod", "Shared Preferences", "Path Provider", "Sqflite"],
      correct: 0,
      exp: "Riverpod is a complete rewrite of Provider that offers compile-time safety and independence from the widget tree."
    },
    {
      q: "What is the key difference between 'Hot Reload' and 'Hot Restart' in Flutter?",
      options: [
        "Hot Reload preserves state; Hot Restart destroys and resets app state",
        "Hot Restart preserves state; Hot Reload resets state",
        "Hot Reload compiles native code; Hot Restart runs in browser",
        "There is no difference"
      ],
      correct: 0,
      exp: "Hot Reload injects updated source code files into the running Dart VM while preserving application state; Hot Restart completely resets state."
    },
    {
      q: "Which method in a State object should be used to cancel streams, timers, and text controllers?",
      options: ["deactivate()", "dispose()", "clean()", "stop()"],
      correct: 1,
      exp: "dispose() is called when the State object is permanently removed from the tree, and is where resources must be released."
    },
    {
      q: "What does keys (like ValueKey, GlobalKey) do in Flutter widgets?",
      options: [
        "Encrypt widget data",
        "Preserve state when widgets move in the widget tree or identify elements uniquely",
        "Control keyboard input",
        "Set database primary keys"
      ],
      correct: 1,
      exp: "Keys preserve state when widgets move around the widget tree and allow unique element identification."
    },
    {
      q: "Which widget is best suited to detect taps, double-taps, drags, and scaling gestures?",
      options: ["GestureDetector", "InkWell", "TapListener", "MouseRegion"],
      correct: 0,
      exp: "GestureDetector recognizes a wide variety of touch and pointer gestures."
    },
    {
      q: "What visual effect does 'InkWell' provide that 'GestureDetector' does not by default?",
      options: ["Haptic feedback", "Material ink splash / ripple reaction", "Shadow animation", "Blur effect"],
      correct: 1,
      exp: "InkWell responds to touches by showing a Material splash ripple effect on the surface."
    },
    {
      q: "Which widget allows animations with explicit control using an AnimationController?",
      options: ["AnimatedContainer", "AnimatedBuilder", "Hero", "FadeInImage"],
      correct: 1,
      exp: "AnimatedBuilder is useful for complex animations that need explicit controller listeners and custom transitions."
    },
    {
      q: "What widget creates a shared transition animation between two screens across routes?",
      options: ["SharedAxis", "Hero", "SlideTransition", "PageRoute"],
      correct: 1,
      exp: "The Hero widget animates a child from one screen to another during route navigation."
    },
    {
      q: "What is the role of the 'Material3' flag in ThemeData?",
      options: [
        "Requires 3D graphics hardware",
        "Enables Google Material Design 3 tokens, colors, elevation, and component styles",
        "Enables 3 columns on tablet screens",
        "Limits supported Android versions to Android 13"
      ],
      correct: 1,
      exp: "useMaterial3: true configures the theme to follow Google's Material 3 design system specifications."
    },
    {
      q: "Which widget allows creating custom paint graphics by implementing a CustomPainter?",
      options: ["CustomPaint", "CanvasWidget", "DrawBox", "GraphicView"],
      correct: 0,
      exp: "CustomPaint provides a canvas on which custom shapes and graphics can be drawn."
    },
    {
      q: "How does the 'FutureBuilder' widget handle asynchronous operations?",
      options: [
        "Blocks the UI thread until the future finishes",
        "Rebuilds itself based on the latest snapshot of interaction with a Future",
        "Runs the future in an isolated background process",
        "Cancels the future if user scrolls"
      ],
      correct: 1,
      exp: "FutureBuilder listens to a Future and builds its widget tree depending on ConnectionState (waiting, done, error)."
    },
    {
      q: "Which widget in Flutter is used to restrict a child to a specific aspect ratio?",
      options: ["AspectRatio", "FractionallySizedBox", "SizedBox", "FittedBox"],
      correct: 0,
      exp: "The AspectRatio widget attempts to size the child to a specific aspect ratio (width / height)."
    },
    {
      q: "What is the recommended declarative routing package officially maintained by Flutter team?",
      options: ["go_router", "auto_route", "fluro", "get"],
      correct: 0,
      exp: "go_router is the declarative routing package supported by the Flutter team with URL path parsing and deep linking."
    },
    {
      q: "What tool does Flutter provide to analyze app rendering performance, frame rendering times, and memory leaks?",
      options: ["Flutter DevTools", "Android Studio Profiler only", "Chrome Console", "Xcode Instruments only"],
      correct: 0,
      exp: "Flutter DevTools is a suite of performance and debugging tools for Dart and Flutter apps."
    }
  ],
  "Data Structures & Algorithms": [
    {
      q: "What is the time complexity of accessing an element in an array by its index?",
      options: ["O(1)", "O(log n)", "O(n)", "O(n log n)"],
      correct: 0,
      exp: "Direct array access via memory offset calculation (base_address + index * size) runs in O(1) constant time."
    },
    {
      q: "In a singly linked list, what is the time complexity to insert a node at the head?",
      options: ["O(1)", "O(n)", "O(log n)", "O(n^2)"],
      correct: 0,
      exp: "Inserting at the head simply requires updating the new node's next pointer and head reference, taking O(1) time."
    },
    {
      q: "Which data structure is primarily used to implement Depth First Search (DFS) on a graph?",
      options: ["Queue", "Stack (or recursion)", "Min-Heap", "Hash Table"],
      correct: 1,
      exp: "DFS traverses deep into tree/graph branches using a Stack or the system call stack via recursion."
    },
    {
      q: "Which data structure is primarily used to implement Breadth First Search (BFS)?",
      options: ["Queue", "Stack", "Binary Search Tree", "Disjoint Set"],
      correct: 0,
      exp: "BFS explores vertices level by level, requiring a FIFO Queue to track visited frontier nodes."
    },
    {
      q: "What is the average and worst-case time complexity of Quick Sort?",
      options: ["Average O(n log n), Worst O(n^2)", "Average O(n), Worst O(n log n)", "Average O(n log n), Worst O(n log n)", "Average O(n^2), Worst O(n^2)"],
      correct: 0,
      exp: "Quick Sort averages O(n log n) with balanced partitions, but degrades to O(n^2) if partitions are severely unbalanced."
    },
    {
      q: "What is the maximum number of children a node can have in a Binary Tree?",
      options: ["1", "2", "3", "Unlimited"],
      correct: 1,
      exp: "By definition, each node in a binary tree has at most two children (left and right)."
    },
    {
      q: "Which property distinguishes a Min-Heap from a general Binary Tree?",
      options: [
        "Every node's value is less than or equal to its children's values",
        "Left child is always less than right child",
        "It is always a binary search tree",
        "It has no leaf nodes"
      ],
      correct: 0,
      exp: "In a Min-Heap, the key at the root must be minimum among all keys, and this property holds recursively for all subtrees."
    },
    {
      q: "What is the time complexity of searching in a balanced Binary Search Tree (AVL or Red-Black Tree)?",
      options: ["O(1)", "O(log n)", "O(n)", "O(n log n)"],
      correct: 1,
      exp: "Because height is kept proportional to log n in balanced trees, search, insert, and delete take O(log n) time."
    },
    {
      q: "What is the worst-case time complexity of looking up a key in a Hash Table with collision chaining?",
      options: ["O(1)", "O(log n)", "O(n)", "O(n!)"],
      correct: 2,
      exp: "If all n keys hash to the same bucket in worst-case collision, lookup degrades to O(n) linear search."
    },
    {
      q: "Which algorithm finds the Minimum Spanning Tree of a connected undirected graph using greedy edge selection?",
      options: ["Kruskal's algorithm", "Dijkstra's algorithm", "Bellman-Ford algorithm", "Floyd-Warshall algorithm"],
      correct: 0,
      exp: "Kruskal's algorithm sorts all edges by weight and adds edges greedily without forming cycles to construct an MST."
    },
    {
      q: "Which technique is used to solve the 0/1 Knapsack problem efficiently?",
      options: ["Greedy method", "Dynamic Programming", "Divide and Conquer", "Backtracking only"],
      correct: 1,
      exp: "Dynamic programming solves the 0/1 Knapsack problem in O(n*W) pseudo-polynomial time by caching subproblem solutions."
    },
    {
      q: "What is the space complexity of an in-place sorting algorithm like Heap Sort?",
      options: ["O(1) auxiliary space", "O(log n)", "O(n)", "O(n log n)"],
      correct: 0,
      exp: "In-place algorithms modify the input array directly with only O(1) extra auxiliary memory."
    },
    {
      q: "What does topological sort produce for a Directed Acyclic Graph (DAG)?",
      options: [
        "A linear ordering of vertices such that for every directed edge u->v, u comes before v",
        "A minimum spanning tree",
        "The shortest distance between all pairs",
        "A cycle count"
      ],
      correct: 0,
      exp: "Topological sorting produces a linear ordering where dependencies (edges) always point forward."
    },
    {
      q: "What is the time complexity of the Binary Search algorithm on a sorted array of size n?",
      options: ["O(1)", "O(log n)", "O(n)", "O(n log n)"],
      correct: 1,
      exp: "Binary search cuts the search space in half at each comparison, yielding O(log n) time complexity."
    },
    {
      q: "Which data structure is optimal for implementing an LRU (Least Recently Used) Cache?",
      options: ["HashMap + Doubly Linked List", "Binary Search Tree", "Array + Stack", "Queue only"],
      correct: 0,
      exp: "A HashMap combined with a Doubly Linked List enables O(1) lookups and O(1) element repositioning/eviction."
    },
    {
      q: "What is a circular queue primarily used to prevent?",
      options: [
        "Memory wastage in fixed-size linear queues where space before front cannot be reused",
        "Data corruption",
        "Hash collisions",
        "Infinite loops"
      ],
      correct: 0,
      exp: "Circular queues wrap rear pointers back to index 0 using modulo arithmetic to reuse dequeued space."
    },
    {
      q: "Which algorithm is used to detect a cycle in a linked list in O(n) time and O(1) memory?",
      options: ["Floyd's Tortoise and Hare algorithm", "Tarjan's algorithm", "Kadane's algorithm", "KMP algorithm"],
      correct: 0,
      exp: "Floyd's cycle detection uses two pointers moving at different speeds (1 step and 2 steps) to detect cycles."
    },
    {
      q: "What is Kadane's algorithm used for?",
      options: [
        "Finding the maximum subarray sum in a 1D array in O(n) time",
        "Sorting strings lexicographically",
        "String pattern matching",
        "Shortest path in graphs"
      ],
      correct: 0,
      exp: "Kadane's algorithm computes the maximum contiguous subarray sum in a single linear O(n) pass."
    },
    {
      q: "In Big-O notation, what is the order of growth from slowest to fastest growing?",
      options: [
        "O(1) < O(log n) < O(n) < O(n log n) < O(n^2) < O(2^n)",
        "O(n) < O(1) < O(log n) < O(n^2)",
        "O(log n) < O(1) < O(n log n) < O(n)",
        "O(1) < O(n) < O(log n) < O(2^n)"
      ],
      correct: 0,
      exp: "Constant O(1) is fastest, followed by logarithmic, linear, linearithmic, quadratic, and exponential growth."
    },
    {
      q: "Which tree traversal visits nodes in the order: Left, Root, Right?",
      options: ["Pre-order", "In-order", "Post-order", "Level-order"],
      correct: 1,
      exp: "In-order traversal visits Left subtree, then current Root node, then Right subtree (yielding sorted order in BSTs)."
    },
    {
      q: "What is a Trie data structure primarily used for?",
      options: [
        "Prefix-based string search and dictionary auto-completion",
        "Numerical matrix multiplication",
        "Graph coloring",
        "Image compression"
      ],
      correct: 0,
      exp: "A Trie (prefix tree) stores strings where nodes represent characters, enabling fast O(length) prefix lookups."
    },
    {
      q: "What is the time complexity of building a heap from an unordered array of n elements?",
      options: ["O(n)", "O(n log n)", "O(n^2)", "O(log n)"],
      correct: 0,
      exp: "Using bottom-up heapify (Build-Heap), an unordered array can be turned into a valid heap in linear O(n) time."
    },
    {
      q: "Which string matching algorithm preprocesses the pattern to avoid backtracking in the text?",
      options: ["Knuth-Morris-Pratt (KMP) algorithm", "Bubble Sort", "Dijkstra's algorithm", "Prim's algorithm"],
      correct: 0,
      exp: "KMP uses a Longest Proper Prefix which is also Suffix (LPS) array to skip redundant comparisons in O(n + m) time."
    },
    {
      q: "What is the amortized time complexity of inserting an element into a dynamic array (like std::vector or Dart List)?",
      options: ["O(1)", "O(n)", "O(log n)", "O(n^2)"],
      correct: 0,
      exp: "While resizing takes O(n), it happens infrequently enough that the amortized cost per append is O(1)."
    },
    {
      q: "Which problem can be solved in O(V + E) time using Kahn's algorithm or DFS?",
      options: [
        "Topological sorting of a directed graph",
        "Traveling Salesperson Problem",
        "Graph 3-coloring",
        "Hamiltonian path"
      ],
      correct: 0,
      exp: "Kahn's algorithm uses in-degree tracking to produce a topological sort in linear O(V + E) time."
    }
  ],
  "Database & SQL (DBMS)": [
    {
      q: "Which SQL command is used to retrieve data from a database table?",
      options: ["SELECT", "GET", "FETCH", "EXTRACT"],
      correct: 0,
      exp: "The SELECT statement in SQL is used to query and retrieve data records from one or more tables."
    },
    {
      q: "What does ACID stand for in the context of relational database transactions?",
      options: [
        "Atomicity, Consistency, Isolation, Durability",
        "Accuracy, Control, Integrity, Data",
        "Action, Connection, Index, Directory",
        "Access, Concurrency, Isolation, Deletion"
      ],
      correct: 0,
      exp: "ACID properties ensure that database transactions are processed reliably."
    },
    {
      q: "Which normal form requires removing transitive functional dependencies?",
      options: ["1NF", "2NF", "3NF", "BCNF"],
      correct: 2,
      exp: "Third Normal Form (3NF) requires 2NF and that no non-prime attribute is transitively dependent on the primary key."
    },
    {
      q: "Which SQL clause is used to filter records resulting from a GROUP BY aggregate function?",
      options: ["WHERE", "HAVING", "ORDER BY", "FILTER"],
      correct: 1,
      exp: "HAVING filters groups created by GROUP BY; WHERE filters individual rows before aggregation."
    },
    {
      q: "What type of JOIN returns all records when there is a match in either left or right table?",
      options: ["INNER JOIN", "FULL OUTER JOIN", "LEFT JOIN", "CROSS JOIN"],
      correct: 1,
      exp: "FULL OUTER JOIN returns all rows from both tables, filling with NULL where matches do not exist."
    },
    {
      q: "What is a Foreign Key in a relational database?",
      options: [
        "A field in one table that uniquely identifies a row in another table",
        "A key encrypted by a foreign algorithm",
        "A key that can only store strings",
        "A backup copy of the primary key"
      ],
      correct: 0,
      exp: "A Foreign Key establishes a relational link between columns in two tables, enforcing referential integrity."
    },
    {
      q: "Which database index structure is most widely used in relational engines for fast range queries and equality lookups?",
      options: ["B+ Tree", "Binary Search Tree", "Linked List", "Radix Tree"],
      correct: 0,
      exp: "B+ Trees maintain balanced depth and store all records in leaf nodes linked sequentially, making range queries O(log n)."
    },
    {
      q: "Which SQL constraint ensures that all values in a column are distinct?",
      options: ["UNIQUE", "NOT NULL", "CHECK", "DEFAULT"],
      correct: 0,
      exp: "The UNIQUE constraint prevents duplicate entries across all rows in a specified column."
    },
    {
      q: "Which command permanently saves all changes made during the current database transaction?",
      options: ["COMMIT", "ROLLBACK", "SAVEPOINT", "CHECKPOINT"],
      correct: 0,
      exp: "COMMIT makes all changes made in the transaction permanent in database storage."
    },
    {
      q: "What does the ROLLBACK command do?",
      options: [
        "Reverts changes made by the transaction since the last commit or savepoint",
        "Deletes the entire table structure",
        "Restores a database from backup tape",
        "Re-runs the query"
      ],
      correct: 0,
      exp: "ROLLBACK undoes uncommitted modifications to maintain database consistency."
    },
    {
      q: "What is the difference between DELETE and TRUNCATE in SQL?",
      options: [
        "DELETE is DML (row by row, can be rolled back); TRUNCATE is DDL (deallocates pages, faster)",
        "TRUNCATE can have a WHERE clause; DELETE cannot",
        "DELETE removes the table schema; TRUNCATE does not",
        "They are identical commands"
      ],
      correct: 0,
      exp: "TRUNCATE is a DDL operation that drops and recreates table pages without firing row-level triggers, making it much faster than DELETE."
    },
    {
      q: "Which NoSQL database category does MongoDB belong to?",
      options: ["Document-oriented store", "Graph database", "Columnar store", "Key-value store"],
      correct: 0,
      exp: "MongoDB stores JSON-like BSON documents in collections, making it a document-oriented database."
    },
    {
      q: "What is a database transaction deadlock?",
      options: [
        "A situation where two or more transactions are waiting indefinitely for locks held by each other",
        "A table with no primary key",
        "A corrupt index file",
        "A query running out of memory"
      ],
      correct: 0,
      exp: "A deadlock occurs when concurrent transactions hold locks that each other requires to proceed."
    },
    {
      q: "Which concurrency control anomaly occurs when a transaction reads uncommitted changes from another transaction?",
      options: ["Dirty Read", "Non-repeatable Read", "Phantom Read", "Lost Update"],
      correct: 0,
      exp: "A Dirty Read happens when Transaction A reads data modified by Transaction B that has not yet been committed."
    },
    {
      q: "Which transaction isolation level offers the highest level of consistency by preventing all concurrency anomalies?",
      options: ["Serializable", "Repeatable Read", "Read Committed", "Read Uncommitted"],
      correct: 0,
      exp: "Serializable ensures transactions execute as if run serially one after another, eliminating all anomalies."
    },
    {
      q: "Which SQL operator is used to search for a specified pattern in a column using wildcards (% and _)?",
      options: ["LIKE", "MATCH", "CONTAINS", "IN"],
      correct: 0,
      exp: "The LIKE operator searches for patterns where '%' matches zero or more characters and '_' matches one character."
    },
    {
      q: "What is the purpose of a Database View?",
      options: [
        "A virtual table based on the result-set of an SQL query",
        "A physical backup copy of table records",
        "A graphical dashboard plugin",
        "A hardware display setting"
      ],
      correct: 0,
      exp: "A View is a stored virtual query that can be queried like a table without duplicating raw storage."
    },
    {
      q: "Which SQL aggregate function returns the total number of non-null rows in a column?",
      options: ["COUNT()", "SUM()", "TOTAL()", "AVG()"],
      correct: 0,
      exp: "COUNT(column_name) returns the count of non-null rows matching the criteria."
    },
    {
      q: "What does the CAP theorem state for distributed data stores?",
      options: [
        "A distributed system can guarantee at most two out of: Consistency, Availability, and Partition Tolerance",
        "Computers Always Progress",
        "Clusters are Always Protected",
        "Cache And Persistence are mutually exclusive"
      ],
      correct: 0,
      exp: "The CAP theorem states that when network partitions (P) occur, a distributed system must choose between Consistency (C) and Availability (A)."
    },
    {
      q: "Which SQL keyword is used to eliminate duplicate rows from a query result?",
      options: ["DISTINCT", "UNIQUE", "DIFFERENT", "FILTER"],
      correct: 0,
      exp: "SELECT DISTINCT returns only unique tuples from the result set."
    },
    {
      q: "What is a Stored Procedure in SQL?",
      options: [
        "A prepared SQL code block saved in the database that can be reused and executed repeatedly",
        "A disk defragmentation script",
        "A database user account",
        "An automated cloud backup"
      ],
      correct: 0,
      exp: "A Stored Procedure contains pre-compiled SQL statements stored directly in the database engine."
    },
    {
      q: "What is the primary objective of Database Normalization?",
      options: [
        "Reduce data redundancy and eliminate undesirable insertion, update, and deletion anomalies",
        "Increase table size for faster queries",
        "Encrypt passwords",
        "Convert SQL into NoSQL"
      ],
      correct: 0,
      exp: "Normalization organizes tables and attributes to minimize duplicate data and prevent logical inconsistencies."
    },
    {
      q: "Which clause in SQL restricts the number of returned rows (supported in SQLite, PostgreSQL, MySQL)?",
      options: ["LIMIT", "TOP", "MAXROWS", "STOP"],
      correct: 0,
      exp: "LIMIT specifies the maximum number of rows to return in the query result."
    },
    {
      q: "In an Entity-Relationship (ER) diagram, what does a diamond shape represent?",
      options: ["Relationship", "Entity", "Attribute", "Primary Key"],
      correct: 0,
      exp: "In standard ER diagrams, rectangles represent entities, ellipses represent attributes, and diamonds represent relationships."
    },
    {
      q: "What is the local embedded SQL database engine utilized by default in Flutter mobile apps?",
      options: ["SQLite (via sqflite)", "Oracle DB", "Microsoft Access", "Cassandra"],
      correct: 0,
      exp: "SQLite is a self-contained, serverless zero-configuration SQL database engine widely used on Android and iOS."
    }
  ],
  "Aptitude & Technical Reasoning": [
    {
      q: "If a train traveling at 72 km/h crosses a 180-meter platform in 18 seconds, what is the length of the train?",
      options: ["180 meters", "200 meters", "160 meters", "220 meters"],
      correct: 0,
      exp: "Speed = 72 * (5/18) = 20 m/s. Total distance in 18s = 20 * 18 = 360m. Length of train = 360 - 180 = 180 meters."
    },
    {
      q: "A can complete a project in 12 days and B can complete it in 24 days. How many days will they take working together?",
      options: ["8 days", "6 days", "10 days", "9 days"],
      correct: 0,
      exp: "Combined rate = 1/12 + 1/24 = 3/24 = 1/8. Working together they take 8 days."
    },
    {
      q: "A sum of money doubles itself in 5 years at simple interest. What is the annual rate of interest?",
      options: ["20%", "15%", "25%", "10%"],
      correct: 0,
      exp: "Interest = Principal (P). Formula: P = (P * R * 5) / 100 => R = 100 / 5 = 20% per annum."
    },
    {
      q: "What is the next number in the series: 3, 8, 18, 38, 78, ...?",
      options: ["158", "156", "148", "162"],
      correct: 0,
      exp: "Each number is multiplied by 2 and added with 2: 3*2+2=8, 8*2+2=18, 18*2+2=38, 38*2+2=78, 78*2+2=158."
    },
    {
      q: "Find the odd one out: 64, 125, 216, 343, 512, 729, 1000",
      options: ["343", "64", "125", "None (all are perfect cubes)"],
      correct: 3,
      exp: "64=4^3, 125=5^3, 216=6^3, 343=7^3, 512=8^3, 729=9^3, 1000=10^3. All numbers in the sequence are cubes of integers."
    },
    {
      q: "In a certain code language, 'LEARN' is coded as 'OHDUQ'. How will 'STUDY' be coded?",
      options: ["VWXGB", "VWXGZ", "VWHGB", "UWXGB"],
      correct: 0,
      exp: "Each letter is shifted forward by 3 places: S->V, T->W, U->X, D->G, Y->B."
    },
    {
      q: "Pointing to a photograph, a woman says: 'He is the son of the only daughter of my father'. How is the man in the photo related to the woman?",
      options: ["Her son", "Her brother", "Her nephew", "Her father"],
      correct: 0,
      exp: "'The only daughter of my father' is the woman herself. The son of that daughter is her own son."
    },
    {
      q: "A shopkeeper marks an article 40% above the cost price and gives a discount of 25%. What is his profit percentage?",
      options: ["5%", "10%", "15%", "12%"],
      correct: 0,
      exp: "Let CP = 100. Marked Price = 140. Selling Price = 140 * 0.75 = 105. Profit = 105 - 100 = 5%."
    },
    {
      q: "Two dice are rolled simultaneously. What is the probability of getting a sum of 7?",
      options: ["1/6", "1/12", "5/36", "7/36"],
      correct: 0,
      exp: "Favorable outcomes: (1,6), (2,5), (3,4), (4,3), (5,2), (6,1) = 6 pairs. Total outcomes = 36. Probability = 6/36 = 1/6."
    },
    {
      q: "A person travels 10 km North, turns right and travels 10 km, then turns right and travels 10 km. Where is he now relative to his starting point?",
      options: ["10 km East", "10 km West", "At starting point", "10 km North"],
      correct: 0,
      exp: "North 10km, East 10km, South 10km forms three sides of a square. The final position is 10 km directly East of the start."
    },
    {
      q: "What is the angle between the hour hand and minute hand of a clock at 3:30?",
      options: ["75 degrees", "80 degrees", "90 degrees", "70 degrees"],
      correct: 0,
      exp: "Angle = |30*H - (11/2)*M| = |30*3 - (11/2)*30| = |90 - 165| = 75 degrees."
    },
    {
      q: "If 5 workers can build a wall in 12 days, how many workers are needed to build the same wall in 4 days?",
      options: ["15 workers", "12 workers", "20 workers", "10 workers"],
      correct: 0,
      exp: "Total man-days required = 5 * 12 = 60. Workers required for 4 days = 60 / 4 = 15 workers."
    },
    {
      q: "The average age of 24 students and their teacher is 15 years. If the teacher's age is excluded, the average decreases by 1 year. What is the teacher's age?",
      options: ["39 years", "40 years", "35 years", "42 years"],
      correct: 0,
      exp: "Total age (25 people) = 25 * 15 = 375. Total age of 24 students = 24 * 14 = 336. Teacher's age = 375 - 336 = 39 years."
    },
    {
      q: "What is the remainder when 7^84 is divided by 342?",
      options: ["1", "7", "341", "49"],
      correct: 0,
      exp: "7^3 = 343 = 342 + 1. So 7^84 = (7^3)^28 = (342 + 1)^28 = 342k + 1. Remainder is 1."
    },
    {
      q: "In an exam, a student scores 4 marks for every correct answer and loses 1 mark for every wrong answer. If he attempts 60 questions and scores 140 marks, how many questions were correct?",
      options: ["40", "45", "35", "50"],
      correct: 0,
      exp: "Let correct = C, wrong = 60 - C. 4C - 1*(60 - C) = 140 => 5C - 60 = 140 => 5C = 200 => C = 40."
    },
    {
      q: "A bag contains 5 red, 4 green, and 3 blue balls. If two balls are drawn at random without replacement, what is the probability that both are red?",
      options: ["5/33", "5/36", "1/6", "10/33"],
      correct: 0,
      exp: "Total balls = 12. P(First red) = 5/12. P(Second red) = 4/11. Combined P = (5/12) * (4/11) = 20/132 = 5/33."
    },
    {
      q: "Which word does NOT belong with the others: Byte, Bit, Megabyte, Kilogram, Terabyte?",
      options: ["Kilogram", "Byte", "Bit", "Terabyte"],
      correct: 0,
      exp: "Kilogram is a unit of mass/weight, while all other words are units of digital computer storage."
    },
    {
      q: "If 1st January 2024 was a Monday, what day of the week was 1st January 2025? (Note: 2024 is a leap year)",
      options: ["Wednesday", "Tuesday", "Thursday", "Monday"],
      correct: 0,
      exp: "A leap year has 366 days = 52 weeks + 2 odd days. Monday + 2 days = Wednesday."
    },
    {
      q: "A car covers a distance of 300 km at 60 km/h and returns at 40 km/h. What is the average speed for the whole round trip?",
      options: ["48 km/h", "50 km/h", "45 km/h", "52 km/h"],
      correct: 0,
      exp: "Average speed for equal distances = 2xy / (x + y) = 2 * 60 * 40 / (60 + 40) = 4800 / 100 = 48 km/h."
    },
    {
      q: "Statements: All laptops are electronic. All electronic devices require power. Conclusion: All laptops require power.",
      options: ["Conclusion is definitely True", "Conclusion is False", "Data is insufficient", "Partially True"],
      correct: 0,
      exp: "By standard categorical syllogism: Laptops subset of Electronic, Electronic subset of Require Power => Laptops subset of Require Power."
    },
    {
      q: "What is the HCF (Highest Common Factor) of 72, 108, and 180?",
      options: ["36", "18", "24", "12"],
      correct: 0,
      exp: "72 = 36*2, 108 = 36*3, 180 = 36*5. The highest common divisor among them is 36."
    },
    {
      q: "A pipe can fill a cistern in 6 hours and another pipe can empty it in 8 hours. If both are opened together, how long will it take to fill the cistern?",
      options: ["24 hours", "12 hours", "14 hours", "18 hours"],
      correct: 0,
      exp: "Net filling rate per hour = 1/6 - 1/8 = (4 - 3)/24 = 1/24. Time to fill = 24 hours."
    },
    {
      q: "Find the value of x: 2^(x+3) = 128.",
      options: ["4", "5", "3", "7"],
      correct: 0,
      exp: "128 = 2^7. Therefore x + 3 = 7 => x = 4."
    },
    {
      q: "How many squares are there on a standard 8x8 chessboard?",
      options: ["204", "64", "128", "256"],
      correct: 0,
      exp: "Total squares = 1^2 + 2^2 + 3^2 + ... + 8^2 = (8 * 9 * 17) / 6 = 204."
    },
    {
      q: "A father is 30 years older than his son. In 5 years, he will be three times as old as his son. What is the son's present age?",
      options: ["10 years", "12 years", "8 years", "15 years"],
      correct: 0,
      exp: "Let son's age = S. Father's age = S + 30. In 5 years: (S + 35) = 3*(S + 5) => S + 35 = 3S + 15 => 2S = 20 => S = 10 years."
    }
  ]
};

const output = [];
let idCounter = 1;
const counts = {};

for (const [catName, qList] of Object.entries(categories)) {
  counts[catName] = qList.length;
  for (const item of qList) {
    // Validation checks
    if (!item.options || item.options.length !== 4) {
      throw new Error(`Question must have 4 options: ${item.q}`);
    }
    if (item.correct < 0 || item.correct > 3) {
      throw new Error(`Invalid correct index in: ${item.q}`);
    }
    if (!item.exp || item.exp.length < 5) {
      throw new Error(`Missing explanation in: ${item.q}`);
    }

    output.push({
      id: `q_${idCounter++}`,
      category: catName,
      question: item.q,
      options: item.options,
      correctIndex: item.correct,
      explanation: item.exp
    });
  }
}

const targetPath = path.join(__dirname, '..', 'assets', 'data', 'quiz_questions.json');
fs.writeFileSync(targetPath, JSON.stringify(output, null, 2), 'utf-8');

console.log('=== QUESTION BANK AUDIT REPORT ===');
console.log(`Total questions generated: ${output.length}`);
for (const [cat, cnt] of Object.entries(counts)) {
  console.log(`- ${cat}: ${cnt} validated questions (Minimum 25 satisfied: ${cnt >= 25 ? 'YES' : 'NO'})`);
}
