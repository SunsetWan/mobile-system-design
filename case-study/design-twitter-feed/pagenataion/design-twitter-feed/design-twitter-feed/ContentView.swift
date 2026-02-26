//
//  ContentView.swift
//  design-twitter-feed
//
//  Created by Sunset on 26/2/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingFirstPage && viewModel.tweets.isEmpty {
                    ProgressView("Loading home timeline...")
                } else {
                    List {
                        ForEach(viewModel.tweets) { tweet in
                            TweetRowView(tweet: tweet)
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentItem: tweet)
                                }
                        }

                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView("Loading more...")
                                Spacer()
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Load failed")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Button("Retry") {
                                    viewModel.retry()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Home Feed")
            .task {
                viewModel.loadInitialIfNeeded()
            }
        }
    }
}

private struct TweetRowView: View {
    let tweet: Tweet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("@\(tweet.author)")
                    .font(.headline)
                Spacer()
                Text(tweet.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(tweet.text)
                .font(.body)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
