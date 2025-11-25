import SwiftUI

struct MedicineDetailView: View {
    @StateObject var medicineDetailVM: MedicineDetailViewModel
    @EnvironmentObject var session: SessionViewModel
    @EnvironmentObject var dataStore: DataStore
    @State var medicine: Medicine
    @State var isNew: Bool = false //pr gérer l'ajout d'un médicament
    @State private var hasSavedAisle = false
    @State private var isEditingStock = false
    @State private var stockText: String = ""
    @State private var originalStock: Int = 0
    @FocusState private var isAisleFocused: Bool
    @State private var lastValidAisle: String = ""
    @FocusState private var isNameFocused: Bool
    @State private var lastValidName: String = ""
    @State private var localMedicine: Medicine // pour éviter que quand on maj aisle la liste de AisleListView se maj et qu'on sorte de la vue details
    
    init(medicine: Medicine, isNew: Bool = false) {
        self.medicine = medicine
        self._localMedicine = State(initialValue: medicine) // copie locale
        _medicineDetailVM = StateObject(wrappedValue: MedicineDetailViewModel(dataStore: DataStore.shared))
        self._isNew = State(initialValue: isNew)
        print("🏗️ INIT MedicineDetailView")

    }
   
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(localMedicine.name)
                    .font(.largeTitle)
                    .padding(.top, 20)
                    .padding(.leading, 15)

                // Medicine Name
                medicineNameSection

                // Medicine Stock
                medicineStockSection

                // Medicine Aisle
                medicineAisleSection

