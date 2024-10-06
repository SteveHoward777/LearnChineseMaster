import SwiftUI

struct RepetitionTrainingView: View {
    @State private var fromLesson = 1
    @State private var toLesson = 1
    @State private var showFromLessonPicker = false
    @State private var showToLessonPicker = false
    @State private var positionMultiplier: CGFloat = 0.44 // Set this value to control the vertical position
    @State private var currentFlashcard: Flashcard? = FlashcardManager.getFlashcards(for: 1).randomElement() // Initialize with a random flashcard
    @State private var flashcards: [Flashcard] = FlashcardManager.getFlashcards(for: 1)
    @State private var shownFlashcards: [Flashcard] = [] // Track shown flashcards
    @Binding var language: String // Binding for language state
    @Binding var phrasesToLearn: [Flashcard] // Shared state for phrases to learn
    @ObservedObject var storeManager: StoreManager
    @Binding var showSubscriptionScreen: Bool
    @State private var showPinyin = true
    @State private var showChinese = true
    @State private var showTranslation = true
    
    // New state variables for counters
    @State private var totalPhrases = 0
    @State private var correctCounter = 0
    @State private var incorrectCounter = 0
    @State private var isReviewing = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack {
                    HStack {
                        Text(language == "Russian" ? "С:" : "From:")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                        Button(action: {
                            showFromLessonPicker.toggle()
                        }) {
                            Text(language == "Russian" ? "Урок \(fromLesson)" : "Lesson \(fromLesson)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding()
                                .background(Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                        }
                        .actionSheet(isPresented: $showFromLessonPicker) {
                            ActionSheet(title: Text(language == "Russian" ? "Выбрать урок" : "Select From Lesson"), buttons: lessonButtons(selection: $fromLesson))
                        }
                        
                        Text(language == "Russian" ? "До:" : "To:")
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .padding(.leading)
                            .foregroundColor(.white)
                        Button(action: {
                            showToLessonPicker.toggle()
                        }) {
                            Text(language == "Russian" ? "Урок \(toLesson)" : "Lesson \(toLesson)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding()
                                .background(Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                        }
                        .actionSheet(isPresented: $showToLessonPicker) {
                            ActionSheet(title: Text(language == "Russian" ? "Выбрать урок" : "Select To Lesson"), buttons: lessonButtons(selection: $toLesson))
                        }
                    }
                    .padding()
                    
                    HStack {
                        Text(language == "Russian" ? "Всего фраз: \(totalPhrases)" : "Total phrases: \(totalPhrases)")
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                        
                        Text("\(correctCounter)")
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                        
                        Text("\(incorrectCounter)")
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    HStack {
                        Text(language == "Russian" ? "Фраз для изучения: \(phrasesToLearn.count)" : "Phrases to learn: \(phrasesToLearn.count)")
                            .font(.system(size: 23.4, weight: .regular, design: .rounded))
                            .padding(.leading, 10)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            startReview()
                        }) {
                            Text(language == "Russian" ? "Обзор" : "Review")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .padding()
                                .background(Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                        }
                        .padding(.trailing, 10)
                    }
                    
                    if let flashcard = currentFlashcard {
                        VStack {
                            RectangleView(showText: $showPinyin, text: flashcard.pinyin, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть Пиньинь"  : "Tap to see Pinyin", height: 80, fontSize: 25)
                            RectangleView(showText: $showChinese, text: flashcard.chinese, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть китайские иероглифы" : "Tap to see Chinese characters", height: 80, fontSize: 25)
                            RectangleView(showText: $showTranslation, text: language == "Russian" ? flashcard.russian : flashcard.english, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть перевод на русский" : "Tap to see English translation ", height: 80, fontSize: 25)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.6), radius: 10, x: 5, y: 5)
                        .padding()
                    }
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .position(x: geometry.size.width / 2, y: geometry.size.height * positionMultiplier)
                
                Spacer()
                
                HStack {
                    Button(action: {
                        handleDontAction()
                    }) {
                        Text(language == "Russian" ? "Не знаю" : "Don't")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.red.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        handleKnowAction()
                    }) {
                        Text(language == "Russian" ? "Знаю" : "Know")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.green.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                    .padding(.trailing, 20)
                }
            }
        }
        .onAppear {
            totalPhrases = flashcards.count
        }
        .navigationBarTitle("Immersive Chinese", displayMode: .inline)
    }
    
    private func lessonButtons(selection: Binding<Int>) -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = (1...35).map { lesson in
            .default(Text(language == "Russian" ? "Урок \(lesson)" : "Lesson \(lesson)")) {
                if lesson > 10 && !storeManager.isPurchased {
                    showSubscriptionScreen = true
                } else {
                    selection.wrappedValue = lesson
                    updateFlashcards()
                }
            }
        }
        buttons.append(.cancel())
        return buttons
    }
    
    private func updateFlashcards() {
        isReviewing = false
        if fromLesson <= toLesson {
            flashcards = FlashcardManager.getFlashcards(from: fromLesson, to: toLesson)
            shownFlashcards.removeAll()
            showNextFlashcard()
            totalPhrases = flashcards.count
        } else {
            flashcards = []
            shownFlashcards.removeAll()
            currentFlashcard = nil
            totalPhrases = 0
        }
        correctCounter = 0
        incorrectCounter = 0
    }
    
    private func showNextFlashcard() {
        if isReviewing {
            if !phrasesToLearn.isEmpty {
                currentFlashcard = phrasesToLearn.randomElement()
            } else {
                currentFlashcard = nil
            }
        } else {
            if shownFlashcards.count == flashcards.count {
                shownFlashcards.removeAll()
            }
            let remainingFlashcards = flashcards.filter { flashcard in
                !shownFlashcards.contains { $0.id == flashcard.id }
            }
            currentFlashcard = remainingFlashcards.randomElement()
            if let current = currentFlashcard {
                shownFlashcards.append(current)
            }
        }
    }
    
    private func startReview() {
        isReviewing = true
        showNextFlashcard()
    }
    
    private func handleDontAction() {
        if isReviewing {
            showNextFlashcard()
        } else {
            if totalPhrases > 0 {
                totalPhrases -= 1
                incorrectCounter += 1
                phrasesToLearn.append(currentFlashcard!)
                showNextFlashcard()
            }
        }
    }
    
    private func handleKnowAction() {
        if isReviewing {
            if let flashcard = currentFlashcard, let index = phrasesToLearn.firstIndex(where: { $0.id == flashcard.id }) {
                phrasesToLearn.remove(at: index)
                showNextFlashcard()
            }
        } else {
            if totalPhrases > 0 {
                totalPhrases -= 1
                correctCounter += 1
                showNextFlashcard()
            }
        }
    }
}

struct RectangleView: View {
    @Binding var showText: Bool
    let text: String
    let placeholder: String
    var height: CGFloat = 60
    var fontSize: CGFloat = 21

    var body: some View {
        Text(showText ? text : placeholder)
            .frame(maxWidth: .infinity)
            .frame(minHeight: height, maxHeight: .infinity)
            .font(.system(size: fontSize))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
            .foregroundColor(.white)
            .lineLimit(nil)
            .multilineTextAlignment(.center)
            .onTapGesture {
                showText.toggle()
            }
    }
}

struct RepetitionTrainingView_Previews: PreviewProvider {
    static var previews: some View {
        RepetitionTrainingView(language: .constant("English"), phrasesToLearn: .constant([]), storeManager: StoreManager(), showSubscriptionScreen: .constant(false))
    }
}
