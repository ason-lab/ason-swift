import Foundation
import AsonSwift

// ===========================================================================
// Helpers
// ===========================================================================

func jsonEncode(_ value: AsonValue) -> Data {
    let obj = asonToJSON(value)
    return try! JSONSerialization.data(withJSONObject: obj, options: [])
}

func jsonDecode(_ data: Data) -> Any {
    return try! JSONSerialization.jsonObject(with: data, options: [])
}

func asonToJSON(_ v: AsonValue) -> Any {
    switch v {
    case .int(let i): return NSNumber(value: i)
    case .uint(let u): return NSNumber(value: u)
    case .float(let d): return NSNumber(value: d)
    case .bool(let b): return NSNumber(value: b)
    case .string(let s): return s
    case .array(let arr): return arr.map { asonToJSON($0) }
    case .object(let obj):
        var dict: [String: Any] = [:]
        for (k, v) in obj { dict[k] = asonToJSON(v) }
        return dict
    case .null: return NSNull()
    }
}

// ===========================================================================
// Data generators
// ===========================================================================

func generateUsers(_ n: Int) -> AsonValue {
    let names = ["Alice", "Bob", "Carol", "David", "Eve", "Frank", "Grace", "Hank"]
    let roles = ["engineer", "designer", "manager", "analyst"]
    let cities = ["NYC", "LA", "Chicago", "Houston", "Phoenix"]
    var rows: [AsonValue] = []
    rows.reserveCapacity(n)
    for i in 0..<n {
        rows.append(.object([
            "id": .int(Int64(i)),
            "name": .string(names[i % names.count]),
            "email": .string("\(names[i % names.count].lowercased())@example.com"),
            "age": .int(Int64(25 + i % 40)),
            "score": .float(50.0 + Double(i % 50) + 0.5),
            "active": .bool(i % 3 != 0),
            "role": .string(roles[i % roles.count]),
            "city": .string(cities[i % cities.count])
        ]))
    }
    return .array(rows)
}

func generateCompanies(_ n: Int) -> AsonValue {
    var companies: [AsonValue] = []
    companies.reserveCapacity(n)
    for i in 0..<n {
        var divisions: [AsonValue] = []
        for d in 0..<2 {
            var teams: [AsonValue] = []
            for t in 0..<2 {
                var projects: [AsonValue] = []
                for p in 0..<3 {
                    var tasks: [AsonValue] = []
                    for tk in 0..<4 {
                        let task: AsonValue = .object([
                            "id": .int(Int64(i * 100 + d * 10 + t * 5 + tk)),
                            "title": .string("Task_\(tk)"),
                            "priority": .int(Int64(tk % 3 + 1)),
                            "done": .bool(tk % 2 == 0),
                            "hours": .float(2.0 + Double(tk) * 1.5)
                        ])
                        tasks.append(task)
                    }
                    let project: AsonValue = .object([
                        "name": .string("Proj_\(t)_\(p)"),
                        "budget": .float(100.0 + Double(p) * 50.5),
                        "active": .bool(p % 2 == 0),
                        "tasks": .array(tasks)
                    ])
                    projects.append(project)
                }
                let locations = ["NYC","London","Tokyo","Berlin"]
                let leads = ["Alice","Bob","Carol","David"]
                let team: AsonValue = .object([
                    "name": .string("Team_\(i)_\(d)_\(t)"),
                    "lead": .string(leads[t % 4]),
                    "size": .int(Int64(5 + t * 2)),
                    "projects": .array(projects)
                ])
                teams.append(team)
            }
            let div: AsonValue = .object([
                "name": .string("Div_\(i)_\(d)"),
                "location": .string(["NYC","London","Tokyo","Berlin"][d % 4]),
                "headcount": .int(Int64(50 + d * 20)),
                "teams": .array(teams)
            ])
            divisions.append(div)
        }
        let company: AsonValue = .object([
            "name": .string("Corp_\(i)"),
            "founded": .int(Int64(1990 + i % 35)),
            "revenue_m": .float(10.0 + Double(i) * 5.5),
            "public": .bool(i % 2 == 0),
            "divisions": .array(divisions),
            "tags": .array([.string("enterprise"), .string("tech"), .string("sector_\(i % 5)")])
        ])
        companies.append(company)
    }
    return .array(companies)
}

// ===========================================================================
// Timing helpers
// ===========================================================================

