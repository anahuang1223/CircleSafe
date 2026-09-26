import SwiftUI

struct CircleMember: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
}

struct CircleView: View {
    @Environment(\.dismiss) private var dismiss

    let members = [
        CircleMember(name: "You", initials: "YO"),
        CircleMember(name: "Maya", initials: "MA"),
        CircleMember(name: "Alex", initials: "AL")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Roommates")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("3 members")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Members") {
                    ForEach(members) { member in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.blue.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Text(member.initials)
                                    .fontWeight(.semibold)
                            }

                            Text(member.name)

                            Spacer()

                            if member.name == "You" {
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        // Invite flow comes later
                    } label: {
                        Label("Invite Friend", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("My Circle")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CircleView()
}
