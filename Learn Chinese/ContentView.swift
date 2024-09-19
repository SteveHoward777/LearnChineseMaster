import SwiftUI
import StoreKit

enum SerialCourseLevel: CaseIterable {
    case intermediate, upperIntermediate, advanced, mastery
    
    var range: ClosedRange<Int> {
        switch self {
        case .intermediate: return 1...10
        case .upperIntermediate: return 11...20
        case .advanced: return 21...30
        case .mastery: return 31...35
        }
    }
    
    func title(language: String) -> String {
        switch self {
        case .intermediate: return language == "Russian" ? "Средний уровень" : "Intermediate"
        case .upperIntermediate: return language == "Russian" ? "Верхний средний уровень" : "Upper Intermediate"
        case .advanced: return language == "Russian" ? "Продвинутый уровень" : "Advanced"
        case .mastery: return language == "Russian" ? "Мастер" : "Mastery"
        }
    }
}

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @Published var myProducts: [SKProduct] = []
    @Published var isPurchased = false
    @Published var subscriptionMessage: String? = nil
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        checkSubscriptionStatus()
    }
    
    func getProducts(productIDs: [String]) {
        print("Fetching products...")
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.myProducts = response.products
            print("Products fetched: \(self.myProducts)")
        }
    }
    
    func purchaseProduct(product: SKProduct) {
        print("Purchasing product: \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                DispatchQueue.main.async {
                    self.isPurchased = true
                    print("Transaction successful: \(transaction.payment.productIdentifier)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError {
                    print("Payment failed: \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    func verifyReceipt() {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            print("Receipt URL not found.")
            return
        }
        
        guard let receipt = try? Data(contentsOf: receiptURL) else {
            print("Receipt data not found.")
            return
        }
        
        let receiptData = receipt.base64EncodedString(options: [])
        print("Receipt data: \(receiptData)")
        
        // For simplicity, we're doing a local check. In a production app, send this to your server.
        self.isPurchased = receiptData.contains("com.learnchinese.flashcards.basic1")
        
        // Save the purchase status locally
        UserDefaults.standard.set(self.isPurchased, forKey: "isPurchased")
        print("Receipt verification status: \(self.isPurchased)")
    }

    func checkSubscriptionStatus() {
        self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
        print("Subscription status: \(self.isPurchased)")
    }
    
    func cancelSubscription() {
        openManageSubscriptions()
    }

    func openManageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var showPinyin = true
    @State private var showChinese = true
    @State private var showTranslation = true
    @State private var showLessonButtons = true
    @State private var flashcards: [Flashcard] = FlashcardManager.getFlashcards(for: 1)
    @State private var currentLesson = 1
    @State private var language = UserDefaults.standard.string(forKey: "language") ?? "English"
    @State private var selectedTab = "Serial Course"
    @State private var phrasesToLearn: [Flashcard] = []
    @StateObject private var storeManager = StoreManager()
    @State private var showSubscriptionScreen = false

    var body: some View {
        ZStack {
            VideoBackgroundView()
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Picker("Select Mode", selection: $selectedTab) {
                    Text("Serial Course")
                        .tag("Serial Course")
                        .background(Color.white)
                    Text("Repetition Training")
                        .tag("Repetition Training")
                        .background(Color.gray.opacity(0.5))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedTab) { _ in
                    showLessonButtons = true
                    currentIndex = 0
                    if selectedTab == "Serial Course" {
                        flashcards = []
                    }
                }

                if selectedTab == "Serial Course" {
                    SerialCourseView(
                        language: $language,
                        showLessonButtons: $showLessonButtons,
                        flashcards: $flashcards,
                        currentIndex: $currentIndex,
                        currentLesson: $currentLesson,
                        showPinyin: $showPinyin,
                        showChinese: $showChinese,
                        showTranslation: $showTranslation,
                        phrasesToLearn: $phrasesToLearn,
                        storeManager: storeManager,
                        showSubscriptionScreen: $showSubscriptionScreen
                    )
                } else {
                    RepetitionTrainingView(
                        language: $language,
                        phrasesToLearn: $phrasesToLearn,
                        storeManager: storeManager,
                        showSubscriptionScreen: $showSubscriptionScreen
                    )
                }
                Spacer()
            }
            .navigationBarTitle("Immersive Chinese", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleLanguage()
                    }) {
                        Text(language)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.blue.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                }
            }
            .onAppear {
                storeManager.getProducts(productIDs: ["com.learnchinese.flashcards.basic1", "com.learnchinese.flashcards.basic3"])
                SKPaymentQueue.default().add(storeManager)
                storeManager.checkSubscriptionStatus()
            }
            
            if showSubscriptionScreen {
                SubscriptionView(storeManager: storeManager, showSubscriptionScreen: $showSubscriptionScreen)
                    .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
            }
        }
    }

    func toggleLanguage() {
        language = (language == "Russian") ? "English" : "Russian"
        UserDefaults.standard.set(language, forKey: "language")
    }
}

