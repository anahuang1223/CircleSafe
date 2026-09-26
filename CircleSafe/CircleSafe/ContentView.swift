import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @State private var incidents: [Incident] = []
    @State private var selectedIncident: Incident?
    @State private var refreshTask: Task<Void, Never>?
    @State private var showingReport = false
    @State private var showingCircle = false
    @State private var isWatchActive = false
    @State private var showingWatchSession = false
    @State private var activeWatchSession: WatchSession?
    @State private var myWatchSessionId: String?
    @State private var showingWatcherView = false
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
                        showingCircle = true
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
                        Task {
                            do {
                                let session = try await APIService.shared.startWatch()

                                await MainActor.run {
                                    activeWatchSession = session
                                    myWatchSessionId = session.id
                                    isWatchActive = true
                                    showingWatchSession = true
                                }

                                print("Watch session started")
                            } catch {
                                print("Failed to start Watch session:", error)
                            }
                        }
                    } label: {
                        Label("Watch Me", systemImage: "shield.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                if let session = activeWatchSession,
                   session.id != myWatchSessionId {

                    Button {
                        showingWatcherView = true
                    } label: {
                        Label(
                            "Circle member is using Watch Me",
                            systemImage: "eye.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .task {
            while !Task.isCancelled {
                do {
                    incidents = try await APIService.shared.fetchIncidents()
                    let watchSession = try await APIService.shared.fetchActiveWatch()
                    
                    if watchSession?.id != activeWatchSession?.id {
                        activeWatchSession = watchSession
                        // The other person ended Watch Me
                        if watchSession == nil {
                            showingWatcherView = false
                        }
                    }
                    print("Refreshed \(incidents.count) incidents")
                } catch {
                    print("Failed to refresh incidents:", error)
                }
                
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    break
                }
            }
        }
        .sheet(item: $selectedIncident) { selected in
            if let index = incidents.firstIndex(where: { $0.id == selected.id }) {
                IncidentDetailView(incident: $incidents[index])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                Text("Incident unavailable")
            }
        }
        .sheet(isPresented: $showingReport) {
            ReportView { newIncident in
                incidents.insert(newIncident, at: 0)
            }
        }
        .sheet(isPresented: $showingCircle) {
            CircleView()
        }
        .sheet(isPresented: $showingWatchSession) {
            if let session = activeWatchSession {
                WatchSessionView(
                    session: session,
                    isWatchActive: $isWatchActive,
                    activeWatchSession: $activeWatchSession,
                    myWatchSessionId: $myWatchSessionId
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingWatcherView) {
            if let session = activeWatchSession {
                WatcherView(session: session)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}
struct WatchSessionView: View {
    let session: WatchSession
    @Binding var isWatchActive: Bool
    @Binding var activeWatchSession: WatchSession?
    @Binding var myWatchSessionId: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Watch Me Active")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your safety session is active.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(role: .destructive) {
                Task {
                    do {
                        try await APIService.shared.endWatch(
                            sessionId: session.id
                        )

                        await MainActor.run {
                            isWatchActive = false
                            activeWatchSession = nil
                            myWatchSessionId = nil
                            dismiss()
                        }

                        print("Watch session ended")
                    } catch {
                        print("Failed to end Watch session:", error)
                    }
                }
            } label: {
                Text("End Watch")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
struct WatcherView: View {
    let session: WatchSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Watching Circle Member")
                .font(.title2)
                .fontWeight(.bold)

            Text("Their live location will appear here while Watch Me is active.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
    }
}

struct IncidentDetailView: View {
    @Binding var incident: Incident
    @State private var displayedNearbyCount: Int
    @State private var displayedThanksCount: Int

    init(incident: Binding<Incident>) {
        self._incident = incident
        self._displayedNearbyCount = State(
            initialValue: incident.wrappedValue.nearbyCount ?? 0
        )
        self._displayedThanksCount = State(
            initialValue: incident.wrappedValue.thanksCount ?? 0
        )
    }

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

            if let locationContext = incident.locationContext {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Location Context", systemImage: "location.fill")
                        .font(.headline)

                    Text(locationContext.areaType)
                        .fontWeight(.semibold)

                    Text(locationContext.context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()
            }
            
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
            
            Divider()

            Text("Respond to your Circle")
                .font(.headline)

            HStack(spacing: 10) {
                Button {
                    Task {
                        do {
                            try await APIService.shared.sendThanks(
                                incidentId: incident.id
                            )

                            displayedThanksCount += 1

                            print("Thanks sent")
                        } catch {
                            print("Thanks failed:", error)
                        }
                    }
                } label: {
                    Label("Thanks", systemImage: "hand.thumbsup.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    Task {
                        do {
                            try await APIService.shared.markNearby(
                                incidentId: incident.id
                            )

                            displayedNearbyCount += 1

                            print("Nearby response sent")
                        } catch {
                            print("Nearby response failed:", error)
                        }
                    }
                } label: {
                    Label("I'm nearby", systemImage: "location.fill")
                }
                .buttonStyle(.bordered)
            }
            if displayedNearbyCount > 0 {
                Text(
                    "\(displayedNearbyCount) Circle member\(displayedNearbyCount == 1 ? "" : "s") nearby"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if displayedThanksCount > 0 {
                Text(
                    "\(displayedThanksCount) \(displayedThanksCount == 1 ? "person" : "people") thanked this report"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .onChange(of: incident.nearbyCount) { _, newValue in
            displayedNearbyCount = newValue ?? 0
        }
        .onChange(of: incident.thanksCount) { _, newValue in
            displayedThanksCount = newValue ?? 0
        }
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share with")
                        .font(.headline)

                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading) {
                            Text("Roommates")
                                .fontWeight(.semibold)

                            Text("3 members")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
