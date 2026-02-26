import Foundation

struct FeedRepository {
    private let apiClient: TimelineAPIClient
    private let userToken: String

    init(apiClient: TimelineAPIClient = MockTimelineAPIClient(), userToken: String = "demo_user_token") {
        self.apiClient = apiClient
        self.userToken = userToken
    }

    func readHomeTimeline(pageSize: Int = 20, pageToken: String?) async throws -> HomeTimelinePage {
        try await apiClient.readHomeTimeline(userToken: userToken, pageSize: pageSize, pageToken: pageToken)
    }
}