                // History Section
                historySection
            }
            .padding(.vertical)
        }
        .hideKeyboardOnTap()
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .onAppear {
            print("🔍 MedicineDetailView appeared")
                        print("🔍 Medicine ID: \(localMedicine.id ?? "nil")")
                        print("🔍 Medicine exists in VM: \(dataStore.medicines.contains(where: { $0.id == localMedicine.id }))")
                        print("🔍 Total medicines count: \(dataStore.medicines.count)")
            if isNew {
                medicine = Medicine(name: "", stock: 0, aisle: "")
                localMedicine = medicine
            } else {
                medicineDetailVM.fetchNextHistoryBatch(for: medicine)
            }
        }
        .onDisappear {
            saveAisleIfNeeded()
        }
        .alert(item: $medicineDetailVM.appError) { appError in
            Alert(
                title: Text("Erreur"),
                message: Text(appError.userMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.headline)
            TextField("Name", text: $localMedicine.name)
                .focused($isNameFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .accessibilityLabel("Medicine Name")
                .accessibilityHint("Enter the medicine name. Letters only, no numbers allowed")
                .onChange(of: isNameFocused) { _, focused in
                    if !focused {
                        // Vérifie si le texte contient un chiffre
                        if localMedicine.name.rangeOfCharacter(from: .decimalDigits) != nil {
                            // Contient un chiffre → revenir à la dernière valeur valide
                            localMedicine.name = lastValidName
                        } else {
                            // Pas de chiffres → sauvegarde et mise à jour de la dernière valeur valide
                            lastValidName = localMedicine.name
                            saveIfNeeded()
                        }
                    }
                }
        }
        .padding(.horizontal)
    }

    private var medicineStockSection: some View {
        VStack(alignment: .leading) {
            Text("Stock")
                .font(.headline)
            HStack {
                Button(action: {
                    Task {
                        guard !isNew else { return }
                        isEditingStock = true
                        if localMedicine.stock >= 1 {
                            let newStock = await medicineDetailVM.decreaseStock(localMedicine, user: session.session?.uid ?? "")
                            DispatchQueue.main.async {
                                //self.medicine.stock = newStock
                                originalStock = newStock  
                                stockText = "\(newStock)"
                                print("localmedicine.stock \(newStock)")
                                self.localMedicine.stock = newStock
                            }
                        }
                        if localMedicine.stock < 1 {
                            return
                        }
                        
                        isEditingStock = false
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .accessibilityLabel("Decrease stock")
                .accessibilityHint("Tap to decrease the stock by one unit")
                
                TextField("Stock", text: $stockText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 100)
                .disabled(isNew)
                .accessibilityLabel("Stock quantity")
                .accessibilityHint("Enter the current stock quantity")
                .onAppear {
                    // Récupérer le stock réel depuis le VM
                    let realStock = dataStore.medicines.first(where: { $0.id == localMedicine.id })?.stock ?? localMedicine.stock
                    originalStock = realStock
                    stockText = "\(realStock)"
                }
                .onSubmit {
                    guard let newStock = Int(stockText) else {
                        stockText = "\(originalStock)"
                        return
                    }
                    
                    if newStock < 0 {
                        stockText = "\(originalStock)"
                        return
                    }
                    
                    if newStock != originalStock {
                        let difference = newStock - originalStock
                        
                        Task {
                            let finalStock = await medicineDetailVM.updateStock(
                                localMedicine,  // ← Avec son stock d'origine
                                by: difference,
                                user: session.session?.uid ?? ""
                            )
                            
                            await MainActor.run {
                                localMedicine.stock = finalStock
                                originalStock = finalStock
                                stockText = "\(finalStock)"
                            }
                        }
                        print("Stock mis à jour de \(originalStock) à \(newStock) (différence: \(difference))")
                    }
                }
                
                Button(action: {
                    Task { 
                        guard !isNew else { return }
                        isEditingStock = true
                        let newStock = await medicineDetailVM.increaseStock(localMedicine, user: session.session?.uid ?? "")
                        DispatchQueue.main.async {
                            print("localmedicine.stock \(newStock)")
                            self.localMedicine.stock = newStock
                            originalStock = newStock
                            stockText = "\(newStock)"
                        }
                        isEditingStock = false
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title)
                        .foregroundColor(.green)
                }
                .accessibilityLabel("Increase stock")
                .accessibilityHint("Tap to increase the stock by one unit")
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal)
    }

    private var medicineAisleSection: some View {
        VStack(alignment: .leading) {
            Text("Aisle")
                .font(.headline)
            TextField("Aisle", text: $localMedicine.aisle)
                .focused($isAisleFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .disabled(localMedicine.name.isEmpty)
                .accessibilityLabel("Aisle")
                .accessibilityHint("Enter the aisle where this medicine is stored")
                .onChange(of: localMedicine.aisle) {_, newAisle in
                    if newAisle.allSatisfy({ $0.isNumber }) {
                        // Chiffres seulement → update lastValidAisle
                        lastValidAisle = newAisle
                        
                        // Si le champ n'est pas vide et ce n'est pas un nouveau médicament, on ajoute l'historique
                        if !newAisle.isEmpty && !isNew {
                            Task {
                                await medicineDetailVM.addHistory(
                                    action: "Updated \(localMedicine.name)",
                                    user: session.session?.uid ?? "Unknown user",
                                    medicineId: localMedicine.id ?? "",
                                    details: "Updated medicine details"
                                )
                            }
                        }
                    } else {
                        // Contient une lettre → revenir à la dernière valeur valide
                        localMedicine.aisle = lastValidAisle
                    }
                }
        }
        .padding(.horizontal)
    }

    private var historySection: some View {
            LazyVStack { //Lazy loading coté affichage
                Text("History")
                    .font(.headline)
                    .padding(.top, 20)
                ForEach(dataStore.history
                    .filter { $0.medicineId == localMedicine.id }
                    .sorted { $0.timestamp < $1.timestamp },
                        id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.action)
                            .font(.headline)
                        Text("User: \(medicineDetailVM.emailsCache[entry.user] ?? "Chargement...")")
                            .font(.subheadline)
                            .task {
                                _ = await medicineDetailVM.fetchEmail(for: entry.user)
                            }
                        Text("Date: \(entry.timestamp.formatted())")
                            .font(.subheadline)
                        Text("Details: \(entry.details)")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.bottom, 5)
                    .onAppear {
                        // ⚡️ Lazy loading côté données : charger batch suivant si dernier élément
                        if entry == dataStore.history.last {
                            medicineDetailVM.fetchNextHistoryBatch(for: medicine)
                        }
                    }
                }
            }
            .padding(.horizontal)            
    }
    
    private func saveIfNeeded() {
        let isValid = !localMedicine.name.isEmpty
        guard isValid else { return }
        
        if isNew {
            self.isNew = false
            Task {
                let savedMedicine = await medicineDetailVM.addMedicine(localMedicine, user: session.session?.uid ?? "")
                await MainActor.run {
                    self.localMedicine = savedMedicine
                    if !dataStore.medicines.contains(where: { $0.id == savedMedicine.id }) {
                        dataStore.medicines.append(savedMedicine)
                    }
                }
            }
        } else {
            Task {
                await medicineDetailVM.updateMedicine(localMedicine, user: session.session?.uid ?? "")
            }
        }
    }
    
    private func saveAisleIfNeeded() {
        if localMedicine.aisle != medicine.aisle {
            print("🧾 Sauvegarde : localMedicine.aisle =", localMedicine.aisle)
            print("🧾 Avant envoi : medicine.id =", localMedicine.id ?? "nil")
            Task {
                await medicineDetailVM.updateMedicine(localMedicine, user: session.session?.uid ?? "", shouldAddHistory: false)
                medicine = localMedicine
                isNew = false
            }
        }
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock Session
        let session = SessionViewModel()
        // Mock DataStore
        let dataStore = DataStore()
        
        // Exemple de Medicine
        let sampleMedicine = Medicine(name: "Doliprane", stock: 42, aisle: "A1")
        dataStore.medicines = [sampleMedicine]
        
        return Group {
            NavigationStack {
                MedicineDetailView(medicine: sampleMedicine, isNew: false)
                    .environmentObject(session)
                    .environmentObject(dataStore)
            }
            .previewDisplayName("Existing Medicine")
            
            NavigationStack {
                MedicineDetailView(medicine: Medicine(name: "", stock: 0, aisle: ""), isNew: true)
                    .environmentObject(session)
                    .environmentObject(dataStore)
            }
            .previewDisplayName("New Medicine")
        }
    }
}
