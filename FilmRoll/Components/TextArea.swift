import SwiftUI

// MARK: - Text Area
struct FilmTextArea: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var helperText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(FilmRollTheme.secondaryText.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(FilmRollTheme.inputBackground)
            .cornerRadius(FilmRollTheme.cornerRadiusMedium)
            
            if let helper = helperText {
                Text(helper)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
    }
}

// MARK: - Date Picker Field
struct FilmDatePicker: View {
    let label: String
    @Binding var date: Date
    var helperText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
            
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, 16)
                .frame(height: 52)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FilmRollTheme.inputBackground)
                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
            
            if let helper = helperText {
                Text(helper)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
    }
}

// MARK: - Number Input Field
struct FilmNumberField: View {
    let label: String
    @Binding var value: Int
    var helperText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FilmRollTheme.primaryText)
            
            TextField("", value: $value, format: .number)
                .font(.system(size: 16))
                .keyboardType(.numberPad)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(FilmRollTheme.inputBackground)
                .cornerRadius(FilmRollTheme.cornerRadiusMedium)
            
            if let helper = helperText {
                Text(helper)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
        }
    }
}
