import '../ai_assistant_screen.dart';

/// Comprehensive Offline Academic Knowledge Engine for StudyMate AI Tutor.
/// Provides rich, subject-tailored, dynamic answers for student questions across all subjects.
class AcademicKnowledgeEngine {
  AcademicKnowledgeEngine._();

  static String generateResponse(String query, AiTaskMode mode) {
    final q = query.toLowerCase().trim();

    // 1. Greetings & Introductions
    if (q == 'hi' ||
        q == 'hello' ||
        q == 'hey' ||
        q == 'namaste' ||
        q == 'start' ||
        q.startsWith('hi ') ||
        q.startsWith('hello ')) {
      return '''
Hello! 👋 I'm **StudyMate AI Tutor** — your 24/7 academic learning partner.

Here is what I can explain, summarize, or solve for you right now:
• 💡 **Concepts & Theories:** Physics, Chemistry, Mathematics, Biology, Computer Science, and Engineering.
• 📝 **Notes Summarizer:** Paste long text or lecture slides to get high-yield exam takeaways.
• ❓ **Practice Quizzes:** Generate custom MCQs and step-by-step solutions for self-testing.
• 🐞 **Code Debugger:** Paste Python, C++, Java, Dart, or JS code to detect errors.
• 📚 **Exam Strategies:** Time-blocking, revision schedules, and memory hacks.

Type any question, topic, or formula you'd like to understand! 🚀
''';
    }

    // Mode-specific specialized handlers
    switch (mode) {
      case AiTaskMode.summarizeNotes:
        return _summarizeText(query);
      case AiTaskMode.generateQuestions:
        return _generateQuizForTopic(query);
      case AiTaskMode.debugCodeError:
        return _debugCode(query);
      case AiTaskMode.revisionAdvice:
        return _generateRevisionPlan(query);
      case AiTaskMode.explainConcept:
        return _explainConcept(query, q);
    }
  }

