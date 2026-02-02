import SwiftUI

struct BookCardView: View {
    let book: Book
    let isFavorite: Bool
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

                Spacer()

                Text(book.price)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 즐겨찾기 버튼
            Button(action: onFavoriteTap) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(isFavorite ? .yellow : .gray)
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
        BookCardView(
            book: Book(
                isbn13: "9781234567890",
                title: "Swift Programming",
                subtitle: "The Big Nerd Ranch Guide",
                price: "$39.99",
                imageURL: "https://itbook.store/img/books/9781617294136.png",
                url: ""
            ),
            isFavorite: false,
            onFavoriteTap: {}
        )

        BookCardView(
            book: Book(
                isbn13: "9781234567891",
                title: "iOS Development with Swift",
                subtitle: "",
                price: "$49.99",
                imageURL: "",
                url: ""
            ),
            isFavorite: true,
            onFavoriteTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