func elapsedMs(_ body: () throws -> Void) rethrows -> Double {
    let t0 = DispatchTime.now().uptimeNanoseconds
    try body()
    let t1 = DispatchTime.now().uptimeNanoseconds
    return Double(t1 - t0) / 1_000_000.0
}

// ===========================================================================
// Benchmark result types
// ===========================================================================

struct BenchResult {
    let name: String
    let jsonSerMs: Double
    let asonSerMs: Double
    let jsonDeMs: Double
    let asonDeMs: Double
    let jsonBytes: Int
    let asonBytes: Int

    func print_() {
        let serRatio = jsonSerMs / asonSerMs
        let deRatio = jsonDeMs / asonDeMs
        let saving = (1.0 - Double(asonBytes) / Double(jsonBytes)) * 100.0
        print("  \(name)")
        print(String(format: "    Serialize:   JSON %8.2fms | ASON %8.2fms | ratio %.2fx %@",
            jsonSerMs, asonSerMs, serRatio, serRatio >= 1.0 ? "✓ ASON faster" : ""))
        print(String(format: "    Deserialize: JSON %8.2fms | ASON %8.2fms | ratio %.2fx %@",
            jsonDeMs, asonDeMs, deRatio, deRatio >= 1.0 ? "✓ ASON faster" : ""))
        print(String(format: "    Size:        JSON %8d B | ASON %8d B | saving %.0f%%",
            jsonBytes, asonBytes, saving))
    }
}

struct BinBenchResult {
    let name: String
    let jsonSerMs: Double
    let asonSerMs: Double
    let binSerMs: Double
    let jsonDeMs: Double
    let asonDeMs: Double
    let binDeMs: Double
    let jsonBytes: Int
    let asonBytes: Int
    let binBytes: Int

    func print_() {
        let serAson = jsonSerMs / asonSerMs
        let serBin = jsonSerMs / binSerMs
        let deAson = jsonDeMs / asonDeMs
        let deBin = jsonDeMs / binDeMs
        let svA = (1.0 - Double(asonBytes) / Double(jsonBytes)) * 100.0
        let svB = (1.0 - Double(binBytes) / Double(jsonBytes)) * 100.0
        print("  \(name)")
        print(String(format: "    Serialize:   JSON %8.2fms | ASON %8.2fms (%.1fx) | BIN %8.2fms (%.1fx)",
            jsonSerMs, asonSerMs, serAson, binSerMs, serBin))
        print(String(format: "    Deserialize: JSON %8.2fms | ASON %8.2fms (%.1fx) | BIN %8.2fms (%.1fx)",
            jsonDeMs, asonDeMs, deAson, binDeMs, deBin))
        print(String(format: "    Size:  JSON %8d B | ASON %8d B (%.0f%% smaller) | BIN %8d B (%.0f%% smaller)",
            jsonBytes, asonBytes, svA, binBytes, svB))
    }
}

// ===========================================================================
// Benchmark functions
// ===========================================================================

func benchFlat(count: Int, iterations: Int) throws -> BenchResult {
    let users = generateUsers(count)
    var jsonData = Data()
    let jsonSerMs = try elapsedMs {
        for _ in 0..<iterations { jsonData = jsonEncode(users) }
    }
    var asonStr = ""
    let asonSerMs = try elapsedMs {
        for _ in 0..<iterations { asonStr = try encode(users) }
    }
    let jsonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = jsonDecode(jsonData) }
    }
    let asonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decode(asonStr) }
    }
    let decoded = try decode(asonStr)
    assert(decoded == users, "flat \(count) roundtrip failed")
    return BenchResult(
        name: "Flat struct × \(count) (8 fields)",
        jsonSerMs: jsonSerMs, asonSerMs: asonSerMs,
        jsonDeMs: jsonDeMs, asonDeMs: asonDeMs,
        jsonBytes: jsonData.count, asonBytes: asonStr.utf8.count)
}

func benchDeep(count: Int, iterations: Int) throws -> BenchResult {
    let companies = generateCompanies(count)
    var jsonData = Data()
    let jsonSerMs = try elapsedMs {
        for _ in 0..<iterations { jsonData = jsonEncode(companies) }
    }
    var asonStr = ""
    let asonSerMs = try elapsedMs {
        for _ in 0..<iterations { asonStr = try encode(companies) }
    }
    let jsonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = jsonDecode(jsonData) }
    }
    let asonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decode(asonStr) }
    }
    let decoded = try decode(asonStr)
    assert(decoded == companies, "deep \(count) roundtrip failed")
    return BenchResult(
        name: "5-level deep × \(count) (Company>Division>Team>Project>Task)",
        jsonSerMs: jsonSerMs, asonSerMs: asonSerMs,
        jsonDeMs: jsonDeMs, asonDeMs: asonDeMs,
        jsonBytes: jsonData.count, asonBytes: asonStr.utf8.count)
}