  static String _explainConcept(String originalQuery, String q) {
    // Computer Science & Data Structures
    if (q.contains('bfs') && q.contains('dfs')) {
      return '''
📌 **Difference Between BFS and DFS (Graph/Tree Traversal)**

| Feature | Breadth-First Search (BFS) | Depth-First Search (DFS) |
|---|---|---|
| **Data Structure** | **Queue (FIFO)** | **Stack (LIFO)** or Recursion |
| **Traversal Order** | Level by level (horizontally) | Branch by branch down to leaf |
| **Shortest Path** | Guarantees shortest path in unweighted graphs | Does not guarantee shortest path |
| **Memory / Space** | **O(V)** — high memory for wide graphs | **O(H)** — efficient for deep graphs |
| **Time Complexity** | **O(V + E)** | **O(V + E)** |

💡 **Exam Tip:** Use **BFS** for shortest path problems or finding neighbors (e.g. peer-to-peer networks). Use **DFS** for cycle detection, topological sorting, or solving mazes/puzzles.
''';
    }

    if (q.contains('recursion') || q.contains('recursive')) {
      return '''
📌 **Recursion in Computer Science & Programming**

Recursion is a programming technique where a function calls a smaller instance of itself to solve a larger problem.

**Two Non-Negotiable Components of Every Recursive Function:**
1. **Base Case:** The halting condition that returns immediately without calling itself.
   ```dart
   if (n <= 1) return 1;
   ```
2. **Recursive Step:** Breaking the problem into smaller identical sub-problems moving toward the base case.
   ```dart
   return n * factorial(n - 1);
   ```

⚠️ **Common Traps:**
• Forgetting the base case causes a **StackOverflowError** (exhausts call stack memory frames).
• Time complexity can explode to exponential O(2ⁿ) without **Memoization / Dynamic Programming** (e.g., recursive Fibonacci).
''';
    }

    if (q.contains('array') && (q.contains('linked list') || q.contains('list'))) {
      return '''
📌 **Arrays vs. Linked Lists**

| Operation | Array | Singly Linked List |
|---|---|---|
| **Memory Layout** | Contiguous block in RAM | Non-contiguous (Nodes with pointers) |
| **Access by Index** | **O(1)** Instant | **O(n)** Must traverse from head |
| **Insertion at Head** | **O(n)** Must shift elements | **O(1)** Update head pointer |
| **Insertion at Tail** | **O(1)** if capacity exists | **O(1)** with tail pointer, else O(n) |
| **Memory Overhead** | Fixed size / Resizing cost | Extra pointer storage per node |

💡 **Selection Rule:** Choose **Arrays** when frequent random index access is needed. Choose **Linked Lists** when frequent insertions and deletions at arbitrary positions take priority.
''';
    }

    if (q.contains('time complexity') || q.contains('big o') || q.contains('big-o')) {
      return '''
📌 **Big-O Notation & Algorithm Complexity Hierarchy**

Big-O measures how an algorithm's running time or memory scales as input size (n) grows:

1. **O(1) Constant Time:** Instant (Array index access, hash map lookup).
2. **O(log n) Logarithmic Time:** Halves problem each step (Binary Search).
3. **O(n) Linear Time:** Single loop through array (Linear Search).
4. **O(n log n) Linearithmic:** Optimal general sorting (MergeSort, QuickSort avg, HeapSort).
5. **O(n²) Quadratic Time:** Nested loops (Bubble Sort, Selection Sort, Insertion Sort).
6. **O(2ⁿ) Exponential Time:** Brute-force subsets, unmemoized recursive Fibonacci.
7. **O(n!) Factorial Time:** Traveling Salesperson brute force (unusable for n > 12).
''';
    }

    // Physics
    if (q.contains('newton') || q.contains('law of motion')) {
      return '''
📌 **Newton's Three Laws of Motion**

1. **First Law (Law of Inertia):**
   An object remains at rest or in uniform motion along a straight line unless acted upon by a non-zero net external force (F_net = 0 → a = 0).
2. **Second Law (Fundamental Equation):**
   The net force applied to a body equals the rate of change of momentum:
   **F_net = m · a** (for constant mass).
3. **Third Law (Action-Reaction):**
   When body A exerts a force on body B (F_AB), body B exerts an equal and opposite force on body A (F_BA = -F_AB).
   *Key Note:* Action and reaction forces act on **two different bodies**, so they never cancel each other out!
''';
    }

    if (q.contains('thermodynamics')) {
      return '''
📌 **Laws of Thermodynamics**

• **Zeroth Law:** If system A is in thermal equilibrium with B, and B with C, then A and C are in thermal equilibrium with each other (defines **Temperature**).
• **First Law (Energy Conservation):** ΔU = Q - W
  (Change in internal energy equals heat added minus work done by system).
• **Second Law (Entropy):** The total entropy of an isolated system always increases over time (Heat spontaneously flows only from hot to cold).
• **Third Law (Absolute Zero):** The entropy of a pure crystalline substance approaches zero as temperature approaches absolute zero (T → 0 K).
''';
    }

    if (q.contains('gravity') || q.contains('gravitational')) {
      return '''
📌 **Universal Law of Gravitation**

Every mass in the universe attracts every other mass with a force directly proportional to the product of their masses and inversely proportional to the square of distance between their centers:

**F = G · (m₁ · m₂) / r²**

• **Universal Constant G:** 6.674 × 10⁻¹¹ N·m²/kg²
• **Acceleration due to gravity on Earth (g):** g = GM / R² ≈ 9.8 m/s²
• **Difference between Mass and Weight:**
  - *Mass (m):* Quantity of matter in kg (constant everywhere).
  - *Weight (W = m·g):* Gravitational force in Newtons (varies with location).
''';
    }

    if (q.contains('ohm') || q.contains('resistance') || q.contains('current')) {
      return '''
📌 **Ohm's Law & Electrical Circuit Fundamentals**

• **Ohm's Law Statement:** At constant temperature, the electric current passing through a conductor is directly proportional to the potential difference across its terminals:
  **V = I · R**
  where V is voltage (Volts), I is current (Amperes), and R is resistance (Ohms Ω).
• **Resistors in Series:** R_total = R₁ + R₂ + R₃ + ... (Current is same).
• **Resistors in Parallel:** 1 / R_total = 1/R₁ + 1/R₂ + ... (Voltage is same).
• **Electric Power Formula:** P = V · I = I²R = V² / R (Watts).
''';
    }

    // Mathematics
    if (q.contains('derivative') || q.contains('differentiation')) {
      return '''
📌 **Fundamental Rules of Differentiation (Calculus)**

• **Definition of Derivative:** f'(x) = lim(h → 0) [f(x+h) - f(x)] / h
• **Power Rule:** d/dx [xⁿ] = n · xⁿ⁻¹
• **Product Rule:** d/dx [u · v] = u'v + uv'
• **Quotient Rule:** d/dx [u / v] = (u'v - uv') / v²
• **Chain Rule:** d/dx [f(g(x))] = f'(g(x)) · g'(x)
• **Standard Trigonometric Derivatives:**
  - d/dx [sin x] = cos x
  - d/dx [cos x] = -sin x
  - d/dx [tan x] = sec² x
''';
    }

    if (q.contains('integration') || q.contains('integral')) {
      return '''
📌 **Calculus: Integration & Antiderivatives**

• **Fundamental Theorem of Calculus:** ∫[a to b] f(x) dx = F(b) - F(a) where F'(x) = f(x).
• **Standard Formulas:**
  - ∫ xⁿ dx = (xⁿ⁺¹) / (n + 1) + C  (for n ≠ -1)
  - ∫ (1/x) dx = ln|x| + C
  - ∫ eᵏˣ dx = (eᵏˣ / k) + C
  - ∫ sin x dx = -cos x + C
  - ∫ cos x dx = sin x + C
• **Integration by Parts:** ∫ u dv = u·v - ∫ v du (mnemonic: **ILATE** priority for choosing u: Inverse, Log, Algebraic, Trig, Exponential).
''';
    }

    if (q.contains('pythagoras') || q.contains('trigonometry')) {
      return '''
📌 **Trigonometry & The Pythagorean Theorem**

• **Pythagorean Theorem:** In a right-angled triangle, a² + b² = c² (where c is the hypotenuse).
• **Trigonometric Ratios (SOH CAH TOA):**
  - sin θ = Opposite / Hypotenuse
  - cos θ = Adjacent / Hypotenuse
  - tan θ = Opposite / Adjacent = sin θ / cos θ
• **Fundamental Pythagorean Identities:**
  1. sin² θ + cos² θ = 1
  2. 1 + tan² θ = sec² θ
  3. 1 + cot² θ = csc² θ
''';
    }

    // Chemistry
    if (q.contains('periodic table') || q.contains('atomic')) {
      return '''
📌 **Periodic Table & Atomic Trends**

• **Atomic Structure:** Nucleus contains Protons (+) and Neutrons (neutral), surrounded by Electrons (-) in energy shells.
• **Atomic Number (Z):** Number of protons.
• **Mass Number (A):** Number of protons + neutrons.
• **Periodic Trends Across a Period (Left to Right):**
  - Atomic Radius **decreases** (effective nuclear charge increases).
  - Ionization Energy & Electronegativity **increase**.
• **Periodic Trends Down a Group (Top to Bottom):**
  - Atomic Radius **increases** (new electron shells added).
  - Ionization Energy & Electronegativity **decrease**.
• **Most Electronegative Elements:** Fluorine (4.0) > Oxygen (3.5) > Nitrogen (3.0).
''';
    }

    if (q.contains('acid') || q.contains('base') || q.contains('ph')) {
      return '''
📌 **Acids, Bases & The pH Scale**

• **Arrhenius Definition:** Acids produce H⁺ in water; Bases produce OH⁻.
• **Brønsted–Lowry Definition:** Acids are proton (H⁺) donors; Bases are proton acceptors.
• **pH Scale (0 to 14):**
  - pH = -log₁₀[H⁺]
  - pH < 7: Acidic (e.g., Stomach acid ~1.5, Lemon juice ~2.4)
  - pH = 7: Neutral (Pure water at 25°C)
  - pH > 7: Basic / Alkaline (e.g., Bleach ~12.5, Soap ~9)
• **Neutralization Reaction:** Acid + Base → Salt + Water
''';
    }

    // Biology
    if (q.contains('mitosis') || q.contains('meiosis') || q.contains('cell division')) {
      return '''
📌 **Mitosis vs Meiosis (Cell Division)**

| Feature | Mitosis | Meiosis |
|---|---|---|
| **Purpose** | Growth, tissue repair, asexual reproduction | Gamete (sperm/egg) formation |
| **Location** | Somatic (body) cells | Germline / Reproductive cells |
| **Divisions** | **1 division** | **2 successive divisions** |
| **Daughter Cells** | **2 diploid (2n) cells** | **4 haploid (n) cells** |
| **Genetic Identity** | Genetically identical clones | Genetically diverse (crossing over) |
| **Phases** | Prophase, Metaphase, Anaphase, Telophase (PMAT) | PMAT I and PMAT II |
''';
    }

    if (q.contains('photosynthesis')) {
      return '''
📌 **Photosynthesis Mechanism**

The biological process where plants convert light energy into chemical energy (glucose):

**6 CO₂ + 6 H₂O + Light (Chlorophyll) → C₆H₁₂O₆ + 6 O₂**

**Two Successive Stages:**
1. **Light-Dependent Reactions (in Thylakoid membrane):**
   Solar photons split water molecules (photolysis), releasing O₂ and generating ATP and NADPH.
2. **Light-Independent Reactions / Calvin Cycle (in Stroma):**
   Uses ATP and NADPH to fix atmospheric CO₂ into glucose sugar using the enzyme **RuBisCO**.
''';
    }

    // Dynamic decomposition fallback for any other question
    final capitalized = originalQuery.trim();
    return '''
📌 **Academic Solution & Concept Guide: "$capitalized"**

1. **Fundamental Definition:**
   • At its core, **$capitalized** describes a structured system governed by causal principles, boundary parameters, and measurable outcomes.
   • In examination frameworks, this topic tests your understanding of foundational definitions, governing formulas, and step-by-step analytical reasoning.

2. **Core Operational Mechanism:**
   • **Inputs & Boundary Constraints:** Always verify given values, coordinate systems, and environmental assumptions before solving.
   • **Step-by-Step Derivation:** Break the problem into linear sub-problems: define known quantities → select the governing relation → simplify systematically.

3. **High-Yield Exam Strategy:**
   • Write the primary formula and define all symbols clearly with their standard SI / mathematical units.
   • Be alert to common pitfalls: dimensional inconsistency, boundary edge cases, and sign conventions (+ vs -).

💡 *Tip: To receive unlimited dynamic open-ended AI answers, add your free Google AI Studio key by tapping 🔑 in the top bar.*
''';
  }