struct SubscriptionView: View {
    @ObservedObject var storeManager: StoreManager
    @Binding var showSubscriptionScreen: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                Text("Subscription Options")
                    .font(.title)
                    .padding(.top, 10)

                Text("(Unlock lessons from lesson 11 to lesson 35)")
                    .font(.subheadline)
                    .padding(.bottom, 10)

                Text("One Month Subscription: $1.99\nOne Year Subscription: $19.99\nSubscriptions automatically renew unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple ID account settings at any time.")
                    .font(.footnote)
                    .padding(.bottom, 10)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 10) {
                    HStack {
                        Text("One Month Subscription,\n1.99$")
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button(action: {
                            if let product = storeManager.myProducts.first(where: { $0.productIdentifier == "com.learnchinese.flashcards.basic1" }) {
                                storeManager.purchaseProduct(product: product)
                            }
                        }) {
                            Text("Subscribe")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    HStack {
                        Text("One Year Subscription,\n19.99$")
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button(action: {
                            if let product = storeManager.myProducts.first(where: { $0.productIdentifier == "com.learnchinese.flashcards.basic3" }) {
                                storeManager.purchaseProduct(product: product)
                            }
                        }) {
                            Text("Subscribe")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                HStack {
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.blue)
                    Spacer()
                    Link("Privacy Policy", destination: URL(string: "https://genesiskmd.wixsite.com/privacypolicy")!)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                Button(action: {
                    storeManager.restorePurchases()
                }) {
                    Text("Restore Purchases")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.vertical, 10)

                Button(action: {
                    showSubscriptionScreen = false
                }) {
                    Text("Close")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 10)
            }
            .background(Color.gray)
            .cornerRadius(20)
            .shadow(radius: 10)
            .frame(width: 350, height: 300)
        }
    }
}

// Extension to chunk array into smaller arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct SerialCourseView: View {
    @Binding var language: String
    @Binding var showLessonButtons: Bool
    @Binding var flashcards: [Flashcard]
    @Binding var currentIndex: Int
    @Binding var currentLesson: Int
    @Binding var showPinyin: Bool
    @Binding var showChinese: Bool
    @Binding var showTranslation: Bool
    @Binding var phrasesToLearn: [Flashcard]
    @ObservedObject var storeManager: StoreManager
    @Binding var showSubscriptionScreen: Bool
    
    @State private var totalPhrases = 0
    @State private var correctCounter = 0
    @State private var incorrectCounter = 0
    @State private var progressGreen: CGFloat = 0.0
    @State private var progressRed: CGFloat = 0.0
    @State private var answers: [Bool] = []

    var body: some View {
        if showLessonButtons {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(SerialCourseLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading, spacing: 15) {
                            Text(level.title(language: language))
                                .font(.headline)
                                .foregroundColor(.white)
                            ForEach(Array(level.range).chunked(into: 2), id: \.self) { row in
                                HStack(spacing: 20) {
                                    ForEach(row, id: \.self) { lesson in
                                        Button(action: {
                                            if lesson > 10 && !storeManager.isPurchased {
                                                showSubscriptionScreen = true
                                            } else {
                                                loadFlashcards(for: lesson)
                                            }
                                        }) {
                                            Text(getLessonTitle(for: lesson, language: language))
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .padding()
                                                .background(lesson > 10 && !storeManager.isPurchased ? Color.gray.opacity(0.6) : Color.blue.opacity(0.6))
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                                .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Button(action: {
                        storeManager.restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.green.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                    Button(action: {
                        storeManager.cancelSubscription()
                    }) {
                        Text("Cancel Subscription")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.red.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                    if let message = storeManager.subscriptionMessage {
                        Text(message)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        } else {
            VStack {
                HStack {
                    Button(action: {
                        showLessonButtons = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text(language == "Russian" ? "Назад" : "Back")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .padding()
                        .background(Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                    Spacer()
                    Button(action: {
                        toggleLanguage()
                    }) {
                        Text(language)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding()
                            .background(Color.blue.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)
                    }
                }
                .padding()
                
                VStack {
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
                    .padding(.bottom, 5)
                    
                    Divider()
                    
                    HStack {
                        ProgressBar(progressGreen: $progressGreen, progressRed: $progressRed)
                            .frame(height: 20)
                        Text("\(Int((progressGreen + progressRed) * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.leading, 10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    RectangleView(showText: $showPinyin, text: flashcards[currentIndex].pinyin, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть Пиньинь" : "Tap to see Pinyin", height: 80, fontSize: 30)
                    RectangleView(showText: $showChinese, text: flashcards[currentIndex].chinese, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть китайские иероглифы" : "Tap to see Chinese characters", height: 80, fontSize: 30)
                    RectangleView(showText: $showTranslation, text: language == "Russian" ? flashcards[currentIndex].russian : flashcards[currentIndex].english, placeholder: language == "Russian" ? "Нажмите, чтобы увидеть перевод на русский" : "Tap to see English translation", height: 80, fontSize: 30)
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
                    }
                    .padding()
                }
                .padding()
            }
        }
    }
    
    func getLessonTitle(for lesson: Int, language: String) -> String {
        return language == "Russian" ? "Урок \(lesson)" : "Lesson \(lesson)"
    }
    
    func toggleLanguage() {
        language = (language == "Russian") ? "English" : "Russian"
        UserDefaults.standard.set(language, forKey: "language")
    }
    
    func loadFlashcards(for lesson: Int) {
        let newFlashcards = FlashcardManager.getFlashcards(for: lesson)
        if !newFlashcards.isEmpty {
            showLessonButtons = false
            flashcards = newFlashcards
            currentIndex = 0
            currentLesson = lesson
            totalPhrases = newFlashcards.count
            correctCounter = 0
            incorrectCounter = 0
            progressGreen = 0.0
            progressRed = 0.0
            answers = []
        } else {
            print("No flashcards found for lesson \(lesson).")
        }
    }
    
    func handleDontAction() {
        if totalPhrases > 0 {
            phrasesToLearn.append(flashcards[currentIndex])
            incorrectCounter += 1
            totalPhrases -= 1
            currentIndex = (currentIndex + 1) % flashcards.count
            answers.append(false)
            updateProgress()
        }
    }
    
    func handleKnowAction() {
        if totalPhrases > 0 {
            correctCounter += 1
            totalPhrases -= 1
            currentIndex = (currentIndex + 1) % flashcards.count
            answers.append(true)
            updateProgress()
        }
    }
    
    func updateProgress() {
        let total = correctCounter + incorrectCounter
        let increment = 1.0 / CGFloat(flashcards.count)
        progressGreen = CGFloat(answers.filter { $0 }.count) * increment
        progressRed = CGFloat(answers.filter { !$0 }.count) * increment
        
        if total == flashcards.count {
            answers.sort { $0 && !$1 }
            progressGreen = CGFloat(answers.filter { $0 }.count) * increment
            progressRed = CGFloat(answers.filter { !$0 }.count) * increment
        }
    }
}

struct ProgressBar: View {
    @Binding var progressGreen: CGFloat
    @Binding var progressRed: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                HStack(spacing: 0) {
                    Rectangle().frame(width: geometry.size.width * progressGreen, height: geometry.size.height)
                        .foregroundColor(Color.green)
                    Rectangle().frame(width: geometry.size.width * progressRed, height: geometry.size.height)
                        .foregroundColor(Color.red)
                }
            }
            .cornerRadius(45.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



