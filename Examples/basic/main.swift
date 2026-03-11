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
// Main
// ===========================================================================

print("=== ASON Basic Examples ===\n")

// 1. Serialize a single struct
let user: AsonValue = .object([
    "id": .int(1),
    "name": .string("Alice"),
    "active": .bool(true)
])

let asonStr = try encode(user)
print("1. Serialize single struct:")
print("   \(asonStr)\n")

// 2. Serialize with type annotations (encodeTyped)
let typedStr = try encodeTyped(user)
print("2. Serialize with type annotations:")
print("   \(typedStr)\n")

// 3. Deserialize from ASON (accepts both annotated and unannotated)
let input3 = "{id:int,name:str,active:bool}:(1,Alice,true)"
let user3 = try decode(input3)
print("3. Deserialize single struct:")
print("   \(user3)\n")

// 4. Serialize a vec of structs (schema-driven)
let users: AsonValue = .array([
    .object(["id": .int(1), "name": .string("Alice"), "active": .bool(true)]),
    .object(["id": .int(2), "name": .string("Bob"), "active": .bool(false)]),
    .object(["id": .int(3), "name": .string("Carol Smith"), "active": .bool(true)])
])

let asonVec = try encode(users)
print("4. Serialize vec (schema-driven):")
print("   \(asonVec)\n")

// 5. Serialize vec with type annotations (encodeTyped)
let typedVec = try encodeTyped(users)
print("5. Serialize vec with type annotations:")
print("   \(typedVec)\n")

// 6. Deserialize vec
let input6 = "[{id:int,name:str,active:bool}]:(1,Alice,true),(2,Bob,false),(3,\"Carol Smith\",true)"
let users6 = try decode(input6)
print("6. Deserialize vec:")
if case .array(let arr) = users6 {
    for u in arr { print("   \(u)") }
}

// 7. Multiline format
print("\n7. Multiline format:")
let multiline = """
[{id:int, name:str, active:bool}]:
  (1, Alice, true),
  (2, Bob, false),
  (3, "Carol Smith", true)
"""
let users7 = try decode(multiline)
if case .array(let arr) = users7 {
    for u in arr { print("   \(u)") }
}

// 8. Roundtrip (ASON-text + ASON-bin + JSON)
print("\n8. Roundtrip (ASON-text vs ASON-bin vs JSON):")
let original: AsonValue = .object([
    "id": .int(42),
    "name": .string("Test User"),
    "active": .bool(true)
])
let asonText = try encode(original)
let fromAson = try decode(asonText)
assert(fromAson == original, "ASON text roundtrip failed")

let asonBin = try encodeBinary(original)
let fromBin = try decodeBinary(asonBin)
assert(fromBin == original, "ASON binary roundtrip failed")

let jsonData = jsonEncode(original)
print("   original:     \(original)")
print("   ASON text:    \(asonText) (\(asonText.utf8.count) B)")
print("   ASON binary:  \(asonBin.count) B")
print("   JSON:         \(String(data: jsonData, encoding: .utf8)!) (\(jsonData.count) B)")
print("   ✓ all 3 formats roundtrip OK")

// 9. Vec roundtrip (ASON-text + ASON-bin + JSON)
print("\n9. Vec roundtrip (ASON-text vs ASON-bin vs JSON):")
let vecAson = try encode(users)
let vecBin = try encodeBinary(users)
let vecJson = jsonEncode(users)
let v1 = try decode(vecAson)
let v2 = try decodeBinary(vecBin)
assert(v1 == users, "vec text roundtrip failed")
assert(v2 == users, "vec bin roundtrip failed")
print("   ASON text:   \(vecAson.utf8.count) B")
print("   ASON binary: \(vecBin.count) B")
print("   JSON:        \(vecJson.count) B")
let saving = (1.0 - Double(vecBin.count) / Double(vecJson.count)) * 100.0
print(String(format: "   BIN vs JSON: %.0f%% smaller", saving))
print("   ✓ vec roundtrip OK (all 3 formats)")

// 10. Optional fields
print("\n10. Optional fields:")
let input10a = "{id:int,label:str}:(1,hello)"
let item10a = try decode(input10a)
print("   with value: \(item10a)")

let input10b = "{id:int,label:str?}:(2,)"
let item10b = try decode(input10b)
print("   with null:  \(item10b)")

// 11. Array fields
print("\n11. Array fields:")
let input11 = "{name:str,tags:[str]}:(Alice,[rust,go,python])"
let t11 = try decode(input11)
print("   \(t11)")

// 12. Comments
print("\n12. With comments:")
let input12 = "/* user list */ {id:int,name:str,active:bool}:(1,Alice,true)"
let user12 = try decode(input12)
print("   \(user12)")

print("\n=== All examples passed! ===")