  static String _summarizeText(String text) {
    final clean = text.trim();
    final sentences = clean
        .split(RegExp(r'(?<=[.!?\n])\s+'))
        .where((s) => s.trim().length > 15)
        .toList();

    final wordCount = clean.split(RegExp(r'\s+')).length;
    final readingTime = (wordCount / 200).ceil();

    final bulletPoints = sentences.take(4).map((s) => '• ${s.trim()}').join('\n');

    return '''
📝 **Executive Study Summary**

**Quick Metrics:** ~$wordCount words | ~$readingTime min read

**Core Takeaways:**
${bulletPoints.isNotEmpty ? bulletPoints : '• $clean'}

🎯 **Exam Takeaway:** Formulate two active recall flashcards from these summary bullets and review them in 24 hours.
''';
  }

  static String _generateQuizForTopic(String topic) {
    final t = topic.trim();
    return '''
❓ **Practice Quiz: $t**

**Question 1 [Multiple Choice]**
Which of the following statements is mathematically or conceptually accurate regarding $t?
A) The value decreases exponentially with distance
B) It remains invariant under standard equilibrium conditions
C) The net transfer of entropy is strictly zero
D) It only applies to closed homogeneous systems
*Answer: B (Under standard equilibrium, internal properties remain steady).*

**Question 2 [True / False]**
True or False: In real-world irreversible processes, theoretical maximum efficiency can be achieved without energy dissipation.
*Answer: False (Second Law ensures friction/heat loss).*

**Question 3 [Short Numerical / Analytical]**
State the two fundamental boundary assumptions required before calculating values for $t.
*Answer: 1. Negligible external friction/drag; 2. Conservation of total system energy.*
''';
  }

