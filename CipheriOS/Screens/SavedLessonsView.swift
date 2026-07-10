import SwiftUI

/// The learner's reading list — lessons they bookmarked from the lesson screen,
/// in curriculum order, to jump back to anytime.
struct SavedLessonsView: View {
    @EnvironmentObject private var progress: ProgressStore

    private var saved: [Lesson] { progress.savedLessons }

    var body: some View {
        ZStack {
            CircuitBackground(tint: Theme.amber)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Bookmark lessons with the ribbon icon at the top of any lesson to build a reading list you can return to.")
                        .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if saved.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bookmark.slash").font(.system(size: 34)).foregroundStyle(Theme.textDim)
                            Text("No saved lessons yet").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.textSecondary)
                            Text("Tap the bookmark icon at the top of any lesson.")
                                .font(.system(size: 12)).foregroundStyle(Theme.textDim)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 60)
                    } else {
                        Text("\(saved.count) saved").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                        ForEach(saved) { lesson in
                            let accent = Curriculum.track(forLesson: lesson.id)?.accent ?? Theme.teal
                            NavigationLink(value: CipherRoute.lesson(lesson.id)) {
                                LessonRow(lesson: lesson, completed: progress.isComplete(lesson.id), accent: accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
