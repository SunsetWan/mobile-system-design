import Foundation

protocol TimelineAPIClient {
    func readHomeTimeline(userToken: String, pageSize: Int, pageToken: String?) async throws -> HomeTimelinePage
}

enum TimelineAPIError: LocalizedError {
    case invalidPageToken

    var errorDescription: String? {
        switch self {
        case .invalidPageToken:
            return "Invalid page token"
        }
    }
}

struct MockTimelineAPIClient: TimelineAPIClient {
    private let allTweets: [Tweet]

    init(totalCount: Int = 120) {
        var generated: [Tweet] = []
        generated.reserveCapacity(totalCount)

        for index in 0..<totalCount {
            let idNumber = totalCount - index
            generated.append(
                Tweet(
                    id: "t_\(idNumber)",
                    author: "user\(idNumber % 7)",
                    text: "Tweet #\(idNumber): this is a mock timeline item for infinite scroll demo.",
                    createdAt: Date().addingTimeInterval(TimeInterval(-index * 73))
                )
            )
        }

        self.allTweets = generated
    }

    func readHomeTimeline(userToken: String, pageSize: Int, pageToken: String?) async throws -> HomeTimelinePage {
        try await Task.sleep(for: .seconds(2))

        let safePageSize = max(pageSize, 1)
        let startIndex = try parseStartIndex(pageToken)
        guard startIndex <= allTweets.count else { throw TimelineAPIError.invalidPageToken }

        let endIndex = min(startIndex + safePageSize, allTweets.count)
        let items = Array(allTweets[startIndex..<endIndex])
        let nextPageToken = endIndex < allTweets.count ? "cursor_\(endIndex)" : nil

        return HomeTimelinePage(
            items: items,
            nextPageToken: nextPageToken,
            hasMore: nextPageToken != nil
        )
    }

    private func parseStartIndex(_ pageToken: String?) throws -> Int {
        guard let pageToken, !pageToken.isEmpty else { return 0 }
        guard pageToken.hasPrefix("cursor_") else { throw TimelineAPIError.invalidPageToken }

        let raw = pageToken.replacingOccurrences(of: "cursor_", with: "")
        guard let value = Int(raw), value >= 0 else { throw TimelineAPIError.invalidPageToken }
        return value
    }
}