func benchFlatBin(count: Int, iterations: Int) throws -> BinBenchResult {
    let users = generateUsers(count)
    var jsonData = Data()
    let jsonSerMs = try elapsedMs {
        for _ in 0..<iterations { jsonData = jsonEncode(users) }
    }
    var asonStr = ""
    let asonSerMs = try elapsedMs {
        for _ in 0..<iterations { asonStr = try encode(users) }
    }
    var binBuf = Data()
    let binSerMs = try elapsedMs {
        for _ in 0..<iterations { binBuf = try encodeBinary(users) }
    }
    let jsonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = jsonDecode(jsonData) }
    }
    let asonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decode(asonStr) }
    }
    let binDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decodeBinary(binBuf) }
    }
    let decoded = try decodeBinary(binBuf)
    assert(decoded == users, "bin flat \(count) roundtrip failed")
    return BinBenchResult(
        name: "Flat struct × \(count) (8 fields)",
        jsonSerMs: jsonSerMs, asonSerMs: asonSerMs, binSerMs: binSerMs,
        jsonDeMs: jsonDeMs, asonDeMs: asonDeMs, binDeMs: binDeMs,
        jsonBytes: jsonData.count, asonBytes: asonStr.utf8.count, binBytes: binBuf.count)
}

func benchDeepBin(count: Int, iterations: Int) throws -> BinBenchResult {
    let companies = generateCompanies(count)
    var jsonData = Data()
    let jsonSerMs = try elapsedMs {
        for _ in 0..<iterations { jsonData = jsonEncode(companies) }
    }
    var asonStr = ""
    let asonSerMs = try elapsedMs {
        for _ in 0..<iterations { asonStr = try encode(companies) }
    }
    var binBuf = Data()
    let binSerMs = try elapsedMs {
        for _ in 0..<iterations { binBuf = try encodeBinary(companies) }
    }
    let jsonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = jsonDecode(jsonData) }
    }
    let asonDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decode(asonStr) }
    }
    let binDeMs = try elapsedMs {
        for _ in 0..<iterations { _ = try decodeBinary(binBuf) }
    }
    let decoded = try decodeBinary(binBuf)
    assert(decoded == companies, "bin deep \(count) roundtrip failed")
    return BinBenchResult(
        name: "Deep struct × \(count) (5-level nested)",
        jsonSerMs: jsonSerMs, asonSerMs: asonSerMs, binSerMs: binSerMs,
        jsonDeMs: jsonDeMs, asonDeMs: asonDeMs, binDeMs: binDeMs,
        jsonBytes: jsonData.count, asonBytes: asonStr.utf8.count, binBytes: binBuf.count)
}

func benchSingleRoundtrip(iterations: Int) throws -> (Double, Double) {
    let user: AsonValue = .object([
        "id": .int(1), "name": .string("Alice"),
        "email": .string("alice@example.com"),
        "age": .int(30), "score": .float(95.5),
        "active": .bool(true), "role": .string("engineer"),
        "city": .string("NYC")
    ])
    let asonMs = try elapsedMs {
        for _ in 0..<iterations {
            let s = try encode(user)
            _ = try decode(s)
        }
    }
    let jsonMs = try elapsedMs {
        for _ in 0..<iterations {
            let d = jsonEncode(user)
            _ = jsonDecode(d)
        }
    }
    return (asonMs, jsonMs)
}

func benchDeepSingleRoundtrip(iterations: Int) throws -> (Double, Double) {
    let company: AsonValue = .object([
        "name": .string("MegaCorp"), "founded": .int(2000),
        "revenue_m": .float(500.5), "public": .bool(true),
        "divisions": .array([.object([
            "name": .string("Engineering"), "location": .string("SF"), "headcount": .int(200),
            "teams": .array([.object([
                "name": .string("Backend"), "lead": .string("Alice"), "size": .int(12),
                "projects": .array([.object([
                    "name": .string("API v3"), "budget": .float(250.0), "active": .bool(true),
                    "tasks": .array([
                        .object(["id": .int(1), "title": .string("Design"), "priority": .int(1), "done": .bool(true), "hours": .float(40.0)]),
                        .object(["id": .int(2), "title": .string("Implement"), "priority": .int(1), "done": .bool(false), "hours": .float(120.0)]),
                        .object(["id": .int(3), "title": .string("Test"), "priority": .int(2), "done": .bool(false), "hours": .float(30.0)])
                    ])
                ])])
            ])])
        ])]),
        "tags": .array([.string("tech"), .string("public")])
    ])
    let asonMs = try elapsedMs {
        for _ in 0..<iterations {
            let s = try encode(company)
            _ = try decode(s)
        }
    }
    let jsonMs = try elapsedMs {
        for _ in 0..<iterations {
            let d = jsonEncode(company)
            _ = jsonDecode(d)
        }
    }
    return (asonMs, jsonMs)
}

