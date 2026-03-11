import Foundation
import AsonSwift

// ===========================================================================
// Helpers
// ===========================================================================

func jsonEncode(_ value: AsonValue) -> Data {
    let obj = asonToJSON(value)
    return try! JSONSerialization.data(withJSONObject: obj, options: [])
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
// 1. Nested struct
// ===========================================================================
print("=== ASON Complex Examples ===\n")

print("1. Nested struct:")
let emp: AsonValue = .object([
    "id": .int(1),
    "name": .string("Alice"),
    "dept": .object(["title": .string("Manager")]),
    "skills": .array([.string("Rust"), .string("Go")]),
    "active": .bool(true)
])
let empText = try encodeTyped(emp)
print("   \(empText)")
let empBack = try decode(empText)
assert(empBack == emp)
print("   ✓ nested struct roundtrip OK")

// ===========================================================================
// 2. Vec with nested structs
// ===========================================================================
print("\n2. Vec with nested structs:")
let employees: AsonValue = .array([
    .object([
        "id": .int(1), "name": .string("Alice"),
        "dept": .object(["title": .string("Manager")]),
        "skills": .array([.string("Rust"), .string("Go")]),
        "active": .bool(true)
    ]),
    .object([
        "id": .int(2), "name": .string("Bob"),
        "dept": .object(["title": .string("Engineer")]),
        "skills": .array([.string("Python")]),
        "active": .bool(false)
    ]),
    .object([
        "id": .int(3), "name": .string("Carol Smith"),
        "dept": .object(["title": .string("Director")]),
        "skills": .array([.string("Leadership"), .string("Strategy")]),
        "active": .bool(true)
    ])
])
let empVecText = try encodeTyped(employees)
print("   \(empVecText)")
let empVecBack = try decode(empVecText)
assert(empVecBack == employees)
print("   ✓ vec nested roundtrip OK")

// ===========================================================================
// 3. Escaped strings
// ===========================================================================
print("\n3. Escaped strings:")
let note: AsonValue = .object([
    "text": .string("say \"hi\", then (wave)\tnewline\nend")
])
let noteS = try encode(note)
print("   serialized: \(noteS)")
let note2 = try decode(noteS)
assert(note2 == note)
print("   ✓ escape roundtrip OK")

// ===========================================================================
// 4. Float fields
// ===========================================================================
print("\n4. Float fields:")
let measurement: AsonValue = .object([
    "id": .int(2),
    "value": .float(95.0),
    "label": .string("score")
])
let mS = try encode(measurement)
print("   serialized: \(mS)")
let m2 = try decode(mS)
assert(m2 == measurement)
print("   ✓ float roundtrip OK")

// ===========================================================================
// 5. Negative numbers
// ===========================================================================
print("\n5. Negative numbers:")
let nums: AsonValue = .object([
    "a": .int(-42),
    "b": .float(-3.15),
    "c": .int(-9223372036854775807)
])
let nS = try encode(nums)
print("   serialized: \(nS)")
let n2 = try decode(nS)
assert(n2 == nums)
print("   ✓ negative roundtrip OK")

// ===========================================================================
// 6. 5-level deep: Country > Region > City > District > Street > Building
// ===========================================================================
print("\n6. Five-level nesting (Country>Region>City>District>Street>Building):")
let country: AsonValue = .object([
    "name": .string("Rustland"),
    "code": .string("RL"),
    "population": .int(50_000_000),
    "gdp_trillion": .float(1.5),
    "regions": .array([
        .object([
            "name": .string("Northern"),
            "cities": .array([
                .object([
                    "name": .string("Ferriton"),
                    "population": .int(2_000_000),
                    "area_km2": .float(350.5),
                    "districts": .array([
                        .object([
                            "name": .string("Downtown"),
                            "population": .int(500_000),
                            "streets": .array([
                                .object([
                                    "name": .string("Main St"),
                                    "length_km": .float(2.5),
                                    "buildings": .array([
                                        .object(["name": .string("Tower A"), "floors": .int(50), "residential": .bool(false), "height_m": .float(200.0)]),
                                        .object(["name": .string("Apt Block 1"), "floors": .int(12), "residential": .bool(true), "height_m": .float(40.5)])
                                    ])
                                ]),
                                .object([
                                    "name": .string("Oak Ave"),
                                    "length_km": .float(1.2),
                                    "buildings": .array([
                                        .object(["name": .string("Library"), "floors": .int(3), "residential": .bool(false), "height_m": .float(15.0)])
                                    ])
                                ])
                            ])
                        ]),
                        .object([
                            "name": .string("Harbor"),
                            "population": .int(150_000),
                            "streets": .array([
                                .object([
                                    "name": .string("Dock Rd"),
                                    "length_km": .float(0.8),
                                    "buildings": .array([
                                        .object(["name": .string("Warehouse 7"), "floors": .int(1), "residential": .bool(false), "height_m": .float(8.0)])
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        ]),
        .object([
            "name": .string("Southern"),
            "cities": .array([
                .object([
                    "name": .string("Crabville"),
                    "population": .int(800_000),
                    "area_km2": .float(120.0),
                    "districts": .array([
                        .object([
                            "name": .string("Old Town"),
                            "population": .int(200_000),
                            "streets": .array([
                                .object([
                                    "name": .string("Heritage Ln"),
                                    "length_km": .float(0.5),
                                    "buildings": .array([
                                        .object(["name": .string("Museum"), "floors": .int(2), "residential": .bool(false), "height_m": .float(12.0)]),
                                        .object(["name": .string("Town Hall"), "floors": .int(4), "residential": .bool(false), "height_m": .float(20.0)])
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        ])
    ])
])

let countryS = try encode(country)
print("   serialized (\(countryS.utf8.count) bytes)")
let countryPrefix = String(countryS.prefix(200))
print("   first 200 chars: \(countryPrefix)...")
let country2 = try decode(countryS)
assert(country2 == country)
print("   ✓ 5-level ASON-text roundtrip OK")

let countryBin = try encodeBinary(country)
let country3 = try decodeBinary(countryBin)
assert(country3 == country)
print("   ✓ 5-level ASON-bin roundtrip OK")

let countryJson = jsonEncode(country)
print("   ASON text: \(countryS.utf8.count) B | ASON bin: \(countryBin.count) B | JSON: \(countryJson.count) B")
let binVsJson = (1.0 - Double(countryBin.count) / Double(countryJson.count)) * 100.0
let textVsJson = (1.0 - Double(countryS.utf8.count) / Double(countryJson.count)) * 100.0
print(String(format: "   BIN vs JSON: %.0f%% smaller | TEXT vs JSON: %.0f%% smaller", binVsJson, textVsJson))

// ===========================================================================
// 7. Service config with nested objects
// ===========================================================================
print("\n7. Complex config struct (nested):")
let config: AsonValue = .object([
    "name": .string("my-service"),
    "version": .string("2.1.0"),
    "db": .object([
        "host": .string("db.example.com"),
        "port": .int(5432),
        "max_connections": .int(100),
        "ssl": .bool(true),
        "timeout_ms": .float(3000.5)
    ]),
    "cache": .object([
        "enabled": .bool(true),
        "ttl_seconds": .int(3600),
        "max_size_mb": .int(512)
    ]),
    "log": .object([
        "level": .string("info"),
        "file": .string("/var/log/app.log"),
        "rotate": .bool(true)
    ]),
    "features": .array([.string("auth"), .string("rate-limit"), .string("websocket")])
])
let configS = try encode(config)
print("   serialized (\(configS.utf8.count) bytes):")
print("   \(configS)")
let config2 = try decode(configS)
assert(config2 == config)
print("   ✓ config roundtrip OK")

let configJson = jsonEncode(config)
print(String(format: "   ASON text: %d B | JSON: %d B | TEXT vs JSON: %.0f%% smaller",
    configS.utf8.count, configJson.count,
    (1.0 - Double(configS.utf8.count) / Double(configJson.count)) * 100.0))

let configBin = try encodeBinary(config)
let config3 = try decodeBinary(configBin)
assert(config3 == config)
print("   ✓ config ASON-bin roundtrip OK")
print(String(format: "   ASON bin: %d B | BIN vs JSON: %.0f%% smaller",
    configBin.count,
    (1.0 - Double(configBin.count) / Double(configJson.count)) * 100.0))

// ===========================================================================
// 8. Large structure — 100 records × nested
// ===========================================================================
print("\n8. Large structure (100 records × nested regions):")
var totalAsonBytes = 0
var totalJsonBytes = 0
var totalBinBytes = 0
for i in 0..<100 {
    var regions: [AsonValue] = []
    for r in 0..<3 {
        var cities: [AsonValue] = []
        for ci in 0..<2 {
            var buildings: [AsonValue] = []
            for b in 0..<2 {
                let bldg: AsonValue = .object([
                    "name": .string("Bldg_\(ci)_\(b)"),
                    "floors": .int(Int64(5 + b * 3)),
                    "residential": .bool(b % 2 == 0),
                    "height_m": .float(15.0 + Double(b) * 10.5)
                ])
                buildings.append(bldg)
            }
            let street: AsonValue = .object([
                "name": .string("St_\(ci)"),
                "length_km": .float(1.0 + Double(ci) * 0.5),
                "buildings": .array(buildings)
            ])
            let district: AsonValue = .object([
                "name": .string("Dist_\(ci)"),
                "population": .int(Int64(50_000 + ci * 10_000)),
                "street": street
            ])
            let city: AsonValue = .object([
                "name": .string("City_\(i)_\(r)_\(ci)"),
                "population": .int(Int64(100_000 + ci * 50_000)),
                "area_km2": .float(50.0 + Double(ci) * 25.5),
                "district": district
            ])
            cities.append(city)
        }
        let region: AsonValue = .object([
            "name": .string("Region_\(i)_\(r)"),
            "cities": .array(cities)
        ])
        regions.append(region)
    }
    let c: AsonValue = .object([
        "name": .string("Country_\(i)"),
        "code": .string(String(format: "C%02d", i % 100)),
        "population": .int(Int64(1_000_000 + i * 500_000)),
        "gdp_trillion": .float(Double(i) * 0.5),
        "regions": .array(regions)
    ])
    let s = try encodeTyped(c)
    let j = jsonEncode(c)
    let b = try encodeBinary(c)
    let c2 = try decode(s)
    assert(c2 == c, "text roundtrip failed for country \(i)")
    let c3 = try decodeBinary(b)
    assert(c3 == c, "bin roundtrip failed for country \(i)")
    totalAsonBytes += s.utf8.count
    totalJsonBytes += j.count
    totalBinBytes += b.count
}
print("   100 records with nested regions:")
print(String(format: "   Total ASON text: %d bytes (%.1f KB)", totalAsonBytes, Double(totalAsonBytes) / 1024.0))
print(String(format: "   Total ASON bin:  %d bytes (%.1f KB)", totalBinBytes, Double(totalBinBytes) / 1024.0))
print(String(format: "   Total JSON:      %d bytes (%.1f KB)", totalJsonBytes, Double(totalJsonBytes) / 1024.0))
print(String(format: "   TEXT vs JSON: %.0f%% smaller | BIN vs JSON: %.0f%% smaller",
    (1.0 - Double(totalAsonBytes) / Double(totalJsonBytes)) * 100.0,
    (1.0 - Double(totalBinBytes) / Double(totalJsonBytes)) * 100.0))
print("   ✓ all 100 records roundtrip OK (text + bin)")

// ===========================================================================
// 9. Typed serialization (encodeTyped)
// ===========================================================================
print("\n9. Typed serialization (encodeTyped):")
let empTyped = try encodeTyped(emp)
print("   nested struct: \(empTyped)")
let empTypedBack = try decode(empTyped)
assert(empTypedBack == emp)
print("   ✓ typed nested struct roundtrip OK")

let configTyped = try encodeTyped(config)
let configTypedPrefix = String(configTyped.prefix(100))
print("   config (\(configTyped.utf8.count) bytes): \(configTypedPrefix)...")
let configTypedBack = try decode(configTyped)
assert(configTypedBack == config)
print("   ✓ typed config roundtrip OK")

let untypedLen = configS.utf8.count
let typedLen = configTyped.utf8.count
print("   untyped schema: \(untypedLen) bytes | typed schema: \(typedLen) bytes | overhead: \(typedLen - untypedLen) bytes")

// ===========================================================================
// 10. Pretty text output
// ===========================================================================
print("\n10. Pretty text output:")
let pretty = try encodePretty(employees)
print(pretty)
let prettyBack = try decode(pretty)
assert(prettyBack == employees)
print("   ✓ pretty roundtrip OK")

let prettyTyped = try encodePrettyTyped(employees)
print("\n   typed pretty:")
print(prettyTyped)
let prettyTypedBack = try decode(prettyTyped)
assert(prettyTypedBack == employees)
print("   ✓ pretty typed roundtrip OK")

print("\n=== All complex examples passed! ===")
