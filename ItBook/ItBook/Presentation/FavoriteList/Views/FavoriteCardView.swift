import SwiftUI

struct FavoriteCardView: View {
    let book: FavoriteBook
    let onFavoriteTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 도서 이미지
            AsyncImage(url: URL(string: book.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 110)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            // 도서 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if !book.subtitle.isEmpty {
                    Text(book.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !book.authors.isEmpty {
                    Text(book.authors)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack {
                    Text(book.price)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)

                    Spacer()

                    if let rating = book.rating, !rating.isEmpty, rating != "0" {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(rating)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 즐겨찾기 버튼 (항상 활성화 상태)
            Button(action: onFavoriteTap) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        FavoriteCardView(
            book: FavoriteBook(
                isbn13: "9781234567890",
                title: "Swift Programming",
                subtitle: "The Big Nerd Ranch Guide",
                authors: "Matthew Mathias",
                publisher: "Big Nerd Ranch",
                imageURL: "https://itbook.store/img/books/9781617294136.png",
                price: "$39.99",
                year: "2020",
                rating: "4"
            ),
            onFavoriteTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
