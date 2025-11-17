import SwiftUI

struct MedicineDetailView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @EnvironmentObject var session: SessionViewModel
    @State var medicine: Medicine
    @State var isNew: Bool = false //pr gérer l'ajout d'un médicament
    //@State private var hasSaved = false
    @State private var hasSavedAisle = false
    @State private var isEditingStock = false
    @State private var stockText: String = ""
    @State private var originalStock: Int = 0
    @FocusState private var isAisleFocused: Bool
    @State private var lastValidAisle: String = ""
    @FocusState private var isNameFocused: Bool
    @State private var lastValidName: String = ""
    @State private var localMedicine: Medicine // pour éviter que quand on maj aisle la liste de AisleListView se maj et qu'on sorte de la vue details
    
    init(medicine: Medicine, medicineStockVM: MedicineStockViewModel, isNew: Bool = false) {
        self.medicine = medicine
        self._localMedicine = State(initialValue: medicine) // copie locale
        self.medicineStockVM = medicineStockVM
        self._isNew = State(initialValue: isNew)
    }
   
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(localMedicine.name)
                    .font(.largeTitle)
                    .padding(.top, 20)

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
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .onAppear {
            if isNew {
                medicine = Medicine(name: "", stock: 0, aisle: "")
                localMedicine = medicine
            } else {
                medicineStockVM.fetchHistory(for: medicine)
            }
        }
        .onDisappear {
            saveAisleIfNeeded()
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
                            let newStock = await medicineStockVM.decreaseStock(localMedicine, user: session.session?.uid ?? "")
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
                
                TextField("Stock", text: $stockText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 100)
                .disabled(isNew)
                .onAppear {
                    // Récupérer le stock réel depuis le VM
                    let realStock = medicineStockVM.medicines.first(where: { $0.id == localMedicine.id })?.stock ?? localMedicine.stock
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
                            let finalStock = await medicineStockVM.updateStock(
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
                        let newStock = await medicineStockVM.increaseStock(localMedicine, user: session.session?.uid ?? "")
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
                .onChange(of: localMedicine.aisle) {_, newAisle in
                    if newAisle.allSatisfy({ $0.isNumber }) {
                        // Chiffres seulement → update lastValidAisle
                        lastValidAisle = newAisle
                        
                        // Si le champ n'est pas vide et ce n'est pas un nouveau médicament, on ajoute l'historique
                        if !newAisle.isEmpty && !isNew {
                            Task {
                                await medicineStockVM.addHistory(
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
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.top, 20)
            ForEach(medicineStockVM.history
                .filter { $0.medicineId == localMedicine.id }
                .sorted { $0.timestamp < $1.timestamp },
                    id: \.id) { entry in
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.action)
                        .font(.headline)
                    Text("User: \(medicineStockVM.emailsCache[entry.user] ?? "Chargement...")")
                        .font(.subheadline)
                        .task {
                            _ = await medicineStockVM.fetchEmail(for: entry.user)
                        }
                    Text("Date: \(entry.timestamp.formatted())")
                        .font(.subheadline)
                    Text("Details: \(entry.details)")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 5)
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
                let savedMedicine = await medicineStockVM.addMedicine(localMedicine, user: session.session?.uid ?? "")
                await MainActor.run {
                    self.localMedicine = savedMedicine
                }
            }
        } else {
            Task {
                await medicineStockVM.updateMedicine(localMedicine, user: session.session?.uid ?? "")
            }
        }
    }
    
    private func saveAisleIfNeeded() {
        if localMedicine.aisle != medicine.aisle {
            print("🧾 Sauvegarde : localMedicine.aisle =", localMedicine.aisle)
            print("🧾 Avant envoi : medicine.id =", localMedicine.id ?? "nil")
            Task {
                await medicineStockVM.updateMedicine(localMedicine, user: session.session?.uid ?? "", shouldAddHistory: false)
                medicine = localMedicine
                isNew = false
            }
        }
    }
}

/*struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedicine = Medicine(name: "Sample", stock: 10, aisle: "Aisle 1")
        let sampleViewModel = MedicineStockViewModel()
        MedicineDetailView(medicine: sampleMedicine, medicineStockVM: sampleViewModel).environmentObject(SessionViewModel())
    }
}
*/
