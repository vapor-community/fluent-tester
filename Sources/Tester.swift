import Fluent
import XCTest

final class Tester {
	public let database: Database

    public enum Error: Swift.Error {
        case failed(String)
    }

	public init(database: Database) {
		self.database = database
	}

    public func testAll() {
        do {
            try testInsertAndFind()
            try testRawQuery()
        } catch {
            XCTFail("Testing failed: \(error)")
        }
    }
}

extension Tester {
    public func testInsertAndFind() throws {
        try Atom.prepare(database)

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

	public func testRawQuery() throws {
        try database.driver.raw("SELECT @@version")
	}
}
