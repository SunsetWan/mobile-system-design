import Foundation

struct Tweet: Identifiable, Equatable {
    let id: String
    let author: String
    let text: String
    let createdAt: Date
}

struct HomeTimelinePage {
    let items: [Tweet]
    let nextPageToken: String?
    let hasMore: Bool
}
