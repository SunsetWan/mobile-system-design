import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var tweets: [Tweet] = []
    @Published private(set) var isLoadingFirstPage = false
    @Published private(set) var isLoadingMore = false
    @Published var errorMessage: String?

    private let repository: FeedRepository
    private let pageSize: Int

    private var nextPageToken: String?
    private var hasMore = true
    private var hasLoadedAtLeastOnce = false

    init(pageSize: Int = 20) {
        self.repository = FeedRepository()
        self.pageSize = pageSize
    }

    init(repository: FeedRepository, pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() {
        guard !hasLoadedAtLeastOnce else { return }
        Task { await loadInitial() }
    }

    func loadInitial() async {
        guard !isLoadingFirstPage else { return }

        isLoadingFirstPage = true
        errorMessage = nil
        nextPageToken = nil
        hasMore = true

        do {
            let page = try await repository.readHomeTimeline(pageSize: pageSize, pageToken: nil)
            tweets = page.items
            nextPageToken = page.nextPageToken
            hasMore = page.hasMore
            hasLoadedAtLeastOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingFirstPage = false
    }

    func refresh() async {
        hasLoadedAtLeastOnce = false
        await loadInitial()
    }

    func loadMoreIfNeeded(currentItem: Tweet) {
        guard shouldLoadMore(currentItem: currentItem) else { return }
        Task { await loadMore() }
    }

    func retry() {
        Task {
            if tweets.isEmpty {
                await loadInitial()
            } else {
                await loadMore()
            }
        }
    }

    private func shouldLoadMore(currentItem: Tweet) -> Bool {
        guard hasMore, !isLoadingFirstPage, !isLoadingMore else { return false }
        guard let currentIndex = tweets.firstIndex(where: { $0.id == currentItem.id }) else { return false }

        let thresholdOffset = 5
        let thresholdIndex = max(tweets.count - thresholdOffset, 0)
        return currentIndex >= thresholdIndex
    }

    private func loadMore() async {
        guard hasMore, !isLoadingFirstPage, !isLoadingMore else { return }

        isLoadingMore = true
        errorMessage = nil

        defer { isLoadingMore = false }

        do {
            let page = try await repository.readHomeTimeline(pageSize: pageSize, pageToken: nextPageToken)
            tweets.append(contentsOf: page.items)
            nextPageToken = page.nextPageToken
            hasMore = page.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
