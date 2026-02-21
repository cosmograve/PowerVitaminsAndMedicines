import SwiftUI
import UIKit
import PDFKit

struct MainView: View {

    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]

    @State private var selectedEventForAction: DoseEvent? = nil

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "List Of Pills", showsBack: false, onBackTap: nil)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if morningItems.isEmpty && eveningItems.isEmpty {
                            emptyState
                        } else {
                            if !morningItems.isEmpty {
                                SectionTitle(icon: "sun.max.fill", title: "Morning")
                                ForEach(morningItems) { item in
                                    medicationCard(item)
                                }
                            }

                            if !eveningItems.isEmpty {
                                SectionTitle(icon: "moon.fill", title: "Evening")
                                ForEach(eveningItems) { item in
                                    medicationCard(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.sidePadding)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }

            if let event = selectedEventForAction {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { selectedEventForAction = nil }

                takeOverlay(for: event)
                    .padding(.horizontal, AppLayout.sidePadding)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedEventForAction == nil {
                FloatingAddButton {
                    path.append(.medicationEditor(mode: .create))
                }
                .padding(.trailing, AppLayout.sidePadding)
                .padding(.bottom, AppLayout.sidePadding)
            }
        }
        .onAppear {
            store.ensureTodayScheduleExists()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var todayEvents: [DoseEvent] {
        store.doseEvents(for: Date())
    }

    private var items: [MedicationListItem] {
        todayEvents.compactMap { event in
            guard let medication = store.medication(by: event.medicationId) else { return nil }
            return MedicationListItem(
                event: event,
                medication: medication
            )
        }
        .sorted { $0.event.scheduledAt < $1.event.scheduledAt }
    }

    private var morningItems: [MedicationListItem] {
        items.filter { calendar.component(.hour, from: $0.event.scheduledAt) < 12 }
    }

    private var eveningItems: [MedicationListItem] {
        items.filter { calendar.component(.hour, from: $0.event.scheduledAt) >= 12 }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You don't have any pills yet.")
                .font(AppFont.poppins(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text("Tap + to add your first medication.")
                .font(AppFont.poppins(size: 14, weight: .regular))
                .foregroundColor(AppColors.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func medicationCard(_ item: MedicationListItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(item.medication.category.title)
                            .font(AppFont.poppins(size: 14, weight: .regular))
                            .foregroundColor(AppColors.yellow)

                        Text(timeString(item.event.scheduledAt))
                            .font(AppFont.poppins(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text(item.medication.name)
                        .font(AppFont.poppins(size: 30 / 2, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.blue.opacity(0.30))
                    .frame(width: 94, height: 94)
                    .overlay(
                        Group {
                            if let image = packageImage(for: item.medication) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Text(item.medication.category.icon)
                                    .font(.system(size: 34))
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                path.append(.pillCard(id: item.medication.id))
            }

            statusChip(item.event.status) {
                selectedEventForAction = item.event
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.92))
        )
    }

    private func statusChip(_ status: IntakeStatus, onTap: @escaping () -> Void) -> some View {
        let bg: Color
        let title: String

        switch status {
        case .taken:
            bg = AppColors.green
            title = "✓ Taken"
        case .missed:
            bg = Color(hex: "B70F0F")
            title = "× Missed"
        case .planned:
            bg = AppColors.gray
            title = "Planned"
        }

        return Button(action: onTap) {
            Text(title)
                .font(AppFont.poppins(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(bg)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func takeOverlay(for event: DoseEvent) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    selectedEventForAction = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, -6)

            if let medication = store.medication(by: event.medicationId) {
                Text("Take \(medication.name)\n(\(medication.subtitle))")
                    .font(AppFont.poppins(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 14) {
                Button {
                    store.markDoseEvent(id: event.id, status: .taken)
                    selectedEventForAction = nil
                } label: {
                    Text("✓ Taken")
                        .font(AppFont.poppins(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppColors.green)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    store.markDoseEvent(id: event.id, status: .missed)
                    selectedEventForAction = nil
                } label: {
                    Text("× Missed")
                        .font(AppFont.poppins(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "B70F0F"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func packageImage(for medication: Medication) -> UIImage? {
        guard
            let packaging = medication.attachments.first(where: { $0.kind == .packagePhoto }),
            let url = try? LocalAttachmentsManager.shared.url(forRelativePath: packaging.relativePath),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }
}

private struct MedicationListItem: Identifiable {
    var id: UUID { event.id }
    let event: DoseEvent
    let medication: Medication
}

private struct SectionTitle: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text(title)
                .font(AppFont.poppins(size: 38 / 2, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.top, 4)
    }
}
#Preview {
    MainView(path: .constant([]))
        .environmentObject(AppStore())
}

struct PillCardView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm: Bool = false
    @State private var instructionImagePreview: InstructionImagePreviewItem? = nil
    @State private var instructionPDFPreview: InstructionPDFPreviewItem? = nil

    let medicationId: UUID

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Pill Card", showsBack: true, onBackTap: { dismiss() })

                ScrollView(showsIndicators: false) {
                    if let med = store.medication(by: medicationId) {
                        content(for: med)
                            .padding(.horizontal, AppLayout.sidePadding)
                            .padding(.top, 12)
                            .padding(.bottom, 18)
                    } else {
                        Text("Medication not found")
                            .font(AppFont.poppins(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 28)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Delete medication?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteMedication(id: medicationId)
                path.removeAll()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the medication, its events, and pending reminders.")
        }
        .fullScreenCover(item: $instructionImagePreview) { item in
            InstructionImageViewer(image: item.image)
        }
        .sheet(item: $instructionPDFPreview) { item in
            InstructionPDFViewer(url: item.url)
        }
    }

    private func content(for med: Medication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            headerImage(for: med)

            Text(med.name)
                .font(AppFont.poppins(size: 44 / 2, weight: .semibold))
                .foregroundColor(.white)

            Text(med.subtitle)
                .font(AppFont.poppins(size: 34 / 2, weight: .regular))
                .foregroundColor(AppColors.yellow)

            HStack(spacing: 10) {
                infoRow(title: "Date Picker", value: dateString(med.expiryDate))
                infoRow(title: "TimePicker", value: med.intakeTime.formatted24h())
            }

            infoRow(title: "Category", value: med.category.title)
            infoRow(title: "Frequency", value: med.frequency.title)
            reminderToggleRow(medicationId: med.id)

            instructionsBlock(for: med)

            Button {
                path.append(.medicationEditor(mode: .edit(id: med.id)))
            } label: {
                Text("Edit")
                    .font(AppFont.poppins(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Button {
                showDeleteConfirm = true
            } label: {
                Text("Delete")
                    .font(AppFont.poppins(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "B70F0F"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func headerImage(for med: Medication) -> some View {
        let pack = med.attachments.first(where: { $0.kind == .packagePhoto })
        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.95))

            if let pack, let image = loadImage(relativePath: pack.relativePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                Text("💊")
                    .font(.system(size: 64))
            }
        }
        .frame(height: 220)
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.poppins(size: 15, weight: .semibold))
                .foregroundColor(AppColors.yellow)

            Text(value)
                .font(AppFont.poppins(size: 34 / 2, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.95))
        )
    }

    private func instructionsBlock(for med: Medication) -> some View {
        let instruction = med.attachments.first(where: { $0.kind == .instructionPhoto || $0.kind == .instructionPDF })
        return VStack(alignment: .leading, spacing: 10) {
            Text("Instructions")
                .font(AppFont.poppins(size: 16, weight: .semibold))
                .foregroundColor(AppColors.yellow)

            Text("Use as prescribed. Check attached instruction file for details.")
                .font(AppFont.poppins(size: 16, weight: .regular))
                .foregroundColor(.white)

            if let instruction {
                if instruction.kind == .instructionPhoto,
                   let image = loadImage(relativePath: instruction.relativePath) {
                    Button {
                        instructionImagePreview = InstructionImagePreviewItem(image: image)
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 154)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        if let url = instructionURL(relativePath: instruction.relativePath) {
                            instructionPDFPreview = InstructionPDFPreviewItem(url: url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(AppColors.yellow)
                            Text("Instruction PDF attached (Tap to open)")
                                .font(AppFont.poppins(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.blue)
        )
    }

    private func reminderToggleRow(medicationId: UUID) -> some View {
        let enabled = store.medication(by: medicationId)?.notificationsEnabled ?? false

        return Button {
            let current = store.medication(by: medicationId)?.notificationsEnabled ?? false
            store.setNotificationsEnabled(for: medicationId, enabled: !current)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminders")
                        .font(AppFont.poppins(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.yellow)
                    Text(enabled ? "Enabled" : "Disabled")
                        .font(AppFont.poppins(size: 34 / 2, weight: .regular))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: enabled ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(enabled ? AppColors.yellow : .white.opacity(0.75))
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.95))
        )
    }

    private func loadImage(relativePath: String) -> UIImage? {
        guard
            let url = try? LocalAttachmentsManager.shared.url(forRelativePath: relativePath),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }

    private func dateString(_ date: Date?) -> String {
        guard let date else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }

    private func instructionURL(relativePath: String) -> URL? {
        try? LocalAttachmentsManager.shared.url(forRelativePath: relativePath)
    }
}

private struct InstructionImagePreviewItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct InstructionPDFPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct InstructionImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(18)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(18)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct InstructionPDFViewer: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        NavigationStack {
            PDFDocumentView(url: url)
                .background(AppColors.background)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .font(AppFont.poppins(size: 16, weight: .semibold))
                    }
                }
                .navigationTitle("Instruction")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(url: url)
        }
    }
}
