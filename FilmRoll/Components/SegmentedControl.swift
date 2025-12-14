import SwiftUI

struct SegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                }) {
                    Text(options[index])
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selectedIndex == index ? .white : FilmRollTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedIndex == index ? FilmRollTheme.buttonBackground : Color.clear
                        )
                        .cornerRadius(FilmRollTheme.cornerRadiusPill)
                }
            }
        }
        .padding(4)
        .background(FilmRollTheme.inputBackground)
        .cornerRadius(FilmRollTheme.cornerRadiusPill)
    }
}

// MARK: - Stepper Control
struct StepperControl: View {
    let value: Binding<Int>
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: {
                if value.wrappedValue > range.lowerBound {
                    value.wrappedValue -= 1
                }
            }) {
                Circle()
                    .fill(FilmRollTheme.inputBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    )
            }
            
            Text("\(value.wrappedValue)")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(FilmRollTheme.primaryText)
                .frame(minWidth: 60)
            
            Button(action: {
                if value.wrappedValue < range.upperBound {
                    value.wrappedValue += 1
                }
            }) {
                Circle()
                    .fill(FilmRollTheme.inputBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FilmRollTheme.primaryText)
                    )
            }
        }
    }
}

// MARK: - Toggle Row
struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var iconColor: Color = FilmRollTheme.accent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: FilmRollTheme.accent))
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Navigation Row
struct NavigationRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(FilmRollTheme.primaryText)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(FilmRollTheme.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FilmRollTheme.secondaryText)
            }
            .padding(.vertical, 12)
        }
    }
}
