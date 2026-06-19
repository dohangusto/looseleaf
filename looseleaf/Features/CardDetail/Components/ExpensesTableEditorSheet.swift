import SwiftUI

/// Bottom sheet to create or edit an Expenses Tab block. Visually resembles the
/// embedded expense card, with editable rows and a live total.
struct ExpensesTableEditorSheet: View {
    let title: String
    @State private var rows: [ExpenseRow]
    var onCancel: () -> Void
    var onSave: (_ rows: [ExpenseRow]) -> Void

    init(title: String,
         rows: [ExpenseRow],
         onCancel: @escaping () -> Void,
         onSave: @escaping ([ExpenseRow]) -> Void) {
        self.title = title
        self._rows = State(initialValue: rows.isEmpty ? [ExpenseRow(category: "", amount: 0)] : rows)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    private var total: Int { rows.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Column headers
                    HStack {
                        Text("Category")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Expense (Rupiah)")
                            .frame(width: 140, alignment: .trailing)
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)

                    VStack(spacing: 10) {
                        ForEach($rows) { $row in
                            HStack(spacing: 10) {
                                TextField("Category", text: $row.category)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))

                                TextField("0", value: $row.amount, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))

                                Button {
                                    rows.removeAll { $0.id == row.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .disabled(rows.count <= 1)
                                .opacity(rows.count <= 1 ? 0.3 : 1)
                            }
                        }
                    }

                    Button {
                        rows.append(ExpenseRow(category: "", amount: 0))
                    } label: {
                        Label("Add row", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)

                    Divider()

                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(RupiahFormatter.string(total))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray)))
                    }
                    .font(.subheadline)
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Drop fully-empty rows on save.
                        onSave(rows.filter { !($0.category.isEmpty && $0.amount == 0) })
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ExpensesTableEditorSheet(title: "Edit Expenses", rows: [
        ExpenseRow(category: "mie ayam", amount: 18000),
        ExpenseRow(category: "transjakarta", amount: 3500),
    ], onCancel: {}, onSave: { _ in })
}
