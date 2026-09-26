import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var incidents: [Incident] = []
    @State private var selectedIncident: Incident?
    @State private var showingReport = false
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 33.7756,
                longitude: -84.3963
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.06,
                longitudeDelta: 0.06
            )
        )
    )

    var body: some View {
        ZStack {
            Map(position: $position) {
                ForEach(incidents) { incident in
                    Annotation(
                        incident.title,
                        coordinate: incident.location.coordinate
                    ) {
                        Button {
                            selectedIncident = incident
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(9)
                                .background(.red)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CircleSafe")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Atlanta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                    } label: {
                        Image(systemName: "person.2.fill")
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        showingReport = true
                    } label: {
                        Label(
                            "Report",
                            systemImage: "exclamationmark.bubble.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                    } label: {
                        Label("Watch Me", systemImage: "shield.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
        }
        .task {
            do {
                incidents = try await APIService.shared.fetchIncidents()
                print("✅ Loaded \(incidents.count) incidents")
            } catch {
                print("❌ Failed to load incidents:", error)
            }
        }
        .sheet(item: $selectedIncident) { incident in
            IncidentDetailView(incident: incident)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingReport) {
            ReportView { newIncident in
                incidents.insert(newIncident, at: 0)
            }
        }
    }
}

struct IncidentDetailView: View {
    let incident: Incident

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                Text(incident.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(incident.summary)
                .font(.body)

            Divider()

            HStack {
                Label(
                    incident.severity.capitalized,
                    systemImage: "gauge.medium"
                )

                Spacer()

                Label(
                    incident.source.capitalized,
                    systemImage: "person.2.fill"
                )
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
    }
}

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var reportText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var incidentCoordinate = CLLocationCoordinate2D(
        latitude: 33.7765,
        longitude: -84.3895
    )

    @State private var reportMapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 33.7765,
                longitude: -84.3895
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.02,
                longitudeDelta: 0.02
            )
        )
    )
    
    @State private var locationName = "Select a location"
    @State private var isFindingLocation = false
    
    let onSubmitted: (Incident) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                Text("What did you notice?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Describe what happened. CircleSafe AI will organize the report for your Circle.")
                    .foregroundStyle(.secondary)

                TextEditor(text: $reportText)
                    .frame(height: 160)
                    .padding(8)
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("Where did this happen?")
                    .font(.headline)

                MapReader { proxy in
                    Map(position: $reportMapPosition) {
                        Annotation(
                            "Incident",
                            coordinate: incidentCoordinate
                        ) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture { screenCoordinate in
                        if let coordinate = proxy.convert(
                            screenCoordinate,
                            from: .local
                        ) {
                            incidentCoordinate = coordinate
                            
                            Task {
                                await findLocationName(for: coordinate)
                            }
                        }
                    }
                }

                Text("Tap the map to place the incident pin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "location.fill")

                    if isFindingLocation {
                        ProgressView()
                    } else {
                        Text(locationName)
                            .fontWeight(.semibold)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button {
                    submit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Submit Report", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(
                    reportText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || isSubmitting
                )

                Spacer()
            }
            .padding()
            .navigationTitle("New Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    private func findLocationName(
        for coordinate: CLLocationCoordinate2D
    ) async {
        await MainActor.run {
            isFindingLocation = true
        }

        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        do {
            let placemarks = try await CLGeocoder()
                .reverseGeocodeLocation(location)

            let placemark = placemarks.first

            let parts = [
                placemark?.name,
                placemark?.locality,
                placemark?.administrativeArea
            ]
            .compactMap { $0 }

            await MainActor.run {
                locationName = parts.isEmpty
                    ? "Selected location"
                    : parts.joined(separator: ", ")

                isFindingLocation = false
            }

        } catch {
            await MainActor.run {
                locationName = "Selected location"
                isFindingLocation = false
            }
        }
    }
    
    
    private func submit() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let incident = try await APIService.shared.submitReport(
                    report: reportText,
                    latitude: incidentCoordinate.latitude,
                    longitude: incidentCoordinate.longitude
                )

                await MainActor.run {
                    onSubmitted(incident)
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    errorMessage = "Could not submit report."
                    isSubmitting = false
                    print("❌ Report submission failed:", error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
