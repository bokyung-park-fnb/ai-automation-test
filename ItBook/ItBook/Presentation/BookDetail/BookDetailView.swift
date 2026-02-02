import SwiftUI

struct BookDetailView: View {
    @ObservedObject var viewModel: BookDetailViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if let book = viewModel.bookDetail {
                contentView(book: book)
            } else {
                emptyView
            }
        }
        .navigationTitle("도서 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                favoriteButton
            }
        }
        .onAppear {
            viewModel.loadBookDetail()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
            Button("다시 시도") {
                viewModel.loadBookDetail()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        Text("도서 정보를 불러올 수 없습니다")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func contentView(book: BookDetail) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 이미지
                bookImageSection(book: book)

                // 기본 정보
                bookInfoSection(book: book)

                // 상세 정보
                bookDetailSection(book: book)

                // 설명
                if !book.desc.isEmpty {
                    descriptionSection(book: book)
                }

                // PDF 다운로드 (있는 경우)
                if let pdf = book.pdf, !pdf.isEmpty {
                    pdfSection(pdf: pdf)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func bookImageSection(book: BookDetail) -> some View {
        AsyncImage(url: URL(string: book.imageURL)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 280)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private func bookInfoSection(book: BookDetail) -> some View {
        VStack(spacing: 8) {
            Text(book.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if !book.subtitle.isEmpty {
                Text(book.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(book.price)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .padding(.top, 4)

            if !book.rating.isEmpty, book.rating != "0" {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < (Int(book.rating) ?? 0) ? "star.fill" : "star")
                            .foregroundStyle(.orange)
                    }
                    Text("(\(book.rating))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bookDetailSection(book: BookDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("도서 정보")
                .font(.headline)

            DetailRow(title: "저자", value: book.authors)
            DetailRow(title: "출판사", value: book.publisher)
            DetailRow(title: "출판연도", value: book.year)
            DetailRow(title: "페이지", value: book.pages)
            DetailRow(title: "ISBN-10", value: book.isbn10)
            DetailRow(title: "ISBN-13", value: book.isbn13)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func descriptionSection(book: BookDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("설명")
                .font(.headline)

            Text(book.desc)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func pdfSection(pdf: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PDF 샘플")
                .font(.headline)

            ForEach(Array(pdf.keys.sorted()), id: \.self) { key in
                if let urlString = pdf[key], let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(key)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var favoriteButton: some View {
        Button(action: {
            viewModel.toggleFavorite()
        }) {
            Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                .foregroundStyle(viewModel.isFavorite ? .yellow : .gray)
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(isbn13: "9781617294136"))
    }
}
