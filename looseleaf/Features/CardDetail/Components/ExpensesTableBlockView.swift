import SwiftUI

/// A clean, rounded expense table embedded in the page.
/// Two columns: Category and Expense (Rupiah), with an auto-calculated total.
struct ExpensesTableBlockView: View {
    let block: InputBlock

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text("Category")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Expense (Rupiah)")
                    .frame(width: 130, alignment: .trailing)
            }
            .font(.subheadline)
            .fontWeight(.bold)

            // Rows
            VStack(spacing: 10) {
                ForEach(block.expenses) { row in
                    HStack(spacing: 12) {
                        Text(row.category)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(RupiahFormatter.string(row.amount))
                            .font(.subheadline)
                            .frame(width: 110, alignment: .trailing)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
            }

            Divider()

            // Total
            HStack(spacing: 12) {
                Text("Total")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(RupiahFormatter.string(block.expensesTotal))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 110, alignment: .trailing)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

#Preview {
    ExpensesTableBlockView(
        block: InputBlock(type: .expenses, expenses: [
            ExpenseRow(category: "mie ayam", amount: 18000),
            ExpenseRow(category: "transjakarta", amount: 3500),
            ExpenseRow(category: "gojek", amount: 26000),
            ExpenseRow(category: "kopi", amount: 17000),
        ])
    )
    .padding()
}
