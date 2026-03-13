import Foundation

package final class VSKClientObject: PrivateObject {
    let base: AnyObject

    package init(config: VSKConfigObject) throws {
        try FrameworkLoader.loadVectorSearch()

        let cls: AnyClass = try Self.requiredClass(named: "VSKClient")
        let rawObject = try Self.allocateObject(of: cls, className: "VSKClient")

        guard
            let initialize = VSKClientObject(base: rawObject).objcInstanceMethod(
                selector: Self.initSelector,
                as: VSKClientInitMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing -initWithConfig:error: on VSKClient") }

        var errorObject: AnyObject?
        guard let object = initialize(rawObject, Self.initSelector, config.base, &errorObject) else {
            throw BridgeError(.operationFailed, "Failed to create VSKClient", underlyingError: errorObject as? Error)
        }

        if let errorObject = errorObject as? Error {
            throw BridgeError(
                .operationFailed,
                "VSKClient initialization reported an error",
                underlyingError: errorObject
            )
        }

        self.base = object
    }

    init(base: AnyObject) { self.base = base }

    package func search(
        vector: Data,
        stringIdentifiers: [String]?,
        attributeFilters: [VSKFilterObject],
        selectAttributes: [VSKAttributeObject],
        limit: Int,
        fullScan: Bool,
        numberOfProbes: Int,
        batchSize: Int,
        numConcurrentReaders: Int
    ) throws -> [VSKSearchResultObject] {
        guard let method = objcInstanceMethod(selector: Self.searchByVectorSelector, as: VSKSearchByVectorMethod.self)
        else { throw BridgeError(.selectorUnavailable, "Missing search selector on VSKClient") }

        var errorObject: AnyObject?
        let resultsObject = method(
            base,
            Self.searchByVectorSelector,
            vector as NSData,
            stringIdentifiers?.map { $0 as NSString } as NSArray?,
            attributeFilters.isEmpty ? nil : attributeFilters.map(\.base) as NSArray,
            selectAttributes.isEmpty ? nil : selectAttributes.map(\.base) as NSArray,
            Int32(limit),
            fullScan,
            false,
            NSNumber(value: numberOfProbes),
            NSNumber(value: batchSize),
            NSNumber(value: numConcurrentReaders),
            &errorObject
        )

        if let errorObject = errorObject as? Error {
            throw BridgeError(.searchFailed, "Vector search failed", underlyingError: errorObject)
        }

        guard let results = resultsObject as? [AnyObject] else {
            throw BridgeError(.invalidResponse, "Vector search returned an unexpected response")
        }

        return results.map(VSKSearchResultObject.init(base:))
    }

    package func stringIdentifiedAssets(
        identifiers: [String],
        attributeFilters: [VSKFilterObject],
        includeVectors: Bool,
        selectAttributes: [VSKAttributeObject]
    ) throws -> [VSKAssetObject] {
        guard
            let method = objcInstanceMethod(
                selector: Self.stringIdentifiedAssetsSelector,
                as: VSKStringIdentifiedAssetsMethod.self
            )
        else { throw BridgeError(.selectorUnavailable, "Missing stringIdentifiedAssets selector on VSKClient") }

        var errorObject: AnyObject?
        let assetsObject = method(
            base,
            Self.stringIdentifiedAssetsSelector,
            identifiers.map { $0 as NSString } as NSArray,
            attributeFilters.isEmpty ? nil : attributeFilters.map(\.base) as NSArray,
            nil,
            includeVectors,
            selectAttributes.isEmpty ? nil : selectAttributes.map(\.base) as NSArray,
            &errorObject
        )

        if let errorObject = errorObject as? Error {
            throw BridgeError(.searchFailed, "Asset lookup failed", underlyingError: errorObject)
        }

        guard let assets = assetsObject as? [AnyObject] else {
            throw BridgeError(.invalidResponse, "Asset lookup returned an unexpected response")
        }

        return assets.map(VSKAssetObject.init(base:))
    }

    package func requiredStringIdentifiedAsset(
        identifier: String,
        attributeFilters: [VSKFilterObject],
        includeVectors: Bool,
        selectAttributes: [VSKAttributeObject]
    ) throws -> VSKAssetObject {
        guard
            let asset = try stringIdentifiedAssets(
                identifiers: [identifier],
                attributeFilters: attributeFilters,
                includeVectors: includeVectors,
                selectAttributes: selectAttributes
            ).first
        else { throw BridgeError(.assetNotFound, "No documentation entry was found for \(identifier)") }

        return asset
    }

    private static let initSelector = NSSelectorFromString("initWithConfig:error:")
    private static let searchByVectorSelector = NSSelectorFromString(
        "searchByVector:stringIdentifiers:attributeFilters:selectAttributes:limit:fullScan:includePayload:numberOfProbes:batchSize:numConcurrentReaders:error:"
    )
    private static let stringIdentifiedAssetsSelector = NSSelectorFromString(
        "stringIdentifiedAssetsWithIdentifiers:attributeFilters:pagination:includeVectors:selectAttributes:error:"
    )
}

private typealias VSKClientInitMethod =
    @convention(c) (AnyObject, Selector, AnyObject, UnsafeMutablePointer<AnyObject?>?) -> AnyObject?

private typealias VSKSearchByVectorMethod =
    @convention(c) (
        AnyObject, Selector, NSData, NSArray?, NSArray?, NSArray?, Int32, Bool, Bool, NSNumber?, NSNumber?, NSNumber?,
        UnsafeMutablePointer<AnyObject?>?
    ) -> AnyObject?

private typealias VSKStringIdentifiedAssetsMethod =
    @convention(c) (
        AnyObject, Selector, NSArray, NSArray?, AnyObject?, Bool, NSArray?, UnsafeMutablePointer<AnyObject?>?
    ) -> AnyObject?