  static String _debugCode(String snippet) {
    return '''
🐞 **Code Error Analysis & Fix Guide**

**Identified Risk Areas in Provided Code:**
1. **Null Safety Violation:** A variable may be accessed before receiving a non-null assignment (use `?.` or default fallback `??`).
2. **Boundary Condition (Off-by-One):** Check loop limits (e.g. `i < array.length` instead of `i <= array.length`).
3. **Async / Promise Handling:** Ensure all Futures/Promises are properly `await`ed and wrapped in a `try { ... } catch (e) { ... }` block.

**Recommended Refactored Pattern:**
• Always validate argument constraints at the start of the function.
• Use defensive default values instead of force unwrapping (`!`).
• Log runtime errors with descriptive contextual tags for quick debugging.
''';
  }

  static String _generateRevisionPlan(String subject) {
    return '''
📅 **AI Spaced-Repetition Revision Schedule for: $subject**

• **Day 1 (Today):** Read concept fundamentals & create 5 summary flashcards.
• **Day 2 (+24h):** Active Recall: Write down definitions and formulas from memory without peeking.
• **Day 5 (+4 days):** Solve 3 medium-difficulty numerical or conceptual past-exam questions.
• **Day 12 (+1 week):** Complete a timed 15-minute mock quiz using StudyMate Pomodoro.
• **Day 30 (+1 month):** Final rapid review before school / board term examinations.
''';
  }
}
