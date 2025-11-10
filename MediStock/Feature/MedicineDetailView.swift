import SwiftUI

struct MedicineDetailView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @EnvironmentObject var session: SessionViewModel
    @State var medicine: Medicine
    @State var isNew: Bool = false //pr gérer l'ajout d'un médicament
    @State private var hasSaved = false
    @State private var isEditingStock = false
    @FocusState private var isAisleFocused: Bool
    @FocusState private var isNameFocused: Bool
   
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(medicine.name)
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
            } else {
                medicineStockVM.fetchHistory(for: medicine)
            }
        }
        .onChange(of: medicine.aisle) {_, _ in
            saveIfNeeded()
        }
    }
}

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.headline)
            TextField("Name", text: $medicine.name)
                .focused($isNameFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 10)
                .onChange(of: isNameFocused) { _, focused in
                    if !focused {
                        saveIfNeeded()
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
                        medicine.stock += 1
                        Task {
                            let newStock = await medicineStockVM.decreaseStock(medicine, user: session.session?.uid ?? "")
                            DispatchQueue.main.async {
                                self.medicine.stock = newStock
                            }
                            isEditingStock = false
                        }
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title)
                        .foregroundColor(.red)
                }
                
                TextField("Stock", value: Binding(
                    get: {
                        medicineStockVM.medicines.first(where: { $0.id == medicine.id })?.stock ?? medicine.stock
                    },
                    set: { newValue in
                        guard !isNew else { return }
                        Task {
                            let updatedStock = await medicineStockVM.updateStock(medicine, by: newValue, user: session.session?.uid ?? "")
                            DispatchQueue.main.async {
                                self.medicine.stock = updatedStock
                            }
                        }
                    }
                ), formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .frame(width: 100)
                .disabled(isNew)
                
                Button(action: {
                    Task {
                        guard !isNew else { return }
                        Task {
                            isEditingStock = true
                            let newStock = await medicineStockVM.increaseStock(medicine, user: session.session?.uid ?? "")
                            DispatchQueue.main.async {
                                self.medicine.stock = newStock
                            }
                            isEditingStock = false
                        }
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
            TextField("Aisle", text: $medicine.aisle)
                .focused($isAisleFocused)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.bottom, 10)
            .disabled(medicine.name.isEmpty)
            .onChange(of: isAisleFocused) { _, focused in
                if !focused {
                    medicineStockVM.updateMedicine(medicine, user: session.session?.uid ?? "")
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
            ForEach(medicineStockVM.history.filter { $0.medicineId == medicine.id }, id: \.id) { entry in
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.action)
                        .font(.headline)
                    Text("User: \(entry.user)")
                        .font(.subheadline)
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
        let isValid = !medicine.name.isEmpty
        guard isValid && !hasSaved else { return }
        
        if isNew {
            medicineStockVM.addMedicine(medicine, user: session.session?.uid ?? "") { savedMedicine in
                self.medicine = savedMedicine
                self.isNew = false
            }
        } else {
            medicineStockVM.updateMedicine(medicine, user: session.session?.uid ?? "")
        }
        hasSaved = true
    }
}

struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMedicine = Medicine(name: "Sample", stock: 10, aisle: "Aisle 1")
        let sampleViewModel = MedicineStockViewModel()
        MedicineDetailView(medicineStockVM: sampleViewModel, medicine: sampleMedicine).environmentObject(SessionViewModel())
    }
}
