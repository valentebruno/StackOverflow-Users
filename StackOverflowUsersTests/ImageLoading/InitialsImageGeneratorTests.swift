import XCTest
@testable import StackOverflowUsers

// MARK: - InitialsImageGeneratorTests

final class InitialsImageGeneratorTests: XCTestCase {

    // MARK: - Output shape

    func test_image_returnsImageOfRequestedSize() {
        let size = CGSize(width: 60, height: 60)
        let image = InitialsImageGenerator.image(for: "Jon Skeet", size: size)
        XCTAssertEqual(image.size, size)
    }

    // MARK: - Determinism

    func test_image_forSameName_producesEquivalentPixelData() {
        let first  = InitialsImageGenerator.image(for: "Jon Skeet")
        let second = InitialsImageGenerator.image(for: "Jon Skeet")
        XCTAssertEqual(first.pngData(), second.pngData())
    }

    func test_image_forDifferentNames_producesDifferentColors() {
        let annaPNG = InitialsImageGenerator.image(for: "Anna").pngData()
        let bobPNG  = InitialsImageGenerator.image(for: "Bob").pngData()
        XCTAssertNotEqual(annaPNG, bobPNG)
    }

    // MARK: - Edge cases

    func test_image_forEmptyName_fallsBackToQuestionMark() {
        let empty = InitialsImageGenerator.image(for: "")
        let whitespace = InitialsImageGenerator.image(for: "   ")
        XCTAssertEqual(empty.pngData(), whitespace.pngData())
    }
}