// ===========================================================================
// Memory measurement
// ===========================================================================

func getRSSBytes() -> Int {
    var info = rusage()
    getrusage(RUSAGE_SELF, &info)
    return Int(info.ru_maxrss) // macOS returns bytes
}

func formatBytes(_ b: Int) -> String {
    if b >= 1_048_576 { return String(format: "%.1f MB", Double(b) / 1_048_576.0) }
    if b >= 1024 { return String(format: "%.1f KB", Double(b) / 1024.0) }
    return "\(b) B"
}

// ===========================================================================
// Main
// ===========================================================================

do {
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║            ASON vs JSON Comprehensive Benchmark              ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    #if os(macOS)
    print("\nSystem: macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
    #else
    print("\nSystem: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    #endif

    let rssBefore = getRSSBytes()
    print("RSS before benchmarks: \(formatBytes(rssBefore))\n")

    let iterations = 100

    // ===================================================================
    // Section 1: Flat struct (schema-driven vec)
    // ===================================================================
    print("┌─────────────────────────────────────────────┐")
    print("│  Section 1: Flat Struct (schema-driven vec) │")
    print("└─────────────────────────────────────────────┘")

    for count in [100, 500, 1000, 5000] {
        let r = try benchFlat(count: count, iterations: iterations)
        r.print_()
        print()
    }

    let rssAfterFlat = getRSSBytes()
    print("  RSS after flat benchmarks: \(formatBytes(rssAfterFlat)) (Δ \(formatBytes(rssAfterFlat - rssBefore)))")

    // ===================================================================
    // Section 2: 5-level deep nested struct
    // ===================================================================
    print("\n┌──────────────────────────────────────────────────────────┐")
    print("│  Section 2: 5-Level Deep Nesting (Company hierarchy)     │")
    print("└──────────────────────────────────────────────────────────┘")

    for count in [10, 50, 100] {
        let r = try benchDeep(count: count, iterations: iterations)
        r.print_()
        print()
    }

    let rssAfterDeep = getRSSBytes()
    print("  RSS after deep benchmarks: \(formatBytes(rssAfterDeep)) (Δ \(formatBytes(rssAfterDeep - rssBefore)))")

    // ===================================================================
    // Section 3: Single Struct Roundtrip
    // ===================================================================
    print("\n┌──────────────────────────────────────────────┐")
    print("│  Section 3: Single Struct Roundtrip (10000x) │")
    print("└──────────────────────────────────────────────┘")

    let (asonFlat, jsonFlat) = try benchSingleRoundtrip(iterations: 10000)
    print(String(format: "  Flat:  ASON %6.2fms | JSON %6.2fms | ratio %.2fx",
        asonFlat, jsonFlat, jsonFlat / asonFlat))

    let (asonDeep, jsonDeep) = try benchDeepSingleRoundtrip(iterations: 10000)
    print(String(format: "  Deep:  ASON %6.2fms | JSON %6.2fms | ratio %.2fx",
        asonDeep, jsonDeep, jsonDeep / asonDeep))

    // ===================================================================
    // Section 4: Large Payload (10k records)
    // ===================================================================
    print("\n┌──────────────────────────────────────────────┐")
    print("│  Section 4: Large Payload (10k records)      │")
    print("└──────────────────────────────────────────────┘")

    let rLarge = try benchFlat(count: 10000, iterations: 10)
    print("  (10 iterations for large payload)")
    rLarge.print_()

    let rssAfterLarge = getRSSBytes()
    print(String(format: "\n  RSS after large payload: %@ (Δ %@)",
        formatBytes(rssAfterLarge), formatBytes(rssAfterLarge - rssBefore)))

    // ===================================================================
    // Section 5: Throughput Summary
    // ===================================================================
    print("\n┌──────────────────────────────────────────────┐")
    print("│  Section 5: Throughput Summary               │")
    print("└──────────────────────────────────────────────┘")

    let users1k = generateUsers(1000)
    let json1k = jsonEncode(users1k)
    let ason1k = try encode(users1k)

    let iters = 100

    let jsonSerDur = try elapsedMs {
        for _ in 0..<iters { _ = jsonEncode(users1k) }
    }
    let asonSerDur = try elapsedMs {
        for _ in 0..<iters { _ = try encode(users1k) }
    }
    let jsonDeDur = try elapsedMs {
        for _ in 0..<iters { _ = jsonDecode(json1k) }
    }
    let asonDeDur = try elapsedMs {
        for _ in 0..<iters { _ = try decode(ason1k) }
    }

    let totalRecords = 1000.0 * Double(iters)
    let jsonSerRps = totalRecords / (jsonSerDur / 1000.0)
    let asonSerRps = totalRecords / (asonSerDur / 1000.0)
    let jsonDeRps = totalRecords / (jsonDeDur / 1000.0)
    let asonDeRps = totalRecords / (asonDeDur / 1000.0)

    print("  Serialize throughput (1000 records × \(iters) iters):")
    print(String(format: "    JSON: %.0f records/s", jsonSerRps))
    print(String(format: "    ASON: %.0f records/s", asonSerRps))
    print(String(format: "    Speed: %.2fx %@", asonSerRps / jsonSerRps,
        asonSerRps > jsonSerRps ? "✓ ASON faster" : ""))
    print("  Deserialize throughput:")
    print(String(format: "    JSON: %.0f records/s", jsonDeRps))
    print(String(format: "    ASON: %.0f records/s", asonDeRps))
    print(String(format: "    Speed: %.2fx %@", asonDeRps / jsonDeRps,
        asonDeRps > jsonDeRps ? "✓ ASON faster" : ""))

    let rssFinal = getRSSBytes()
    print("\n  Memory:")
    print("    Initial RSS:  \(formatBytes(rssBefore))")
    print("    Final RSS:    \(formatBytes(rssFinal))")
    print("    Peak delta:   \(formatBytes(rssFinal - rssBefore))")

    // ===================================================================
    // Section 6: Binary Format (ASON-BIN) vs ASON text vs JSON
    // ===================================================================
    print("\n┌──────────────────────────────────────────────────────────────┐")
    print("│  Section 6: Binary Format (ASON-BIN) vs ASON text vs JSON    │")
    print("└──────────────────────────────────────────────────────────────┘")

    print("\n  ── Flat struct ──")
    try benchFlatBin(count: 100, iterations: 50).print_()
    try benchFlatBin(count: 1000, iterations: 20).print_()
    try benchFlatBin(count: 5000, iterations: 5).print_()

    print("\n  ── Deep struct (5-level nested) ──")
    try benchDeepBin(count: 10, iterations: 50).print_()
    try benchDeepBin(count: 100, iterations: 10).print_()

    print("\n  ── Single User roundtrip ──")
    let singleUser: AsonValue = .object([
        "id": .int(42), "name": .string("Alice"),
        "email": .string("alice@example.com"),
        "age": .int(30), "score": .float(9.8),
        "active": .bool(true), "role": .string("admin"),
        "city": .string("Berlin")
    ])
    let singleIters = 100_000
    let binNs = try elapsedMs {
        for _ in 0..<singleIters {
            let b = try encodeBinary(singleUser)
            _ = try decodeBinary(b)
        }
    } * 1_000_000.0 / Double(singleIters)

    let asonNs = try elapsedMs {
        for _ in 0..<singleIters {
            let s = try encode(singleUser)
            _ = try decode(s)
        }
    } * 1_000_000.0 / Double(singleIters)

    let jsonNs = try elapsedMs {
        for _ in 0..<singleIters {
            let d = jsonEncode(singleUser)
            _ = jsonDecode(d)
        }
    } * 1_000_000.0 / Double(singleIters)

    print(String(format: "    × %d: BIN %6.0fns | ASON %6.0fns | JSON %6.0fns",
        singleIters, binNs, asonNs, jsonNs))
    print(String(format: "    Speedup vs JSON: BIN %.1fx faster | ASON %.1fx faster",
        jsonNs / binNs, jsonNs / asonNs))

    print("\n╔══════════════════════════════════════════════════════════════╗")
    print("║                    Benchmark Complete                        ║")
    print("╚══════════════════════════════════════════════════════════════╝")
} catch {
    print("error: \(error)")
    exit(1)
}
