import Fluent
import XCTest

public final class Tester {
	public let database: Database

    public enum Error: Swift.Error {
        case failed(String)
    }

	public init(database: Database) {
		self.database = database
	}

    public func test(_ f: () throws -> (), _ name: String) {
        do {
            try f()
        } catch {
            XCTFail("\(name) failed: \(error)")
        }
    }

    public func testAll() {
        test(testInsertAndFind, "Insert and find")
        test(testRawQuery, "Raw query")
        test(testPivotsAndRelations, "Pivots and relations")
    }
}

extension Tester {
    public func testInsertAndFind() throws {
        try Atom.prepare(database)
        Atom.database = database

        var hydrogen = Atom(id: nil, name: "Hydrogen", protons: 1, weight: 1.007)

        XCTAssertEqual(hydrogen.exists, false)
        try hydrogen.save()
        XCTAssertEqual(hydrogen.exists, true)

        guard let id = hydrogen.id else {
            XCTFail("ID not set on Atom after save.")
            return
        }

        guard let found = try Atom.find(id) else {
            throw Error.failed("Could not find Atom by id.")
        }

        XCTAssertEqual(hydrogen.id, found.id)
        XCTAssertEqual(hydrogen.name, found.name)
        XCTAssertEqual(hydrogen.protons, found.protons)
        XCTAssertEqual(hydrogen.weight, found.weight)

        try Atom.revert(database)
    }

    public func testPivotsAndRelations() throws {
        try Atom.prepare(database)
        try Compound.prepare(database)
        try Pivot<Atom, Compound>.prepare(database)

        Atom.database = database
        Compound.database = database
        Pivot<Atom, Compound>.database = database

        var hydrogen = Atom(id: nil, name: "Hydrogen", protons: 1, weight: 1.007)
        try hydrogen.save()

        var carbon = Atom(id: nil, name: "Carbon", protons: 6, weight: 12.011)
        try carbon.save()

        var oxygen = Atom(id: nil, name: "Oxygen", protons: 8, weight: 15.999)
        try oxygen.save()

        var water = Compound(id: nil, name: "Water")
        try water.save()
        var hydrogenWater = Pivot<Atom, Compound>(hydrogen, water)
        try hydrogenWater.save()
        var oxygenWater = Pivot<Atom, Compound>(oxygen, water)
        try oxygenWater.save()

        var sugar = Compound(id: nil, name: "Sugar")
        try sugar.save()
        var hydrogenSugar = Pivot<Atom, Compound>(hydrogen, sugar)
        try hydrogenSugar.save()
        var oxygenSugar = Pivot<Atom, Compound>(oxygen, sugar)
        try oxygenSugar.save()
        var carbonSugar = Pivot<Atom, Compound>(carbon, sugar)
        try carbonSugar.save()

        let hydrogenCompounds = try hydrogen.compounds().all()
        XCTAssertEqual(hydrogenCompounds.count, 2)
        XCTAssertEqual(hydrogenCompounds.first?.id?.int, water.id?.int)
        XCTAssertEqual(hydrogenCompounds.last?.id?.int, sugar.id?.int)

        let sugarAtoms = try sugar.atoms().all()
        XCTAssertEqual(sugarAtoms.count, 3)

        try Atom.revert(database)
        try Compound.revert(database)
        try Pivot<Atom, Compound>.revert(database)
    }

	public func testRawQuery() throws {
        try database.driver.raw("SELECT @@version")
	}
}
