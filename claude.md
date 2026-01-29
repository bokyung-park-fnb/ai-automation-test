# CLAUDE.md

This file provides guidance to Claude Code when working with this IT Book Search iOS application.

## Project Overview

**IT 도서 검색 앱** - IT Bookstore API를 활용한 도서 검색 및 즐겨찾기 관리 앱

- **목적**: 스터디용 iOS 앱 개발
- **API**: IT Bookstore API (https://api.itbook.store)
- **아키텍처**: Clean Architecture + MVVM
- **최소 지원 버전**: iOS 16.0+
- **Xcode 버전**: 16.2
- **언어**: Swift 5

## Tech Stack

### Core
- **Language**: Swift 5
- **UI Framework**: UIKit (Code-based UI preferred, 자유 선택 가능)
- **Minimum iOS**: 16.0+
- **Architecture**: Clean Architecture + MVVM pattern

### Libraries & Frameworks (이외는 자유 선택)
- **Networking**: URLSession
- **Reactive**: Combine
- **Image Loading**: Kingfisher
- **Local Storage**: UserDefaults / CoreData / Realm (이 중 선택)
- **Dependency Management**: Swift Package Manager

## Project Structure

```
ItBook/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Domain/
│   ├── Entities/
│   │   └── Book.swift
│   ├── UseCases/
│   │   ├── SearchBooksUseCase.swift
│   │   └── ManageFavoritesUseCase.swift
│   └── Repositories/
│       ├── BookRepositoryProtocol.swift
│       └── FavoriteRepositoryProtocol.swift
├── Data/
│   ├── Network/
│   │   ├── ITBookAPIService.swift
│   │   └── NetworkManager.swift
│   ├── Repositories/
│   │   ├── BookRepository.swift
│   │   └── FavoriteRepository.swift
│   └── Local/
│       └── FavoriteStorage.swift
├── Presentation/
│   ├── SearchList/
│   │   ├── SearchListViewController.swift
│   │   ├── SearchListViewModel.swift
│   │   └── Views/
│   │       └── BookCardCell.swift
│   ├── FavoriteList/
│   │   ├── FavoriteListViewController.swift
│   │   └── FavoriteListViewModel.swift
│   ├── BookDetail/
│   │   ├── BookDetailViewController.swift
│   │   └── BookDetailViewModel.swift
│   └── Common/
│       └── TabBarController.swift
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

## Requirements Checklist

### 1. 하단 탭바 (UITabBarController)
- [ ] 탭1: 전체 리스트 (검색 화면)
- [ ] 탭2: 즐겨찾기 리스트

### 2. 검색 리스트 화면 (탭1)
- [ ] 카드 형태 리스트 아이템 (제목, 부제목, 저자, 출판사, 가격, 이미지)
- [ ] 검색 기능 (질의어 기반, IT Bookstore API 사용)
- [ ] 새 도서 목록 보기 기능 (New Books)
- [ ] 페이징 기능 (무한 스크롤)
- [ ] 즐겨찾기 토글 버튼 (로컬 저장)
- [ ] 아이템 탭 시 상세화면 이동

### 3. 즐겨찾기 리스트 화면 (탭2)
- [ ] 검색 리스트와 동일한 카드 UI
- [ ] 로컬 검색 기능 (질의어 기반)
- [ ] 정렬 기능 (제목 오름차순/내림차순)
- [ ] 필터링 기능 (금액 필터)
- [ ] 즐겨찾기 토글 버튼
- [ ] 아이템 탭 시 상세화면 이동

### 4. 도서 상세 화면
- [ ] 도서 이미지 (큰 사이즈)
- [ ] 도서 정보 상세 표시
- [ ] 즐겨찾기 토글 버튼

## API Integration

### IT Bookstore API

**Base URL**: `https://api.itbook.store/1.0`

**No Authentication Required** - 이 API는 인증이 필요 없습니다.

#### 1. 새 도서 검색 (New Books)
**Endpoint**: `GET /new`

**Response Example**:
```json
{
  "total": "10",
  "books": [
    {
      "title": "Book Title",
      "subtitle": "Book Subtitle",
      "isbn13": "9781234567890",
      "price": "$29.99",
      "image": "https://itbook.store/img/books/...",
      "url": "https://itbook.store/books/..."
    }
  ]
}
```

#### 2. 도서 검색 (Search)
**Endpoint**: `GET /search/{query}`

**Path Parameters**:
- `query` (required): 검색어

**Optional**: Pagination with `/search/{query}/{page}`
- `page`: 페이지 번호 (기본값: 1)

**Response Example**:
```json
{
  "total": "42",
  "page": "1",
  "books": [
    {
      "title": "Swift Programming",
      "subtitle": "The Big Nerd Ranch Guide",
      "isbn13": "9780135264249",
      "price": "$39.99",
      "image": "https://itbook.store/img/books/...",
      "url": "https://itbook.store/books/..."
    }
  ]
}
```

#### 3. 도서 상세 정보 (Book Details)
**Endpoint**: `GET /books/{isbn13}`

**Path Parameters**:
- `isbn13` (required): 13자리 ISBN 번호

**Response Example**:
```json
{
  "title": "Swift Programming",
  "subtitle": "The Big Nerd Ranch Guide",
  "authors": "Matthew Mathias, John Gallagher",
  "publisher": "Big Nerd Ranch Guides",
  "isbn10": "0135264243",
  "isbn13": "9780135264249",
  "pages": "480",
  "year": "2020",
  "rating": "4",
  "desc": "Book description...",
  "price": "$39.99",
  "image": "https://itbook.store/img/books/...",
  "url": "https://itbook.store/books/...",
  "pdf": {
    "Chapter 1": "https://itbook.store/files/...",
    "Chapter 2": "https://itbook.store/files/..."
  }
}
```

### API 특징
- ✅ 인증 불필요 (No API Key)
- ✅ IT 관련 도서에 특화
- ✅ 영문 도서 중심
- ✅ 무료 사용
- ✅ Rate Limiting 없음 (합리적 사용 권장)


## Coding Conventions

### Naming
- **ViewController**: `*ViewController` (e.g., `SearchListViewController`)
- **ViewModel**: `*ViewModel` (e.g., `SearchListViewModel`)
- **UseCase**: `*UseCase` (e.g., `SearchBooksUseCase`)
- **Repository**: `*Repository` (e.g., `BookRepository`)
- **Protocol**: `*Protocol` suffix (e.g., `BookRepositoryProtocol`)
- **Cell**: `*Cell` (e.g., `BookCardCell`)

### Code Style
- Swift API Design Guidelines 준수
- 들여쓰기: 4 spaces
- 최대 줄 길이: 120자
- `guard let` 선호 (`if let` 최소화)
- Optional chaining 적극 활용

### Architecture Rules
- **Domain Layer**: 비즈니스 로직만 포함, UI/프레임워크 의존성 없음
- **Data Layer**: Repository 구현, API/로컬 저장소 접근
- **Presentation Layer**: MVVM 패턴, ViewController는 View 로직만, ViewModel에 비즈니스 로직

### Memory Management
- Closure에서 `[weak self]` 사용
- Delegate는 `weak` 선언
- Combine/RxSwift subscription 적절한 dispose 처리

## Local Storage Strategy

### 즐겨찾기 데이터 저장
- **Option 1**: UserDefaults (간단한 구현, 소량 데이터)
- **Option 2**: CoreData (복잡도 중간, 검색/정렬 용이)
- **Option 3**: Realm (간단한 사용, 강력한 쿼리)

**권장**: UserDefaults + Codable (과제 규모 고려)

### 저장 데이터 구조
```swift
struct FavoriteBook: Codable {
    let isbn13: String      // Primary Key (13자리 ISBN)
    let title: String
    let subtitle: String?
    let authors: String
    let publisher: String
    let image: String       // 이미지 URL
    let price: String       // "$39.99" 형식
    let year: String?
    let rating: String?
    let addedAt: Date       // 즐겨찾기 추가 시간
}
```

## Build & Run

### Prerequisites
- Xcode 16.2
- iOS 16.0+ Simulator
- **No API Key Required**

### Setup
1. 프로젝트 클론 또는 다운로드
2. Xcode로 프로젝트 열기
3. 시뮬레이터 선택 후 빌드 및 실행
4. IT Bookstore API는 인증 불필요

### Build Commands
```bash
# Clean build
xcodebuild clean -scheme ItBook

# Build
xcodebuild build -scheme ItBook -configuration Debug

# Run tests (if implemented)
xcodebuild test -scheme ItBook -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Development Workflow

### Git Workflow
- `main`: 안정 버전
- `develop`: 개발 브랜치
- `feature/*`: 기능별 브랜치

### Commit Convention
```
feat: 새로운 기능 추가
fix: 버그 수정
refactor: 코드 리팩토링
style: 코드 포맷팅
docs: 문서 수정
test: 테스트 추가/수정
```

## Important Notes

### 특이사항
- UI 가이드는 참고용, 디테일은 자유롭게 구현
- 프레임워크 선택 자유 (UIKit/SwiftUI)
- 의문점은 합리적인 방향으로 판단하여 진행
- 코드 품질과 아키텍처 설계에 집중

### 평가 포인트
- ✅ Clean Architecture 이해도
- ✅ MVVM 패턴 적용
- ✅ API 통합 및 에러 핸들링
- ✅ 로컬 저장소 관리
- ✅ UI/UX 완성도
- ✅ 코드 가독성 및 유지보수성

## Tips for Claude Code

### When creating new files:
- 항상 적절한 디렉토리 구조 확인
- Clean Architecture 레이어 분리 준수
- Protocol-Oriented Programming 활용
- Unit Test를 고려한 코드 작성

### When implementing features:
- API 호출은 Repository 패턴으로 추상화
- IT Bookstore API는 인증 불필요 (Authorization Header 제거)
- ISBN13을 Primary Key로 사용 (고유 식별자)
- 가격 형식: String ("$39.99") - 파싱 로직 필요
- 에러 처리 철저히 (네트워크 에러, 파싱 에러, 404 등)
- Loading/Empty/Error 상태 UI 고려
- 페이징 구현 시 중복 호출 방지
- 이미지 캐싱 전략 고려 (Kingfisher 권장)

### When refactoring:
- SOLID 원칙 준수
- 중복 코드 제거
- 테스트 가능한 코드 구조
- Dependency Injection 활용

## Current Status

- [x] 프로젝트 초기화
- [ ] 프로젝트 구조 설정
- [ ] Domain Layer 구현
- [ ] Data Layer 구현 (API + Local Storage)
- [ ] Presentation Layer 구현 (UI + ViewModel)
- [ ] 통합 테스트 및 버그 수정
- [ ] 최종 검토 및 제출

---

**Last Updated**: 2025-01-29
**Developer**: 보경 (Bokyung)
**Purpose**: iOS 앱 개발