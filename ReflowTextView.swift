//
//  ReflowTextView.swift
//  PDFlow
//

import SwiftUI

struct ReflowTextView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    let item: PDFItem
    let fontScale: CGFloat
    let readerMode: ReaderMode
    let horizontalMargin: CGFloat
    let lineSpacing: CGFloat

    @StateObject private var provider: PageDataProvider
    @State private var currentIndex = 0

    init(item: PDFItem,
         fontScale: CGFloat,
         readerMode: ReaderMode,
         vm: LibraryViewModel,
         horizontalMargin: CGFloat = 15.0,
         lineSpacing: CGFloat = 5.0
        )
    {
        self.item = item
        self.fontScale = fontScale
        self.readerMode = readerMode
        self.horizontalMargin = horizontalMargin
        self.lineSpacing = lineSpacing
        _provider = StateObject(wrappedValue: PageDataProvider(item: item, vm: vm))
    }

    var body: some View {
        Group {
            if !provider.initialSetupComplete {
                 ProgressView("Loading Document...")
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if let err = provider.setupError {
                EmptyContentView(message: "Error: \(err)")
            }
            else if provider.isPotentiallyUnsuitableForReflow {
                VStack(spacing: 15) {
                     Image(systemName: "doc.text.image.fill")
                          .font(.largeTitle).foregroundColor(.orange)
                     Text("Reflow Might Be Limited").font(.headline)
                     Text("This document might be image-based or have complex formatting. Text reflow may not work as expected.")
                          .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else if provider.totalPages > 0 {
                 PageViewController(
                    provider: provider,
                    current: $currentIndex,
                    fontScale: fontScale,
                    horizontalMargin: horizontalMargin,
                    lineSpacing: lineSpacing,
                    mode: readerMode
                 )
            }
            else {
                EmptyContentView(message: "This document has no pages.")
            }
        }
        .onAppear {
             let initialIndex = vm.position(for: item)
             currentIndex = initialIndex
             provider.preloadPages(around: initialIndex)
        }
        .onChange(of: currentIndex) { newIndex in
            vm.savePosition(item: item, pageIndex: newIndex)
            provider.preloadPages(around: newIndex)
            provider.evictOldPages(around: newIndex)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReaderBackground(mode: readerMode).ignoresSafeArea())
    }
}

struct EmptyContentView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
